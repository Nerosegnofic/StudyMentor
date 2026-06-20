import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/repositories/ai_engine_repository.dart';
import '../../../bloc/document/document_upload_bloc.dart';
import '../../../bloc/document/document_upload_event.dart';
import '../../../bloc/document/document_upload_state.dart';
import '../../../bloc/subject/subject_bloc.dart';
import '../../../bloc/subject/subject_event.dart';
import '../../../../l10n/app_localizations.dart';
import '../../utils/error_localizer.dart';

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
              content: Text(localizeError(state.message, AppLocalizations.of(context))),
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
        }
      },
      builder: (context, state) {
        if (state is DocumentUploadLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF4A6CF7)),
                const SizedBox(height: 20),
                Text(
                  loc.uploadingProcessingMessage,
                  style: const TextStyle(color: Color(0xFF8B93A7), fontSize: 15),
                ),
              ],
            ),
          );
        }

        if (state is DocumentUploadAccepted) {
          return _PreparingView(
            studentUid: widget.studentUid,
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

            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Preparing view — shown after upload while ingestion runs, with live stage text.
// ---------------------------------------------------------------------------

class _PreparingView extends StatefulWidget {
  final String studentUid;
  final String subjectName;
  final VoidCallback onUploadAnother;

  const _PreparingView({
    required this.studentUid,
    required this.subjectName,
    required this.onUploadAnother,
  });

  @override
  State<_PreparingView> createState() => _PreparingViewState();
}

class _PreparingViewState extends State<_PreparingView> {
  Timer? _poll;

  /// Live state of the just-uploaded subject: "processing" | "ready" | "failed".
  /// Starts as processing (the upload was just accepted; ingestion runs in background).
  String _state = 'processing';
  String? _stage;

  @override
  void initState() {
    super.initState();
    _fetch();
    _poll = Timer.periodic(const Duration(seconds: 12), (_) => _fetch());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final statuses = await AiEngineRepository.instance
          .getSubjectsStatus(studentUid: widget.studentUid);
      if (!mounted) return;
      final name = widget.subjectName.toLowerCase().trim();
      final match = statuses
          .where((s) => s.subjectName.toLowerCase().trim() == name)
          .toList();
      if (match.isEmpty) return; // not visible yet; keep "processing" and retry
      final s = match.first;
      setState(() {
        _state = s.state;
        _stage = s.stage;
      });
      if (s.state != 'processing') {
        _poll?.cancel();
        _poll = null;
      }
    } catch (_) {
      // Best-effort; keep last state and retry next tick.
    }
  }

  String _stageLabel(AppLocalizations loc) {
    switch (_stage) {
      case 'parsing':
        return loc.subjectStageParsing;
      case 'analyzing':
        return loc.subjectStageAnalyzing;
      case 'building_skills':
        return loc.subjectStageBuildingSkills;
      default:
        return loc.subjectPreparingLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isProcessing = _state == 'processing';
    final isFailed = _state == 'failed';

    final IconData icon;
    final Color iconColor;
    final String title;
    final String message;
    if (isProcessing) {
      icon = Icons.hourglass_top_rounded;
      iconColor = const Color(0xFF2196F3);
      title = loc.subjectPreparingLabel;
      message = _stageLabel(loc);
    } else if (isFailed) {
      icon = Icons.error_outline_rounded;
      iconColor = const Color(0xFFEA4335);
      title = loc.curriculumAddedSuccessTitle; // reuse heading slot
      message = loc.subjectIngestFailed;
    } else {
      icon = Icons.check_circle_rounded;
      iconColor = const Color(0xFF34A853);
      title = loc.curriculumAddedSuccessTitle;
      message = loc.curriculumAddedSuccessMessage(widget.subjectName);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isProcessing)
              const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(color: Color(0xFF2196F3)),
              )
            else
              Icon(icon, size: 80, color: iconColor),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // "Upload Another" is disabled while this subject is still processing —
            // a second upload for the same subject would be rejected with 409 anyway.
            ElevatedButton(
              onPressed: isProcessing ? null : widget.onUploadAnother,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFCED4DA),
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
