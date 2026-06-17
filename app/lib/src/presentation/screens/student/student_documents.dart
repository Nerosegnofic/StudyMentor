import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../bloc/document/document_upload_bloc.dart';
import '../../../bloc/document/document_upload_event.dart';
import '../../../bloc/document/document_upload_state.dart';
import '../../../bloc/subject/subject_bloc.dart';
import '../../../bloc/subject/subject_event.dart';
import '../../../features/mascot/mascot_cubit.dart';
import '../../../features/mascot/mascot_state.dart';
import '../../../features/mascot/mascot_widget.dart';
import '../../../features/mascot/mascot_with_bubble.dart';
import '../../../../l10n/app_localizations.dart';

/// Document upload screen that lets the student browse for a PDF and upload it
/// to the AI Engine for curriculum ingestion.
class StudentDocumentUploadScreen extends StatefulWidget {
  final String studentUid;
  final List<String> existingSubjectKeys;
  const StudentDocumentUploadScreen({super.key, required this.studentUid, required this.existingSubjectKeys});

  @override
  State<StudentDocumentUploadScreen> createState() =>
      _StudentDocumentUploadScreenState();
}

class _StudentDocumentUploadScreenState
    extends State<StudentDocumentUploadScreen> {
  String? _selectedFilePath;
  String? _selectedFileName;
  final TextEditingController _subjectNameController = 
      TextEditingController();

  @override
  void dispose() {
    _subjectNameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path!;
        _selectedFileName = result.files.single.name;
      });
    }
  }

  void _upload(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.selectPdfFirstMessage)),
      );
      return;
    }

    final name = _subjectNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.enterSubjectNameMessage)),
      );
      return;
    }

    if (widget.existingSubjectKeys.contains(name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.subjectAlreadyExistsMessage)),
      );
      return;
    }

    context.read<DocumentUploadBloc>().add(
      PickAndUploadDocumentEvent(
        file: File(_selectedFilePath!),
        subjectName: name,
        studentUid: widget.studentUid,
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedFilePath = null;
      _selectedFileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocConsumer<DocumentUploadBloc, DocumentUploadState>(
      listener: (context, state) {
        if (state is DocumentUploadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFEA4335),
            ),
          );
        } else if (state is DocumentUploadAccepted) {
          context.read<SubjectBloc>().add(
            AddSubjectsRequested(
              studentUid: widget.studentUid,
              selectedKeys: [_subjectNameController.text.trim().toLowerCase()],
            ),
          );
          context.read<MascotCubit>().reactTemporarily(
                MascotState.happy,
                duration: const Duration(seconds: 2),
              );
        }
      },
      builder: (context, state) {
        if (state is DocumentUploadLoading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: MascotWithBubble(
                state: MascotState.thinking,
                showLoadingSpinner: true,
                message: loc.uploadingProcessingMessage,
              ),
            ),
          );
        }

        if (state is DocumentUploadAccepted) {
          return _SuccessView(
            subjectName: _subjectNameController.text.trim(),
            onUploadAnother: () {
              _clearSelection();
              _subjectNameController.clear();
              context.read<DocumentUploadBloc>().add(
                ResetDocumentUploadEvent(),
              );
            },
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Icon(
                Icons.upload_file_rounded,
                size: 72,
                color: Color(0xFF2196F3),
              ),
              const SizedBox(height: 20),
              Text(
                loc.uploadCurriculumTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.uploadCurriculumDescription,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Subject Name Input
              Text(
                loc.subjectNameLabel,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _subjectNameController,
                style: GoogleFonts.cairo(fontSize: 14),
                decoration: InputDecoration(
                  hintText: loc.subjectNameHint,
                  prefixIcon: const Icon(Icons.subtitles_outlined, color: Color(0xFF2196F3)),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

              // File picker area
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _selectedFileName != null
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedFileName != null
                          ? const Color(0xFF34A853)
                          : const Color(0xFF2196F3),
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.02),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFileName != null
                            ? Icons.picture_as_pdf_rounded
                            : Icons.cloud_upload_outlined,
                        size: 44,
                        color: _selectedFileName != null
                            ? const Color(0xFF34A853)
                            : const Color(0xFF2196F3),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedFileName != null) ...[
                        Text(
                          _selectedFileName!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: _clearSelection,
                          icon: const Icon(Icons.close, size: 16),
                          label: Text(
                            loc.removeFileButton,
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFEA4335),
                          ),
                        ),
                      ] else ...[
                        Text(
                          loc.tapToBrowsePdfMessage,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2196F3),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.onlyPdfSupportedMessage,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _selectedFilePath != null
                    ? () => _upload(context)
                    : null,
                icon: const Icon(Icons.cloud_upload_rounded, size: 20),
                label: Text(
                  loc.uploadAndIngestButton,
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFCED4DA),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
              ),

              const SizedBox(height: 12),

              // Error banner if previous attempt failed
              if (state is DocumentUploadError) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const MascotWidget(state: MascotState.sad, size: 64),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEA4335)),
                        ),
                        child: Text(
                          state.message,
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFB71C1C),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Success view
// ---------------------------------------------------------------------------

class _SuccessView extends StatelessWidget {
  final String subjectName;
  final VoidCallback onUploadAnother;

  const _SuccessView({required this.subjectName, required this.onUploadAnother});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loc.curriculumAddedSuccessTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),
            BlocBuilder<MascotCubit, MascotState>(
              builder: (context, mascotState) => MascotWithBubble(
                state: mascotState,
                mascotSize: 90,
                message: loc.curriculumAddedSuccessMessage(subjectName),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onUploadAnother,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Text(
                loc.uploadAnotherButton,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
