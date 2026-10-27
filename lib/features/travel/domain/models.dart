import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  const Place(
    this.name,
    this.latitude,
    this.longitude, {
    this.source = 'places',
    this.provider = 'open-meteo',
  });
  final String name;
  final double latitude;
  final double longitude;
  final String source;
  final String provider;
}

class TravelEntry {
  const TravelEntry({
    required this.id,
    required this.name,
    required this.memory,
    required this.imagePath,
    required this.coordinates,
    this.createdAt,
  });
  final String id, name, memory, imagePath;
  final GeoPoint coordinates;
  final DateTime? createdAt;

  factory TravelEntry.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return TravelEntry(
      id: doc.id,
      name: data['placeName'] as String,
      memory: data['memory'] as String,
      imagePath: data['imagePath'] as String,
      coordinates: data['coordinates'] as GeoPoint,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
