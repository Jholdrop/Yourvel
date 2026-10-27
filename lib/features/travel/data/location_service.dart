import 'package:geolocator/geolocator.dart';
import '../../../core/errors.dart';
import '../domain/models.dart';

class LocationService {
  Future<Place> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const AppException(
        'Ative a localização do aparelho ou use a busca de cidades.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const AppException(
        'Localização não autorizada. Use a busca ou altere a permissão nas configurações do aparelho.',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return Place(
      'Minha localização',
      position.latitude,
      position.longitude,
      source: 'device',
      provider: 'device',
    );
  }
}
