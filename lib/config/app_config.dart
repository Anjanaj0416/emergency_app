import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // API Base URL - automatically detects platform
  static String get apiBaseUrl {
    if (kIsWeb) {
      // For Web (Chrome, Edge, etc.)
      return 'http://localhost:3000/api';
    } else {
      // For Android Emulator
      return 'http://10.0.2.2:3000/api';
    }
  }

  static const String googleMapsApiKey =
      'AIzaSyAOnsGvGP04YlbO7rd53VGNy0QfwVavqyc';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration locationTimeout = Duration(seconds: 10);
}

class Environment {
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get isDevelopment => !isProduction;
  static bool get isWeb => kIsWeb;
}
