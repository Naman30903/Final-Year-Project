import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/api_constants.dart';
import '../utils/logger.dart';

class ApiClient {
  late final Dio _dio;
  final AppLogger _logger = AppLogger();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: ApiConstants.defaultHeaders,
        // Important for handling responses
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final fullUrl = '${options.baseUrl}${options.path}';
          _logger.logInfo('REQUEST[${options.method}] => URL: $fullUrl');

          if (kIsWeb) {
            _logger.logInfo('Running on Web platform');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.logInfo(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          final fullUrl =
              '${error.requestOptions.baseUrl}${error.requestOptions.path}';

          _logger.logError(
            'ERROR[${error.response?.statusCode ?? error.type}] => URL: $fullUrl\n'
            'Message: ${error.message}\n'
            'Type: ${error.type}',
            error,
          );

          // Provide helpful debugging info for web
          if (kIsWeb && error.type == DioExceptionType.connectionError) {
            _logger.logError(
              '⚠️ Web Connection Error - Possible causes:\n'
              '1. CORS not enabled on backend (most likely)\n'
              '2. Backend not running at $fullUrl\n'
              '3. Mixed content (HTTPS page calling HTTP API)\n'
              '4. Network/firewall blocking the request',
              error,
            );
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    final fullUrl =
        '${error.requestOptions.baseUrl}${error.requestOptions.path}';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Connection timeout. Please check your internet connection and ensure the server is running at $fullUrl',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        return Exception(
          'Server error ($statusCode): $responseData',
        );

      case DioExceptionType.cancel:
        return Exception('Request was cancelled');

      case DioExceptionType.connectionError:
        if (kIsWeb) {
          return Exception(
            'Connection failed to $fullUrl.\n\n'
            'This is likely a CORS issue. Please ensure your backend server:\n'
            '• Is running at ${ApiConstants.baseUrl}\n'
            '• Has CORS headers enabled:\n'
            '  - Access-Control-Allow-Origin: *\n'
            '  - Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS\n'
            '  - Access-Control-Allow-Headers: Content-Type, Accept',
          );
        }
        return Exception(
          'No internet connection. Please check your network and try again.',
        );

      case DioExceptionType.badCertificate:
        return Exception(
          'SSL Certificate error. Please check your network security settings.',
        );

      case DioExceptionType.unknown:
        if (kIsWeb && error.message?.contains('XMLHttpRequest') == true) {
          return Exception(
            'Network request blocked (likely CORS).\n\n'
            'Your backend needs CORS headers. Add CORS middleware to your Go server.',
          );
        }
        return Exception('Unexpected error: ${error.message}');
    }
  }
}
