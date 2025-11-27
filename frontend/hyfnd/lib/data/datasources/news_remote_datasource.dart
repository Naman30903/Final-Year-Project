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
      return PredictionModel.fromJson(response.data);
    } catch (e) {
      throw _enhanceError(e, 'analyzeNews');
    }
  }

  @override
  Future<PredictionModel> getPrediction(String id) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.predictionsEndpoint}/$id',
      );
      return PredictionModel.fromJson(response.data);
    } catch (e) {
      throw _enhanceError(e, 'getPrediction');
    }
  }

  @override
  Future<List<PredictionModel>> getHistory() async {
    try {
      final response = await apiClient.get(ApiConstants.historyEndpoint);
      final List<dynamic> data = response.data;
      return data.map((json) => PredictionModel.fromJson(json)).toList();
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
        '• Backend is running at ${ApiConstants.baseUrl}\n'
        '• CORS is enabled on the backend\n'
        '• No mixed content issues (HTTP vs HTTPS)',
      );
    }

    if (error is Exception) {
      return error;
    }

    return Exception('Failed to $operation: $error');
  }
}
