import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/emergency_type.dart';
import '../models/emergency_center.dart';
import '../config/app_config.dart';

class ApiService {
  static final String _baseUrl = AppConfig.apiBaseUrl;

  // Login with phone number
  static Future<Map<String, dynamic>> login(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phoneNumber}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ✅ UPDATED: Send emergency alert with optional userId and userPhone
  static Future<Map<String, dynamic>> sendAlert(
    EmergencyType type,
    double lat,
    double lng, {
    String? userId, // ✅ NEW: Optional userId parameter
    String? userPhone, // ✅ NEW: Optional userPhone parameter
  }) async {
    try {
      // ✅ Get the correct type string
      String typeString;
      switch (type) {
        case EmergencyType.ambulance:
          typeString = 'ambulance';
          break;
        case EmergencyType.police:
          typeString = 'police';
          break;
        case EmergencyType.fire:
          typeString = 'fire';
          break;
      }

      final body = {
        'type': typeString,
        'lat': lat,
        'lng': lng,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // ✅ NEW: Add userId if provided
      if (userId != null) {
        body['userId'] = userId;
      }

      // ✅ NEW: Add userPhone if provided
      if (userPhone != null) {
        body['userPhone'] = userPhone;
      }

      print('📤 Sending alert with data: $body');

      final response = await http.post(
        Uri.parse('$_baseUrl/alerts/$typeString'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('📡 Alert response status: ${response.statusCode}');
      print('📦 Alert response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send alert: ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending alert: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get nearby emergency centers
  // ⚠️ FIXED: Corrected endpoint paths to match backend routes
  static Future<List<EmergencyCenter>> getNearbyCenters(
    EmergencyType type,
    double lat,
    double lng,
  ) async {
    try {
      String endpoint;
      switch (type) {
        case EmergencyType.ambulance:
          endpoint = 'health-centers/nearby'; // ✅ Fixed endpoint
          break;
        case EmergencyType.police:
          endpoint =
              'police/stations'; // ✅ Fixed from 'police-stations' to 'police/stations'
          break;
        case EmergencyType.fire:
          endpoint = 'fire-stations/nearby'; // ✅ Fixed endpoint
          break;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/$endpoint?lat=$lat&lng=$lng'),
        headers: {'Content-Type': 'application/json'},
      );

      print('🔍 Fetching from: $_baseUrl/$endpoint?lat=$lat&lng=$lng');
      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle both array and object responses
        List<dynamic> centersData;
        if (data is List) {
          centersData = data;
        } else if (data is Map && data.containsKey('data')) {
          centersData = data['data'] as List;
        } else if (data is Map && data.containsKey('stations')) {
          centersData = data['stations'] as List;
        } else {
          print('⚠️ Unexpected response format: $data');
          return [];
        }

        return centersData
            .map((center) => EmergencyCenter.fromJson(center))
            .toList();
      } else {
        print('❌ Error response: ${response.body}');
        throw Exception('Failed to fetch centers: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception in getNearbyCenters: $e');
      throw Exception('Network error: $e');
    }
  }

  // Logout
  static Future<void> logout() async {
    // Clear any stored tokens/data
    // This is handled by AuthProvider
  }
}
