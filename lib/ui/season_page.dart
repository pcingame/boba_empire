/// Thẻ Mùa: thanh XP, đường thưởng miễn phí + Cao cấp (mua bằng 💎) theo 30 bậc. Lối vào là [SeasonEntryCard]
/// ở Cửa hàng 💎. Logic ở core/season.dart, nhận/mua ở GameController.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/season.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';
import 'widgets/anim_assets.dart';
import 'email_gate.dart';
import 'season_leaderboard_page.dart';
import 'widgets/clay.dart';
import 'widgets/one_shot_lottie.dart';
import 'widgets/phone_width.dart';

/// Giá trị so sánh theo CHUỖI cho `select` (snapshot tạo list mới mỗi tick).
String _signature(dynamic s) =>
    '${s.seasonXp}|${s.seasonPremium}|${s.seasonFreeClaimed.join(",")}|${s.seasonPremiumClaimed.join(",")}';

/// Mô tả ngắn một phần thưởng (ngôn ngữ trung tính: emoji + số; độ hiếm dùng chuỗi có sẵn).
String seasonRewardText(AppLocalizations l10n, SeasonReward r, {required bool exact, int seasonId = 0, bool premium = false}) => [
      if (r.gems > 0) '${r.gems} 💎',
      if (r.essence > 0) '${r.essence} 🧪',
      if (r.accessory != null) '🎁 ${accessoryRarityLabel(l10n, r.accessory!)}${exact ? '' : '+'}',
      if (r.exclusive) '⭐${(premium ? seasonItemsFor(seasonId).premium : seasonItemsFor(seasonId).free).emoji}',
    ].join(' · ');

class SeasonEntryCard extends ConsumerWidget {
  const SeasonEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    ref.watch(gameControllerProvider.select(_signature));
    final s = ref.read(gameControllerProvider.notifier).gameStateForSeason;
    final now = ref.read(clockProvider)();
    final claimable = seasonClaimable(s);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        key: const Key('season-open'),
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.colorScheme.tertiaryContainer, theme.colorScheme.primaryContainer]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SeasonPage())),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                const Text('🏆', style: TextStyle(fontSize: 30)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l10n.seasonTitle,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    Text(l10n.seasonEntrySub(seasonDaysLeft(now), seasonTier(s)),
                        key: const Key('season-open-sub'), style: theme.textTheme.bodySmall),
                  ]),
                ),
                if (claimable > 0)
                  Container(
                    key: const Key('season-open-dot'),
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                  ),
                const Icon(Icons.chevron_right),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class SeasonPage extends ConsumerWidget {
  const SeasonPage({super.key});

  void _snack(BuildContext context, String text) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    ref.watch(gameControllerProvider.select(_signature));
    final ctrl = ref.read(gameControllerProvider.notifier);
    final s = ctrl.gameStateForSeason;
    final gems = ref.watch(gameControllerProvider.select((x) => x.gems));
    final now = ref.read(clockProvider)();
    final tier = seasonTier(s);
    final maxed = tier >= seasonTiers;
    final into = maxed ? seasonXpPerTier : s.seasonXp % seasonXpPerTier;

    void claim(int t, bool premium) {
      final r = ctrl.claimSeasonTier(t, premium: premium);
      if (r == null) return;
      playEffect(context, r.drop != null ? AnimAssets.confetti : AnimAssets.sparkle, heavy: r.drop != null);
      final shown = seasonRewardText(l10n, premium ? seasonPremiumReward(t) : seasonFreeReward(t),
          exact: true, seasonId: ctrl.gameStateForSeason.seasonId, premium: premium);
      _snack(
          context,
          r.drop == null
              ? l10n.seasonGot(shown)
              : l10n.seasonGot('$shown · ${r.drop!.accessory.emoji} ${accessoryName(l10n, r.drop!.accessory.id)}'));
    }

    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.seasonTitle),
          actions: [
            IconButton(
              key: const Key('season-open-lb'),
              tooltip: l10n.seasonLbTitle,
              icon: const Icon(Icons.leaderboard_outlined),
              onPressed: () async {
                // Tính năng online: cần đã liên kết email (xem email_gate.dart).
                if (!await ensureOnlineLinked(context) || !context.mounted) return;
                showSeasonLeaderboard(context);
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          children: [
            ClayCard(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(l10n.seasonTierLine(seasonTiers, tier),
                        key: const Key('season-tier'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  Text(l10n.seasonDaysLeft(seasonDaysLeft(now)), style: theme.textTheme.labelMedium),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                      key: const Key('season-xp-bar'), value: into / seasonXpPerTier, minHeight: 12),
                ),
                const SizedBox(height: 4),
                Text(maxed ? 'MAX' : '$into / $seasonXpPerTier XP', style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(l10n.seasonHint(seasonXpDailyCap), style: theme.textTheme.bodySmall),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: s.seasonPremium
                      ? Text(l10n.seasonPremiumOwned,
                          key: const Key('season-premium-owned'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))
                      : FilledButton(
                          key: const Key('season-buy-premium'),
                          onPressed: gems < seasonPremiumGems
                              ? null
                              : () {
                                  final ok = ctrl.buySeasonPremium();
                                  _snack(context, ok ? l10n.seasonPremiumBought : l10n.seasonNotEnoughGems);
                                },
                          child: FittedBox(
                              fit: BoxFit.scaleDown, child: Text(l10n.seasonBuyPremium(seasonPremiumGems))),
                        ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const SizedBox(width: 44),
              Expanded(
                  child: Text(l10n.seasonFreeTrack,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700))),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(l10n.seasonPremiumTrack,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700))),
            ]),
            for (var t = 1; t <= seasonTiers; t++)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                // IntrinsicHeight: Row `stretch` trong ListView (cao vô hạn) nếu không sẽ ném lỗi layout.
                child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SizedBox(
                    width: 44,
                    child: Center(
                      child: Text('$t',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: t <= tier ? theme.colorScheme.primary : theme.colorScheme.outline)),
                    ),
                  ),
                  Expanded(
                    child: _RewardCell(
                      cellKey: Key('season-free-$t'),
                      text: seasonRewardText(l10n, seasonFreeReward(t), exact: false, seasonId: s.seasonId),
                      claimed: s.seasonFreeClaimed.contains(t),
                      canClaim: seasonCanClaim(s, t, premium: false),
                      locked: t > tier,
                      onClaim: () => claim(t, false),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _RewardCell(
                      cellKey: Key('season-premium-$t'),
                      text: seasonRewardText(l10n, seasonPremiumReward(t),
                          exact: t == seasonTiers, seasonId: s.seasonId, premium: true),
                      claimed: s.seasonPremiumClaimed.contains(t),
                      canClaim: seasonCanClaim(s, t, premium: true),
                      locked: t > tier || !s.seasonPremium,
                      onClaim: () => claim(t, true),
                    ),
                  ),
                ])),
              ),
          ],
        ),
      ),
    );
  }
}

class _RewardCell extends StatelessWidget {
  const _RewardCell({
    required this.cellKey,
    required this.text,
    required this.claimed,
    required this.canClaim,
    required this.locked,
    required this.onClaim,
  });

  final Key cellKey;
  final String text;
  final bool claimed;
  final bool canClaim;
  final bool locked;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: cellKey,
      borderRadius: BorderRadius.circular(12),
      onTap: canClaim ? onClaim : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: canClaim ? scheme.primaryContainer : scheme.surfaceContainerHighest.withValues(alpha: locked ? 0.35 : 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: canClaim ? scheme.primary : Colors.transparent, width: 2),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              claimed ? '✓' : text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: canClaim ? FontWeight.w800 : FontWeight.w600,
                color: locked && !claimed ? scheme.onSurface.withValues(alpha: 0.5) : scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
