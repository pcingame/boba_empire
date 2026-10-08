/// Lời nhắc liên kết email để đồng bộ đám mây (xem core/cloud_remind.dart).
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'cloud_save_dialog.dart';

Future<void> showCloudRemindDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final link = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.cloudRemindTitle),
      content: Text(l10n.cloudRemindBody),
      actions: [
        TextButton(
          key: const Key('cloud-remind-later'),
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cloudRemindLater),
        ),
        FilledButton(
          key: const Key('cloud-remind-link'),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.cloudRemindLink),
        ),
      ],
    ),
  );
  if (link == true && context.mounted) await showCloudSaveDialog(context);
}
