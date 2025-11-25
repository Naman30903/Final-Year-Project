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
    final response = await apiClient.post(
      ApiConstants.analyzeEndpoint,
      data: data,
    );
    return PredictionModel.fromJson(response.data);
  }

  @override
  Future<PredictionModel> getPrediction(String id) async {
    final response = await apiClient.get(
      '${ApiConstants.predictionsEndpoint}?id=$id',
    );
    return PredictionModel.fromJson(response.data);
  }

  @override
  Future<List<PredictionModel>> getHistory() async {
    final response = await apiClient.get(ApiConstants.historyEndpoint);
    final List<dynamic> data = response.data;
    return data.map((json) => PredictionModel.fromJson(json)).toList();
  }

  @override
  Future<bool> checkHealth() async {
    final response = await apiClient.get(ApiConstants.healthEndpoint);
    return response.statusCode == 200;
  }
}
