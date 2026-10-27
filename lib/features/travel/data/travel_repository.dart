import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_photos.dart';
import '../../../core/errors.dart';
import '../../../core/validation.dart';
import '../domain/models.dart';

class TravelRepository {
  TravelRepository(this._db, this.uid) : _photos = LocalPhotos(uid);
  final FirebaseFirestore _db;
  final LocalPhotos _photos;
  final String uid;
  CollectionReference<Map<String, dynamic>> get _entries =>
      _db.collection('users').doc(uid).collection('travel_entries');
  String newId() => _entries.doc().id;
  Stream<List<TravelEntry>> watch() => _entries
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(TravelEntry.fromDocument).toList());
  Future<Uint8List?> image(String path) => _photos.read(path);

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
    imageType(bytes);
    final doc = _entries.doc(id);
    if ((await doc.get(const GetOptions(source: Source.server))).exists) return;
    final path = _photos.pathFor(id);
    progress(0);
    await _photos.save(path, bytes);
    progress(null);
    // Create-only pelas regras. Em resposta incerta, consultar o mesmo ID
    // antes de repetir; preservar a foto ate confirmacao ou descarte.
    await doc.set({
      'placeName': name.trim(),
      'memory': memory.trim(),
      'imagePath': path,
      'imageStorage': 'local',
      'coordinates': GeoPoint(place.latitude, place.longitude),
      'locationSource': place.source,
      'placeProvider': place.provider,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(TravelEntry entry) => discard(entry.id);

  Future<void> discard(String id) async {
    // Confirmar a exclusao remota antes de remover a copia local.
    await _entries.doc(id).delete();
    await _photos.remove(_photos.pathFor(id));
  }
}
