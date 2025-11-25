class Prediction {
  final String id;
  final String result;
  final double confidence;
  final String processingTime;
  final String modelVersion;
  final DateTime createdAt;

  const Prediction({
    required this.id,
    required this.result,
    required this.confidence,
    required this.processingTime,
    required this.modelVersion,
    required this.createdAt,
  });

  bool get isFake => result.toUpperCase() == 'FAKE';
  bool get isReal => result.toUpperCase() == 'REAL';
}
