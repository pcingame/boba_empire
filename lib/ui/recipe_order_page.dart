import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_service.dart';
import '../ads/banner_ad_box.dart';
import '../core/accessories.dart' show activeFestival, festivals;
import '../core/daily.dart';
import '../core/format.dart';
import '../core/recipe_counter.dart';
import '../core/recipe_mastery.dart';
import '../core/recipe_names.dart';
import '../core/recipe_orders.dart';
import '../core/recipes.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart' show festivalName;
import '../state/game_providers.dart';
import '../state/recipe_providers.dart';
import '../leaderboard/recipe_leaderboard_repository.dart' show RecipeBoard;
import 'cup_share_dialog.dart';
import 'email_gate.dart';
import 'minigame_how_to_dialogs.dart';
import 'recipe_hub_page.dart' show recipeBoxName;
import 'recipe_leaderboard_page.dart' show showRecipeLeaderboard;
import 'widgets/accessory_reveal.dart';
import 'widgets/anim_assets.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';
import 'widgets/motion.dart';
import 'widgets/order_visuals.dart';
import 'widgets/one_shot_lottie.dart';
import 'widgets/recipe_motion.dart';

Future<void> showRecipeOrders(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecipeOrderPage()));

/// Thử thách hằng ngày: cùng màn Pha theo đơn nhưng đề cố định theo ngày, không gợi ý, không ghi bậc.
Future<void> showRecipeDaily(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecipeOrderPage(daily: true)));

/// "Pha theo đơn": khách gọi một món, người chơi kéo (hoặc chạm) nguyên liệu từ khay vào ly rồi đặt lượng.
/// Kết quả ghi vào bậc thuộc như câu trắc nghiệm (`answerRecipe`); gợi ý giảm dần theo bậc của món.
class RecipeOrderPage extends ConsumerWidget {
  const RecipeOrderPage({super.key, this.daily = false});

  /// Chế độ thử thách hằng ngày (xem [showRecipeDaily]).
  final bool daily;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trò mở thẳng từ hộp Trò chơi nên danh mục có thể chưa nạp xong: chờ rồi mới dựng buổi chơi.
    return ref.watch(recipeCatalogProvider).when(
          data: (_) => _RecipeOrderGame(daily: daily),
          loading: () => Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Scaffold(appBar: AppBar(), body: const SizedBox.shrink()),
        );
  }
}

class _RecipeOrderGame extends ConsumerStatefulWidget {
  const _RecipeOrderGame({required this.daily});
  final bool daily;

  @override
  ConsumerState<_RecipeOrderGame> createState() => _RecipeOrderPageState();
}

class _Served {
  _Served(this.order, this.grade, this.result,
      {this.hinted = false, this.combo = 0, this.tip = 0, this.score = 0, this.late = false, this.rush = false, this.festival = false});
  final bool hinted;

  /// Giờ cao điểm: hết giờ mới phục vụ (khách bỏ đi) / nhận tip giao kịp giờ.
  final bool late;
  final bool rush;
  final bool festival;

  /// Combo SAU đơn này (số đơn hoàn hảo liên tiếp) và tip combo đã nhận (0 nếu chưa đủ / đơn không tính bậc).
  final int combo;
  final double tip;

  /// Điểm đơn 0..100 (chỉ chế độ thử thách ngày).
  final int score;
  final Order order;
  final OrderResult grade;
  final RecipeAnswerResult result;
}

/// Emoji đại diện dịp lễ (món sưu tập đầu tiên của dịp).
String _festivalEmoji(String id) => festivals.firstWhere((f) => f.id == id).items.first.emoji;

/// Ngôi sao tổng kết nảy ra lần lượt (sao rỗng hiện ngay); tắt chuyển động thì hiện luôn.
class _StarPop extends StatelessWidget {
  const _StarPop({required this.index, required this.filled});
  final int index;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final star = Icon(filled ? Icons.star_rounded : Icons.star_outline_rounded,
        size: 34, color: Colors.amber.shade600);
    if (!filled || reduceMotion) return star;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + index * 260),
      builder: (context, t, child) {
        final local = Interval(index * 260 / (420 + index * 260), 1, curve: Curves.elasticOut).transform(t);
        return Transform.scale(scale: local, child: child);
      },
      child: star,
    );
  }
}

String _amt(double v, String unit) => '${v == v.roundToDouble() ? v.round() : v} $unit';

/// Phần chiều cao ly mà đồng hồ rót trong bảng đặt lượng dùng (cũng là thang của vạch chia/vạch mốc).
const double _gaugeFill = 0.9;

/// Chiều cao lớp trong ly theo lượng (so với mức lớn nhất của đơn vị đó trên thanh trượt).
double _cupFraction(Poured p) => (p.value / amountSteps(p.item.unit).last).clamp(0.04, 1.0) * 0.55;

class _RecipeOrderPageState extends ConsumerState<_RecipeOrderGame> {
  RecipeLabels _labels = const RecipeLabels(null, 'vi');

  late List<Order> _orders = _newSession();

  /// Đã làm thử thách hôm nay từ trước khi mở màn (mỗi ngày một lần) ⇒ chỉ xem lại điểm.
  late final bool _alreadyDone = widget.daily &&
      ref.read(gameControllerProvider).recipeDailyDay == dayIndex(ref.read(clockProvider)());
  ({bool counted, int gems, double cash})? _dailyReward;
  final _served = <_Served>[];
  final _poured = <Poured>[];
  int _index = 0;
  bool _checked = false; // đơn hiện tại đã phục vụ
  bool _hinted = false; // đơn hiện tại đã xem công thức mẫu (xem quảng cáo) ⇒ không tính bậc
  bool _doubled = false; // đã nhân đôi thưởng buổi này
  bool _watchingAd = false;
  int _combo = 0; // số đơn hoàn hảo liên tiếp (không gợi ý) trong buổi
  int _drops = 0; // số lần thả topping (kích hoạt animation rơi)
  Color _dropColor = const Color(0xFF2B1B14);
  bool _sealing = false; // đang đậy nắp + lắc ly trước khi chấm
  bool _rush = false; // "Giờ cao điểm": mỗi đơn có đồng hồ kiên nhẫn
  bool _sheetOpen = false; // bảng đặt lượng mở ⇒ tạm dừng đồng hồ
  int _leftMs = 0;
  Timer? _ticker;

  static const _tickMs = 200;

  int _patienceMs() => orderPatienceSeconds(_orders[_index].recipe.ingredients.length) * 1000;

  void _setRush(bool on) {
    _ticker?.cancel();
    setState(() {
      _rush = on;
      _leftMs = _patienceMs();
    });
    if (on) _ticker = Timer.periodic(const Duration(milliseconds: _tickMs), (_) => _tick());
  }

  void _tick() {
    // Đang có popup che màn (VD cutscene Hồi 4 vừa mở khoá) ⇒ đứng đồng hồ, khách không bỏ đi lúc người chơi đang đọc.
    if (!mounted || _finished || _checked || _sealing || _sheetOpen || _watchingAd) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    setState(() => _leftMs -= _tickMs);
    if (_leftMs <= 0) _grade(late: true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  List<Order> _newSession() {
    final catalog = ref.read(recipeCatalogProvider).requireValue;
    if (widget.daily) return buildDailyOrders(catalog, dayIndex(ref.read(clockProvider)()));
    final progress = ref.read(gameControllerProvider).recipeProgress;
    final nowMs = ref.read(clockProvider)();
    final today = dayIndex(nowMs);
    final rnd = ref.read(recipeRandomProvider);
    final pool = unlockedRecipes(catalog, (id) => progress[id]?.best ?? 0);
    final orders = buildOrders(catalog, progress, today, rnd, pool: pool);
    // Đang trong dịp lễ: thêm "đơn lễ hội" ở cuối buổi.
    final fest = activeFestival(DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true));
    final special = fest == null
        ? null
        : buildFestivalOrder(fest.id, catalog, progress, today, rnd,
            pool: pool, exclude: {for (final o in orders) o.recipe.id});
    return [...orders, ?special];
  }

  bool get _finished => _index >= _orders.length;

  Future<void> _edit(TrayItem item) async {
    if (_checked || _sealing) return;
    final at = _poured.indexWhere((p) => p.item.name == item.name);
    final current = at < 0 ? null : _poured[at].value;
    // Vạch gợi ý theo bậc: Mới (hoặc đã xem công thức mẫu) có thước + vạch mốc đúng; Quen chỉ có thước; còn lại ẩn.
    final o = _orders[_index];
    final full = o.guide == OrderGuide.full || _hinted;
    final ticks = full || o.guide == OrderGuide.names;
    final steps = amountSteps(item.unit);
    final right = [for (final i in o.recipe.ingredients) if (i.name == item.name) i];
    _sheetOpen = true;
    final r = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AmountSheet(
        item: item,
        current: current,
        name: _labels.ingredient(item.name),
        marks: ticks ? [for (var i = 3; i < steps.length; i += 3) i / (steps.length - 1) * _gaugeFill] : const [],
        target: full && right.isNotEmpty
            ? nearestStep(item.unit, right.first.qty) / (steps.length - 1) * _gaugeFill
            : null,
      ),
    );
    _sheetOpen = false;
    if (r == null || !mounted || _checked) return;
    setState(() {
      if (at >= 0) _poured.removeAt(at);
      if (r >= 0) {
        HapticFeedback.lightImpact();
        _poured.add(Poured(item, r));
        if (isTopping(item.name)) {
          _drops++;
          _dropColor = ingredientColor(item.name);
        }
      }
    });
  }

  /// Bấm "Phục vụ": đậy nắp + lắc ly một nhịp (bỏ qua khi tắt hiệu ứng) rồi mới chấm.
  Future<void> _serve() async {
    if (_checked || _sealing || _poured.isEmpty) return;
    if (!reduceMotion) {
      setState(() => _sealing = true);
      await Future<void>.delayed(const Duration(milliseconds: 950));
      if (!mounted) return;
      setState(() => _sealing = false);
    }
    _grade();
  }

  void _grade({bool late = false}) {
    if (_checked || (_poured.isEmpty && !late)) return;
    final order = _orders[_index];
    final grade = gradeOrder(order, _poured);
    grade.stars == 3 ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact();
    if (widget.daily) {
      // Thử thách ngày: chỉ chấm điểm, KHÔNG ghi bậc / thưởng từng đơn / combo / BXH Pha theo đơn.
      const none = RecipeProgress();
      setState(() {
        _checked = true;
        _served.add(_Served(
          order,
          grade,
          RecipeAnswerResult(none, none, RecipeAnswerOutcome(none, counted: false, leveledUp: false, newBest: false), 0, 0),
          score: scoreOrder(order, grade),
          late: late,
        ));
      });
      if (grade.stars == 3) playEffect(context, AnimAssets.sparkle, size: 140, heavy: false);
      return;
    }
    final game = ref.read(gameControllerProvider.notifier);
    final result = game.answerRecipe(order.recipe.id, grade.correct, hinted: _hinted);
    // Bảng xếp hạng: chỉ tính món pha hoàn hảo khi KHÔNG được xem công thức mẫu (bậc Mới / gợi ý quảng cáo).
    if (grade.stars == 3 && order.guide != OrderGuide.full && !_hinted) game.recordOrderPerfect(order.recipe.id);
    // Combo: đơn hoàn hảo không gợi ý nối tiếp; sai / gợi ý thì đứt. Tip chỉ trả khi đơn thật sự được tính bậc
    // (món đến hạn ôn) — nếu không thì lặp lại món dễ để cày tip.
    _combo = grade.stars == 3 && !_hinted && !late ? _combo + 1 : 0;
    final counted = result.outcome.counted;
    final rush = _rush && !late && grade.stars == 3 && !_hinted && counted;
    final fest = order.festival != null && grade.stars == 3 && !_hinted && counted;
    final tip = (_combo >= 2 && counted) || rush || fest ? game.grantOrderTip(_combo, rush: rush, festival: fest) : 0.0;
    setState(() {
      _checked = true;
      _served.add(_Served(order, grade, result,
          hinted: _hinted, combo: _combo, tip: tip, late: late, rush: rush, festival: fest));
    });
    if (tip > 0) playEffect(context, AnimAssets.coinFly, size: 160, heavy: false);
    final drop = result.drop;
    if (drop != null) playAccessoryReveal(context, drop);
    if (grade.correct) playEffect(context, AnimAssets.sparkle, size: 140, heavy: false);
    if (result.outcome.leveledUp) playEffect(context, AnimAssets.levelUp, size: 220);
    if (result.streakGems > 0) playEffect(context, AnimAssets.gemBurst, size: 160, heavy: false);
    if (result.milestone > 0) playEffect(context, AnimAssets.confetti, size: 260);
  }

  void _next() {
    setState(() {
      _index++;
      _checked = false;
      _hinted = false;
      _poured.clear();
      if (!_finished) _leftMs = _rush ? _patienceMs() : 0;
    });
    if (_finished) _ticker?.cancel();
    if (_finished && widget.daily) {
      if (_served.every((s) => s.grade.stars == 3)) playEffect(context, AnimAssets.confetti, size: 260);
      final total = _served.fold<int>(0, (a, s) => a + s.score);
      setState(() => _dailyReward = ref.read(gameControllerProvider.notifier).completeDailyChallenge(total));
      return;
    }
    if (_finished) {
      if (_served.every((s) => s.grade.correct)) playEffect(context, AnimAssets.confetti, size: 260);
      ref
          .read(gameControllerProvider.notifier)
          .completeRecipeSession(anyCounted: _served.any((s) => s.result.outcome.counted));
    }
  }

  void _again() => setState(() {
        _orders = _newSession();
        _served.clear();
        _poured.clear();
        _index = 0;
        _combo = 0;
        _checked = false;
        _hinted = false;
        _doubled = false;
        _leftMs = _rush ? _patienceMs() : 0;
        if (_rush) {
          _ticker?.cancel();
          _ticker = Timer.periodic(const Duration(milliseconds: _tickMs), (_) => _tick());
        }
      });

  /// Xem quảng cáo thưởng (người đã gỡ quảng cáo/VIP được cộng thẳng — cùng khuôn trò trắc nghiệm).
  Future<bool> _watchAd() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _watchingAd = true);
    final adFree = ref.read(gameControllerProvider).adFree;
    final outcome = adFree ? RewardOutcome.earned : await ref.read(adServiceProvider).showRewardedAd();
    if (!mounted) return false;
    setState(() => _watchingAd = false);
    if (outcome != RewardOutcome.earned) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l10n.adNotReadySnack)));
      return false;
    }
    return true;
  }

  /// Gợi ý: hiện công thức mẫu (đầy đủ lượng). Đơn này không tính bậc.
  Future<void> _useHint() async {
    if (_hinted || _checked || _watchingAd) return;
    final at = _index;
    if (!await _watchAd() || !mounted || _index != at || _checked) return;
    setState(() => _hinted = true);
  }

  Future<void> _doubleReward(double cash) async {
    if (_doubled || _watchingAd) return;
    if (!await _watchAd() || !mounted) return;
    ref.read(gameControllerProvider.notifier).doubleRecipeReward(cash);
    setState(() => _doubled = true);
  }

  @override
  Widget build(BuildContext context) {
    _labels = recipeLabelsOf(ref, context);
    final l10n = AppLocalizations.of(context)!;
    final guide = widget.daily ? MiniGameGuide.daily : MiniGameGuide.orders;
    // Lần đầu vào chế độ này thì tự mở hướng dẫn (không tự mở khi chỉ xem lại điểm thử thách đã làm).
    return HowToOnce(
      guide: guide,
      enabled: !_alreadyDone,
      child: Scaffold(
      appBar: AppBar(
        title: Text(_finished
            ? l10n.recipeResultTitle
            : widget.daily
                ? (_alreadyDone ? l10n.recipeDailyTitle : '${l10n.recipeDailyTitle} ${_index + 1}/${_orders.length}')
                : '${_index + 1}/${_orders.length}'),
        actions: [
          HowToButton(guide),
          IconButton(
            key: const Key('order-leaderboard'),
            tooltip: l10n.rlbTitle,
            icon: const Icon(Icons.emoji_events),
            onPressed: () async {
              // Tính năng online: cần đã liên kết email (xem email_gate.dart).
              if (!await ensureOnlineLinked(context) || !context.mounted) return;
              showRecipeLeaderboard(context, board: RecipeBoard.orders);
            },
          ),
        ],
        bottom: _finished || _alreadyDone
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: SmoothBar(
                  key: const Key('order-progress'),
                  value: (_index + (_checked ? 1 : 0)) / _orders.length,
                  minHeight: 4,
                  radius: 0,
                ),
              ),
      ),
      body: PhoneWidth(child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0.12, 0), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_finished ? -1 : _index),
                    child: _finished
                        ? (widget.daily ? _dailyResult(context) : _result(context))
                        : (_alreadyDone ? _dailyAlready(context) : _order(context)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const BannerAdBox(),
          ],
        ),
      )),
    ));
  }

  // --- đơn hàng ----------------------------------------------------------------

  Widget _guide(BuildContext context, Order o) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ings = o.recipe.ingredients;
    switch (_hinted ? OrderGuide.full : o.guide) {
      case OrderGuide.full:
        return ClayTile(
          key: const Key('order-guide'),
          margin: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.recipeOrderGuideFull, style: theme.textTheme.labelLarge),
              for (final i in ings)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Text(ingredientEmoji(i.name), style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_labels.ingredient(i.name), style: theme.textTheme.bodyLarge)),
                    Text(i.amount, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
                  ]),
                ),
            ],
          ),
        );
      case OrderGuide.names:
        return ClayTile(
          key: const Key('order-guide'),
          margin: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.recipeOrderGuideNames, style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Wrap(spacing: 12, runSpacing: 2, children: [
                for (final i in ings) Text('${ingredientEmoji(i.name)} ${_labels.ingredient(i.name)}'),
              ]),
            ],
          ),
        );
      case OrderGuide.count:
        return Padding(
          key: const Key('order-guide'),
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.recipeOrderGuideCount(ings.length), style: theme.textTheme.bodyMedium),
        );
      case OrderGuide.none:
        return Padding(
          key: const Key('order-guide'),
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.recipeOrderGuideNone, style: theme.textTheme.bodyMedium),
        );
    }
  }

  Widget _cup(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final last = _checked ? _served.last : null;
    return ShakeOnTrigger(
      trigger: last != null && !last.grade.correct ? 1 : 0,
      child: PulseOnIncrease(
        value: _served.where((x) => x.grade.stars == 3).length,
        peak: 1.05,
        child: DragTarget<TrayItem>(
        onAcceptWithDetails: (d) => _edit(d.data),
        builder: (context, candidate, _) => AnimatedContainer(
          key: const Key('order-cup'),
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: candidate.isNotEmpty
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: candidate.isNotEmpty ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
              width: candidate.isNotEmpty ? 2 : 1,
            ),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            OrderCup(
              layers: [for (final p in _poured) CupLayer(ingredientColor(p.item.name), _cupFraction(p))],
              lidded: _sealing || _checked,
              shaking: _sealing,
              dropBurst: _drops,
              dropColor: _dropColor,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _poured.isEmpty
                  ? Text(l10n.recipeOrderCupEmpty, style: theme.textTheme.titleSmall)
                  : Column(
                      children: [
                        for (final p in _poured)
                          InkWell(
                            key: Key('order-poured-${p.item.name}'),
                            onTap: _checked || _sealing ? null : () => _edit(p.item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                      color: ingredientColor(p.item.name),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: theme.colorScheme.outlineVariant)),
                                ),
                                const SizedBox(width: 6),
                                Text(ingredientEmoji(p.item.name), style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                // Cả tên lẫn lượng co được: cột này hẹp (nằm cạnh ly) và chữ có thể rất to.
                                Expanded(
                                    flex: 3,
                                    child: Text(_labels.ingredient(p.item.name),
                                        maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium)),
                                Flexible(
                                  flex: 2,
                                  child: Text(_amt(p.value, p.item.unit),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                                ),
                              ]),
                            ),
                          ),
                      ],
                    ),
            ),
          ]),
        ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, TrayItem t, {required bool used, bool dragging = false}) {
    final theme = Theme.of(context);
    final poured = used ? _poured.where((p) => p.item.name == t.name).firstOrNull : null;
    return Material(
      // Đã rót thì chip đổi màu mượt + hiện dấu ✓ và lượng đã rót ngay trên khay.
      animationDuration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
      color: used ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
      elevation: dragging ? 6 : 1,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(ingredientEmoji(t.name), style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Flexible(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_labels.ingredient(t.name),
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                if (poured != null)
                  Text('✓ ${_amt(poured.value, poured.item.unit)}',
                      key: Key('order-tray-amount-${t.name}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _tray(BuildContext context, Order o) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in o.tray)
          Builder(builder: (context) {
            final used = _poured.any((p) => p.item.name == t.name);
            final chip = _chip(context, t, used: used);
            if (_checked) return Opacity(opacity: 0.6, child: chip);
            return Draggable<TrayItem>(
              key: Key('order-tray-${t.name}'),
              data: t,
              feedback: _chip(context, t, used: false, dragging: true),
              childWhenDragging: Opacity(opacity: 0.35, child: chip),
              child: GestureDetector(onTap: () => _edit(t), child: chip),
            );
          }),
      ],
    );
  }

  /// Kệ trưng bày: phụ kiện đang trưng bày + chỗ phụ mở theo số món Thạo (xem recipe_counter.dart).
  Widget _shelf(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final g = ref.watch(gameControllerProvider);
    final mastered = recipeMasteredEver({for (final e in g.recipeProgress.entries) '${e.key}': e.value.toList()});
    final items = counterShelf(
        equipped: g.equippedAccessories, owned: {...g.ownedAccessories, ...g.ownedLimited}, mastered: mastered);
    if (items.isEmpty) return const SizedBox.shrink();
    final next = counterNextThreshold(mastered);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
          key: const Key('order-shelf'),
          spacing: 6,
          runSpacing: 4,
          children: [for (final a in items) Text(a.emoji, style: const TextStyle(fontSize: 22))],
        ),
        if (next != null) Text(l10n.recipeCounterNext(next), style: theme.textTheme.bodySmall),
      ]),
    );
  }

  Widget _order(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final o = _orders[_index];
    final last = _checked ? _served.last : null;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shelf(context),
                if (o.festival != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Chip(
                      key: const Key('order-festival'),
                      visualDensity: VisualDensity.compact,
                      label: Text('${_festivalEmoji(o.festival!)} ${l10n.recipeOrderFestival(festivalName(l10n, o.festival!))}'),
                    ),
                  ),
                OrderCustomer(
                  avatar: o.festival == null ? null : _festivalEmoji(o.festival!),
                  seed: o.recipe.id + _index,
                  mood: last == null
                      ? CustomerMood.waiting
                      : switch (last.grade.stars) {
                          3 => CustomerMood.delighted,
                          2 => CustomerMood.pleased,
                          _ => CustomerMood.upset,
                        },
                  upsetCount: _served.where((x) => !x.grade.correct).length,
                  // Giờ cao điểm sắp hết giờ (<25% kiên nhẫn) ⇒ khách sốt ruột.
                  impatient: _rush && !_checked && _leftMs * 4 < _patienceMs(),
                  child: Text(
                    l10n.recipeOrderAsk(_labels.recipe(o.recipe)),
                    key: const Key('order-prompt'),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (!widget.daily && _index == 0 && !_checked && _poured.isEmpty)
                  SwitchListTile(
                    key: const Key('order-rush-toggle'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: _rush,
                    onChanged: _setRush,
                    title: Text('⏱ ${l10n.recipeOrderRush}'),
                    subtitle: _rush ? Text(l10n.recipeOrderRushSub) : null,
                  ),
                if (_rush)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        // Mượt giữa các nhịp 200ms của đồng hồ (và khi đơn mới đầy lại).
                        tween: Tween(end: (_leftMs / _patienceMs()).clamp(0.0, 1.0)),
                        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: _tickMs),
                        builder: (context, v, _) => LinearProgressIndicator(
                          key: const Key('order-patience'),
                          minHeight: 8,
                          value: v,
                          color: v < 0.25 ? Colors.red : (v < 0.5 ? Colors.orange : Colors.green),
                        ),
                      ),
                    ),
                  ),
                if (widget.daily && _index == 0 && !_checked)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(l10n.recipeDailyIntro, key: const Key('daily-intro'), style: theme.textTheme.bodySmall),
                  ),
                if (_combo >= 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: PulseOnIncrease(
                      value: _combo,
                      peak: 1.12,
                      child: Chip(
                        key: const Key('order-combo'),
                        visualDensity: VisualDensity.compact,
                        label: Text(l10n.recipeOrderCombo(_combo)),
                      ),
                    ),
                  ),
                _guide(context, o),
                if (!widget.daily && o.guide != OrderGuide.full && !_hinted && !_checked)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('order-hint'),
                      onPressed: _watchingAd ? null : _useHint,
                      icon: const Icon(Icons.lightbulb_outline, size: 20),
                      label: Text(l10n.recipeHint),
                    ),
                  ),
                const SizedBox(height: 12),
                _cup(context),
                if (!_checked) ...[
                  const SizedBox(height: 6),
                  Text(l10n.recipeOrderHint, style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 12),
                Text(l10n.recipeOrderTray, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                _tray(context, o),
              ],
            ),
          ),
        ),
        // Giới hạn chiều cao bảng đáy (chữ to/ngôn ngữ dài): vùng cuộn phía trên luôn còn chỗ.
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.45),
          child: Material(
          elevation: 8,
          color: last == null
              ? theme.colorScheme.surface
              : Color.alphaBlend(
                  (last.grade.correct ? Colors.green : Colors.red).withValues(alpha: 0.10), theme.colorScheme.surface),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (last != null)
                  Flexible(child: SingleChildScrollView(child: AppearIn(child: _feedback(context, l10n, last)))),
                if (last != null && last.grade.stars == 3)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('order-share'),
                      onPressed: () => showCupShare(context,
                          recipeName: _labels.recipe(last.order.recipe),
                          layers: [for (final p in _poured) CupLayer(ingredientColor(p.item.name), _cupFraction(p))]),
                      icon: const Icon(Icons.ios_share, size: 20),
                      label: Text(l10n.recipeOrderShare),
                    ),
                  ),
                if (last != null) const SizedBox(height: 4),
                if (last == null)
                  FilledButton(
                    key: const Key('order-serve'),
                    onPressed: _poured.isEmpty || _sealing ? null : _serve,
                    child: Text(l10n.recipeOrderServe),
                  )
                else
                  FilledButton(
                    key: const Key('order-next'),
                    onPressed: _next,
                    child: Text(_index + 1 >= _orders.length ? l10n.recipeSeeResult : l10n.recipeNext),
                  ),
              ],
            ),
          ),
        ),
        ),
      ],
    );
  }

  Widget _feedback(BuildContext context, AppLocalizations l10n, _Served s) {
    final theme = Theme.of(context);
    final r = s.result;
    final g = s.grade;
    final lines = <String>[
      if (widget.daily) l10n.recipeDailyOrderScore(s.score),
      for (final it in g.items)
        switch (it.verdict) {
          ItemVerdict.missing => l10n.recipeOrderMissing(_amt(it.right!, it.unit), _labels.ingredient(it.name)),
          ItemVerdict.extra => l10n.recipeOrderExtra(_labels.ingredient(it.name)),
          ItemVerdict.wrongAmount || ItemVerdict.close =>
            l10n.recipeOrderOff(_amt(it.mine!, it.unit), _labels.ingredient(it.name), _amt(it.right!, it.unit)),
          _ => '',
        },
    ].where((x) => x.isNotEmpty).toList();
    final tail = <String>[
      if (!widget.daily && s.hinted) l10n.recipeHintNoCount else if (!r.outcome.counted) l10n.recipePracticeOnly,
      if (r.outcome.leveledUp) l10n.recipeLevelUp(recipeBoxName(l10n, r.after.box), _labels.recipe(s.order.recipe)),
      if (r.milestone > 0) l10n.recipeMilestone(r.milestone),
      if (s.late) l10n.recipeOrderTimeUp,
      if (s.tip > 0)
        s.festival
            ? l10n.recipeOrderFestivalTip(formatNumber(s.tip))
            : s.rush
                ? l10n.recipeOrderRushTip(formatNumber(s.tip))
                : l10n.recipeOrderComboTip(formatNumber(s.tip), s.combo)
      else if (s.combo >= 2)
        l10n.recipeOrderCombo(s.combo),
      if (r.streakGems > 0)
        l10n.recipeStreakGems(r.streakDays, r.streakGems)
      else if (r.streakExtended)
        l10n.recipeStreakFeedback(r.streakDays),
      if (r.cash > 0 && r.gems > 0)
        l10n.recipeRewardBoth(formatNumber(r.cash), r.gems)
      else if (r.cash > 0)
        l10n.recipeRewardCash(formatNumber(r.cash)),
    ];
    final head = switch (g.stars) {
      3 => l10n.recipeOrderPerfect,
      2 => l10n.recipeOrderGood,
      _ => l10n.recipeOrderFail,
    };
    return Column(
      key: const Key('order-feedback'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(g.correct ? '🎉' : '💡', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(head,
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800, color: g.correct ? Colors.green.shade700 : Colors.red.shade700)),
          ),
        ]),
        for (final t in [...lines, if (!widget.daily) ...tail])
          Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(t, style: theme.textTheme.bodyMedium)),
      ],
    );
  }

  // --- tổng kết ----------------------------------------------------------------

  Widget _result(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ok = _served.where((s) => s.grade.correct).length;
    final stars = _served.isEmpty ? 1 : (ok == _served.length ? 3 : (ok * 5 >= _served.length * 3 ? 2 : 1));
    final cash = _served.fold<double>(0, (a, s) => a + s.result.cash + s.tip);
    final gems = _served.fold<int>(0, (a, s) => a + s.result.gems);
    return ListView(
      key: const Key('order-result'),
      padding: const EdgeInsets.all(16),
      children: [
        ClayCard(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text(ok == _served.length ? '🏆' : (ok * 2 >= _served.length ? '🎉' : '💪'),
                style: const TextStyle(fontSize: 56)),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 1; i <= 3; i++) _StarPop(index: i - 1, filled: i <= stars),
            ]),
            const SizedBox(height: 8),
            CountUp(
              value: ok,
              builder: (context, n) => Text(l10n.recipeScore(n, _served.length),
                  key: const Key('order-score'),
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            ),
            if (cash > 0) ...[
              const SizedBox(height: 6),
              Text(
                gems > 0
                    ? l10n.recipeRewardBoth(formatNumber(cash), gems)
                    : l10n.recipeRewardCash(formatNumber(cash)),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ]),
        ),
        if (cash > 0) ...[
          const SizedBox(height: 12),
          if (_doubled)
            Center(
              child: Text(l10n.recipeDoubled,
                  key: const Key('order-doubled'),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.w800)),
            )
          else
            OutlinedButton.icon(
              key: const Key('order-double'),
              onPressed: _watchingAd ? null : () => _doubleReward(cash),
              icon: const Icon(Icons.play_circle_outline),
              label: Text(l10n.recipeDouble),
            ),
        ],
        const SizedBox(height: 16),
        FilledButton(key: const Key('order-again'), onPressed: _again, child: Text(l10n.recipeAgain)),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('order-done'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.recipeDone),
        ),
      ],
    );
  }

  // --- thử thách hằng ngày -----------------------------------------------------

  Widget _dailyButtons(BuildContext context, AppLocalizations l10n) => Column(children: [
        FilledButton.icon(
          key: const Key('daily-board'),
          icon: const Icon(Icons.emoji_events),
          onPressed: () async {
            // Tính năng online: cần đã liên kết email (xem email_gate.dart).
            if (!await ensureOnlineLinked(context) || !context.mounted) return;
            showRecipeLeaderboard(context, board: RecipeBoard.daily);
          },
          label: Text(l10n.recipeDailyBoard),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('daily-done'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.recipeDone),
        ),
      ]);

  /// Đã làm hôm nay từ trước: chỉ xem lại điểm + bảng.
  Widget _dailyAlready(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final score = ref.read(gameControllerProvider).recipeDailyScore;
    return ListView(
      key: const Key('daily-already'),
      padding: const EdgeInsets.all(16),
      children: [
        ClayCard(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const Text('📅', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            Text(l10n.recipeDailyDone(score),
                key: const Key('daily-score'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(l10n.recipeDailyAlready, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ]),
        ),
        const SizedBox(height: 16),
        _dailyButtons(context, l10n),
      ],
    );
  }

  Widget _dailyResult(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final total = _served.fold<int>(0, (a, s) => a + s.score);
    final reward = _dailyReward;
    return ListView(
      key: const Key('daily-result'),
      padding: const EdgeInsets.all(16),
      children: [
        ClayCard(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text(total >= dailyMaxScore ? '🏆' : (total * 2 >= dailyMaxScore ? '🎉' : '💪'),
                style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            CountUp(
              value: total,
              builder: (context, n) => Text(l10n.recipeDailyTotal(n),
                  key: const Key('daily-score'),
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 10),
            for (final s in _served)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Expanded(child: Text(_labels.recipe(s.order.recipe), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Text('${s.score}/100', style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
              ),
            if (reward != null && reward.counted) ...[
              const SizedBox(height: 10),
              Text(
                l10n.recipeRewardBoth(formatNumber(reward.cash), reward.gems),
                key: const Key('daily-reward'),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        _dailyButtons(context, l10n),
      ],
    );
  }
}

/// Bảng đặt lượng một nguyên liệu: thanh trượt theo các mức cho sẵn. Trả về lượng, hoặc -1 để bỏ ra khỏi ly.
class _AmountSheet extends StatefulWidget {
  const _AmountSheet({
    required this.item,
    required this.current,
    required this.name,
    this.marks = const [],
    this.target,
  });
  final List<double> marks;
  final double? target;
  final TrayItem item;
  final double? current;
  final String name;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  late final List<double> _steps = amountSteps(widget.item.unit);
  late int _i = widget.current != null ? nearestStep(widget.item.unit, widget.current!) : 0;
  Timer? _pourTimer;
  int _ticks = 0;

  @override
  void dispose() {
    _pourTimer?.cancel();
    super.dispose();
  }

  /// Giữ để rót: mỗi nhịp lên một mức, càng giữ lâu càng nhanh; chạm nhẹ = một mức.
  void _startPour() {
    _ticks = 0;
    _tick();
  }

  void _tick() {
    if (_i < _steps.length - 1) {
      setState(() => _i++);
      HapticFeedback.selectionClick();
    }
    _ticks++;
    final ms = _ticks < 6 ? 170 : (_ticks < 14 ? 110 : 70);
    _pourTimer = Timer(Duration(milliseconds: ms), _tick);
  }

  void _stopPour() {
    _pourTimer?.cancel();
    _pourTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = ingredientColor(widget.item.name);
    final frac = _steps.length <= 1 ? 0.0 : (_i / (_steps.length - 1)).clamp(0.0, 1.0);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${ingredientEmoji(widget.item.name)}  ${l10n.recipeOrderSetAmount(widget.name)}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(children: [
              OrderCup(
                layers: [CupLayer(color, frac * _gaugeFill)],
                width: 64,
                height: 86,
                marks: widget.marks,
                target: widget.target,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(children: [
                  Text(_amt(_steps[_i], widget.item.unit),
                      key: const Key('order-amount'),
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  // Giữ để rót (Listener: bắt cả nhấn-giữ lẫn chạm nhẹ, không bị cuộn của bảng cướp).
                  Listener(
                    onPointerDown: (_) => _startPour(),
                    onPointerUp: (_) => _stopPour(),
                    onPointerCancel: (_) => _stopPour(),
                    child: FilledButton.tonalIcon(
                      key: const Key('order-hold'),
                      onPressed: () {},
                      icon: const Icon(Icons.water_drop_rounded),
                      label: Text(l10n.recipeOrderHold),
                    ),
                  ),
                ]),
              ),
            ]),
            Slider(
              key: const Key('order-slider'),
              value: _i.toDouble(),
              min: 0,
              max: (_steps.length - 1).toDouble(),
              divisions: _steps.length - 1,
              onChanged: (v) => setState(() => _i = v.round()),
            ),
            Row(children: [
              TextButton(
                key: const Key('order-reset'),
                onPressed: () => setState(() => _i = 0),
                child: Text(l10n.recipeOrderPourAgain),
              ),
              const Spacer(),
              if (widget.current != null)
                TextButton(
                  key: const Key('order-remove'),
                  onPressed: () => Navigator.of(context).pop(-1.0),
                  child: Text(l10n.recipeOrderRemove),
                ),
            ]),
            FilledButton(
              key: const Key('order-pour'),
              onPressed: () => Navigator.of(context).pop(_steps[_i]),
              child: Text(l10n.recipeOrderPour),
            ),
          ],
        ),
      ),
    );
  }
}
