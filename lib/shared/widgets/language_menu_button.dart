import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../state/locale_controller.dart';

/// A compact language switcher shown in app bars / screen headers. Tapping it
/// opens a menu of the three supported languages; picking one updates the
/// [LocaleController] immediately (Arabic flips the whole app to RTL).
class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key, this.color});

  /// Icon tint — pass the surrounding header's text colour so it blends in.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocaleController>();
    final l = AppLocalizations.of(context);
    final current = controller.locale?.languageCode;

    return PopupMenuButton<String>(
      tooltip: l.settingsLanguage,
      icon: Icon(Icons.language, color: color),
      onSelected: (code) =>
          context.read<LocaleController>().setLocale(Locale(code)),
      itemBuilder: (context) => [
        _item('en', l.langEnglish, current),
        _item('ar', l.langArabic, current),
        _item('fr', l.langFrench, current),
      ],
    );
  }

  PopupMenuItem<String> _item(String code, String label, String? current) {
    final selected = code == current;
    return PopupMenuItem<String>(
      value: code,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: selected
                ? const Icon(Icons.check, size: 18, color: AppColors.accent)
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
