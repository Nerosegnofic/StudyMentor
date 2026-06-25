import 'package:equatable/equatable.dart';

abstract class DocumentUploadState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DocumentUploadInitial extends DocumentUploadState {}

class DocumentUploadLoading extends DocumentUploadState {}

/// The server accepted the PDF and started background ingestion.
class DocumentUploadAccepted extends DocumentUploadState {}

class DocumentUploadError extends DocumentUploadState {
  final String message;

  DocumentUploadError(this.message);

  @override
  List<Object?> get props => [message];
}
