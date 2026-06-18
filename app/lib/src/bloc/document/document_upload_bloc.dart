import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/ai_engine_repository.dart';
import 'document_upload_event.dart';
import 'document_upload_state.dart';

/// Stable sentinel emitted when the server rejects an upload because a document
/// for the same subject is still ingesting (409). Mapped to a localized string
/// by `localizeError`.
const String kSubjectStillProcessingError =
    'A document for this subject is still being processed. '
    'Please wait until it finishes before uploading another.';

class DocumentUploadBloc
    extends Bloc<DocumentUploadEvent, DocumentUploadState> {
  final AiEngineRepository repository;

  DocumentUploadBloc({required this.repository})
      : super(DocumentUploadInitial()) {
    on<PickAndUploadDocumentEvent>(_onUpload);
    on<ResetDocumentUploadEvent>(_onReset);
  }

  Future<void> _onUpload(
    PickAndUploadDocumentEvent event,
    Emitter<DocumentUploadState> emit,
  ) async {
    emit(DocumentUploadLoading());
    try {
      final response = await repository.uploadDocument(
        pdfFile: event.file,
        subjectName: event.subjectName,
        studentUid: event.studentUid,
      );
      emit(DocumentUploadAccepted(response));
    } on SubjectStillProcessingException {
      emit(DocumentUploadError(kSubjectStillProcessingError));
    } catch (e) {
      emit(DocumentUploadError('Upload failed. Please try again.'));
    }
  }

  void _onReset(
    ResetDocumentUploadEvent event,
    Emitter<DocumentUploadState> emit,
  ) {
    emit(DocumentUploadInitial());
  }
}
