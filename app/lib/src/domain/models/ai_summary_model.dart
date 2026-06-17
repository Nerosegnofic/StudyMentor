class AiSummaryModel {
  final String parentUid;
  final List<AiSummarySlide> slides;
  final DateTime generatedAt;

  const AiSummaryModel({
    required this.parentUid,
    required this.slides,
    required this.generatedAt,
  });
}

/// A single slide in the parent-home AI Daily Summary.
/// `childUid` is null for the household headline; otherwise it identifies the
/// child the slide is about (used to deep-link into that child's dashboard).
/// `severity` is one of: 'good' | 'info' | 'warn' | 'high'.
class AiSummarySlide {
  final String? childUid;
  final String text;
  final String severity;

  const AiSummarySlide({
    this.childUid,
    required this.text,
    required this.severity,
  });
}