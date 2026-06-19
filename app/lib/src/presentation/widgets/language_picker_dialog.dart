// lib/src/presentation/widgets/language_picker_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/locale/locale_cubit.dart';
import '../../../l10n/app_localizations.dart';

/// Shows a dialog letting the user pick the app language (English/Arabic).
Future<void> showLanguagePickerDialog(BuildContext context) {
  final loc = AppLocalizations.of(context);
  final cubit = context.read<LocaleCubit>();
  final themeData = Theme.of(context);

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Theme(
      data: themeData,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(loc.languageDialogTitle),
        content: BlocBuilder<LocaleCubit, Locale>(
          bloc: cubit,
          builder: (context, currentLocale) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguageOption(
                label: loc.languageEnglish,
                selected: currentLocale.languageCode == 'en',
                onTap: () {
                  cubit.setLocale(const Locale('en'));
                  Navigator.of(dialogContext).pop();
                },
              ),
              _LanguageOption(
                label: loc.languageArabic,
                selected: currentLocale.languageCode == 'ar',
                onTap: () {
                  cubit.setLocale(const Locale('ar'));
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(loc.commonCancel),
          ),
        ],
      ),
    ),
  );
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
