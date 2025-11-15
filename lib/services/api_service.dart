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

  // Send emergency alert
  static Future<Map<String, dynamic>> sendAlert(
    EmergencyType type,
    double lat,
    double lng,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/alerts/${type.value}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': type.value,
          'lat': lat,
          'lng': lng,
          'createdAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send alert: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get nearby emergency centers
  static Future<List<EmergencyCenter>> getNearbyCenters(
    EmergencyType type,
    double lat,
    double lng,
  ) async {
    try {
      String endpoint;
      switch (type) {
        case EmergencyType.ambulance:
          endpoint = 'health-centers';
          break;
        case EmergencyType.police:
          endpoint = 'police-stations';
          break;
        case EmergencyType.fire:
          endpoint = 'fire-stations';
          break;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/$endpoint?lat=$lat&lng=$lng'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => EmergencyCenter.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch centers: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Register user (optional - for future use)
  static Future<Map<String, dynamic>> register(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/user/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phoneNumber}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
