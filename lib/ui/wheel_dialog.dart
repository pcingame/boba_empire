import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_service.dart';
import '../audio/audio_service.dart';
import '../core/format.dart';
import '../core/wheel.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';

/// Vòng quay may mắn: 1 lượt miễn phí/ngày, hết thì xem QC để quay.
Future<void> showWheel(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _WheelDialog(),
  );
}

/// Nhãn ngắn hiển thị trên mỗi ô.
String _shortLabel(WheelPrize p) => switch (p.kind) {
      WheelKind.gems => '${p.amount}💎',
      WheelKind.x2 => 'x2',
      WheelKind.coins =>
        p.amount < 3600 ? '${p.amount ~/ 60}p' : '${p.amount ~/ 3600}h',
    };

const _sectorColors = [
  Color(0xFFFBE0C3), Color(0xFFCDE9DE), Color(0xFFF6D0DA), Color(0xFFD9CBEF),
  Color(0xFFFDEBB0), Color(0xFFCDE3F0), Color(0xFFF7C9A8), Color(0xFFFFD54F),
];

class _WheelDialog extends ConsumerStatefulWidget {
  const _WheelDialog();

  @override
  ConsumerState<_WheelDialog> createState() => _WheelDialogState();
}

class _WheelDialogState extends ConsumerState<_WheelDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );
  double _rotation = 0; // góc hiện tại (accumulate)
  Animation<double>? _anim;
  bool _spinning = false;
  String? _result;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_spinning) return;
    final free = ref.read(gameControllerProvider).freeSpinAvailable;
    setState(() {
      _spinning = true;
      _result = null;
    });

    if (!free) {
      final adFree = ref.read(gameControllerProvider).adFree;
      final outcome = adFree
          ? RewardOutcome.earned
          : await ref.read(adServiceProvider).showRewardedAd();
      if (outcome != RewardOutcome.earned) {
        if (mounted) setState(() => _spinning = false);
        return;
      }
    }

    final r = ref.read(gameControllerProvider.notifier).spin(free: free);
    const step = 2 * math.pi / 8;
    // Góc để ô r.index dừng ở kim trên đỉnh (+ nhiều vòng cho đã mắt).
    final landMod = (2 * math.pi - (r.index * step + step / 2)) % (2 * math.pi);
    final cur = _rotation % (2 * math.pi);
    final target =
        _rotation + 2 * math.pi * 5 + ((landMod - cur) % (2 * math.pi));
    _anim = Tween<double>(begin: _rotation, end: target)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    await _ctrl.forward(from: 0);
    if (!mounted) return; // dialog đã đóng giữa lúc quay.

    _rotation = target;
    HapticFeedback.mediumImpact();
    ref.read(audioServiceProvider).play(Sfx.reward);
    final l10n = AppLocalizations.of(context)!;
    final msg = switch (r.kind) {
      WheelKind.gems => l10n.iapGemsSnack(formatNumber(r.value)),
      WheelKind.coins => l10n.instantCashSnack(formatNumber(r.value)),
      WheelKind.x2 => l10n.rewardX2Snack,
    };
    setState(() {
      _spinning = false;
      _result = msg;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final free = ref.watch(
      gameControllerProvider.select((s) => s.freeSpinAvailable),
    );

    return AlertDialog(
      title: Text(l10n.wheelName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 260,
            height: 274,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, child) => Transform.rotate(
                      angle: _anim?.value ?? _rotation,
                      child: child,
                    ),
                    child: CustomPaint(
                      size: const Size(260, 260),
                      painter: _WheelPainter(),
                    ),
                  ),
                ),
                // Kim chỉ trên đỉnh.
                const Icon(Icons.arrow_drop_down, size: 40),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _result ?? (free ? l10n.spinFree : l10n.spinAd),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _result != null
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _spinning ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
        FilledButton.icon(
          key: const Key('wheel-spin'),
          onPressed: _spinning ? null : _spin,
          icon: Icon(free ? Icons.casino : Icons.play_circle_outline),
          label: Text(free ? l10n.spinFree : l10n.spinAd),
        ),
      ],
    );
  }
}

class _WheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    const step = 2 * math.pi / 8;
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < wheelPrizes.length; i++) {
      paint.color = _sectorColors[i % _sectorColors.length];
      final start = -math.pi / 2 + i * step;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, step, true,
          paint);
      // Nhãn ở giữa ô.
      final mid = start + step / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: _shortLabel(wheelPrizes[i]),
          style: const TextStyle(
              color: Color(0xFF4A2F14),
              fontWeight: FontWeight.w800,
              fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = c +
          Offset(math.cos(mid), math.sin(mid)) * (r * 0.62) -
          Offset(tp.width / 2, tp.height / 2);
      tp.paint(canvas, pos);
    }
    // Viền + tâm.
    canvas.drawCircle(c, r,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 6..color = Colors.white);
    canvas.drawCircle(c, 14, Paint()..color = const Color(0xFF8D5524));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
