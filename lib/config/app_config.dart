class AppConfig {
  // Backend API Base URL
  // TODO: Replace with your actual backend URL when deployed
  static const String apiBaseUrl = 'http://localhost:3000/api';
  // For Android Emulator use: 'http://10.0.2.2:3000/api'
  // For real device use: 'http://YOUR_COMPUTER_IP:3000/api'
  // For production use: 'https://your-backend-url.com/api'

  // Google Maps API Key
  // TODO: Replace with your actual Google Maps API key
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // App version
  static const String appVersion = '1.0.0';

  // Other configurations
  static const int requestTimeout = 30; // seconds
}
