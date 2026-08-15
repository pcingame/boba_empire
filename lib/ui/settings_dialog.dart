import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import 'language_dialog.dart';

/// Cài đặt: đổi ngôn ngữ, bật/tắt âm thanh, chơi lại từ đầu.
Future<void> showSettings(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _SettingsDialog(),
  );
}

class _SettingsDialog extends ConsumerWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final soundOn = ref.watch(soundOnProvider);

    return AlertDialog(
      title: Text(l10n.settingsTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLanguageDialog(context),
          ),
          SwitchListTile(
            key: const Key('settings-sound'),
            contentPadding: EdgeInsets.zero,
            secondary: Icon(soundOn ? Icons.volume_up : Icons.volume_off),
            title: Text(l10n.settingsSound),
            value: soundOn,
            onChanged: (_) => ref.read(soundOnProvider.notifier).toggle(),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.restart_alt, color: theme.colorScheme.error),
            title: Text(
              l10n.settingsReset,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => _confirmReset(context, ref),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsReset),
        content: Text(l10n.settingsResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('settings-reset-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.settingsReset),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(gameControllerProvider.notifier).resetGame();
      if (context.mounted) Navigator.of(context).pop(); // đóng Cài đặt
    }
  }
}
