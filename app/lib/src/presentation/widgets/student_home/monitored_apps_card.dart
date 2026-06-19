import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/models/app_config_model.dart';
import 'app_icon_bubble.dart';
import '../../../../l10n/app_localizations.dart';

/// Compact "watched apps" entry (settings-row style) that opens a bottom sheet
/// listing every monitored app with a Ready / Resting status chip.
class MonitoredAppsCard extends StatelessWidget {
  final List<AppRuleModel> rules;
  final Map<String, String?> iconCache;

  /// True when apps are currently on cooldown (mascot service `isBlocked`).
  final bool isResting;

  const MonitoredAppsCard({
    super.key,
    required this.rules,
    required this.iconCache,
    required this.isResting,
  });

  static const Color _green = Color(0xFF4CAF50);
  static const Color _amberInk = Color(0xFF8D6E00);
  static const Color _ink = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    final apps = rules.where((r) => !r.isPaused).toList();

    return Container(
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
      child: apps.isEmpty ? _emptyRow(context) : _entryRow(context, apps),
    );
  }

  Widget _entryRow(BuildContext context, List<AppRuleModel> apps) {
    final loc = AppLocalizations.of(context);
    final subtitle = isResting
        ? loc.restingNowSubtitle
        : loc.appsCountSubtitle(apps.length);

    return InkWell(
      onTap: () => _showAllApps(context, apps),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.apps_rounded, color: _green, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.appsParentWatchesTitle,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: isResting ? _amberInk : Colors.grey.shade500,
                      fontWeight: isResting ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _emptyRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: _green, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppLocalizations.of(context).noAppsWatchedMessage,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllApps(BuildContext context, List<AppRuleModel> apps) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.7;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                  child: Text(
                    AppLocalizations.of(ctx).appsParentWatchesTitle,
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    shrinkWrap: true,
                    itemCount: apps.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 4),
                    itemBuilder: (innerCtx, i) => _appRow(innerCtx, apps[i]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _appRow(BuildContext context, AppRuleModel rule) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          AppIconBubble(
            iconBase64: iconCache[rule.packageName],
            label: rule.appLabel,
            size: 48,
            dimmed: isResting,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              rule.appLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: _ink,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _statusChip(context),
        ],
      ),
    );
  }

  Widget _statusChip(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bg = isResting ? const Color(0xFFFFF8E1) : const Color(0xFFE8F5E9);
    final fg = isResting ? _amberInk : const Color(0xFF43A047);
    final label = isResting ? loc.restingStatusLabel : loc.readyStatusLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}