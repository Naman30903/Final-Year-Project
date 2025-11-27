import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hyfnd/core/constants/api_constants.dart';
import 'package:hyfnd/core/network/api_client.dart';
import 'package:hyfnd/core/utils/logger.dart';

class ConnectionService {
  final ApiClient _apiClient;
  final AppLogger _logger = AppLogger();

  ConnectionService(this._apiClient);

  /// Check if the backend is reachable
  Future<ConnectionStatus> checkConnection() async {
    try {
      _logger.logInfo('Checking connection to ${ApiConstants.baseUrl}...');

      final response = await _apiClient.get(ApiConstants.healthEndpoint);

      if (response.statusCode == 200) {
        _logger.logInfo('✅ Backend is reachable');
        return ConnectionStatus.connected;
      }

      _logger.logError('Backend returned status: ${response.statusCode}', null);
      return ConnectionStatus.serverError;
    } catch (e) {
      _logger.logError('Connection check failed', e);

      if (kIsWeb && e.toString().contains('CORS')) {
        return ConnectionStatus.corsError;
      }

      return ConnectionStatus.disconnected;
    }
  }

  /// Get a user-friendly message for the connection status
  String getStatusMessage(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connected to server';
      case ConnectionStatus.disconnected:
        return 'Cannot reach server. Please check if the backend is running.';
      case ConnectionStatus.corsError:
        return 'CORS error. Please enable CORS on your backend server.';
      case ConnectionStatus.serverError:
        return 'Server error. Please check backend logs.';
    }
  }
}

enum ConnectionStatus {
  connected,
  disconnected,
  corsError,
  serverError,
}
