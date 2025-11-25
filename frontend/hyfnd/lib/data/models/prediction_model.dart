import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/prediction.dart';

part 'prediction_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class PredictionModel extends Prediction {
  const PredictionModel({
    required super.id,
    required super.result,
    required super.confidence,
    required super.processingTime,
    required super.modelVersion,
    required super.createdAt,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    // Handle the response structure from your Go backend
    return PredictionModel(
      id: json['id'] as String,
      result: json['result'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      processingTime: json['processing_time_ms']?.toString() ?? '0 ms',
      modelVersion: json['model_version'] as String? ?? 'v1.0',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => _$PredictionModelToJson(this);
}
