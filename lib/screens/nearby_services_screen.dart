import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../secrets.dart';
import '../models/vet_clinic.dart';

/** Finds nearby vet clinics and pet stores using Google Maps */
class VetClinicScreen extends StatefulWidget {
  const VetClinicScreen({super.key});

  @override
  State<VetClinicScreen> createState() => _VetClinicScreenState();
}

class _VetClinicScreenState extends State<VetClinicScreen> {
  GoogleMapController? mapController;
  Position? _userPosition;
  bool _isLoading = true;
  bool _isOffline = false;
  List<VetClinic> _places = [];
  Set<Marker> _markers = {};

  String _selectedType = 'veterinary_care';
  final String _googleApiKey = places_api_key;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  // Gets location permission and finds nearby vets
  Future<void> _initializeLocation() async {
    setState(() {
      _isLoading = true;
      _isOffline = false;
    });

    // CHECK INTERNET CONNECTION FIRST
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) {
        setState(() {
          _isOffline = true;
          _isLoading = false;
        });
      }
      return;
    }

    // If Online, Proceed with Location & API
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() => _userPosition = position);
        _fetchNearbyPlaces(
            position.latitude, position.longitude, _selectedType);
      }
    } catch (e) {
      debugPrint('Error initializing: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Calls Google Maps to find vets near you
  Future<void> _fetchNearbyPlaces(double lat, double lng, String type) async {
    // Double check internet before API call
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() => _isOffline = true);
      return;
    }

    setState(() => _isLoading = true);

    final url =
        Uri.parse('https://maps.googleapis.com/maps/api/place/nearbysearch/json'
            '?location=$lat,$lng'
            '&radius=5000'
            '&type=$type'
            '&key=$_googleApiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final List results = data['results'];
          final userLatLng = LatLng(lat, lng);

          List<VetClinic> loadedPlaces = results.map((json) {
            var place = VetClinic.fromJson(json, userLatLng, type);

            double distanceMeters = Geolocator.distanceBetween(
                lat, lng, place.latitude, place.longitude);

            return VetClinic(
              id: place.id,
              name: place.name,
              latitude: place.latitude,
              longitude: place.longitude,
              address: place.address,
              rating: place.rating,
              isOpen: place.isOpen,
              distance:
                  double.parse((distanceMeters / 1000).toStringAsFixed(1)),
              type: type,
            );
          }).toList();

          loadedPlaces.sort((a, b) => a.distance.compareTo(b.distance));

          final Set<Marker> newMarkers = loadedPlaces.map((place) {
            final hue = place.type == 'veterinary_care'
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueViolet;

            return Marker(
              markerId: MarkerId(place.id),
              position: LatLng(place.latitude, place.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(hue),
              infoWindow: InfoWindow(
                  title: place.name, snippet: "${place.distance} km away"),
            );
          }).toSet();

          if (mounted) {
            setState(() {
              _places = loadedPlaces;
              _markers = newMarkers;
              _isLoading = false;
            });
            _fitBoundsToVisibleMarkers();
          }
        } else {
          if (mounted) {
            // Default clear places and markers if there are no results
            setState(() {
              _places = [];
              _markers = {};
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch places: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fitBoundsToVisibleMarkers() {
    if (_places.isEmpty || _userPosition == null || mapController == null) {
      return;
    }

    double minLat = _userPosition!.latitude;
    double maxLat = _userPosition!.latitude;
    double minLng = _userPosition!.longitude;
    double maxLng = _userPosition!.longitude;

    for (var place in _places) {
      if (place.latitude < minLat) minLat = place.latitude;
      if (place.latitude > maxLat) maxLat = place.latitude;
      if (place.longitude < minLng) minLng = place.longitude;
      if (place.longitude > maxLng) maxLng = place.longitude;
    }

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100,
      ),
    );
  }

  void _onTypeChanged(String newType) {
    if (_selectedType == newType) return;
    if (_userPosition != null) {
      setState(() => _selectedType = newType);
      _fetchNearbyPlaces(
          _userPosition!.latitude, _userPosition!.longitude, newType);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F5),
        elevation: 0,
        title: const Text(
          'Nearby Services',
          style:
              TextStyle(color: Color(0xFF3D3D3D), fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF3D3D3D)),
      ),
      body: _isOffline
          ? _buildOfflineState()
          : Column(
              children: [
                // MAP SECTION
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      _userPosition == null
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFFD4746B)))
                          : Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: GoogleMap(
                                  onMapCreated: (controller) {
                                    if (mounted) {
                                      setState(() {
                                        mapController = controller;
                                      });
                                    }
                                  },
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(_userPosition!.latitude,
                                        _userPosition!.longitude),
                                    zoom: 14,
                                  ),
                                  myLocationEnabled: true,
                                  myLocationButtonEnabled: true,
                                  // the pre-built _markers state variable instead
                                  markers: _markers,
                                ),
                              ),
                            ),

                      // FILTER CHIPS
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildFilterChip('Vet Clinics', 'veterinary_care',
                                Icons.local_hospital),
                            const SizedBox(width: 12),
                            _buildFilterChip(
                                'Pet Shops', 'pet_store', Icons.shopping_bag),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // LIST SECTION
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAF8F5),
                      border: Border(
                        top: BorderSide(color: Color(0x33E8A89B)),
                      ),
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFFE8A89B)))
                        : _places.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 110),
                                itemCount: _places.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  return _buildPlaceCard(_places[index]);
                                },
                              ),
                  ),
                ),
              ],
            ),
    );
  }

  // --- Offline UI ---
  Widget _buildOfflineState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text(
            "No Internet Connection",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3D3D3D),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Please turn on WiFi or Mobile Data\nto view the map.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _initializeLocation, // Try again when clicked
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8A89B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => _onTypeChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4746B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            "No places found nearby",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(VetClinic place) {
    return GestureDetector(
      onTap: () {
        mapController?.animateCamera(CameraUpdate.newLatLngZoom(
            LatLng(place.latitude, place.longitude), 16));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.04),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color:
                place.isOpen ? const Color(0x4DE8A89B) : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D3D3D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(place.isOpen),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Color(0xFFE8A89B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    place.address,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 18, color: Color(0xFFFFB74D)),
                    const SizedBox(width: 4),
                    Text(
                      place.rating.toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${place.distance} km',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Color(0xFFE8A89B),
                      ),
                    ),
                  ],
                ),
                Icon(
                  place.type == 'veterinary_care'
                      ? Icons.local_hospital
                      : Icons.shopping_bag,
                  size: 20,
                  color: const Color(0xFFD4746B),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen
            ? const Color.fromRGBO(76, 175, 80, 0.1)
            : const Color.fromRGBO(244, 67, 54, 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          color: isOpen ? Colors.green[700] : Colors.red[700],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
