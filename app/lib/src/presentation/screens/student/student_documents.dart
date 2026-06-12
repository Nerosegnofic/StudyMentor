import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/document/document_upload_bloc.dart';
import '../../../bloc/document/document_upload_event.dart';
import '../../../bloc/document/document_upload_state.dart';
import '../../../bloc/subject/subject_bloc.dart';
import '../../../bloc/subject/subject_event.dart';

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
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file first.')),
      );
      return;
    }

    final name = _subjectNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Subject Name.')),
      );
      return;
    }

    if (widget.existingSubjectKeys.contains(name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This subject already exists.')),
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
        }
      },
      builder: (context, state) {
        if (state is DocumentUploadLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF4A6CF7)),
                SizedBox(height: 20),
                Text(
                  'Uploading & processing…',
                  style: TextStyle(color: Color(0xFF8B93A7), fontSize: 15),
                ),
              ],
            ),
          );
        }

        if (state is DocumentUploadAccepted) {
          return _SuccessView(
            documentId: state.response.documentId,
            onUploadAnother: () {
              _clearSelection();
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
                color: Color(0xFF4A6CF7),
              ),
              const SizedBox(height: 20),
              const Text(
                'Upload Curriculum',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1F3C),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload a PDF textbook to build an adaptive quiz from its content.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8B93A7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Subject Name Input
              const Text(
                'Subject Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1F3C),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _subjectNameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Mathematics, Science...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

              // File picker area
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedFileName != null
                          ? const Color(0xFF34A853)
                          : const Color(0xFF4A6CF7),
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFileName != null
                            ? Icons.picture_as_pdf_rounded
                            : Icons.folder_open_rounded,
                        size: 36,
                        color: _selectedFileName != null
                            ? const Color(0xFF34A853)
                            : const Color(0xFF4A6CF7),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedFileName != null) ...[
                        Text(
                          _selectedFileName!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1F3C),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: _clearSelection,
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Remove'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFEA4335),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'Tap to browse PDF',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A6CF7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Only .pdf files are supported',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8B93A7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Subject ID picker
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Upload Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(Icons.settings, color: Color(0xFF4A6CF7)),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: _selectedFilePath != null
                    ? () => _upload(context)
                    : null,
                icon: const Icon(Icons.cloud_upload_rounded, size: 20),
                label: const Text(
                  'Upload & Ingest',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CF7),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFCED4DA),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),

              const SizedBox(height: 12),

              // Error banner if previous attempt failed
              if (state is DocumentUploadError)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEA4335)),
                  ),
                  child: Text(
                    state.message,
                    style: const TextStyle(
                      color: Color(0xFFB71C1C),
                      fontSize: 13,
                    ),
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
// Success view
// ---------------------------------------------------------------------------

class _SuccessView extends StatelessWidget {
  final String documentId;
  final VoidCallback onUploadAnother;

  const _SuccessView({required this.documentId, required this.onUploadAnother});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 80,
              color: Color(0xFF34A853),
            ),
            const SizedBox(height: 20),
            const Text(
              'Upload Accepted!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1F3C),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The AI engine is now parsing and embedding your document in the background.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8B93A7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBD6F4)),
              ),
              child: Text(
                'Document ID: $documentId',
                style: const TextStyle(fontSize: 12, color: Color(0xFF4A6CF7)),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onUploadAnother,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6CF7),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Upload Another'),
            ),
          ],
        ),
      ),
    );
  }
}
