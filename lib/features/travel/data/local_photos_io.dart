import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../../core/errors.dart';

/// Caminhos relativos à pasta privada permanente do aplicativo.
class LocalPhotos {
  LocalPhotos(this.uid, {Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;
  final String uid;
  final Future<Directory> Function() _directory;

  String pathFor(String id) {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(uid) ||
        !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
      throw const AppException('Identificador de foto inválido.');
    }
    return 'users/$uid/travel_entries/$id/photo';
  }

  Future<File> _file(String path) async {
    final parts = path.split('/');
    if (parts.length != 5 || path != pathFor(parts[3])) {
      throw const AppException('Caminho de foto inválido para este usuário.');
    }
    final root = await _directory();
    return File('${root.path}/$path');
  }

  Future<void> save(String path, Uint8List bytes) async {
    try {
      final file = await _file(path);
      await file.parent.create(recursive: true);
      // Tentativas repetidas usam o mesmo ID e os mesmos bytes do formulário.
      await file.writeAsBytes(bytes, flush: true);
    } on FileSystemException {
      throw const AppException(
        'Não foi possível guardar a foto no dispositivo. Confira o espaço disponível.',
      );
    }
  }

  Future<Uint8List?> read(String path) async {
    final file = await _file(path);
    if (!await file.exists()) return null;
    if (await file.length() > 5242880) return null;
    return file.readAsBytes();
  }

  Future<void> remove(String path) async {
    final file = await _file(path);
    if (await file.exists()) await file.delete();
  }
}
