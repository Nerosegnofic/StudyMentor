class AiSummaryModel {
  final List<AiSummarySlide> slides;

  const AiSummaryModel({required this.slides});
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
