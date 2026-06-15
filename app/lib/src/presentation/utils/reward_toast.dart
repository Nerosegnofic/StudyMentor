import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Utility for showing non-blocking reward notifications.
class RewardToast {
  RewardToast._();

  /// Shows a brief SnackBar announcing the XP and Coins just earned.
  static void show(BuildContext context, int xp, int coins) {
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                loc.xpRewardLabel(xp),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Text('🪙', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                loc.coinsRewardLabel(coins),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2E7D32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 3),
          elevation: 8,
        ),
      );
  }
}
