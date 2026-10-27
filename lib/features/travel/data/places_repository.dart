import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/errors.dart';
import '../domain/models.dart';

/// Busca de cidades por Open-Meteo/GeoNames para uso acadêmico não comercial.
class PlacesRepository {
  PlacesRepository(this._client);
  final http.Client _client;
  DateTime? _lastRequest;
  final Map<String, List<Place>> _cache = {};

  Future<List<Place>> search(String query) async {
    final text = query.trim();
    if (text.length < 3) {
      throw const AppException('Digite pelo menos 3 caracteres.');
    }
    if (_cache.containsKey(text)) return _cache[text]!;
    final last = _lastRequest;
    if (last != null && DateTime.now().difference(last).inMilliseconds < 1100) {
      throw const AppException(
        'Aguarde um instante antes de buscar novamente.',
      );
    }
    _lastRequest = DateTime.now();
    final response = await _client
        .get(
          Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
            'name': text,
            'count': '5',
            'language': 'pt',
            'format': 'json',
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw const AppException(
        'A busca está indisponível. Tente novamente mais tarde.',
      );
    }
    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final rows = data['results'] as List<dynamic>? ?? [];
    final places = rows
        .map(
          (row) => Place(
            [
              row['name'],
              row['admin1'],
              row['country'],
            ].whereType<String>().toSet().join(', '),
            (row['latitude'] as num).toDouble(),
            (row['longitude'] as num).toDouble(),
          ),
        )
        .toList();
    _cache[text] = places;
    return places;
  }
}
