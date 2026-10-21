import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cloud_save_controller.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import 'cloud_save_dialog.dart';
import 'how_to_play_dialog.dart';
import 'language_dialog.dart';
import 'redeem_dialog.dart';
import 'invite_dialog.dart' show shareTextProvider;
import '../leaderboard/player_avatar.dart';
import 'my_profile_page.dart';
import 'widgets/avatar_circle.dart';
import 'web_links.dart';
import 'widgets/effects_quality.dart';
import 'widgets/app_dialog.dart';

/// Cài đặt: đổi ngôn ngữ, bật/tắt âm thanh, chơi lại từ đầu.
Future<void> showSettings(BuildContext context) {
  return showAppDialog<void>(
    context: context,
    builder: (_) => const _SettingsDialog(),
  );
}

String _effectsLabel(AppLocalizations l10n, EffectsPref p) => switch (p) {
      EffectsPref.auto => l10n.settingsEffectsAuto,
      EffectsPref.high => l10n.settingsEffectsHigh,
      EffectsPref.medium => l10n.settingsEffectsMedium,
      EffectsPref.low => l10n.settingsEffectsLow,
      EffectsPref.off => l10n.settingsEffectsOff,
    };

Future<void> _pickEffects(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final picked = await showAppDialog<EffectsPref>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(l10n.settingsEffects),
      children: [
        for (final p in EffectsPref.values)
          SimpleDialogOption(
            key: Key('settings-effects-${p.name}'),
            onPressed: () => Navigator.pop(ctx, p),
            child: Row(children: [
              Icon(p == EffectsController.instance.pref
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked),
              const SizedBox(width: 12),
              Expanded(child: Text(_effectsLabel(l10n, p))),
            ]),
          ),
      ],
    ),
  );
  if (picked != null) await EffectsController.instance.setPref(picked);
}

class _SettingsDialog extends ConsumerWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final soundOn = ref.watch(soundOnProvider);
    final cloudSave = ref.watch(cloudSaveControllerProvider);

    return AlertDialog(
      title: Text(l10n.settingsTitle),
      content: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const Key('settings-my-profile'),
            contentPadding: EdgeInsets.zero,
            leading: AvatarCircle(avatarKey: ref.watch(myAvatarProvider), size: 40),
            title: Text(l10n.myProfileTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pop();
              showMyProfile(context);
            },
          ),
          ListTile(
            key: const Key('how-to-play-button'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.help_outline),
            title: Text(l10n.howToPlayTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showHowToPlay(context),
          ),
          // Website, hướng dẫn web, chia sẻ hồ sơ và mạng xã hội gom một dòng (mặc định thu gọn).
          ExpansionTile(
            key: const Key('settings-links'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            leading: const Icon(Icons.link),
            title: Text(l10n.settingsLinks),
            children: [
              ListTile(
                key: const Key('settings-website'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.public),
                title: Text(l10n.settingsWebsite),
                subtitle: const Text('bobaempiregame.com'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => openWebLink(context, ref, webHomeUrl),
              ),
              // Chỉ khi đã đặt tên ở bảng xếp hạng (có tên mới có hạng để khoe).
              if ((ref.read(sharedPreferencesProvider).getString('leaderboard_nickname') ?? '')
                  .isNotEmpty)
                Builder(
                  builder: (tileContext) => ListTile(
                    key: const Key('settings-share-profile'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: Text(l10n.settingsShareProfile),
                    trailing: const Icon(Icons.share, size: 18),
                    onTap: () {
                      final name = ref
                          .read(sharedPreferencesProvider)
                          .getString('leaderboard_nickname')!;
                      final box = tileContext.findRenderObject() as RenderBox?;
                      final origin = box == null
                          ? null
                          : box.localToGlobal(Offset.zero) & box.size;
                      ref.read(shareTextProvider)(
                          l10n.profileShareText(name, webProfileUrl(name)), origin);
                    },
                  ),
                ),
              ListTile(
                key: const Key('settings-web-guide'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(l10n.settingsWebGuide),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => openWebLink(context, ref, webGuideUrl()),
              ),
              // Mạng xã hội gom một hàng icon (trước là 3 dòng riêng). Tooltip = tên mạng.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    key: const Key('settings-facebook'),
                    tooltip: 'Facebook',
                    icon: const FaIcon(FontAwesomeIcons.facebook, color: Color(0xFF1877F2)),
                    onPressed: () => openWebLink(context, ref, facebookUrl),
                  ),
                  IconButton(
                    key: const Key('settings-tiktok'),
                    tooltip: 'TikTok',
                    icon: const FaIcon(FontAwesomeIcons.tiktok),
                    onPressed: () => openWebLink(context, ref, tiktokUrl),
                  ),
                  IconButton(
                    key: const Key('settings-youtube'),
                    tooltip: 'YouTube',
                    icon: const FaIcon(FontAwesomeIcons.youtube, color: Color(0xFFFF0000)),
                    onPressed: () => openWebLink(context, ref, youtubeUrl),
                  ),
                ],
              ),
            ],
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLanguageDialog(context),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(cloudSave is CloudSaveLinked ? Icons.cloud_done : Icons.cloud_outlined),
            title: Text(l10n.cloudSaveMenuTitle),
            subtitle: Text(
              cloudSave is CloudSaveLinked
                  ? l10n.cloudSaveMenuLinked(cloudSave.email)
                  : l10n.cloudSaveMenuUnlinked,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showCloudSaveDialog(context),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.card_giftcard),
            title: Text(l10n.redeemTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showRedeemDialog(context),
          ),
          SwitchListTile(
            key: const Key('settings-sound'),
            contentPadding: EdgeInsets.zero,
            secondary: Icon(soundOn ? Icons.volume_up : Icons.volume_off),
            title: Text(l10n.settingsSound),
            value: soundOn,
            onChanged: (_) => ref.read(soundOnProvider.notifier).toggle(),
          ),
          StatefulBuilder(
            builder: (ctx, setTile) => ListTile(
              key: const Key('settings-effects'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.auto_awesome),
              title: Text(l10n.settingsEffects),
              subtitle: Text(_effectsLabel(l10n, EffectsController.instance.pref)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await _pickEffects(ctx);
                if (ctx.mounted) setTile(() {});
              },
            ),
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
    final ok = await showAppDialog<bool>(
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
