// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prediction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PredictionModel _$PredictionModelFromJson(Map<String, dynamic> json) =>
    PredictionModel(
      id: json['id'] as String,
      result: json['result'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      processingTime: json['processing_time'] as String,
      modelVersion: json['model_version'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$PredictionModelToJson(PredictionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'result': instance.result,
      'confidence': instance.confidence,
      'processing_time': instance.processingTime,
      'model_version': instance.modelVersion,
      'created_at': instance.createdAt.toIso8601String(),
    };
