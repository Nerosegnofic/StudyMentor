import 'dart:io';

abstract class DocumentUploadEvent {}

/// Dispatched when the user has picked a file and wants to upload it.
class PickAndUploadDocumentEvent extends DocumentUploadEvent {
  final File file;
  final String subjectName;
  final String studentUid;

  PickAndUploadDocumentEvent({
    required this.file,
    required this.subjectName,
    required this.studentUid,
  });
}

/// Dispatched to clear any error or accepted state and return to initial.
class ResetDocumentUploadEvent extends DocumentUploadEvent {}
