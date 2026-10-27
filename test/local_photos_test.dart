import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourvel/core/errors.dart';
import 'package:yourvel/features/travel/data/local_photos_io.dart';

void main() {
  late Directory root;
  late LocalPhotos photos;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('yourvel-test-');
    photos = LocalPhotos('alice', directory: () async => root);
  });
  tearDown(() async => root.delete(recursive: true));
  test('foto persiste entre instâncias e exclusão é repetível', () async {
    final path = photos.pathFor('entry1');
    final bytes = Uint8List.fromList([1, 2, 3]);
    await photos.save(path, bytes);
    final reopened = LocalPhotos('alice', directory: () async => root);
    expect(await reopened.read(path), bytes);
    await reopened.remove(path);
    await reopened.remove(path);
    expect(await reopened.read(path), isNull);
  });
  test('rejeita caminho alheio e travessia de diretórios', () async {
    await expectLater(
      photos.read('users/bob/travel_entries/entry1/photo'),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      photos.remove('../outside'),
      throwsA(isA<AppException>()),
    );
    expect(() => photos.pathFor('../outside'), throwsA(isA<AppException>()));
  });
}
