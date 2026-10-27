import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yourvel/core/errors.dart';
import 'package:yourvel/features/travel/data/places_repository.dart';

void main() {
  test('converte resultados e reutiliza cache sem nova chamada HTTP', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      expect(request.url.queryParameters['name'], 'Recife');
      return http.Response(
        '{"results":[{"name":"Recife","admin1":"Pernambuco","country":"Brasil","latitude":-8.05,"longitude":-34.9}]}',
        200,
      );
    });
    final repo = PlacesRepository(client);
    final places = await repo.search('Recife');
    expect(places.single.name, 'Recife, Pernambuco, Brasil');
    expect(places.single.latitude, -8.05);
    expect(await repo.search('Recife'), same(places));
    expect(calls, 1);
    client.close();
  });
  test('trata resultado vazio e falha HTTP', () async {
    final empty = MockClient((_) async => http.Response('{}', 200));
    expect(await PlacesRepository(empty).search('Lugar'), isEmpty);
    final failing = MockClient((_) async => http.Response('indisponível', 503));
    await expectLater(
      PlacesRepository(failing).search('Recife'),
      throwsA(isA<AppException>()),
    );
    empty.close();
    failing.close();
  });
  test('não envia busca curta para a API', () async {
    final client = MockClient(
      (_) async => throw StateError('Não deveria chamar HTTP'),
    );
    await expectLater(
      PlacesRepository(client).search('ab'),
      throwsA(isA<AppException>()),
    );
    client.close();
  });
}
