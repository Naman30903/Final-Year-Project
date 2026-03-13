import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/prediction_model.dart';

abstract class NewsRemoteDataSource {
  Future<PredictionModel> analyzeNews(Map<String, dynamic> data);
  Future<PredictionModel> getPrediction(String id);
  Future<List<PredictionModel>> getHistory();
  Future<bool> checkHealth();
}

class NewsRemoteDataSourceImpl implements NewsRemoteDataSource {
  final ApiClient apiClient;

  NewsRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PredictionModel> analyzeNews(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.post(
        ApiConstants.analyzeEndpoint,
        data: data,
      );

      final body = response.data as Map<String, dynamic>;

      // Go backend wraps in { "success": true, "prediction": { ... } }
      if (body.containsKey('prediction') && body['prediction'] != null) {
        return PredictionModel.fromJson(
          body['prediction'] as Map<String, dynamic>,
        );
      }

      // Fallback: response IS the prediction (direct ML service)
      return PredictionModel.fromJson(body);
    } catch (e) {
      throw _enhanceError(e, 'analyzeNews');
    }
  }

  @override
  Future<PredictionModel> getPrediction(String id) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.predictionsEndpoint}?id=$id',
      );
      return PredictionModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw _enhanceError(e, 'getPrediction');
    }
  }

  @override
  Future<List<PredictionModel>> getHistory() async {
    try {
      final response = await apiClient.get(ApiConstants.historyEndpoint);
      final body = response.data;

      // Go backend returns { "success": true, "count": N, "history": [...] }
      List<dynamic> items;
      if (body is Map<String, dynamic> && body.containsKey('history')) {
        items = body['history'] as List<dynamic>? ?? [];
      } else if (body is List) {
        items = body;
      } else {
        return [];
      }

      return items
          .map((json) =>
              PredictionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _enhanceError(e, 'getHistory');
    }
  }

  @override
  Future<bool> checkHealth() async {
    try {
      final response = await apiClient.get(ApiConstants.healthEndpoint);
      return response.statusCode == 200;
    } catch (e) {
      if (kIsWeb) {
        throw Exception(
          'Health check failed. If running on web, ensure CORS is enabled on your backend.\n\n'
          'Backend URL: ${ApiConstants.baseUrl}${ApiConstants.healthEndpoint}',
        );
      }
      rethrow;
    }
  }

  Exception _enhanceError(dynamic error, String operation) {
    final errorString = error.toString();

    if (kIsWeb &&
        (errorString.contains('XMLHttpRequest') ||
            errorString.contains('CORS') ||
            errorString.contains('connection'))) {
      return Exception(
        'Failed to $operation: Network/CORS error.\n\n'
        'Please ensure:\n'
        '  Backend is running at ${ApiConstants.baseUrl}\n'
        '  CORS is enabled on the backend\n'
        '  No mixed content issues (HTTP vs HTTPS)',
      );
    }

    if (error is Exception) {
      return error;
    }

    return Exception('Failed to $operation: $error');
  }
}
