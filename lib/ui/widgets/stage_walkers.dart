import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'ambient_ticker.dart';
import 'anim_assets.dart';
import 'effects_quality.dart';
import 'motion.dart' show reduceMotion;

/// Một nhân vật khách: file Lottie + cách đặt vào cảnh + (tuỳ chọn) các bộ màu đổi qua delegate.
class WalkerSpec {
  const WalkerSpec(
    this.asset, {
    required this.canvasFrac,
    required this.feetFromBottom,
    this.palettes = const [null],
    this.hidePaths = const [],
    this.facesRight = true,
  });

  final String asset;

  /// Chiều cao khung Lottie so với chiều cao cảnh (nhân vật cao ~90–100% khung).
  final double canvasFrac;

  /// Khoảng cách từ chân nhân vật tới đáy khung Lottie, tính theo chiều cao khung (đo từ ảnh dựng
  /// thật; mỗi file một khác vì khung vẽ chừa lề khác nhau).
  final double feetFromBottom;

  /// Bộ màu (màu chính, màu phụ); null = màu gốc. Chỉ nhân vật có layer đặt tên rõ mới đổi được.
  final List<(Color, Color)?> palettes;

  /// Đường dẫn (KeyPath) tới layer vẽ sẵn "mặt đất"/bóng trong file: ẩn đi vì cảnh đã có nền riêng.
  final List<List<String>> hidePaths;

  /// Hướng đi gốc của hoạt ảnh trong file (false = đi sang trái); dùng để lật cho đúng chiều đi.
  final bool facesRight;
}

/// Các kiểu khách. Thứ tự = chỉ số `WalkerScript.spec`.
const walkerSpecs = <WalkerSpec>[
  // Cô gái đeo kính, váy đổi được 4 màu.
  WalkerSpec(
    AnimAssets.customerWalking,
    canvasFrac: 0.40,
    feetFromBottom: 0.19,
    hidePaths: [
      ['Shape Layer 1', '**'] // layer gốc (không phải layer cùng tên lồng bên trong)
    ],
    palettes: [
      null,
      (Color(0xFF2FA8A0), Color(0xFF1E7C76)), // xanh ngọc
      (Color(0xFFE8A93A), Color(0xFFB27818)), // vàng nghệ
      (Color(0xFF8E6BC7), Color(0xFF65459E)), // tím
    ],
  ),
  // Người dắt chó (hình PNG ghép, rộng hơn nên thấp hơn một chút).
  // Hoạt ảnh gốc đi sang TRÁI (chó dẫn đầu); có bóng elip ở chân (layer "Layer 1") cần ẩn.
  WalkerSpec(
    AnimAssets.customerWalking2,
    canvasFrac: 0.38,
    feetFromBottom: 0.16,
    facesRight: false,
    hidePaths: [
      ['**', 'Layer 1'] // layer ảnh PNG (989×59) là bóng elip
    ],
  ),
  // Doanh nhân xách cặp.
  WalkerSpec(AnimAssets.customerWalking3, canvasFrac: 0.33, feetFromBottom: 0.195),
];

/// Delegate Lottie cho [spec] với bộ màu [palette]: ẩn layer mặt đất/bóng, đổi màu nếu có.
LottieDelegates walkerDelegates(WalkerSpec spec, int palette) {
  final p = spec.palettes[palette];
  return LottieDelegates(values: [
    for (final path in spec.hidePaths) ...[
      // Layer hình vẽ (fill/stroke) VÀ layer ảnh PNG (chỉ có độ mờ của chính layer).
      ValueDelegate.opacity(path, value: 0),
      ValueDelegate.transformOpacity(
          path.last == '**' ? path.sublist(0, path.length - 1) : path,
          value: 0),
    ],
    if (p != null) ...[
      ValueDelegate.color(['**', 'Cloth', '**'], value: p.$1),
      ValueDelegate.color(['**', 'right Hand', '**'], value: p.$1),
      ValueDelegate.color(['**', 'Left Hand', '**'], value: p.$2),
      for (final f in ['Right Foot', 'Right Foot 2', 'Right Foot 3'])
        ValueDelegate.color(['**', f, '**'], value: p.$2),
    ],
  ]);
}


/// Chân khách đứng ở đâu so với đáy cảnh (đơn vị dp), để chân đặt ĐÚNG trên dải "mặt đất" thay vì
/// lơ lửng trên thân xe. Ảnh cảnh 2:1 vẽ `fitWidth` rồi phóng [zoom] neo đáy; dải đất cao ~18.3% ảnh
/// (20.2% ở giai đoạn 10 — đồng cỏ); chân đứng ở 40% chiều dày dải tính từ đáy (trước bánh xe).
double walkerFeetFromBottom(int stage, double sceneWidth, double zoom) {
  final band = (stage == 10 ? 0.202 : 0.183) * 0.5 * zoom * sceneWidth;
  return band * 0.4;
}

/// Giai đoạn có khách đi qua: quán/chuỗi cửa hàng (1..12). Các giai đoạn sau (quốc gia, hành
/// tinh…) không hợp với khách đi bộ ngoài phố.
bool stageHasWalkers(int stage) => stage >= 1 && stage <= 12;

/// Kịch bản khách đi qua (thuần, test được): chờ một khoảng ngẫu nhiên → đi ngang cảnh → chờ…
/// Khoảng chờ dài hơn khi máy yếu; mỗi lượt chọn hướng, bộ màu, cỡ và tốc độ ngẫu nhiên.
class WalkerScript {
  WalkerScript(this.random, this.quality) {
    _wait = 2 + random.nextDouble() * 3; // lượt đầu tới sớm để người chơi thấy
  }

  final math.Random random;
  EffectsQuality quality;

  double _wait = 0;
  double _walkSeconds = 7;
  double _t = 0;
  bool walking = false;
  int _walks = 0;

  /// 0..1 dọc đường đi của lượt hiện tại.
  double get progress => walking ? (_t / _walkSeconds).clamp(0.0, 1.0) : 0;

  /// +1 đi từ trái sang phải, −1 ngược lại.
  int dir = 1;
  int palette = 0;

  /// Chỉ số trong [walkerSpecs] của lượt hiện tại (không lặp lại kiểu vừa đi).
  int spec = 0;

  /// Hệ số cỡ nhân vật (0.9..1.1).
  double scale = 1;

  (double, double) get _gap => switch (quality) {
        EffectsQuality.high => (6, 14),
        EffectsQuality.medium => (12, 26),
        _ => (45, 70),
      };

  /// Tiến thời gian [dt] giây. Trả true khi vừa kết thúc một lượt đi.
  bool step(double dt) {
    if (!walking) {
      _wait -= dt;
      if (_wait <= 0) _begin();
      return false;
    }
    _t += dt;
    if (_t >= _walkSeconds) {
      walking = false;
      final (lo, hi) = _gap;
      _wait = lo + random.nextDouble() * (hi - lo);
      return true;
    }
    return false;
  }

  void _begin() {
    walking = true;
    _t = 0;
    _walkSeconds = 6.5 + random.nextDouble() * 2.5;
    dir = random.nextBool() ? 1 : -1;
    var next = random.nextInt(walkerSpecs.length);
    if (walkerSpecs.length > 1 && next == spec && _walks > 0) next = (next + 1) % walkerSpecs.length;
    spec = next;
    _walks++;
    palette = random.nextInt(walkerSpecs[spec].palettes.length);
    scale = 0.9 + random.nextDouble() * 0.2;
  }
}

/// Khách đi ngang cảnh quán (Lottie `customer_walking`, đổi màu váy theo lượt). Chỉ dựng Lottie
/// trong lúc đang đi; lúc chờ không dựng gì và không tốn khung. Theo mức chất lượng: Tắt /
/// "giảm chuyển động" không dựng; Thấp đi rất thưa. Dừng khi bị hộp thoại phủ lên.
class StageWalkers extends StatefulWidget {
  const StageWalkers({super.key, required this.stage, this.sceneZoom = 1.5, this.random});

  final int stage;

  /// Hệ số phóng của ảnh cảnh (khớp `_sceneZoom` ở màn chính) — để đặt chân khách lên dải đất.
  final double sceneZoom;

  /// Chỉ cho test.
  final math.Random? random;

  @override
  State<StageWalkers> createState() => _StageWalkersState();
}

class _StageWalkersState extends State<StageWalkers> with SingleTickerProviderStateMixin {
  // Controller KHÔNG có ticker chạy: giá trị do nhịp chung đặt (giống IdleMascot).
  late final AnimationController _c = AnimationController(vsync: this);
  final _tick = ValueNotifier<int>(0); // đổi mỗi nhịp để dựng lại vị trí
  late final WalkerScript _script;
  VoidCallback? _unsub;
  bool _covered = false;
  double _cycle = 0; // giây trong chu kỳ bước chân
  double _loopSeconds = 1.0;

  @override
  void initState() {
    super.initState();
    _script = WalkerScript(widget.random ?? math.Random(), EffectsController.instance.quality.value);
    EffectsController.instance.quality.addListener(_onQuality);
    _sync();
  }

  bool get _active =>
      !reduceMotion &&
      stageHasWalkers(widget.stage) &&
      EffectsController.instance.quality.value != EffectsQuality.off;

  void _onQuality() {
    if (!mounted) return;
    _script.quality = EffectsController.instance.quality.value;
    setState(_sync);
  }

  @override
  void didUpdateWidget(StageWalkers old) {
    super.didUpdateWidget(old);
    if (old.stage != widget.stage) setState(_sync);
  }

  void _sync() {
    if (_active) {
      _unsub ??= AmbientTicker.instance.subscribe(_onTick);
    } else {
      _unsub?.call();
      _unsub = null;
    }
  }

  void _onTick(double dt) {
    if (_covered) return;
    final was = _script.walking;
    final finished = _script.step(dt);
    if (_script.walking) {
      _cycle += dt;
      _c.value = (_cycle % _loopSeconds) / _loopSeconds;
      _tick.value++;
    }
    if (!was && _script.walking) _cycle = 0; // lượt mới: bước chân bắt đầu từ khung đầu
    if (was != _script.walking || finished) {
      if (mounted) setState(() {}); // bắt đầu/kết thúc lượt: dựng/gỡ Lottie
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    _covered = route != null && !route.isCurrent;
  }

  @override
  void dispose() {
    EffectsController.instance.quality.removeListener(_onQuality);
    _unsub?.call();
    _c.dispose();
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_active || !_script.walking) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(builder: (context, box) {
          // Nhân vật chiếm ~90% chiều cao khung Lottie, đứng giữa khung: khung = chiều cao mong muốn.
          final spec = walkerSpecs[_script.spec];
          final canvas = box.maxHeight * spec.canvasFrac * _script.scale;
          final bottom = walkerFeetFromBottom(widget.stage, box.maxWidth, widget.sceneZoom) -
              canvas * spec.feetFromBottom;
          final lottie = Lottie.asset(
            spec.asset,
            key: ValueKey((_script.spec, _script.palette)),
            controller: _c,
            width: canvas,
            height: canvas,
            fit: BoxFit.contain,
            // Cache lệnh vẽ (nhẹ bộ nhớ), KHÔNG cache ảnh: khung 1080px × 24 khung sẽ ngốn hàng chục MB.
            renderCache: RenderCache.drawingCommands,
            frameRate: const FrameRate(20),
            delegates: walkerDelegates(spec, _script.palette),
            onLoaded: (comp) => _loopSeconds = comp.duration.inMilliseconds / 1000.0,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          );
          return AnimatedBuilder(
            animation: _tick,
            builder: (context, child) {
              final p = _script.progress;
              final from = _script.dir == 1 ? -0.12 : 1.12;
              final to = _script.dir == 1 ? 1.12 : -0.12;
              final cx = (from + (to - from) * p) * box.maxWidth;
              return Stack(children: [
                Positioned(left: cx - canvas / 2, bottom: bottom, child: child!),
              ]);
            },
            child: Transform.flip(flipX: (_script.dir == 1) != spec.facesRight, child: lottie),
          );
        }),
      ),
    );
  }
}
