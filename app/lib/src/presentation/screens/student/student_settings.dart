import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../services/settings_service.dart';

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
      }
    });
    await setter(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFFF5F7FF),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _sectionLabel('Preferences'),
                _buildPreferencesCard(),
                const SizedBox(height: 20),
                _sectionLabel('Account'),
                _buildAccountCard(),
                const SizedBox(height: 20),
                _sectionLabel('About'),
                _buildAboutCard(),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
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

  Widget _buildPreferencesCard() => _card(
    children: [
      _toggleRow(
        icon: Icons.notifications_outlined,
        title: 'Push Notifications',
        subtitle: 'Receive study reminders and updates',
        value: _notificationsEnabled,
        onChanged: (v) =>
            _toggle('notifications', v, _settings!.setNotificationsEnabled),
      ),
      _divider(),
      _toggleRow(
        icon: Icons.volume_up_outlined,
        title: 'Sound Effects',
        subtitle: 'Button clicks and interactions',
        value: _soundEffectsEnabled,
        onChanged: (v) =>
            _toggle('sound', v, _settings!.setSoundEffectsEnabled),
      ),
      _divider(),
      _toggleRow(
        icon: Icons.music_note_outlined,
        title: 'Background Music',
        subtitle: 'Play music while studying',
        value: _backgroundMusicEnabled,
        onChanged: (v) =>
            _toggle('music', v, _settings!.setBackgroundMusicEnabled),
      ),
    ],
  );

  Widget _buildAccountCard() => _card(
    children: [
      _chevronRow(
        icon: Icons.language_outlined,
        title: 'Language',
        subtitle: 'English / Arabic',
      ),
    ],
  );

  Widget _buildAboutCard() => _card(
    children: [
      _infoRow(
        icon: Icons.info_outline,
        title: 'App Version',
        trailing: _appVersion,
      ),
    ],
  );

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
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
          activeColor: const Color(0xFF4A6CF7),
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
        Text(
          trailing,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
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
