import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_service.dart';
import '../audio/audio_service.dart';
import '../core/accessories.dart';
import '../core/balance.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import 'daily_quests_dialog.dart' show AccessoryReveal;
import 'widgets/accessory_reveal.dart';
import 'widgets/anim_assets.dart';
import 'widgets/one_shot_lottie.dart';

const _sectors = 8;
const _colors = [
  Color(0xFFFBE0C3), Color(0xFFCDE9DE), Color(0xFFF6D0DA), Color(0xFFD9CBEF),
  Color(0xFFFDEBB0), Color(0xFFCDE3F0), Color(0xFFF7C9A8), Color(0xFFE6E0F8),
];

/// Vòng quay phụ kiện: mỗi lượt = 1 QC hoặc [Balance.accessorySpinGems] 💎. Kết
/// quả do `spinAccessoryWheel` quyết trước (cùng tỉ lệ rớt chung); vòng quay chỉ
/// dừng ở ô mang đúng món đó (các ô còn lại là món ngẫu nhiên để trang trí).
class AccessoryWheel extends ConsumerStatefulWidget {
  const AccessoryWheel({super.key});

  @override
  ConsumerState<AccessoryWheel> createState() => _AccessoryWheelState();
}

class _AccessoryWheelState extends ConsumerState<AccessoryWheel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );
  final _random = math.Random();
  late List<String> _emojis = _randomEmojis();
  double _rotation = 0;
  Animation<double>? _anim;
  CurvedAnimation? _curve; // mỗi lượt quay một cái; huỷ cái cũ trước khi tạo mới
  bool _busy = false;
  AccessoryDrop? _result;

  List<String> _randomEmojis() =>
      ([...accessories]..shuffle(_random)).take(_sectors).map((a) => a.emoji).toList();

  @override
  void dispose() {
    _curve?.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _spin({required bool withAd}) async {
    if (_busy) return;
    setState(() => _busy = true);
    if (withAd) {
      final adFree = ref.read(gameControllerProvider).adFree;
      final outcome = adFree
          ? RewardOutcome.earned
          : await ref.read(adServiceProvider).showRewardedAd();
      if (!mounted) return;
      if (outcome != RewardOutcome.earned) {
        setState(() => _busy = false);
        return;
      }
    }
    final drop = ref
        .read(gameControllerProvider.notifier)
        .spinAccessoryWheel(withAd: withAd);
    if (drop == null) {
      setState(() => _busy = false);
      return;
    }
    // Ô thắng ngẫu nhiên, mang đúng emoji của món vừa rớt.
    final win = _random.nextInt(_sectors);
    setState(() {
      _result = null;
      _emojis = _randomEmojis()..[win] = drop.accessory.emoji;
    });
    const step = 2 * math.pi / _sectors;
    final landMod = (2 * math.pi - (win * step + step / 2)) % (2 * math.pi);
    final cur = _rotation % (2 * math.pi);
    final target =
        _rotation + 2 * math.pi * 4 + ((landMod - cur) % (2 * math.pi));
    _curve?.dispose();
    _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _anim = Tween<double>(begin: _rotation, end: target).animate(_curve!);
    await _ctrl.forward(from: 0);
    if (!mounted) return;
    _rotation = target;
    HapticFeedback.mediumImpact();
    ref.read(audioServiceProvider).play(Sfx.reward);
    playAccessoryReveal(context, drop);
    if (drop.accessory.rarity.index >= AccessoryRarity.epic.index) {
      playEffect(context, AnimAssets.confetti, size: 200);
    }
    setState(() {
      _busy = false;
      _result = drop;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gems = ref.watch(gameControllerProvider.select((s) => s.gems));
    final adsLeft =
        ref.watch(gameControllerProvider.select((s) => s.accessoryAdSpinsLeft));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.accessoryWheelTitle,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Center(
          child: SizedBox(
            width: 200,
            height: 214,
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
                      size: const Size(200, 200),
                      painter: _Painter(_emojis),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 36),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            OutlinedButton.icon(
              key: const Key('accessory-wheel-ad'),
              onPressed: _busy || adsLeft <= 0
                  ? null
                  : () => _spin(withAd: true),
              icon: const Icon(Icons.play_circle_outline),
              label: Text(l10n.accessoryWheelAd(adsLeft)),
            ),
            FilledButton(
              key: const Key('accessory-wheel-gems'),
              onPressed: _busy || gems < Balance.accessorySpinGems
                  ? null
                  : () => _spin(withAd: false),
              child: Text(l10n.accessoryWheelGems(Balance.accessorySpinGems)),
            ),
          ],
        ),
        if (_result != null) AccessoryReveal(drop: _result!),
      ],
    );
  }
}

class _Painter extends CustomPainter {
  _Painter(this.emojis);
  final List<String> emojis;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    const step = 2 * math.pi / _sectors;
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < _sectors; i++) {
      paint.color = _colors[i % _colors.length];
      final start = -math.pi / 2 + i * step;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, step, true, paint);
      final mid = start + step / 2;
      final tp = TextPainter(
        text: TextSpan(text: emojis[i], style: const TextStyle(fontSize: 26)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          c + Offset(math.cos(mid), math.sin(mid)) * (r * 0.64) -
              Offset(tp.width / 2, tp.height / 2));
      tp.dispose(); // vẽ mỗi khung hình: không huỷ thì rò đoạn văn native
    }
    canvas.drawCircle(c, r,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 6..color = Colors.white);
    canvas.drawCircle(c, 12, Paint()..color = const Color(0xFF8D5524));
  }

  @override
  bool shouldRepaint(covariant _Painter old) => old.emojis != emojis;
}
