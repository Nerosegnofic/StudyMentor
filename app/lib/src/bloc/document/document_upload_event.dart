import 'dart:io';

abstract class DocumentUploadEvent {}

/// Dispatched when the user has picked a file and wants to upload it.
class PickAndUploadDocumentEvent extends DocumentUploadEvent {
  final File file;
  final String subjectName;

  PickAndUploadDocumentEvent({
    required this.file,
    required this.subjectName,
  });
}

/// Dispatched to clear any error or accepted state and return to initial.
class ResetDocumentUploadEvent extends DocumentUploadEvent {}
