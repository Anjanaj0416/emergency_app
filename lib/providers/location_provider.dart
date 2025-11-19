import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider with ChangeNotifier {
  Position? _currentLocation;
  bool _isLoading = false;
  String? _error;

  Position? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✅ FIXED: Get current location with Future.microtask to prevent setState during build
  Future<void> getCurrentLocation() async {
    // Wrap in Future.microtask to delay state changes until after current build
    await Future.microtask(() async {
      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception(
            'Location services are disabled. Please enable them in settings.',
          );
        }

        // Check location permissions
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception('Location permissions are denied');
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw Exception(
            'Location permissions are permanently denied. Please enable them in settings.',
          );
        }

        // Get current position
        _currentLocation = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        _error = null;
      } catch (e) {
        _error = e.toString();
        debugPrint('Error getting location: $e');
        rethrow;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  // Calculate distance between two points (in meters)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Reset location
  void resetLocation() {
    _currentLocation = null;
    _error = null;
    notifyListeners();
  }
}
