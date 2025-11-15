class AppConfig {
  // ============================================
  // BACKEND API CONFIGURATION
  // ============================================

  // Backend API Base URL
  // TODO: Replace with your actual backend URL when deployed
  static const String apiBaseUrl = 'http://localhost:3000/api';

  // For Android Emulator use:
  // static const String apiBaseUrl = 'http://10.0.2.2:3000/api';

  // For real device use (replace with your computer's IP):
  // static const String apiBaseUrl = 'http://192.168.1.100:3000/api';

  // For production use:
  // static const String apiBaseUrl = 'https://your-backend-url.com/api';

  // ============================================
  // GOOGLE MAPS API KEY
  // ============================================

  // Google Maps API Key
  static const String googleMapsApiKey =
      'AIzaSyAOnsGvGP04YlbO7rd53VGNy0QfwVavqyc';

  // ============================================
  // APP INFORMATION
  // ============================================

  // App version
  static const String appVersion = '1.0.0';

  // App name
  static const String appName = 'RapidAid Emergency';

  // Package name (for reference)
  static const String packageName = 'com.example.emergency_app';

  // ============================================
  // API CONFIGURATION
  // ============================================

  // Request timeout in seconds
  static const int requestTimeout = 30;

  // Maximum number of retry attempts for failed requests
  static const int maxRetries = 3;

  // ============================================
  // FEATURE FLAGS
  // ============================================

  // Enable debug logging
  static const bool enableDebugLogging = true;

  // Enable Firebase Analytics (when Firebase is configured)
  static const bool enableAnalytics = false;

  // Enable crash reporting
  static const bool enableCrashReporting = false;
}
