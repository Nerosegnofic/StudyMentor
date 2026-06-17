import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../services/settings_service.dart';
import '../../../services/overlay/mascot_overlay_service.dart';
import '../../widgets/language_picker_dialog.dart';
import '../../../../l10n/app_localizations.dart';

// ── Study Mentor design tokens (Student app: gamified & immersive) ────────────
const Color _kBackground = Color(0xFFF5F7FA); // Soft Cloud
const Color _kGreen = Color(0xFF4CAF50); // Primary Green
const Color _kInk = Color(0xFF1F2937); // Title ink

class StudentSettings extends StatefulWidget {
  final String uid;
  const StudentSettings({super.key, required this.uid});

  @override
  State<StudentSettings> createState() => _StudentSettingsState();
}

class _StudentSettingsState extends State<StudentSettings> {
  SettingsService? _settings;
  bool _notificationsEnabled = true;
  bool _soundEffectsEnabled = true;
  bool _backgroundMusicEnabled = false;
  bool _timerNotificationEnabled = true;
  bool _cooldownNotificationEnabled = true;
  String _appVersion = 'v1.0';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final settings = await SettingsService.create();
    PackageInfo? info;
    try {
      info = await PackageInfo.fromPlatform();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _notificationsEnabled = settings.notificationsEnabled;
      _soundEffectsEnabled = settings.soundEffectsEnabled;
      _backgroundMusicEnabled = settings.backgroundMusicEnabled;
      _timerNotificationEnabled = settings.timerNotificationEnabled;
      _cooldownNotificationEnabled = settings.cooldownNotificationEnabled;
      _appVersion = info != null ? 'v${info.version}' : 'v1.0';
      _loading = false;
    });
  }

  Future<void> _toggle(
    String key,
    bool value,
    Future<void> Function(bool) setter,
  ) async {
    setState(() {
      switch (key) {
        case 'notifications':
          _notificationsEnabled = value;
        case 'sound':
          _soundEffectsEnabled = value;
        case 'music':
          _backgroundMusicEnabled = value;
        case 'timerNotification':
          _timerNotificationEnabled = value;
          MascotOverlayService.instance.setTimerNotificationEnabled(value);
        case 'cooldownNotification':
          _cooldownNotificationEnabled = value;
          MascotOverlayService.instance.setCooldownNotificationEnabled(value);
      }
    });
    await setter(value);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: _kBackground,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _kGreen),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    children: [
                      _sectionLabel('Preferences'),
                      _buildPreferencesCard(loc),
                      const SizedBox(height: 20),
                      _sectionLabel('Account'),
                      _buildAccountCard(loc),
                      const SizedBox(height: 20),
                      _sectionLabel('About'),
                      _buildAboutCard(loc),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Immersive green header band ─────────────────────────────────────────────

  Widget _buildHeader() => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF43A047), _kGreen],
      ),
    ),
    padding: EdgeInsets.fromLTRB(
      8,
      MediaQuery.of(context).padding.top + 8,
      16,
      20,
    ),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        Text(
          'Settings',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
    child: Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade600,
        letterSpacing: 0.3,
      ),
    ),
  );

  Widget _buildPreferencesCard(AppLocalizations loc) => _card(
    children: [
      _toggleRow(
        icon: Icons.notifications_outlined,
        title: loc.pushNotificationsTitle,
        subtitle: loc.pushNotificationsSubtitle,
        value: _notificationsEnabled,
        onChanged: (v) =>
            _toggle('notifications', v, _settings!.setNotificationsEnabled),
      ),
      _divider(),
      _toggleRow(
        icon: Icons.volume_up_outlined,
        title: loc.soundEffectsTitle,
        subtitle: loc.soundEffectsSubtitle,
        value: _soundEffectsEnabled,
        onChanged: (v) =>
            _toggle('sound', v, _settings!.setSoundEffectsEnabled),
      ),
      _divider(),
      _toggleRow(
        icon: Icons.music_note_outlined,
        title: loc.backgroundMusicTitle,
        subtitle: loc.backgroundMusicSubtitle,
        value: _backgroundMusicEnabled,
        onChanged: (v) =>
            _toggle('music', v, _settings!.setBackgroundMusicEnabled),
      ),
      _divider(),
      _toggleRow(
        icon: Icons.timer_outlined,
        title: loc.usageTimerNotificationTitle,
        subtitle: loc.usageTimerNotificationSubtitle,
        value: _timerNotificationEnabled,
        onChanged: (v) => _toggle(
          'timerNotification',
          v,
          _settings!.setTimerNotificationEnabled,
        ),
      ),
      _divider(),
      _toggleRow(
        icon: Icons.hourglass_bottom_outlined,
        title: loc.cooldownTimerNotificationTitle,
        subtitle: loc.cooldownTimerNotificationSubtitle,
        value: _cooldownNotificationEnabled,
        onChanged: (v) => _toggle(
          'cooldownNotification',
          v,
          _settings!.setCooldownNotificationEnabled,
        ),
      ),
    ],
  );

  Widget _buildAccountCard(AppLocalizations loc) => _card(
    children: [
      InkWell(
        onTap: () => showLanguagePickerDialog(context),
        child: _chevronRow(
          icon: Icons.language_outlined,
          title: loc.languageSettingTitle,
          subtitle: loc.languageSettingSubtitle,
        ),
      ),
    ],
  );

  Widget _buildAboutCard(AppLocalizations loc) => _card(
    children: [
      _infoRow(
        icon: Icons.info_outline,
        title: loc.appVersionLabel,
        trailing: _appVersion,
      ),
    ],
  );

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(children: children),
  );

  Widget _divider() =>
      Divider(height: 1, indent: 62, color: Colors.grey.shade100);

  Widget _toggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        _iconBadge(icon),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: _kInk,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: _kGreen,
        ),
      ],
    ),
  );

  Widget _chevronRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        _iconBadge(icon),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: _kInk,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
      ],
    ),
  );

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String trailing,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        _iconBadge(icon),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _kInk,
            ),
          ),
        ),
        Text(
          trailing,
          style: GoogleFonts.roboto(fontSize: 13, color: Colors.grey.shade500),
        ),
      ],
    ),
  );

  Widget _iconBadge(IconData icon) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: _kGreen.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: _kGreen, size: 18),
  );
}
