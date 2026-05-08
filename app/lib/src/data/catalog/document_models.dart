/// Dart DTOs that mirror the AI Engine `document_schemas.py` Pydantic models.
///
/// The upload endpoint accepts `multipart/form-data`, so there is no JSON
/// request body. The Flutter side assembles a [MultipartRequest] directly
/// in the repository.  This file only defines the *response* model returned
/// after a successful (or accepted) upload.
library;

class DocumentUploadResponse {
  /// Human-readable status string, e.g. "Processing started in background".
  final String status;

  /// Unique UUID assigned to this document by the backend.
  /// Use this ID to poll status or delete the document later.
  final String documentId;

  /// Firebase UID of the authenticated user who triggered the upload.
  /// Echoed back from the backend for confirmation.
  final String firebaseUid;

  const DocumentUploadResponse({
    required this.status,
    required this.documentId,
    required this.firebaseUid,
  });

  factory DocumentUploadResponse.fromJson(Map<String, dynamic> json) {
    return DocumentUploadResponse(
      status: json['status'] as String,
      documentId: json['document_id'] as String,
      firebaseUid: json['firebase_uid'] as String,
    );
  }

  @override
  String toString() =>
      'DocumentUploadResponse(status: $status, documentId: $documentId, '
      'firebaseUid: $firebaseUid)';
}
