class ApiConstants {
  // Base URL - Update this based on your backend deployment
  static const String baseUrl = 'http://localhost:8080';

  // API Endpoints (matching your Go backend)
  static const String analyzeEndpoint = '/api/analyze';
  static const String predictionsEndpoint = '/api/predictions';
  static const String historyEndpoint = '/api/history';
  static const String healthEndpoint = '/api/health';

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
    // You can use flutter_dotenv or environment variables
    const env = String.fromEnvironment('ENV', defaultValue: 'development');

    switch (env) {
      case 'production':
        return 'https://your-production-url.com';
      case 'staging':
        return 'https://your-staging-url.com';
      default:
        return baseUrl;
    }
  }
}
