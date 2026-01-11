import 'package:google_maps_flutter/google_maps_flutter.dart';

class VetClinic {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final double distance;
  final double rating;
  final bool isOpen;
  final String type; // vet' or 'shop'

  VetClinic({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.distance,
    required this.rating,
    required this.isOpen,
    required this.type,
  });

  factory VetClinic.fromJson(
      Map<String, dynamic> json, LatLng userLocation, String placeType) {
    final geometry = json['geometry']['location'];
    final lat = geometry['lat'];
    final lng = geometry['lng'];

    final bool openNow = json['opening_hours'] != null
        ? json['opening_hours']['open_now'] ?? false
        : false;

    return VetClinic(
      id: json['place_id'] ?? '',
      name: json['name'] ?? 'Unknown Place',
      latitude: lat,
      longitude: lng,
      address: json['vicinity'] ?? 'Address not available',
      rating: (json['rating'] ?? 0.0).toDouble(),
      isOpen: openNow,
      distance: 0.0,
      type: placeType, // Store the type
    );
  }
}
