/// Hộp "Có gì mới" sau khi cập nhật (xem core/whats_new.dart).
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'games_hub_dialog.dart';
import 'widgets/app_dialog.dart';

Future<void> showWhatsNew(BuildContext context, String version) {
  return showAppDialog<void>(
    context: context,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      final items = [
        l10n.whatsNewStaff,
        l10n.whatsNewRegulars,
        l10n.whatsNewDecor,
        l10n.whatsNewVip,
        l10n.whatsNewChat,
      ];
      return AlertDialog(
        key: const Key('whats-new'),
        title: Text(l10n.whatsNewTitle(version)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final t in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(t),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.whatsNewLater),
          ),
          FilledButton(
            key: const Key('whats-new-open'),
            onPressed: () {
              Navigator.of(ctx).pop();
              showGamesHub(context);
            },
            child: Text(l10n.whatsNewOpen),
          ),
        ],
      );
    },
  );
}
