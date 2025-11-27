import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

class ApiConstants {
  // Base URL - Update this based on your backend deployment
  static String get baseUrl {
    // For Android emulator, use 10.0.2.2 instead of localhost
    // For iOS simulator and web, localhost works fine
    if (kIsWeb) {
      // Web requires CORS to be enabled on the backend
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8080',
      );
    }

    // For mobile platforms
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );
  }

  // API Endpoints (matching your Go backend)
  static const String analyzeEndpoint = '/predict';
  static const String predictionsEndpoint = '/api/predictions';
  static const String historyEndpoint = '/api/history';
  static const String healthEndpoint = '/health';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // For production, you can switch based on environment
  static String get effectiveBaseUrl {
    const env = String.fromEnvironment('ENV', defaultValue: 'development');

    switch (env) {
      case 'production':
        return const String.fromEnvironment(
          'PROD_API_URL',
          defaultValue: 'https://your-production-url.com',
        );
      case 'staging':
        return const String.fromEnvironment(
          'STAGING_API_URL',
          defaultValue: 'https://your-staging-url.com',
        );
      default:
        return baseUrl;
    }
  }

  // Debug helper
  static void printConfiguration() {
    if (kDebugMode) {
      print('═══════════════════════════════════════');
      print('API Configuration:');
      print('  Base URL: $baseUrl');
      print('  Running on Web: $kIsWeb');
      print('  Endpoints:');
      print('    - Analyze: $analyzeEndpoint');
      print('    - Predictions: $predictionsEndpoint');
      print('    - History: $historyEndpoint');
      print('    - Health: $healthEndpoint');
      print('═══════════════════════════════════════');
    }
  }
}
