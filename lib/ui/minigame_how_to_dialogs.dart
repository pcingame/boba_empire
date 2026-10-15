/// Hướng dẫn cách chơi cho các trò nhỏ: Công thức (ôn cách quãng), Pha theo đơn, Thử thách hằng ngày. Cùng khuôn
/// bảng hướng dẫn Trân Châu Rơi (match3_how_to_dialog.dart): TỰ HIỆN lần đầu vào trò ([showHowToOnce], ghi nhớ trong
/// `GameState.howToSeen`) và mở lại bất cứ lúc nào bằng nút ? ở thanh tiêu đề ([HowToButton]).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/recipe_mastery.dart' show recipeIntervalDays;
import '../core/recipe_orders.dart' show dailyChallengeGems, dailyMaxScore;
import '../core/recipes.dart' show recipeGroupUnlockLearned;
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';

enum MiniGameGuide { recipes, orders, daily }

/// Test đặt false để dialog không tự bật che thao tác (cùng ý `debugAutoShowStory` ở home_page.dart); test hướng dẫn bật lại.
bool debugAutoShowHowTo = true;

Future<void> showMiniGameHowTo(BuildContext context, MiniGameGuide guide) =>
    showDialog<void>(context: context, builder: (_) => _HowToDialog(guide));

/// Tự mở hướng dẫn [guide] nếu người chơi CHƯA từng thấy; ghi nhớ ngay để lần sau không tự hiện (vẫn mở lại được
/// bằng nút ?). Gọi sau khung đầu tiên của màn (xem [HowToOnce]).
Future<void> showHowToOnce(BuildContext context, WidgetRef ref, MiniGameGuide guide) async {
  if (!debugAutoShowHowTo || !context.mounted) return;
  final seen = ref.read(gameControllerProvider).howToSeen.split(',');
  if (seen.contains(guide.name)) return;
  ref.read(gameControllerProvider.notifier).markHowToSeen(guide.name);
  await showMiniGameHowTo(context, guide);
}

/// Nút ? cho thanh tiêu đề.
class HowToButton extends StatelessWidget {
  const HowToButton(this.guide, {super.key});
  final MiniGameGuide guide;

  @override
  Widget build(BuildContext context) => IconButton(
        key: Key('howto-button-${guide.name}'),
        icon: const Icon(Icons.help_outline),
        tooltip: AppLocalizations.of(context)!.howToTooltip,
        onPressed: () => showMiniGameHowTo(context, guide),
      );
}

/// Bọc màn trò chơi: khung hình đầu tiên thì tự mở hướng dẫn lần đầu. Không vẽ gì thêm.
class HowToOnce extends ConsumerStatefulWidget {
  const HowToOnce({super.key, required this.guide, required this.child, this.enabled = true});
  final MiniGameGuide guide;
  final Widget child;

  /// false: không tự mở (VD chỉ xem lại điểm thử thách đã làm).
  final bool enabled;

  @override
  ConsumerState<HowToOnce> createState() => _HowToOnceState();
}

class _HowToOnceState extends ConsumerState<HowToOnce> {
  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showHowToOnce(context, ref, widget.guide);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _HowToDialog extends StatelessWidget {
  const _HowToDialog(this.guide);
  final MiniGameGuide guide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (title, lines) = switch (guide) {
      MiniGameGuide.recipes => (
          l10n.howToRecipesTitle,
          [
            l10n.howToRecipes1,
            l10n.howToRecipes2(recipeIntervalDays[1], recipeIntervalDays[2], recipeIntervalDays[3]),
            l10n.howToRecipes3,
            l10n.howToRecipes4,
            l10n.howToRecipes5,
            l10n.howToRecipes6(recipeGroupUnlockLearned),
          ]
        ),
      MiniGameGuide.orders => (
          l10n.howToOrdersTitle,
          [
            l10n.howToOrders1,
            l10n.howToOrders2,
            l10n.howToOrders3,
            l10n.howToOrders4,
            l10n.howToOrders5,
            l10n.howToOrders6,
            l10n.howToOrders7,
            l10n.howToOrders8,
          ]
        ),
      MiniGameGuide.daily => (
          l10n.howToDailyTitle,
          [
            l10n.howToDaily1,
            l10n.howToDaily2,
            l10n.howToDaily3(dailyMaxScore),
            l10n.howToDaily4(dailyChallengeGems),
            l10n.howToDaily5,
          ]
        ),
    };
    return AlertDialog(
      key: Key('howto-${guide.name}'),
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < lines.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Số thứ tự để người chơi theo dõi từng bước.
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text('${i + 1}', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(lines[i], key: Key('howto-line-$i'))),
                ]),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          key: const Key('howto-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
