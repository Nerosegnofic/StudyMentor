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
import '../../../bloc/subject_status/subject_status_cubit.dart';
import '../../../data/catalog/document_models.dart';
import '../student/student_documents.dart';
import '../../../data/catalog/subject_metadata_registry.dart';
import '../../../../l10n/app_localizations.dart';
import '../../utils/error_localizer.dart';

// SubjectData removed, using SubjectSummaryModel directly


class SubjectsSkillsScreen extends StatefulWidget {
  final StudentModel student;

  /// Optional override for testing — avoids the Firebase singleton inside
  /// [SubjectStatusCubit]'s default constructor.
  final SubjectStatusCubit? statusCubit;

  const SubjectsSkillsScreen({super.key, required this.student, this.statusCubit});

  @override
  State<SubjectsSkillsScreen> createState() => _SubjectsSkillsScreenState();
}

class _SubjectsSkillsScreenState extends State<SubjectsSkillsScreen> {
  /// Child-scoped ingestion-status poll. The parent uploads on the child's behalf, so
  /// this passes the child's uid to see THAT child's subjects (the endpoint falls back
  /// to the JWT uid only when omitted). Drives the transient "Preparing…" banner.
  late final SubjectStatusCubit _statusCubit;
  late final bool _ownsCubit;

  @override
  void initState() {
    super.initState();
    context.read<SubjectBloc>().add(LoadSubjectsRequested(studentUid: widget.student.uid));
    if (widget.statusCubit != null) {
      _statusCubit = widget.statusCubit!;
      _ownsCubit = false;
    } else {
      _statusCubit = SubjectStatusCubit(studentUid: widget.student.uid)..start();
      _ownsCubit = true;
    }
  }

  @override
  void dispose() {
    if (_ownsCubit) _statusCubit.close();
    super.dispose();
  }

  void _openDocumentUpload(BuildContext context, List<String> existingKeys) {
    final repo = AiEngineRepository(baseUrl: AiEngineRepository.defaultBaseUrl);
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
          if (state is SubjectAdded) {
            _statusCubit.start();
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
              return Center(child: Text(localizeError(state.message, AppLocalizations.of(context))));
            }
            final subjects = state is SubjectsLoaded ? state.subjects : <SubjectSummaryModel>[];
            final existingKeys = subjects.map((s) => s.subjectKey).toList();

            return Column(
              children: [
                _buildHeader(context, existingKeys),
                // Transient "preparing" banner — only present while ≥1 subject is still
                // ingesting; absent (normal UI) otherwise. Cards themselves are unchanged.
                BlocBuilder<SubjectStatusCubit, SubjectStatusState>(
                  bloc: _statusCubit,
                  builder: (context, st) => _buildPreparingBanner(context, st),
                ),
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

  /// Maps an ingestion `stage` to a localized human label.
  String _stageLabel(AppLocalizations loc, String? stage) {
    switch (stage) {
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

  /// Transient banner shown ONLY while ≥1 subject is still ingesting (or failed).
  /// Returns an empty box (no space taken) otherwise, so the normal UI is unchanged
  /// in the common all-ready case.
  Widget _buildPreparingBanner(BuildContext context, SubjectStatusState st) {
    final loc = AppLocalizations.of(context);
    final processing = st.processing;
    final failed = st.bySubjectId.values.where((s) => s.isFailed).toList();

    if (processing.isEmpty && failed.isEmpty) {
      return const SizedBox.shrink();
    }

    // Prefer surfacing an in-progress subject; otherwise a failed one.
    final bool isFailed = processing.isEmpty;
    final SubjectStatus s = isFailed ? failed.first : processing.first;
    final String message = isFailed
        ? loc.subjectIngestFailed
        : '${_stageLabel(loc, s.stage)} — ${s.subjectName}';

    final Color bg = isFailed ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1);
    final Color fg = isFailed ? const Color(0xFFB71C1C) : const Color(0xFF8D6E00);

    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (isFailed)
            Icon(Icons.error_outline_rounded, color: fg, size: 20)
          else
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
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

    return Opacity(
      // Dim deselected subjects so the parent can see at a glance which are off-focus.
      opacity: subject.isSelected ? 1.0 : 0.55,
      child: GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => ParentSubjectDetailScreen(
              studentUid: widget.student.uid,
              subjectId: subject.subjectId,
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
                      Tooltip(
                        message: subject.isSelected
                            ? 'Focused — visible to your child'
                            : 'Hidden from your child',
                        child: Switch.adaptive(
                          value: subject.isSelected,
                          activeThumbColor: color,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: subject.subjectId == 0
                              ? null
                              : (v) => context.read<SubjectBloc>().add(
                                    ToggleSubjectSelectionRequested(
                                      studentUid: widget.student.uid,
                                      subjectId: subject.subjectId,
                                      isSelected: v,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(width: 4),
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
      ),
    );
  }

  Future<void> _showRemoveConfirmationDialog(BuildContext context, SubjectSummaryModel subject) async {
    // Capture the bloc before the async gap so we don't touch `context` after awaiting.
    final subjectBloc = context.read<SubjectBloc>();
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
                  subject.isGlobal
                      ? "This clears your child's progress in this subject and moves it back to Add Subjects. The subject itself is kept."
                      : "This permanently deletes the subject and all its data.",
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
      if (subject.isGlobal) {
        // Global: wipe the child's progress and return it to the catalog; keep the subject.
        subjectBloc.add(
          RemoveGlobalSubjectRequested(studentUid: widget.student.uid, subjectId: subject.subjectId),
        );
      } else {
        // Private: hard-delete the subject and all its data.
        subjectBloc.add(
          RemoveSubjectRequested(studentUid: widget.student.uid, subjectKey: subject.subjectKey),
        );
      }
    }
  }

  void _showAddSubjectModal(BuildContext context, List<String> existingKeys) {
    context.read<SubjectBloc>().add(LoadAvailableSubjectsRequested(studentUid: widget.student.uid));
    final selectedIds = <int>{};
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
                          final filteredSubjects = state.subjects.where((s) {
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
                              final isSelected = selectedIds.contains(subject.subjectId);
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
                                      selectedIds.remove(subject.subjectId);
                                    } else {
                                      selectedIds.add(subject.subjectId);
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
                              if (selectedIds.isNotEmpty) {
                                modalContext.read<SubjectBloc>().add(
                                  SelectGlobalSubjectsRequested(
                                    studentUid: widget.student.uid,
                                    subjectIds: selectedIds.toList(),
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
                              AppLocalizations.of(context).addSelectedCountButton(selectedIds.length),
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
