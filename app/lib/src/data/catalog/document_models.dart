/// Dart DTOs that mirror the AI Engine `document_schemas.py` Pydantic models.
library;

/// Mirrors the AI Engine `SubjectStatus` schema — per-subject ingestion readiness,
/// polled to gate uploads/quizzes and to drive the "Preparing…" indicator.
class SubjectStatus {
  final int subjectId;
  final String subjectName;

  /// "processing" | "ready" | "failed".
  final String state;

  /// Coarse progress label while processing: "parsing" | "analyzing" |
  /// "building_skills" (null once ready/failed).
  final String? stage;

  const SubjectStatus({
    required this.subjectId,
    required this.subjectName,
    required this.state,
    this.stage,
  });

  bool get isProcessing => state == 'processing';
  bool get isFailed => state == 'failed';

  factory SubjectStatus.fromJson(Map<String, dynamic> json) {
    return SubjectStatus(
      subjectId: json['subject_id'] as int,
      subjectName: json['subject_name'] as String,
      state: json['state'] as String,
      stage: json['stage'] as String?,
    );
  }
}
