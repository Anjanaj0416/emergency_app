import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../models/emergency_type.dart';
import '../models/emergency_center.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  EmergencyType? _emergencyType;
  bool _isLoading = true;
  bool _alertSent = false;
  List<EmergencyCenter> _nearbyCenters = [];
  Set<Marker> _markers = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get emergency type from route arguments
    if (_emergencyType == null) {
      _emergencyType =
          ModalRoute.of(context)!.settings.arguments as EmergencyType;
      _initializeMap();
    }
  }

  Future<void> _initializeMap() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    try {
      // Get current location
      await locationProvider.getCurrentLocation();

      if (!mounted) return;

      // Fetch nearby centers
      await _fetchNearbyCenters();

      // Send alert to backend
      await _sendAlert();

      // Update markers
      _updateMarkers();
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Failed to get your location: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchNearbyCenters() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    if (locationProvider.currentLocation == null) return;

    try {
      final centers = await ApiService.getNearbyCenters(
        _emergencyType!,
        locationProvider.currentLocation!.latitude,
        locationProvider.currentLocation!.longitude,
      );

      setState(() {
        _nearbyCenters = centers;
      });
    } catch (e) {
      debugPrint('Error fetching centers: $e');
    }
  }

  Future<void> _sendAlert() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    if (locationProvider.currentLocation == null) return;

    try {
      await ApiService.sendAlert(
        _emergencyType!,
        locationProvider.currentLocation!.latitude,
        locationProvider.currentLocation!.longitude,
      );

      setState(() => _alertSent = true);

      if (!mounted) return;

      _showSuccessSnackbar();
    } catch (e) {
      debugPrint('Error sending alert: $e');
      if (!mounted) return;
      _showErrorSnackbar();
    }
  }

  void _updateMarkers() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    if (locationProvider.currentLocation == null) return;

    final Set<Marker> markers = {};

    // Add user location marker
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(
          locationProvider.currentLocation!.latitude,
          locationProvider.currentLocation!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    // Add nearby centers markers
    for (var center in _nearbyCenters) {
      markers.add(
        Marker(
          markerId: MarkerId(center.id),
          position: LatLng(center.lat, center.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerColor(_emergencyType!),
          ),
          infoWindow: InfoWindow(title: center.name, snippet: center.phone),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  double _getMarkerColor(EmergencyType type) {
    switch (type) {
      case EmergencyType.ambulance:
        return BitmapDescriptor.hueRed;
      case EmergencyType.police:
        return BitmapDescriptor.hueBlue;
      case EmergencyType.fire:
        return BitmapDescriptor.hueOrange;
    }
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${_getEmergencyLabel()} alert sent successfully!'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Failed to send alert. Please try again.')),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getEmergencyLabel() {
    switch (_emergencyType!) {
      case EmergencyType.ambulance:
        return 'Ambulance';
      case EmergencyType.police:
        return 'Police';
      case EmergencyType.fire:
        return 'Fire Department';
    }
  }

  Color _getEmergencyColor() {
    switch (_emergencyType!) {
      case EmergencyType.ambulance:
        return Colors.red;
      case EmergencyType.police:
        return Colors.blue;
      case EmergencyType.fire:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_getEmergencyLabel()} Request'),
        backgroundColor: _getEmergencyColor(),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _getEmergencyColor()),
                  const SizedBox(height: 20),
                  const Text(
                    'Getting your location...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : locationProvider.currentLocation == null
          ? const Center(child: Text('Unable to get your location'))
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      locationProvider.currentLocation!.latitude,
                      locationProvider.currentLocation!.longitude,
                    ),
                    zoom: 14,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),

                // Alert Status Banner
                if (_alertSent)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Alert Sent!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Help is on the way',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Centers List
                if (_nearbyCenters.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Nearby ${_getEmergencyLabel()} Centers',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_nearbyCenters.length} centers found',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
