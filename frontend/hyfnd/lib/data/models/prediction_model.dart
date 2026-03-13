import '../../domain/entities/prediction.dart';

class PredictionModel extends Prediction {
  const PredictionModel({
    required super.id,
    required super.result,
    required super.confidence,
    required super.fakeProbability,
    required super.realProbability,
    required super.processingTime,
    required super.modelVersion,
    required super.requestType,
    required super.originalContent,
    required super.createdAt,
    super.articleTitle,
    super.articleDescription,
    super.articleAuthor,
    super.articleSource,
  });

  /// Parse from the Go backend response.
  ///
  /// The Go backend wraps predictions in:
  ///   { "success": true, "prediction": { ... } }
  ///
  /// The datasource layer unwraps and passes the inner prediction map here.
  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      id: json['id'] as String? ?? '',
      result: json['result'] as String? ?? 'UNKNOWN',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      fakeProbability: (json['fake_probability'] as num?)?.toDouble() ?? 0.0,
      realProbability: (json['real_probability'] as num?)?.toDouble() ?? 0.0,
      processingTime: '${json['processing_time_ms'] ?? 0}',
      modelVersion: json['model_version'] as String? ?? 'unknown',
      requestType: json['request_type'] as String? ?? 'text',
      originalContent: json['original_content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      articleTitle: json['article_title'] as String?,
      articleDescription: json['article_description'] as String?,
      articleAuthor: json['article_author'] as String?,
      articleSource: json['article_source'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'result': result,
        'confidence': confidence,
        'fake_probability': fakeProbability,
        'real_probability': realProbability,
        'processing_time_ms': processingTime,
        'model_version': modelVersion,
        'request_type': requestType,
        'original_content': originalContent,
        'created_at': createdAt.toIso8601String(),
        'article_title': articleTitle,
        'article_description': articleDescription,
        'article_author': articleAuthor,
        'article_source': articleSource,
      };
}
