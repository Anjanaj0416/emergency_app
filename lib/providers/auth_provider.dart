import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;

  // Check if user is already logged in
  Future<void> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      final savedUserId = prefs.getString('user_id');
      final savedPhone = prefs.getString('user_phone');

      if (savedToken != null && savedUserId != null && savedPhone != null) {
        _token = savedToken;
        _user = UserModel(id: savedUserId, phone: savedPhone);
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
    }
  }

  // Login with phone number
  Future<bool> login(String phoneNumber) async {
    try {
      final response = await ApiService.login(phoneNumber);

      if (response['success'] == true) {
        _user = UserModel(
          id: response['user']['id'],
          phone: response['user']['phone'],
        );
        _token = response['token'];
        _isAuthenticated = true;

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_id', _user!.id);
        await prefs.setString('user_phone', _user!.phone);

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_phone');

      _user = null;
      _token = null;
      _isAuthenticated = false;

      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }
}
