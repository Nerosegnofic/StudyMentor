import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../bloc/garden/garden_bloc.dart';
import '../../../bloc/garden/garden_event.dart';
import '../../../bloc/garden/garden_state.dart';
import '../../../data/catalog/subject_catalog.dart';
import '../../../domain/models/subject_progress_model.dart';
import '../../../services/installed_apps_service.dart';
import '../../../services/overlay/mascot_overlay_service.dart';
import '../../../domain/models/app_config_model.dart';
import '../../../utils/subject_xp_engine.dart';
import '../../widgets/garden_subject_card.dart';
import 'subject_detail_screen.dart';

class StudentHome extends StatefulWidget {
  final String fullName;
  final String uid;

  const StudentHome({super.key, required this.fullName, required this.uid});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  String? _parentFullName;
  List<AppRuleModel> _appRules = [];
  StudentConfigModel _config = const StudentConfigModel();
  bool _rulesLoading = true;
  final Map<String, String?> _iconCache = {};

  // Last known garden data — persists across BLoC state changes.
  Map<String, SubjectProgressModel> _gardenCache = {};

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(LoadParentNameRequested(studentUid: widget.uid));
    context.read<AuthBloc>().add(LoadStudentAppConfigRequested(studentUid: widget.uid));
    context.read<AuthBloc>().add(SyncInstalledAppsRequested(studentUid: widget.uid));
    context.read<GardenBloc>().add(LoadGardenRequested(studentUid: widget.uid));
  }

  Future<void> _refresh() async {
    setState(() {
      _parentFullName = null;
      _rulesLoading = true;
    });
    context.read<AuthBloc>().add(LoadParentNameRequested(studentUid: widget.uid));
    context.read<AuthBloc>().add(LoadStudentAppConfigRequested(studentUid: widget.uid));
    context.read<GardenBloc>().add(LoadGardenRequested(studentUid: widget.uid));
  }

  Future<void> _loadIcons(List<AppRuleModel> rules) async {
    final missing = rules
        .map((r) => r.packageName)
        .where((pkg) => !_iconCache.containsKey(pkg))
        .toList();
    if (missing.isEmpty) return;
    final results = await Future.wait(
      missing.map((pkg) => InstalledAppsService.instance.getAppIcon(pkg)),
    );
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < missing.length; i++) {
        _iconCache[missing[i]] = results[i];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is ParentNameLoaded) {
              setState(() => _parentFullName = state.parentFullName);
            }
            if (state is AppRulesLoaded && state.studentUid == widget.uid) {
              setState(() {
                _appRules = state.rules;
                _config = state.config;
                _rulesLoading = false;
              });
              MascotOverlayService.instance.updateMonitoredApps(
                state.rules,
                config: state.config,
              );
              _loadIcons(state.rules);
            }
            if (state is AppConfigError) {
              setState(() => _rulesLoading = false);
            }
          },
        ),
        BlocListener<GardenBloc, GardenState>(
          listener: (context, state) {
            if (state is GardenLoaded) {
              setState(() => _gardenCache = state.subjectProgress);
            }
          },
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Garden area — bg #F8FAF6 (matches React scroll area) ──────
              Container(
                color: const Color(0xFFF8FAF6),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome header
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          letterSpacing: -0.3,
                        ),
                        children: [
                          TextSpan(
                            text: 'Welcome back, ${widget.fullName.split(' ').first}! ',
                          ),
                          const TextSpan(text: '☀️'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your garden is growing beautifully!',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 20),

                    // Atmospheric garden
                    _buildGardenArea(),
                    const SizedBox(height: 16),

                    // Owl mascot
                    _buildOwlSection(),
                    const SizedBox(height: 16),

                    // Quick stats
                    _buildQuickStats(),
                  ],
                ),
              ),

              // ── Parent + App rules ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildParentSection(),
                    const SizedBox(height: 28),
                    _buildAppRulesSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Atmospheric garden with 3 plants ───────────────────────────────────────

  Widget _buildGardenArea() {
    return BlocBuilder<GardenBloc, GardenState>(
      builder: (context, state) {
        if ((state is GardenLoading || state is GardenInitial) &&
            _gardenCache.isEmpty) {
          return _gardenShell(
            child: const SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (state is GardenError && _gardenCache.isEmpty) {
          return _gardenShell(
            child: SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Could not load garden',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
            ),
          );
        }

        // First 3 subjects: Math (tree), Science (flower), History (bush)
        final subjects = SubjectCatalog.all.take(3).toList();

        // Soil area — plants bottom-aligned (matches React items-end)
        return _gardenShell(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFC5E8A8), Color(0xFFB8DFA0)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: subjects.map((subject) {
                final progress = _gardenCache[subject.key] ??
                    SubjectProgressModel.empty(widget.uid, subject.key);
                return Expanded(
                  child: GardenSubjectCard(
                    subject: subject,
                    progress: progress,
                    onTap: () => _openSubjectDetail(subject.key),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  /// Garden card shell — sky + progress strip + grass + soil.
  /// Matches the React HomeScreen garden exactly.
  Widget _gardenShell({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: const Color(0xFFE8F5E2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Sky zone (sun + cloud) ──────────────────────────────────
            SizedBox(
              height: 88,
              child: Stack(
                children: [
                  // Sun — solid amber circle with soft glow
                  Positioned(
                    top: 20,
                    left: 22,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFD426),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC107).withValues(alpha: 0.40),
                            blurRadius: 14,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Cloud — three overlapping white circles (right side)
                  Positioned(
                    top: 22,
                    right: 28,
                    child: SizedBox(
                      width: 72,
                      height: 38,
                      child: Stack(
                        children: [
                          // Base pill
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              width: 68,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                          // Left bubble
                          Positioned(
                            top: 0,
                            left: 12,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                          // Right bubble
                          Positioned(
                            top: 4,
                            left: 35,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Garden progress strip ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _overallGardenProgress(),
                  minHeight: 5,
                  backgroundColor: const Color(0xFFB8DBA0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF4CAF50),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // ── Grass strip ─────────────────────────────────────────────
            Container(
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF7CB342),
                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ),

            // ── Soil + plants ───────────────────────────────────────────
            child,
          ],
        ),
      ),
    );
  }

  /// Average progress across all loaded subjects (0.0 – 1.0).
  double _overallGardenProgress() {
    if (_gardenCache.isEmpty) return 0.0;
    double total = 0;
    for (final p in _gardenCache.values) {
      total += SubjectXpEngine.levelProgress(p.totalXp).clamp(0.0, 1.0);
    }
    return total / _gardenCache.length;
  }

  // ── Owl mascot ──────────────────────────────────────────────────────────────

  Widget _buildOwlSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Owl illustration — matches the React SVG
          SizedBox(
            width: 52,
            height: 52,
            child: CustomPaint(painter: _OwlPainter()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1FBF1),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Great job today! Keep studying to help your garden bloom! 🌸',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hootie, your Study Buddy',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick stats ─────────────────────────────────────────────────────────────

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _statCard(_lessonsIcon(), 'Lessons', '12')),
        const SizedBox(width: 10),
        Expanded(child: _statCard(const Text('🔥', style: TextStyle(fontSize: 22)), 'Streak', '7 days')),
        const SizedBox(width: 10),
        Expanded(child: _statCard(const Text('⭐', style: TextStyle(fontSize: 22)), 'Rank', '#24')),
      ],
    );
  }

  /// Three stacked coloured rectangles — matches the React LessonsIcon SVG.
  Widget _lessonsIcon() {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        children: [
          Positioned(
            left: 2, top: 8,
            child: Container(
              width: 20, height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF7EC8E3).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Positioned(
            left: 5, top: 5,
            child: Container(
              width: 20, height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFFF9A8C9).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Positioned(
            left: 8, top: 2,
            child: Container(
              width: 20, height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFFA5D6A7),
                borderRadius: BorderRadius.all(Radius.circular(3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(Widget icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  // ── Parent section ──────────────────────────────────────────────────────────

  Widget _buildParentSection() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFE8EDFF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.school, color: Color(0xFF4A6CF7), size: 26),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your parent',
              style: TextStyle(fontSize: 12, color: Color(0xFF8B93A7)),
            ),
            const SizedBox(height: 2),
            _parentFullName == null
                ? const SizedBox(
                    width: 120,
                    height: 16,
                    child: LinearProgressIndicator(),
                  )
                : Text(
                    _parentFullName!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ],
        ),
      ],
    );
  }

  // ── App rules section ───────────────────────────────────────────────────────

  Widget _buildAppRulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'App Rules',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            if (_rulesLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Rules configured by your parent.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 14),
        if (!_rulesLoading && _appRules.isEmpty)
          _buildNoRulesPlaceholder()
        else if (!_rulesLoading) ...[
          _buildTimingBanner(),
          const SizedBox(height: 12),
          ..._appRules.map(_buildRuleRow),
        ],
      ],
    );
  }

  Widget _buildTimingBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4A6CF7).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF4A6CF7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'All restricted apps share the same limits:',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 8),
          _buildPill(
            icon: Icons.timer_outlined,
            label: _formatDuration(_config.usageHours, _config.usageMinutes),
            color: const Color(0xFF34A853),
            bg: const Color(0xFFE6F4EA),
          ),
          const SizedBox(width: 6),
          _buildPill(
            icon: Icons.hourglass_bottom_outlined,
            label: _formatDuration(_config.cooldownHours, _config.cooldownMinutes),
            color: const Color(0xFFFF9800),
            bg: const Color(0xFFFFF8E1),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRulesPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.app_settings_alt_outlined, size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'No app rules set yet.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              "Your parent hasn't configured any rules for your device yet.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow(AppRuleModel rule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _AppIcon(iconBase64: _iconCache[rule.packageName], label: rule.appLabel),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.appLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  rule.packageName,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int hours, int minutes) {
    if (hours == 0 && minutes == 0) return '0m';
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  void _openSubjectDetail(String subjectKey) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<GardenBloc>()),
          ],
          child: SubjectDetailScreen(
            studentUid: widget.uid,
            subjectKey: subjectKey,
          ),
        ),
      ),
    );
  }
}

// ── Owl CustomPainter — matches the React SVG (60 × 60 viewport) ──────────────

class _OwlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Scale from SVG 60×60 to Flutter canvas (52×52)
    final s = size.width / 60.0;
    canvas.scale(s);

    Paint p(Color c) => Paint()..color = c;

    // Body
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(30, 35), width: 40, height: 46),
      p(const Color(0xFF8D6E63)),
    );

    // Left wing: rotate(-20°) around (15, 35)
    canvas.save();
    canvas.translate(15, 35);
    canvas.rotate(-20 * math.pi / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 16, height: 30),
      p(const Color(0xFF6D4C41)),
    );
    canvas.restore();

    // Right wing: rotate(20°) around (45, 35)
    canvas.save();
    canvas.translate(45, 35);
    canvas.rotate(20 * math.pi / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 16, height: 30),
      p(const Color(0xFF6D4C41)),
    );
    canvas.restore();

    // Head
    canvas.drawCircle(const Offset(30, 22), 16, p(const Color(0xFFA1887F)));

    // Eye whites
    canvas.drawCircle(const Offset(24, 20), 6, p(Colors.white));
    canvas.drawCircle(const Offset(36, 20), 6, p(Colors.white));

    // Pupils
    canvas.drawCircle(const Offset(25, 20), 3, p(const Color(0xFF3E2723)));
    canvas.drawCircle(const Offset(37, 20), 3, p(const Color(0xFF3E2723)));

    // Eye highlights
    canvas.drawCircle(const Offset(26, 19), 1.5, p(Colors.white));
    canvas.drawCircle(const Offset(38, 19), 1.5, p(Colors.white));

    // Beak
    final beak = Path()
      ..moveTo(30, 24)
      ..lineTo(27, 28)
      ..lineTo(33, 28)
      ..close();
    canvas.drawPath(beak, p(const Color(0xFFFF9800)));

    // Left ear tuft
    final leftEar = Path()
      ..moveTo(20, 12)
      ..lineTo(18, 6)
      ..lineTo(22, 10)
      ..close();
    canvas.drawPath(leftEar, p(const Color(0xFF8D6E63)));

    // Right ear tuft
    final rightEar = Path()
      ..moveTo(40, 12)
      ..lineTo(42, 6)
      ..lineTo(38, 10)
      ..close();
    canvas.drawPath(rightEar, p(const Color(0xFF8D6E63)));

    // Tummy
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(30, 38), width: 24, height: 28),
      p(const Color(0xFFBCAAA4)),
    );
  }

  @override
  bool shouldRepaint(_OwlPainter old) => false;
}

// ── App icon widget ────────────────────────────────────────────────────────────

class _AppIcon extends StatelessWidget {
  final String? iconBase64;
  final String label;

  const _AppIcon({required this.iconBase64, required this.label});

  @override
  Widget build(BuildContext context) {
    if (iconBase64 != null && iconBase64!.isNotEmpty) {
      try {
        return CircleAvatar(
          backgroundImage: MemoryImage(base64Decode(iconBase64!)),
          backgroundColor: const Color(0xFFE8EDFF),
          radius: 20,
        );
      } catch (_) {}
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFE8EDFF),
      child: Text(
        label[0].toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF4A6CF7),
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}
