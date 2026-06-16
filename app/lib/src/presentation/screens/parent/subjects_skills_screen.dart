import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../bloc/document/document_upload_bloc.dart';
import '../../../data/repositories/ai_engine_repository.dart';
import '../../../domain/models/student_model.dart';
import '../../../domain/models/subject_summary_model.dart';
import 'parent_subject_detail_screen.dart';
import '../../../bloc/subject/subject_bloc.dart';
import '../../../bloc/subject/subject_event.dart';
import '../../../bloc/subject/subject_state.dart';
import '../student/student_documents.dart';
import '../../../data/catalog/subject_metadata_registry.dart';
import '../../../../l10n/app_localizations.dart';

// SubjectData removed, using SubjectSummaryModel directly


class SubjectsSkillsScreen extends StatefulWidget {
  final StudentModel student;

  const SubjectsSkillsScreen({super.key, required this.student});

  @override
  State<SubjectsSkillsScreen> createState() => _SubjectsSkillsScreenState();
}

class _SubjectsSkillsScreenState extends State<SubjectsSkillsScreen> {

  static const _kAiEngineBaseUrl = 'http://192.168.1.6:8000';


  @override
  void initState() {
    super.initState();
    context.read<SubjectBloc>().add(LoadSubjectsRequested(studentUid: widget.student.uid));
  }

  void _openDocumentUpload(BuildContext context, List<String> existingKeys) {
    final repo = AiEngineRepository(baseUrl: _kAiEngineBaseUrl);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => DocumentUploadBloc(repository: repo),
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F7FF),
            appBar: AppBar(
              title: Text(
                AppLocalizations.of(context).uploadCurriculumTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            body: StudentDocumentUploadScreen(
              studentUid: widget.student.uid,
              existingSubjectKeys: existingKeys,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: BlocListener<SubjectBloc, SubjectState>(
        listener: (context, state) {
          if (state is SubjectRemoved || state is SubjectAdded) {
            context.read<SubjectBloc>().add(LoadSubjectsRequested(studentUid: widget.student.uid));
          }
          if (state is SubjectsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFE53935),
                behavior: SnackBarBehavior.floating,
              ),
            );
            // Reload to restore UI to actual state
            context.read<SubjectBloc>().add(LoadSubjectsRequested(studentUid: widget.student.uid));
          }
        },
        child: BlocBuilder<SubjectBloc, SubjectState>(
          buildWhen: (prev, curr) =>
              curr is SubjectsLoading || curr is SubjectsLoaded || curr is SubjectsError,
          builder: (context, state) {
            if (state is SubjectsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SubjectsError) {
              return Center(child: Text(state.message));
            }
            final subjects = state is SubjectsLoaded ? state.subjects : <SubjectSummaryModel>[];
            final existingKeys = subjects.map((s) => s.subjectKey).toList();

            return Column(
              children: [
                _buildHeader(context, existingKeys),
                Expanded(
                  child: subjects.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: subjects.length,
                          itemBuilder: (context, index) {
                            return _buildSubjectCard(context, subjects[index]);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 48,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.noSubjectsYetTitle,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.noSubjectsYetDescription(widget.student.fullName),
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<String> existingKeys) {
    return Container(
      color: const Color(0xFF2196F3),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            AppLocalizations.of(context).subjectsAndSkillsTitle,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          InkWell(
            onTap: () => _showAddSubjectModal(context, existingKeys),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Color(0xFF2196F3)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, SubjectSummaryModel subject) {
    final loc = AppLocalizations.of(context);
    final title = subject.subjectKey[0].toUpperCase() + subject.subjectKey.substring(1);
    final progress = subject.masteryPercent;

    Color color;
    try {
      color = Color(int.parse(subject.colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      color = Colors.blue;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => ParentSubjectDetailScreen(
              studentUid: widget.student.uid,
              subjectKey: subject.subjectKey,
              subjectName: title,
              color: color,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: BorderDirectional(start: BorderSide(width: 4, color: color)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.07),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                SubjectMetadataRegistry.getSubjectIcon(subject.subjectKey) ?? Icons.book,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF1E293B),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showRemoveConfirmationDialog(context, subject),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFE53935),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      loc.skillsTrackedLabel(subject.skillsCount),
                      style: GoogleFonts.cairo(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.masteryLabel,
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$progress%',
                        style: GoogleFonts.cairo(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            width: constraints.maxWidth,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            width: constraints.maxWidth * (progress / 100),
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRemoveConfirmationDialog(BuildContext context, SubjectSummaryModel subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final loc = AppLocalizations.of(context);
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.removeSubjectConfirmTitle(subject.subjectKey),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.removeSubjectConfirmMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF64748B),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          loc.commonCancel,
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          loc.removeButton,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      context.read<SubjectBloc>().add(
        RemoveSubjectRequested(studentUid: widget.student.uid, subjectKey: subject.subjectKey)
      );
    }
  }

  void _showAddSubjectModal(BuildContext context, List<String> existingKeys) {
    context.read<SubjectBloc>().add(LoadAvailableSubjectsRequested());
    final selectedKeys = <String>{};
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final loc = AppLocalizations.of(modalContext);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      onChanged: (value) {
                        setModalState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: loc.searchSubjectsHint,
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: BlocBuilder<SubjectBloc, SubjectState>(
                      buildWhen: (prev, curr) => curr is SubjectsLoading || curr is AvailableSubjectsLoaded,
                      builder: (context, state) {
                        if (state is SubjectsLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (state is AvailableSubjectsLoaded) {
                          final subjects = state.subjects.where((s) => !existingKeys.contains(s.subjectKey)).toList();
                          final filteredSubjects = subjects.where((s) {
                            final name = s.subjectKey.toLowerCase();
                            return name.startsWith(searchQuery.toLowerCase());
                          }).toList();
                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.5,
                            ),
                            itemCount: filteredSubjects.length,
                            itemBuilder: (context, index) {
                              final subject = filteredSubjects[index];
                              final isSelected = selectedKeys.contains(subject.subjectKey);
                              Color color;
                              try {
                                color = Color(int.parse(subject.colorHex.replaceFirst('#', '0xFF')));
                              } catch (_) {
                                color = Colors.blue;
                              }
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      selectedKeys.remove(subject.subjectKey);
                                    } else {
                                      selectedKeys.add(subject.subjectKey);
                                    }
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFE3F2FD) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF2196F3) : const Color(0xFFE2E8F0),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        SubjectMetadataRegistry.getSubjectIcon(subject.subjectKey) ?? Icons.book,
                                        color: color,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        subject.subjectKey.substring(0, 1).toUpperCase() + subject.subjectKey.substring(1),
                                        style: GoogleFonts.cairo(
                                          color: const Color(0xFF1E293B),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (selectedKeys.isNotEmpty) {
                                modalContext.read<SubjectBloc>().add(
                                  AddSubjectsRequested(
                                    studentUid: widget.student.uid,
                                    selectedKeys: selectedKeys.toList(),
                                  ),
                                );
                                Navigator.pop(modalContext);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                            ),
                            child: Text(
                              loc.addSelectedCountButton(selectedKeys.length),
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(modalContext);
                              _openDocumentUpload(context, existingKeys);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2196F3),
                              side: const BorderSide(color: Color(0xFF2196F3), width: 1),
                              backgroundColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                            child: Text(
                              loc.uploadCurriculumTitle,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2196F3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
