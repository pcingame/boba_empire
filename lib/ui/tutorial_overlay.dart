/// Lớp phủ hướng dẫn lần đầu: vòng sáng nhấp nháy quanh thứ cần chạm + bóng chỉ
/// dẫn ngắn (xem core/tutorial.dart). KHÔNG chặn thao tác — người chơi vẫn chạm
/// thẳng vào cốc/nút mua; chỉ nút "Bỏ qua"/"Đã hiểu" trong bóng nhận chạm.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/balance.dart';
import '../core/economy.dart';
import '../core/tutorial.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import 'widgets/motion.dart';

/// Gắn vào cốc chạm và nút mua của nguồn thu đầu tiên (home_page.dart) để lớp phủ
/// đo được vị trí thật.
final ftueCupKey = GlobalKey(debugLabel: 'ftue-cup');
final ftueBuyKey = GlobalKey(debugLabel: 'ftue-buy');

class TutorialOverlay extends ConsumerStatefulWidget {
  const TutorialOverlay({super.key, required this.enabled});

  /// false (test, hoặc tắt hướng dẫn) → không vẽ gì.
  final bool enabled;

  @override
  ConsumerState<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends ConsumerState<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  // Một lần thôi: CurvedAnimation gắn listener vào _pulse, tạo trong build() sẽ rò dần.
  late final CurvedAnimation _pulseCurve =
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
  Rect? _target;

  /// Khoá của đích bước hiện tại (null: bước không có đích) — cập nhật mỗi lần dựng.
  GlobalKey? _key;

  @override
  void initState() {
    super.initState();
    if (!reduceMotion) _pulse.repeat(reverse: true);
    _scheduleMeasure();
  }

  /// Đo lại vị trí đích SAU MỖI KHUNG HÌNH có dựng: bố cục bên dưới có thể dịch
  /// chuyển bất cứ lúc nào (banner hiện ra đẩy cốc xuống, cuộn danh sách, xoay màn)
  /// mà lớp phủ này không hay biết — chỉ đo lúc nó dựng lại thì vòng sáng bị lệch
  /// (gặp thật trên máy). addPostFrameCallback KHÔNG tự ép dựng khung nên chuỗi này
  /// đứng yên khi màn hình đứng yên (pumpAndSettle trong test vẫn kết thúc).
  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _key;
      final r = key == null ? null : _measure(key);
      if (r != _target) setState(() => _target = r);
      _scheduleMeasure();
    });
  }

  @override
  void dispose() {
    _pulseCurve.dispose();
    _pulse.dispose();
    super.dispose();
  }

  /// Vị trí [key] trong hệ toạ độ của lớp phủ này (null nếu chưa dựng/đã cuộn đi).
  Rect? _measure(GlobalKey key) {
    final target = key.currentContext?.findRenderObject();
    final me = context.findRenderObject();
    if (target is! RenderBox || me is! RenderBox) return null;
    if (!target.hasSize || !target.attached || !me.hasSize) return null;
    final topLeft = target.localToGlobal(Offset.zero, ancestor: me);
    return topLeft & target.size;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    final first = Balance.generators.first;
    final step = ref.watch(gameControllerProvider.select((s) =>
        tutorialStepFor(
          seen: s.tutorialSeen,
          firstLevel: s.levelOf(first.id),
          canAffordFirst: s.money >= bulkCost(first, 0, 1) * s.upgradeCostMult,
        )));
    if (step == TutorialStep.none) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final key = switch (step) {
      TutorialStep.tap => ftueCupKey,
      TutorialStep.buy => ftueBuyKey,
      _ => null,
    };
    _key = key;

    final text = switch (step) {
      TutorialStep.tap => l10n.ftueTap,
      TutorialStep.buy => l10n.ftueBuy,
      _ => l10n.ftueExplain,
    };
    final done = step == TutorialStep.explain;
    final ctrl = ref.read(gameControllerProvider.notifier);

    return Positioned.fill(
      child: LayoutBuilder(builder: (context, box) {
        final target = key == null ? null : _target;
        final bubble = _Bubble(
          text: text,
          onSkip: ctrl.markTutorialSeen,
          onOk: done ? ctrl.markTutorialSeen : null,
        );
        // Bóng nằm dưới đích nếu đích ở nửa trên màn, ngược lại nằm trên đích;
        // không có đích (bước giải thích) → giữa màn.
        final Widget placed;
        if (target == null) {
          placed = Align(alignment: Alignment.center, child: bubble);
        } else if (target.center.dy < box.maxHeight / 2) {
          placed = Positioned(
              top: target.bottom + 14, left: 16, right: 16, child: bubble);
        } else {
          placed = Positioned(
              bottom: box.maxHeight - target.top + 14,
              left: 16,
              right: 16,
              child: bubble);
        }
        return Stack(children: [
          if (target != null)
            Positioned.fromRect(
              rect: target.inflate(6),
              child: IgnorePointer(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.06).animate(_pulseCurve),
                  child: DecoratedBox(
                    key: const Key('ftue-ring'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          step == TutorialStep.tap ? 999 : 22),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.tertiary,
                          width: 4),
                    ),
                  ),
                ),
              ),
            ),
          placed,
        ]);
      }),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.onSkip, this.onOk});

  final String text;
  final VoidCallback onSkip;

  /// Có → hiện nút "Đã hiểu" (bước cuối).
  final VoidCallback? onOk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Material(
          key: const Key('ftue-bubble'),
          elevation: 8,
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(text,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onOk == null)
                      TextButton(
                        key: const Key('ftue-skip'),
                        onPressed: onSkip,
                        child: Text(l10n.ftueSkip),
                      ),
                    if (onOk != null)
                      FilledButton(
                        key: const Key('ftue-ok'),
                        onPressed: onOk,
                        child: Text(l10n.ftueOk),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
