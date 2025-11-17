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
  Set<Circle> _circles = {}; // Add circles for radius
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_emergencyType == null) {
      _emergencyType =
          ModalRoute.of(context)!.settings.arguments as EmergencyType;
      _initializeMap();
    }
  }

  Future<void> _initializeMap() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('🗺️ Initializing map for \${_getEmergencyLabel()}...');
      await locationProvider.getCurrentLocation();

      if (!mounted) return;
      if (locationProvider.currentLocation == null) {
        throw Exception('Unable to get your current location');
      }

      print(
          '📍 Location: \${locationProvider.currentLocation!.latitude}, \${locationProvider.currentLocation!.longitude}');

      try {
        await _fetchNearbyCenters();
        print('✅ Fetched \${_nearbyCenters.length} nearby centers');
      } catch (e) {
        print('⚠️ Warning: Could not fetch nearby centers: \$e');
      }

      await _sendAlert();
      _updateMarkersAndCircles();

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error initializing map: \$e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNearbyCenters() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    if (locationProvider.currentLocation == null) return;

    try {
      final centers = await ApiService.getNearbyCenters(
        _emergencyType!,
        locationProvider.currentLocation!.latitude,
        locationProvider.currentLocation!.longitude,
      );
      if (mounted) setState(() => _nearbyCenters = centers);
    } catch (e) {
      print('❌ Error fetching centers: \$e');
    }
  }

  Future<void> _sendAlert() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    if (locationProvider.currentLocation == null) return;

    try {
      await ApiService.sendAlert(
        _emergencyType!,
        locationProvider.currentLocation!.latitude,
        locationProvider.currentLocation!.longitude,
      );
      if (mounted) {
        setState(() => _alertSent = true);
        _showSuccessSnackbar();
      }
    } catch (e) {
      print('❌ Error sending alert: \$e');
    }
  }

  void _updateMarkersAndCircles() {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    if (locationProvider.currentLocation == null) return;

    final Set<Marker> markers = {};
    final Set<Circle> circles = {};
    final userLatLng = LatLng(
      locationProvider.currentLocation!.latitude,
      locationProvider.currentLocation!.longitude,
    );

    // Blue marker for user location
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: userLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
        zIndex: 2,
      ),
    );

    // Yellow circle radius (5km)
    circles.add(
      Circle(
        circleId: const CircleId('user_radius'),
        center: userLatLng,
        radius: 5000,
        fillColor: Colors.yellow.withOpacity(0.2),
        strokeColor: Colors.yellow.withOpacity(0.5),
        strokeWidth: 2,
        zIndex: 1,
      ),
    );

    // Add police station markers
    for (var center in _nearbyCenters) {
      markers.add(
        Marker(
          markerId: MarkerId(center.id),
          position: LatLng(center.lat, center.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: center.name, snippet: center.phone),
          zIndex: 3,
        ),
      );
    }

    if (mounted)
      setState(() {
        _markers = markers;
        _circles = circles;
      });
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
                child:
                    Text('\${_getEmergencyLabel()} alert sent successfully!')),
          ],
        ),
        backgroundColor: Colors.green,
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
        title: Text('\${_getEmergencyLabel()} Request'),
        backgroundColor: _getEmergencyColor(),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: _getEmergencyColor()))
          : locationProvider.currentLocation == null
              ? const Center(child: Text('Unable to get location'))
              : Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          locationProvider.currentLocation!.latitude,
                          locationProvider.currentLocation!.longitude,
                        ),
                        zoom: 13,
                      ),
                      markers: _markers,
                      circles: _circles,
                      myLocationEnabled: false,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      onMapCreated: (controller) => _mapController = controller,
                    ),
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
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Alert Sent! Help is on the way',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_nearbyCenters.isNotEmpty)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on,
                                  color: _getEmergencyColor()),
                              const SizedBox(width: 8),
                              Text(
                                  '\${_nearbyCenters.length} center(s) nearby'),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
