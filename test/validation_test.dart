import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourvel/core/errors.dart';
import 'package:yourvel/core/validation.dart';
import 'package:yourvel/features/travel/data/travel_repository.dart';

void main() {
  test('valida limites após remover espaços', () {
    expect(Validation.name(' a '), isNotNull);
    expect(Validation.name(' ab '), isNull);
    expect(Validation.name('x' * 100), isNull);
    expect(Validation.name('x' * 101), isNotNull);
    expect(Validation.memory('   '), isNotNull);
    expect(Validation.memory('x' * 1000), isNull);
    expect(Validation.memory('x' * 1001), isNotNull);
    expect(Validation.email('nome@exemplo.com'), isNull);
    expect(Validation.email('nome sem email'), isNotNull);
  });
  test('recusa tipo e tamanho de imagem inválidos antes do envio', () {
    expect(
      () => TravelRepository.imageType(Uint8List(0)),
      throwsA(isA<AppException>()),
    );
    expect(
      () => TravelRepository.imageType(Uint8List(5242881)),
      throwsA(isA<AppException>()),
    );
    expect(
      TravelRepository.imageType(Uint8List.fromList([255, 216, 255, 0])),
      'image/jpeg',
    );
    expect(
      TravelRepository.imageType(
        Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
      ),
      'image/png',
    );
  });
}
