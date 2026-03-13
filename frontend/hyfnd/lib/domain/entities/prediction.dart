class Prediction {
  final String id;
  final String result;
  final double confidence;
  final double fakeProbability;
  final double realProbability;
  final String processingTime;
  final String modelVersion;
  final String requestType;
  final String originalContent;
  final DateTime createdAt;

  // Article metadata (populated for URL requests)
  final String? articleTitle;
  final String? articleDescription;
  final String? articleAuthor;
  final String? articleSource;

  const Prediction({
    required this.id,
    required this.result,
    required this.confidence,
    required this.fakeProbability,
    required this.realProbability,
    required this.processingTime,
    required this.modelVersion,
    required this.requestType,
    required this.originalContent,
    required this.createdAt,
    this.articleTitle,
    this.articleDescription,
    this.articleAuthor,
    this.articleSource,
  });

  bool get isFake => result.toUpperCase() == 'FAKE';
  bool get isReal => result.toUpperCase() == 'REAL';
  bool get isUrlRequest => requestType == 'url';
  bool get hasMetadata =>
      articleTitle != null && articleTitle!.isNotEmpty;
}
