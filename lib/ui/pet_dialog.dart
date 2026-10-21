/// Linh vật quán: nhận nuôi (💎), nâng cấp (Xu), nhặt Xu tích luỹ (xem core/pet.dart).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/pet.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import 'widgets/app_dialog.dart';
import 'widgets/bobbing.dart';
import 'widgets/clay.dart';
import 'widgets/motion.dart';
import 'widgets/reward_burst.dart';

Future<void> showPet(BuildContext context) =>
    showAppDialog<void>(context: context, builder: (_) => const _PetDialog());

class _PetDialog extends ConsumerStatefulWidget {
  const _PetDialog();

  @override
  ConsumerState<_PetDialog> createState() => _PetDialogState();
}

class _PetDialogState extends ConsumerState<_PetDialog> {
  Timer? _tick;
  final _petKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Xu chờ nhặt tăng theo thời gian → vẽ lại mỗi 2 giây (dừng khi đóng hộp).
    _tick = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final g = ref.watch(gameControllerProvider);
    final ctl = ref.read(gameControllerProvider.notifier);
    final now = ref.read(clockProvider)();
    final income = ctl.petIncome;
    final xu = petPendingXu(g.petLevel, g.petSince, now, income);
    final fill = petPendingSeconds(g.petSince, now) / (petStoreHours * 3600);
    final maxed = g.petLevel >= petMaxLevel;
    final cost = petLevelCost(g.petLevel, income);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.petTitle),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            key: _petKey,
            width: 140,
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
              ]),
            ),
            child: Bobbing(
              child: PulseOnIncrease(
                value: g.petLevel,
                peak: 1.25,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: Text(g.petLevel == 0 ? '🥚' : petEmojiOf(g.petLevel),
                      key: ValueKey(g.petLevel), style: const TextStyle(fontSize: 76)),
                ),
              ),
            ),
          ),
          if (g.petLevel > 0) ...[
            const SizedBox(height: 4),
            Text('Lv ${g.petLevel}/$petMaxLevel', style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
          const SizedBox(height: 8),
          Text(l10n.petIntro, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          if (g.petLevel > 0) ...[
            const SizedBox(height: 12),
            ClayTile(
              child: Column(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: fill.clamp(0.0, 1.0)),
                    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 500),
                    builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 10),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('pet-collect'),
                    onPressed: xu > 0
                        ? () {
                            final got = ctl.collectPet();
                            if (got > 0) showRewardBurst(_petKey.currentContext ?? context, emojis: const ['🪙', '✨'], label: '+${formatNumber(got)}');
                          }
                        : null,
                    child: Text(l10n.petCollect(formatNumber(xu)), maxLines: 2, textAlign: TextAlign.center),
                  ),
                ),
              ]),
            ),
          ],
          if (!maxed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: const Key('pet-up'),
                  onPressed: (g.petLevel == 0 ? g.gems >= petAdoptGems : g.money >= cost)
                      ? () {
                          if (ctl.upgradePet()) {
                            showRewardBurst(_petKey.currentContext ?? context, emojis: const ['✨', '💖'], label: g.petLevel == 0 ? '🥚→🐣' : 'Lv ${g.petLevel + 1}');
                          }
                        }
                      : null,
                  child: Text(g.petLevel == 0 ? l10n.petAdopt(petAdoptGems) : '⬆ 🪙 ${formatNumber(cost)}', maxLines: 1),
                ),
              ),
            ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close))],
    );
  }
}
