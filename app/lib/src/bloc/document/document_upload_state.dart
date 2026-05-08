import 'package:equatable/equatable.dart';
import '../../data/catalog/document_models.dart';

abstract class DocumentUploadState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DocumentUploadInitial extends DocumentUploadState {}

class DocumentUploadLoading extends DocumentUploadState {}

/// The server accepted the PDF and started background ingestion.
/// [response] contains the document_id and the firebase_uid for confirmation.
class DocumentUploadAccepted extends DocumentUploadState {
  final DocumentUploadResponse response;

  DocumentUploadAccepted(this.response);

  @override
  List<Object?> get props => [response];
}

class DocumentUploadError extends DocumentUploadState {
  final String message;

  DocumentUploadError(this.message);

  @override
  List<Object?> get props => [message];
}
