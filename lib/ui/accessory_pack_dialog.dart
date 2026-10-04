import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_service.dart';
import '../core/accessories.dart';
import '../core/balance.dart';
import '../core/format.dart';
import '../core/market_fee.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';
import 'accessory_wheel.dart';
import 'daily_quests_dialog.dart' show AccessoryReveal;
import 'widgets/anim_assets.dart';
import 'widgets/clay.dart';
import 'widgets/one_shot_lottie.dart';

/// Gói phụ kiện mua bằng 💎. Công bố tỉ lệ rớt từng độ hiếm (yêu cầu của store).
Future<void> showAccessoryPacks(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const _AccessoryPackDialog(),
    );

class _AccessoryPackDialog extends ConsumerStatefulWidget {
  const _AccessoryPackDialog();

  @override
  ConsumerState<_AccessoryPackDialog> createState() =>
      _AccessoryPackDialogState();
}

class _AccessoryPackDialogState extends ConsumerState<_AccessoryPackDialog> {
  AccessoryDrop? _revealed;

  void _buyFestival() {
    final drop = ref.read(gameControllerProvider.notifier).buyFestivalPack();
    if (drop == null) return;
    HapticFeedback.mediumImpact();
    ref.read(audioServiceProvider).play(Sfx.reward);
    setState(() => _revealed = drop);
    if (drop.accessory.rarity.index >= AccessoryRarity.epic.index) {
      playEffect(context, AnimAssets.confetti, size: 200);
    }
  }

  void _buy(AccessoryPack pack) {
    final drop =
        ref.read(gameControllerProvider.notifier).buyAccessoryPack(pack);
    if (drop == null) return;
    HapticFeedback.mediumImpact();
    ref.read(audioServiceProvider).play(Sfx.reward);
    setState(() => _revealed = drop);
    if (drop.accessory.rarity.index >= AccessoryRarity.epic.index) {
      playEffect(context, AnimAssets.confetti, size: 200);
    }
  }

  String _packName(AppLocalizations l10n, AccessoryPack p) => switch (p) {
        AccessoryPack.basic => l10n.accessoryPackBasic,
        AccessoryPack.rare => l10n.accessoryPackRare,
        AccessoryPack.epic => l10n.accessoryPackEpic,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final gems = ref.watch(gameControllerProvider.select((s) => s.gems));
    final nowUtc = DateTime.fromMillisecondsSinceEpoch(
        ref.read(clockProvider)(),
        isUtc: true);
    final festival = activeFestival(nowUtc);
    final season = festival != null;
    final boost = season || weekendEventActive(nowUtc);
    return AlertDialog(
      title: Text(l10n.accessoryPackTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (season)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(l10n.accessoryPackSeason,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold)),
              ),
            if (festival != null)
              _FestivalTile(festival: festival, onBuy: _buyFestival),
            const AccessoryWheel(),
            const SizedBox(height: 12),
            for (final pack in AccessoryPack.values)
              ClayTile(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_packName(l10n, pack),
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            [
                              for (final e in accessoryOdds(
                                      min: pack.minRarity, weekend: boost)
                                  .entries)
                                '${accessoryRarityLabel(l10n, e.key)} '
                                    '${formatNumber(e.value * 100, decimals: 1)}%',
                            ].join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      key: Key('accessory-pack-${pack.name}'),
                      onPressed:
                          gems >= pack.cost(nowUtc) ? () => _buy(pack) : null,
                      child: Text('${pack.cost(nowUtc)} 💎'),
                    ),
                  ],
                ),
              ),
            if (_revealed != null) AccessoryReveal(drop: _revealed!),
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
}

/// Gói Lễ Hội: món độc quyền của dịp đang diễn ra (xem `festivals`).
class _FestivalTile extends ConsumerWidget {
  const _FestivalTile({required this.festival, required this.onBuy});
  final Festival festival;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final owned = ref.watch(gameControllerProvider.select((s) => s.ownedLimited));
    final gems = ref.watch(gameControllerProvider.select((s) => s.gems));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClayTile(
        key: const Key('festival-pack'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.festivalPackTitle(festivalName(l10n, festival.id)),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              children: [
                for (final a in festival.items)
                  Text(owned.contains(a.id) ? a.emoji : '❔',
                      style: const TextStyle(fontSize: 28)),
              ],
            ),
            const SizedBox(height: 4),
            Text(l10n.festivalPackDesc(Balance.duplicateAccessoryGems),
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            FilledButton(
              key: const Key('festival-pack-buy'),
              onPressed: gems >= Balance.festivalPackGems ? onBuy : null,
              child: Text('${Balance.festivalPackGems} 💎'),
            ),
          ],
        ),
      ),
    );
  }
}
