import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart'; // ✅ NEW: Import AuthProvider
import '../models/emergency_type.dart';
import '../models/emergency_center.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  EmergencyType? _emergencyType;
  bool _isLoading = true;
  bool _alertSent = false;
  List<EmergencyCenter> _nearbyCenters = [];
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  String? _errorMessage;

  // Custom marker icons
  BitmapDescriptor? _userIcon;
  BitmapDescriptor? _policeIcon;

  // Animation controller for spreading animation
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Initialize animation for spreading effect
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Repeat the animation continuously

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    // Load custom icons
    _loadCustomIcons();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // Load custom marker icons
  Future<void> _loadCustomIcons() async {
    _userIcon = await _createCustomMarkerIcon(
      icon: Icons.person_pin_circle,
      color: Colors.blue,
      size: 60,
    );

    _policeIcon = await _createCustomMarkerIcon(
      icon: Icons.local_police,
      color: Colors.red,
      size: 60,
    );
  }

  // Create custom marker icon from IconData
  Future<BitmapDescriptor> _createCustomMarkerIcon({
    required IconData icon,
    required Color color,
    required double size,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // Draw circle background
    final paint = Paint()..color = Colors.white;
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final radius = size / 2;
    final shadowRadius = radius + 4;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(radius, radius), shadowRadius, shadowPaint);

    // Draw white border
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    // Draw colored circle
    canvas.drawCircle(Offset(radius, radius), radius - 4, circlePaint);

    // Draw icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.6,
        fontFamily: icon.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

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

      print('🗺️ Initializing map for ${_getEmergencyLabel()}...');

      // Get user's current location
      await locationProvider.getCurrentLocation();

      if (!mounted) return;
      if (locationProvider.currentLocation == null) {
        throw Exception(
            'Unable to get your current location. Please enable GPS and grant location permission.');
      }

      print('📍 ✅ USER LOCATION DETECTED:');
      print('   Latitude: ${locationProvider.currentLocation!.latitude}');
      print('   Longitude: ${locationProvider.currentLocation!.longitude}');
      print('   Accuracy: ${locationProvider.currentLocation!.accuracy}m');
      print('   Timestamp: ${locationProvider.currentLocation!.timestamp}');

      // Fetch nearby centers
      try {
        await _fetchNearbyCenters();
        print('✅ Fetched ${_nearbyCenters.length} nearby centers');
      } catch (e) {
        print('⚠️ Warning: Could not fetch nearby centers: $e');
      }

      // Send alert
      await _sendAlert();

      // Wait for icons to load before updating markers
      await Future.delayed(const Duration(milliseconds: 100));
      _updateMarkersAndCircles();

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ ERROR initializing map: $e');
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
      print('❌ Error fetching centers: $e');
    }
  }

  // ✅ UPDATED: Send alert with userId and userPhone
  Future<void> _sendAlert() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    if (locationProvider.currentLocation == null) return;

    try {
      // ✅ NEW: Get user info from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userPhone = authProvider.user?.phone;
      final userId = authProvider.user?.id;

      print('📞 Sending alert with phone: $userPhone');

      await ApiService.sendAlert(
        _emergencyType!,
        locationProvider.currentLocation!.latitude,
        locationProvider.currentLocation!.longitude,
        userId: userId, // ✅ NEW: Pass userId
        userPhone: userPhone, // ✅ NEW: Pass userPhone
      );
      if (mounted) {
        setState(() => _alertSent = true);
        _showSuccessSnackbar();
      }
    } catch (e) {
      print('❌ Error sending alert: $e');
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

    print('🎯 Creating user marker at: $userLatLng');

    // ✅ USER LOCATION MARKER with custom icon
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: userLatLng,
        icon: _userIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Emergency alert sent from here',
        ),
        zIndex: 3, // Highest z-index to show on top
      ),
    );

    // Add animated spreading circles from user location (3 layers for ripple effect)
    _animation.addListener(() {
      if (mounted) {
        setState(() {
          circles.clear();

          // Inner spreading circle
          circles.add(
            Circle(
              circleId: const CircleId('user_spread_1'),
              center: userLatLng,
              radius: 1000 * _animation.value, // Grows from 0 to 1000m
              fillColor: _getEmergencyColor()
                  .withOpacity(0.2 * (1 - _animation.value)),
              strokeColor: _getEmergencyColor()
                  .withOpacity(0.5 * (1 - _animation.value)),
              strokeWidth: 2,
              zIndex: 1,
            ),
          );

          // Middle spreading circle (delayed)
          if (_animation.value > 0.3) {
            circles.add(
              Circle(
                circleId: const CircleId('user_spread_2'),
                center: userLatLng,
                radius: 1000 * (_animation.value - 0.3) / 0.7,
                fillColor: _getEmergencyColor()
                    .withOpacity(0.15 * (1 - ((_animation.value - 0.3) / 0.7))),
                strokeColor: _getEmergencyColor()
                    .withOpacity(0.4 * (1 - ((_animation.value - 0.3) / 0.7))),
                strokeWidth: 2,
                zIndex: 1,
              ),
            );
          }

          // Outer spreading circle (more delayed)
          if (_animation.value > 0.6) {
            circles.add(
              Circle(
                circleId: const CircleId('user_spread_3'),
                center: userLatLng,
                radius: 1000 * (_animation.value - 0.6) / 0.4,
                fillColor: _getEmergencyColor()
                    .withOpacity(0.1 * (1 - ((_animation.value - 0.6) / 0.4))),
                strokeColor: _getEmergencyColor()
                    .withOpacity(0.3 * (1 - ((_animation.value - 0.6) / 0.4))),
                strokeWidth: 2,
                zIndex: 1,
              ),
            );
          }

          // Static yellow circle showing 5km search radius
          circles.add(
            Circle(
              circleId: const CircleId('search_radius'),
              center: userLatLng,
              radius: 5000, // 5km radius
              fillColor: Colors.yellow.withOpacity(0.1),
              strokeColor: Colors.yellow.withOpacity(0.3),
              strokeWidth: 2,
              zIndex: 0,
            ),
          );

          _circles = circles;
        });
      }
    });

    // ✅ POLICE STATION / EMERGENCY CENTER MARKERS with custom icon
    for (var center in _nearbyCenters) {
      print(
          '🚔 Creating police station marker: ${center.name} at (${center.lat}, ${center.lng})');
      markers.add(
        Marker(
          markerId: MarkerId(center.id),
          position: LatLng(center.lat, center.lng),
          icon: _policeIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: center.name,
            snippet: center.phone,
          ),
          zIndex: 2,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
        // Initial circles setup
        _circles = {
          Circle(
            circleId: const CircleId('search_radius'),
            center: userLatLng,
            radius: 5000,
            fillColor: Colors.yellow.withOpacity(0.1),
            strokeColor: Colors.yellow.withOpacity(0.3),
            strokeWidth: 2,
            zIndex: 0,
          ),
        };
      });
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
                child:
                    Text('${_getEmergencyLabel()} alert sent successfully!')),
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
        title: Text('${_getEmergencyLabel()} Request'),
        backgroundColor: _getEmergencyColor(),
        actions: [
          // Show location info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              if (locationProvider.currentLocation != null) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Location Info'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Latitude: ${locationProvider.currentLocation!.latitude.toStringAsFixed(6)}'),
                        Text(
                            'Longitude: ${locationProvider.currentLocation!.longitude.toStringAsFixed(6)}'),
                        Text(
                            'Accuracy: ±${locationProvider.currentLocation!.accuracy.toStringAsFixed(1)}m'),
                        const SizedBox(height: 8),
                        Text(
                            'Time: ${locationProvider.currentLocation!.timestamp}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _getEmergencyColor()),
                  const SizedBox(height: 16),
                  const Text('Getting your location...'),
                  const SizedBox(height: 8),
                  const Text(
                    'Make sure GPS is enabled',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Location Error',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _initializeMap(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getEmergencyColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
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
                          myLocationEnabled: false, // We're using custom marker
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: true,
                          compassEnabled: true,
                          onMapCreated: (controller) =>
                              _mapController = controller,
                        ),

                        // Recenter button
                        Positioned(
                          right: 16,
                          bottom: 200,
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: Colors.white,
                            onPressed: () {
                              if (locationProvider.currentLocation != null) {
                                _mapController?.animateCamera(
                                  CameraUpdate.newLatLng(
                                    LatLng(
                                      locationProvider
                                          .currentLocation!.latitude,
                                      locationProvider
                                          .currentLocation!.longitude,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Icon(Icons.my_location,
                                color: _getEmergencyColor()),
                          ),
                        ),

                        // Alert sent banner
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
                                    offset: const Offset(0, 2),
                                  ),
                                ],
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

                        // Legend
                        Positioned(
                          bottom: 80,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.person_pin_circle,
                                        color: Colors.blue, size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Your Location',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.local_police,
                                        color: Colors.red, size: 20),
                                    const SizedBox(width: 8),
                                    Text(_getEmergencyLabel(),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Nearby centers count
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
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on,
                                      color: _getEmergencyColor()),
                                  const SizedBox(width: 8),
                                  Text(
                                      '${_nearbyCenters.length} center(s) nearby'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }
}
