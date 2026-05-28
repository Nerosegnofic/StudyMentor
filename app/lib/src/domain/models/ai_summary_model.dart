class AiSummaryModel {
  final String id;
  final String parentUid;
  final List<String> slides;
  final DateTime generatedAt;

  const AiSummaryModel({
    required this.id,
    required this.parentUid,
    required this.slides,
    required this.generatedAt,
  });
}
