class ApiConfig {
  // Update this to your server URL
  static const String baseUrl = 'http://localhost:8000/api';

  // Alternative for development:
  // iOS Simulator: http://localhost:8000/api
  // Android Emulator: http://10.0.2.2:8000/api
  // Physical Device: http://YOUR_LOCAL_IP:8000/api

  static const Duration timeout = Duration(seconds: 30);
}
