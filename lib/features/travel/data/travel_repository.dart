import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/errors.dart';
import '../../../core/validation.dart';
import '../domain/models.dart';

class TravelRepository {
  TravelRepository(this._db, this._storage, this._functions, this.uid);
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  final String uid;
  CollectionReference<Map<String, dynamic>> get _entries =>
      _db.collection('users').doc(uid).collection('travel_entries');
  String newId() => _entries.doc().id;
  Stream<List<TravelEntry>> watch() => _entries
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(TravelEntry.fromDocument).toList());
  Future<Uint8List?> image(String path) => _storage.ref(path).getData(5242880);

  static String imageType(Uint8List bytes) {
    if (bytes.length > 5242880) {
      throw const AppException('A foto deve ter até 5 MiB.');
    }
    if (bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255) {
      return 'image/jpeg';
    }
    const png = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length >= 8 &&
        List.generate(8, (i) => bytes[i] == png[i]).every((v) => v)) {
      return 'image/png';
    }
    throw const AppException('Selecione uma foto JPEG ou PNG.');
  }

  Future<void> save({
    required String id,
    required String name,
    required String memory,
    required Place place,
    required Uint8List bytes,
    required void Function(double?) progress,
  }) async {
    final validation = Validation.name(name) ?? Validation.memory(memory);
    if (validation != null) throw AppException(validation);
    if (!place.latitude.isFinite ||
        !place.longitude.isFinite ||
        place.latitude.abs() > 90 ||
        place.longitude.abs() > 180) {
      throw const AppException('Selecione uma localização válida.');
    }
    final type = imageType(bytes);
    // Um ID estável permite verificar uma gravação cuja resposta foi perdida.
    final doc = _entries.doc(id);
    if ((await doc.get(const GetOptions(source: Source.server))).exists) return;
    final ref = _storage.ref('users/$uid/travel_entries/$id/photo');
    StreamSubscription<TaskSnapshot>? subscription;
    try {
      // Reutilizar o objeto de uma tentativa anterior, sem sobrescrever fotos.
      try {
        await ref.getMetadata();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') rethrow;
        final task = ref.putData(bytes, SettableMetadata(contentType: type));
        subscription = task.snapshotEvents.listen((event) {
          progress(
            event.totalBytes == 0
                ? 0
                : event.bytesTransferred / event.totalBytes,
          );
        }, onError: (Object _) {});
        await task;
      }
      progress(null);
      await _functions
          .httpsCallable(
            'finalizeEntry',
            options: HttpsCallableOptions(
              timeout: const Duration(seconds: 120),
            ),
          )
          .call({
            'id': id,
            'placeName': name.trim(),
            'memory': memory.trim(),
            'latitude': place.latitude,
            'longitude': place.longitude,
            'locationSource': place.source,
            'placeProvider': place.provider,
          });
    } catch (_) {
      // Nunca remover a foto quando a confirmação do Firestore é incerta.
      try {
        final saved = await doc.get(const GetOptions(source: Source.server));
        if (saved.exists) return;
      } catch (_) {
        throw const AppException(
          'Não foi possível confirmar o envio. Tente novamente sem fechar este formulário.',
        );
      }
      rethrow;
    } finally {
      await subscription?.cancel();
    }
  }

  Future<void> delete(TravelEntry entry) async {
    await discard(entry.id);
  }

  Future<void> discard(String id) async {
    await _functions
        .httpsCallable(
          'deleteEntry',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
        )
        .call({'id': id});
  }
}
