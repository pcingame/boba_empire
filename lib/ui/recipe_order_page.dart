import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_service.dart';
import '../ads/banner_ad_box.dart';
import '../core/daily.dart';
import '../core/format.dart';
import '../core/recipe_mastery.dart';
import '../core/recipe_names.dart';
import '../core/recipe_orders.dart';
import '../core/recipes.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import '../state/recipe_providers.dart';
import 'recipe_hub_page.dart' show recipeBoxName;
import 'widgets/accessory_reveal.dart';
import 'widgets/anim_assets.dart';
import 'widgets/clay.dart';
import 'widgets/motion.dart';
import 'widgets/one_shot_lottie.dart';
import 'widgets/recipe_motion.dart';

/// "Pha theo đơn": khách gọi một món, người chơi kéo (hoặc chạm) nguyên liệu từ khay vào ly rồi đặt lượng.
/// Kết quả ghi vào bậc thuộc như câu trắc nghiệm (`answerRecipe`); gợi ý giảm dần theo bậc của món.
class RecipeOrderPage extends ConsumerStatefulWidget {
  const RecipeOrderPage({super.key});

  @override
  ConsumerState<RecipeOrderPage> createState() => _RecipeOrderPageState();
}

class _Served {
  _Served(this.order, this.grade, this.result, {this.hinted = false});
  final bool hinted;
  final Order order;
  final OrderResult grade;
  final RecipeAnswerResult result;
}

String _amt(double v, String unit) => '${v == v.roundToDouble() ? v.round() : v} $unit';

class _RecipeOrderPageState extends ConsumerState<RecipeOrderPage> {
  RecipeLabels _labels = const RecipeLabels(null, 'vi');

  late List<Order> _orders = _newSession();
  final _served = <_Served>[];
  final _poured = <Poured>[];
  int _index = 0;
  bool _checked = false; // đơn hiện tại đã phục vụ
  bool _hinted = false; // đơn hiện tại đã xem công thức mẫu (xem quảng cáo) ⇒ không tính bậc
  bool _doubled = false; // đã nhân đôi thưởng buổi này
  bool _watchingAd = false;

  List<Order> _newSession() {
    final catalog = ref.read(recipeCatalogProvider).requireValue;
    final progress = ref.read(gameControllerProvider).recipeProgress;
    return buildOrders(
      catalog,
      progress,
      dayIndex(ref.read(clockProvider)()),
      ref.read(recipeRandomProvider),
      pool: unlockedRecipes(catalog, (id) => progress[id]?.best ?? 0),
    );
  }

  bool get _finished => _index >= _orders.length;

  Future<void> _edit(TrayItem item) async {
    if (_checked) return;
    final at = _poured.indexWhere((p) => p.item.name == item.name);
    final current = at < 0 ? null : _poured[at].value;
    final r = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AmountSheet(item: item, current: current, name: _labels.ingredient(item.name)),
    );
    if (r == null || !mounted || _checked) return;
    setState(() {
      if (at >= 0) _poured.removeAt(at);
      if (r >= 0) _poured.add(Poured(item, r));
    });
  }

  void _serve() {
    if (_checked || _poured.isEmpty) return;
    final order = _orders[_index];
    final grade = gradeOrder(order, _poured);
    final game = ref.read(gameControllerProvider.notifier);
    final result = game.answerRecipe(order.recipe.id, grade.correct, hinted: _hinted);
    // Bảng xếp hạng: chỉ tính món pha hoàn hảo khi KHÔNG được xem công thức mẫu (bậc Mới / gợi ý quảng cáo).
    if (grade.stars == 3 && order.guide != OrderGuide.full && !_hinted) game.recordOrderPerfect(order.recipe.id);
    setState(() {
      _checked = true;
      _served.add(_Served(order, grade, result, hinted: _hinted));
    });
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
    });
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
        _checked = false;
        _hinted = false;
        _doubled = false;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_finished ? l10n.recipeResultTitle : '${_index + 1}/${_orders.length}'),
        bottom: _finished
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
      body: SafeArea(
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
                    child: _finished ? _result(context) : _order(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const BannerAdBox(),
          ],
        ),
      ),
    );
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
          child: _poured.isEmpty
              ? Row(children: [
                  const Text('🥤', style: TextStyle(fontSize: 30)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l10n.recipeOrderCupEmpty, style: theme.textTheme.titleSmall)),
                ])
              : Column(
                  children: [
                    for (final p in _poured)
                      InkWell(
                        key: Key('order-poured-${p.item.name}'),
                        onTap: _checked ? null : () => _edit(p.item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(children: [
                            Text(ingredientEmoji(p.item.name), style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_labels.ingredient(p.item.name), style: theme.textTheme.bodyLarge)),
                            Text(_amt(p.value, p.item.unit),
                                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
                          ]),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, TrayItem t, {required bool used, bool dragging = false}) {
    final theme = Theme.of(context);
    return Material(
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
              child: Text(_labels.ingredient(t.name),
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
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
                ClayCard(
                  padding: const EdgeInsets.all(10),
                  child: Row(children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
                      child: const Text('🧋', style: TextStyle(fontSize: 21)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.recipeOrderAsk(_labels.recipe(o.recipe)),
                        key: const Key('order-prompt'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ]),
                ),
                _guide(context, o),
                if (o.guide != OrderGuide.full && !_hinted && !_checked)
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
                  Flexible(child: SingleChildScrollView(child: _feedback(context, l10n, last))),
                if (last != null) const SizedBox(height: 8),
                if (last == null)
                  FilledButton(
                    key: const Key('order-serve'),
                    onPressed: _poured.isEmpty ? null : _serve,
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
      if (s.hinted) l10n.recipeHintNoCount else if (!r.outcome.counted) l10n.recipePracticeOnly,
      if (r.outcome.leveledUp) l10n.recipeLevelUp(recipeBoxName(l10n, r.after.box), _labels.recipe(s.order.recipe)),
      if (r.milestone > 0) l10n.recipeMilestone(r.milestone),
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
        for (final t in [...lines, ...tail])
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
    final cash = _served.fold<double>(0, (a, s) => a + s.result.cash);
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
              for (var i = 1; i <= 3; i++)
                Icon(i <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 34, color: Colors.amber.shade600),
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
}

/// Bảng đặt lượng một nguyên liệu: thanh trượt theo các mức cho sẵn. Trả về lượng, hoặc -1 để bỏ ra khỏi ly.
class _AmountSheet extends StatefulWidget {
  const _AmountSheet({required this.item, required this.current, required this.name});
  final TrayItem item;
  final double? current;
  final String name;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  late final List<double> _steps = amountSteps(widget.item.unit);
  late int _i = widget.current != null ? nearestStep(widget.item.unit, widget.current!) : _steps.length ~/ 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${ingredientEmoji(widget.item.name)}  ${l10n.recipeOrderSetAmount(widget.name)}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Center(
              child: Text(_amt(_steps[_i], widget.item.unit),
                  key: const Key('order-amount'),
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            ),
            Slider(
              key: const Key('order-slider'),
              value: _i.toDouble(),
              min: 0,
              max: (_steps.length - 1).toDouble(),
              divisions: _steps.length - 1,
              onChanged: (v) => setState(() => _i = v.round()),
            ),
            const SizedBox(height: 4),
            FilledButton(
              key: const Key('order-pour'),
              onPressed: () => Navigator.of(context).pop(_steps[_i]),
              child: Text(l10n.recipeOrderPour),
            ),
            if (widget.current != null)
              TextButton(
                key: const Key('order-remove'),
                onPressed: () => Navigator.of(context).pop(-1.0),
                child: Text(l10n.recipeOrderRemove),
              ),
          ],
        ),
      ),
    );
  }
}
