import 'package:flutter/material.dart';
import '../../../services/settings_service.dart';
import '../../../services/overlay/mascot_overlay_service.dart';
import '../../widgets/language_picker_dialog.dart';
import '../../../../l10n/app_localizations.dart';

class StudentSettings extends StatefulWidget {
  final String uid;
  const StudentSettings({super.key, required this.uid});

  @override
  State<StudentSettings> createState() => _StudentSettingsState();
}

class _StudentSettingsState extends State<StudentSettings> {
  SettingsService? _settings;
  bool _timerNotificationEnabled = true;
  bool _cooldownNotificationEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final settings = await SettingsService.create();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _timerNotificationEnabled = settings.timerNotificationEnabled;
      _cooldownNotificationEnabled = settings.cooldownNotificationEnabled;
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
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: Text(loc.studentSettingsTitle),
        backgroundColor: const Color(0xFFF5F7FF),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _sectionLabel(loc.preferencesSection),
                _buildPreferencesCard(loc),
                const SizedBox(height: 20),
                _sectionLabel(loc.accountSection),
                _buildAccountCard(loc),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
        letterSpacing: 0.3,
      ),
    ),
  );

  Widget _buildPreferencesCard(AppLocalizations loc) => _card(
    children: [
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

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF4A6CF7),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
      ],
    ),
  );

  Widget _iconBadge(IconData icon) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: const Color(0xFFE3F2FD),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: const Color(0xFF1E88E5), size: 18),
  );
}
