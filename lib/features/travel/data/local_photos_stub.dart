import 'dart:typed_data';
import '../../../core/errors.dart';

class LocalPhotos {
  LocalPhotos(this.uid);
  final String uid;
  String pathFor(String id) => 'users/$uid/travel_entries/$id/photo';
  Future<void> save(String path, Uint8List bytes) async =>
      throw const AppException(
        'Para guardar fotos no dispositivo, use o aplicativo Android.',
      );
  Future<Uint8List?> read(String path) async => null;
  Future<void> remove(String path) async {}
}
