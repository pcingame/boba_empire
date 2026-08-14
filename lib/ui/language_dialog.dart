import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_provider.dart';

/// Tên bản địa của từng ngôn ngữ — hiện đúng tiếng của nó nên không cần dịch.
const _nativeNames = <String, String>{
  'en': 'English',
  'es': 'Español',
  'id': 'Bahasa Indonesia',
  'pt': 'Português',
  'th': 'ไทย',
  'vi': 'Tiếng Việt',
};

/// Bảng chọn ngôn ngữ: "Theo hệ thống" + danh sách ngôn ngữ hỗ trợ.
Future<void> showLanguageDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _LanguageDialog(),
  );
}

class _LanguageDialog extends ConsumerWidget {
  const _LanguageDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(localeProvider);

    return AlertDialog(
      title: Text(l10n.language),
      content: SingleChildScrollView(
        child: RadioGroup<String?>(
          groupValue: current?.languageCode,
          onChanged: (code) {
            ref
                .read(localeProvider.notifier)
                .set(code == null ? null : Locale(code));
            Navigator.of(context).pop();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String?>(
                value: null,
                title: Text(l10n.languageSystem),
              ),
              for (final locale in AppLocalizations.supportedLocales)
                RadioListTile<String?>(
                  value: locale.languageCode,
                  title: Text(
                    _nativeNames[locale.languageCode] ?? locale.languageCode,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
