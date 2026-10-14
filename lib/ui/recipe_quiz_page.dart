import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_service.dart';
import '../ads/banner_ad_box.dart';
import '../core/daily.dart';
import '../core/format.dart';
import '../core/recipe_mastery.dart';
import '../core/recipe_quiz.dart';
import '../core/recipes.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import '../state/recipe_providers.dart';
import 'recipe_hub_page.dart' show recipeBoxName;
import 'widgets/accessory_reveal.dart';
import 'widgets/anim_assets.dart';
import 'widgets/motion.dart';
import 'widgets/one_shot_lottie.dart';
import 'widgets/recipe_motion.dart';
import 'widgets/clay.dart';

/// Một buổi luyện công thức: lần lượt các câu hỏi trắc nghiệm 4 lựa chọn, ghi bậc ngay sau mỗi câu
/// (thoát giữa chừng không mất kết quả đã trả lời), cuối buổi hiện tổng kết.
class RecipeQuizPage extends ConsumerStatefulWidget {
  const RecipeQuizPage({super.key});

  @override
  ConsumerState<RecipeQuizPage> createState() => _RecipeQuizPageState();
}

class _Answered {
  _Answered(this.question, this.chosen, this.result, {this.hinted = false});
  final QuizQuestion question;
  final int chosen;
  final RecipeAnswerResult result;

  /// Câu này đã dùng gợi ý (xem quảng cáo) ⇒ không tính bậc.
  final bool hinted;
  bool get correct => chosen == question.answer;
}

class _RecipeQuizPageState extends ConsumerState<RecipeQuizPage> {
  late List<QuizQuestion> _questions = _newSession();
  final _answers = <_Answered>[];
  int _index = 0;
  int? _chosen; // lựa chọn của câu hiện tại (null = chưa trả lời)
  bool _hinted = false; // câu hiện tại đã dùng gợi ý
  Set<int> _hidden = {}; // các lựa chọn sai bị gợi ý loại bỏ
  bool _doubled = false; // đã nhân đôi thưởng buổi này
  bool _watchingAd = false;

  List<QuizQuestion> _newSession() {
    final catalog = ref.read(recipeCatalogProvider).requireValue;
    final progress = ref.read(gameControllerProvider).recipeProgress;
    final today = dayIndex(ref.read(clockProvider)());
    return buildSession(
      catalog,
      progress,
      today,
      ref.read(recipeRandomProvider),
    );
  }

  bool get _finished => _index >= _questions.length;

  /// Khoá của lựa chọn [i] ở câu [questionIndex] — mỗi câu bộ khoá riêng để lúc chuyển câu (cây cũ và cây
  /// mới cùng tồn tại ngắn) không trùng GlobalKey.
  final _tileKeys = <int, List<GlobalKey>>{};
  GlobalKey _tileKey(int questionIndex, int i) =>
      (_tileKeys[questionIndex] ??= List.generate(4, (_) => GlobalKey()))[i];

  void _choose(int i, BuildContext tileContext) {
    if (_chosen != null) return;
    final q = _questions[_index];
    final result = ref
        .read(gameControllerProvider.notifier)
        .answerRecipe(q.recipe.id, i == q.answer, hinted: _hinted);
    setState(() {
      _chosen = i;
      _answers.add(_Answered(q, i, result, hinted: _hinted));
    });
    // Rương theo mốc số món Thạo: hiện khoảnh khắc nhận phụ kiện (như mốc Trân Châu Rơi).
    final drop = result.drop;
    if (drop != null) playAccessoryReveal(context, drop);
    _celebrate(tileContext, i == q.answer, result);
    // Bảng phản hồi ở đáy làm vùng cuộn thấp lại: cuộn để đáp án đúng luôn nằm trong tầm nhìn.
    final answerKey = _tileKey(_index, q.answer);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = answerKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// Hiệu ứng theo kết quả câu trả lời. Mọi hiệu ứng đi qua [playEffect] nên tự theo mức chất lượng
  /// (Tắt/giảm chuyển động = không phát; Thấp bỏ hiệu ứng nặng) và có trần số hiệu ứng cùng lúc.
  void _celebrate(
    BuildContext tileContext,
    bool correct,
    RecipeAnswerResult r,
  ) {
    if (correct) {
      playEffect(
        context,
        AnimAssets.sparkle,
        size: 120,
        center: effectCenterOf(tileContext),
        heavy: false,
      );
    }
    if (r.outcome.leveledUp) playEffect(context, AnimAssets.levelUp, size: 220);
    if (r.streakGems > 0) {
      playEffect(context, AnimAssets.gemBurst, size: 160, heavy: false);
    }
    if (r.milestone > 0) playEffect(context, AnimAssets.confetti, size: 260);
  }

  void _next() {
    setState(() {
      _index++;
      _chosen = null;
      _hinted = false;
      _hidden = {};
    });
    if (_finished) {
      // Đúng hết cả buổi: pháo giấy (qua playEffect nên tự bỏ ở mức Thấp/Tắt).
      if (_answers.isNotEmpty && _answers.every((a) => a.correct)) {
        playEffect(context, AnimAssets.confetti, size: 260);
      }
      // Buổi chỉ tính cho nhiệm vụ nếu có ít nhất một câu thật sự được tính bậc.
      ref
          .read(gameControllerProvider.notifier)
          .completeRecipeSession(
            anyCounted: _answers.any((a) => a.result.outcome.counted),
          );
    }
  }

  void _again() => setState(() {
    _questions = _newSession();
    _answers.clear();
    _index = 0;
    _chosen = null;
    _hinted = false;
    _hidden = {};
    _doubled = false;
  });

  /// Xem quảng cáo thưởng (người đã gỡ quảng cáo/VIP được cộng thẳng — cùng khuôn mọi chỗ khác).
  Future<bool> _watchAd() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _watchingAd = true);
    final adFree = ref.read(gameControllerProvider).adFree;
    final outcome = adFree
        ? RewardOutcome.earned
        : await ref.read(adServiceProvider).showRewardedAd();
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

  /// Gợi ý 50:50: bỏ hai đáp án sai. Câu này sẽ không tính bậc (xem `answerRecipe(hinted: true)`).
  Future<void> _useHint() async {
    if (_hinted || _chosen != null || _watchingAd) return;
    final at = _index;
    if (!await _watchAd() || !mounted || _index != at || _chosen != null) {
      return;
    }
    final q = _questions[_index];
    final wrong = [
      for (var i = 0; i < q.options.length; i++)
        if (i != q.answer) i,
    ]..shuffle(ref.read(recipeRandomProvider));
    setState(() {
      _hinted = true;
      _hidden = wrong.take(2).toSet();
    });
  }

  Future<void> _doubleReward(double cash) async {
    if (_doubled || _watchingAd) return;
    if (!await _watchAd() || !mounted) return;
    ref.read(gameControllerProvider.notifier).doubleRecipeReward(cash);
    setState(() => _doubled = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _finished
              ? l10n.recipeResultTitle
              : '${_index + 1}/${_questions.length}',
        ),
        bottom: _finished
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: SmoothBar(
                  key: const Key('recipe-quiz-progress'),
                  value:
                      (_index + (_chosen == null ? 0 : 1)) / _questions.length,
                  minHeight: 4,
                  radius: 0,
                ),
              ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              // Trượt + mờ giữa các câu và sang màn tổng kết; Tắt hiệu ứng thì chuyển ngay.
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 260),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.12, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_finished ? -1 : _index),
                    child: _finished ? _result(context) : _question(context),
                  ),
                ),
              ),
            ),
            // Banner như Trân Châu Rơi (tự ẩn khi đã gỡ quảng cáo/VIP hoặc không phải di động); chừa khoảng
            // cách với nút "Câu tiếp" để không bấm nhầm quảng cáo.
            const SizedBox(height: 8),
            const BannerAdBox(),
          ],
        ),
      ),
    );
  }

  // --- câu hỏi ---------------------------------------------------------------

  String _prompt(AppLocalizations l10n, QuizQuestion q) => switch (q.kind) {
    QuizKind.missingIngredient => l10n.recipeQMissing(q.recipe.name),
    QuizKind.quantity => l10n.recipeQQuantity(
      q.recipe.name,
      q.recipe.ingredients[q.target].name,
    ),
    QuizKind.fullRecipe => l10n.recipeQFull(q.recipe.name),
  };

  Widget _hint(BuildContext context, QuizQuestion q) {
    final theme = Theme.of(context);
    if (q.kind == QuizKind.fullRecipe) return const SizedBox.shrink();
    if (q.kind == QuizKind.quantity) {
      final ing = q.recipe.ingredients[q.target];
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Text(
              ingredientEmoji(ing.name),
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(ing.name, style: theme.textTheme.titleMedium)),
          ],
        ),
      );
    }
    // Thiếu nguyên liệu: hiện cả danh sách, dòng bị hỏi che tên nhưng giữ lượng làm gợi ý.
    return ClayTile(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          for (var i = 0; i < q.recipe.ingredients.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Text(
                    i == q.target
                        ? '❓'
                        : ingredientEmoji(q.recipe.ingredients[i].name),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      i == q.target ? '_ _ _ _' : q.recipe.ingredients[i].name,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    q.recipe.ingredients[i].amount,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _question(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final q = _questions[_index];
    final last = _answers.isNotEmpty && _chosen != null ? _answers.last : null;
    return Column(
      children: [
        Expanded(
          // Cuộn thường (dựng đủ mọi lựa chọn, không dựng lười) để sau khi trả lời có thể cuộn tới đáp án đúng.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Phiếu gọi món": khách hỏi, người chơi trả lời.
                ClayCard(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Text('🧋', style: TextStyle(fontSize: 21)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _prompt(l10n, q),
                          key: const Key('recipe-quiz-prompt'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _hint(context, q),
                if (_chosen == null && !_hinted)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('recipe-hint'),
                      onPressed: _watchingAd ? null : _useHint,
                      icon: const Icon(Icons.lightbulb_outline, size: 20),
                      label: Text(l10n.recipeHint),
                    ),
                  ),
                const SizedBox(height: 8),
                for (var i = 0; i < q.options.length; i++)
                  if (!_hidden.contains(i)) _optionTile(context, q, i),
              ],
            ),
          ),
        ),
        // Phản hồi + "Câu tiếp" ghim ở đáy (không cuộn): trả lời xong là thấy ngay nút đi tiếp, kể cả
        // khi danh sách lựa chọn dài / chữ to.
        if (last != null)
          Material(
            elevation: 8,
            // Nền ngả xanh/đỏ nhạt theo kết quả (pha lên nền sáng của giao diện).
            color: Color.alphaBlend(
              (last.correct ? Colors.green : Colors.red).withValues(alpha: 0.10),
              theme.colorScheme.surface,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: _feedback(context, l10n, last),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('recipe-quiz-next'),
                    onPressed: _next,
                    child: Text(
                      _index + 1 >= _questions.length
                          ? l10n.recipeSeeResult
                          : l10n.recipeNext,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _optionTile(BuildContext context, QuizQuestion q, int i) {
    final theme = Theme.of(context);
    final answered = _chosen != null;
    final isAnswer = i == q.answer;
    final isChosen = i == _chosen;
    Color? bg;
    Color border = theme.colorScheme.outlineVariant;
    if (answered && isAnswer) {
      bg = Colors.green.withValues(alpha: 0.22);
      border = Colors.green;
    } else if (answered && isChosen) {
      bg = Colors.red.withValues(alpha: 0.18);
      border = Colors.red;
    }
    return Padding(
      key: _tileKey(_index, i),
      padding: const EdgeInsets.symmetric(vertical: 4),
      // Đáp án đúng nảy nhẹ; lựa chọn sai lắc ngang (chỉ khi bật hiệu ứng).
      child: ShakeOnTrigger(
        trigger: answered && isChosen && !isAnswer ? 1 : 0,
        child: PulseOnIncrease(
          value: answered && isAnswer ? 1 : 0,
          peak: 1.05,
          child: Builder(
            builder: (tileContext) => Material(
              elevation: answered ? 0 : 2,
              shadowColor: Colors.black.withValues(alpha: 0.25),
              color:
                  bg ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                key: Key('recipe-quiz-option-$i'),
                borderRadius: BorderRadius.circular(14),
                onTap: answered ? null : () => _choose(i, tileContext),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: border,
                      width: answered && (isAnswer || isChosen) ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _LetterBadge(
                        letter: String.fromCharCode(65 + i), // A, B, C, D
                        state: answered && isAnswer
                            ? _BadgeState.right
                            : (answered && isChosen ? _BadgeState.wrong : _BadgeState.idle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: q.kind == QuizKind.fullRecipe
                            ? _RecipeLines(text: q.options[i])
                            : Text(
                                q.kind == QuizKind.missingIngredient
                                    ? '${ingredientEmoji(q.options[i])}  ${q.options[i]}'
                                    : q.options[i],
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _feedback(BuildContext context, AppLocalizations l10n, _Answered a) {
    final theme = Theme.of(context);
    final r = a.result;
    final lines = <String>[
      a.correct ? l10n.recipeCorrect : l10n.recipeWrongShort,
      if (a.hinted)
        l10n.recipeHintNoCount
      else if (!r.outcome.counted)
        l10n.recipePracticeOnly,
      if (r.outcome.leveledUp)
        l10n.recipeLevelUp(
          recipeBoxName(l10n, r.after.box),
          a.question.recipe.name,
        ),
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
    return Column(
      key: const Key('recipe-quiz-feedback'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: i == 0
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.correct ? '🎉' : '💡', style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(lines[i], style: _feedbackHeadStyle(theme, a.correct))),
                    ],
                  )
                : Text(lines[i], style: theme.textTheme.bodyMedium),
          ),
      ],
    );
  }

  TextStyle? _feedbackHeadStyle(ThemeData theme, bool correct) => theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: correct ? Colors.green.shade700 : Colors.red.shade700,
      );

  /// 3 sao khi đúng hết, 2 sao khi đúng ≥ 60%, 1 sao còn lại (luôn có ít nhất 1 sao để động viên).
  int _starsFor(int correct, int total) => total > 0 && correct == total ? 3 : (total > 0 && correct * 5 >= total * 3 ? 2 : 1);

  // --- tổng kết --------------------------------------------------------------

  Widget _result(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final correct = _answers.where((a) => a.correct).length;
    final ups = _answers.where((a) => a.result.outcome.leveledUp).length;
    final cash = _answers.fold<double>(0, (s, a) => s + a.result.cash);
    final gems = _answers.fold<int>(0, (s, a) => s + a.result.gems);
    return ListView(
      key: const Key('recipe-result'),
      padding: const EdgeInsets.all(16),
      children: [
        ClayCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Huy chương + 1–3 sao theo tỉ lệ đúng (chỉ trang trí; điểm chữ ở dưới là số liệu thật).
              Text(
                correct == _questions.length ? '🏆' : (correct * 2 >= _questions.length ? '🎉' : '💪'),
                key: const Key('recipe-result-emoji'),
                style: const TextStyle(fontSize: 56),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var s = 1; s <= 3; s++)
                    Icon(
                      s <= _starsFor(correct, _questions.length) ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 34,
                      color: Colors.amber.shade600,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Điểm đếm lên (hiện luôn khi tắt hiệu ứng).
              CountUp(
                value: correct,
                builder: (context, n) => Text(
                  l10n.recipeScore(n, _questions.length),
                  key: const Key('recipe-score'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (ups > 0) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.recipeLevelUps(ups),
                  style: theme.textTheme.titleMedium,
                ),
              ],
              if (cash > 0) ...[
                const SizedBox(height: 6),
                Text(
                  gems > 0
                      ? l10n.recipeRewardBoth(formatNumber(cash), gems)
                      : l10n.recipeRewardCash(formatNumber(cash)),
                  key: const Key('recipe-reward'),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ],
          ),
        ),
        if (cash > 0) ...[
          const SizedBox(height: 12),
          if (_doubled)
            Center(
              child: Text(
                l10n.recipeDoubled,
                key: const Key('recipe-doubled'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else
            OutlinedButton.icon(
              key: const Key('recipe-double'),
              onPressed: _watchingAd ? null : () => _doubleReward(cash),
              icon: const Icon(Icons.play_circle_outline),
              label: Text(l10n.recipeDouble),
            ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('recipe-again'),
          onPressed: _again,
          child: Text(l10n.recipeAgain),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('recipe-done'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.recipeDone),
        ),
      ],
    );
  }
}

enum _BadgeState { idle, right, wrong }

/// Huy hiệu tròn A/B/C/D ở đầu mỗi lựa chọn; đổi thành ✓ / ✗ sau khi trả lời.
class _LetterBadge extends StatelessWidget {
  const _LetterBadge({required this.letter, required this.state});
  final String letter;
  final _BadgeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg, icon) = switch (state) {
      _BadgeState.right => (Colors.green, Colors.white, Icons.check_rounded),
      _BadgeState.wrong => (Colors.red, Colors.white, Icons.close_rounded),
      _BadgeState.idle => (theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer, null),
    };
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: icon != null
          ? Icon(icon, size: 20, color: fg)
          : Text(letter, style: theme.textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w900)),
    );
  }
}

/// Một công thức đầy đủ (mỗi dòng "Tên nguyên liệu 10 g") vẽ thành các hàng emoji + tên + lượng.
class _RecipeLines extends StatelessWidget {
  const _RecipeLines({required this.text});
  final String text;

  static final _amount = RegExp(r'^(.*?)\s+(\d+(?:\.\d+)?\s*(?:g|ml))$');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in text.split('\n'))
          Builder(builder: (context) {
            final m = _amount.firstMatch(line);
            final name = m?.group(1) ?? line;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(children: [
                Text(ingredientEmoji(name), style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Expanded(child: Text(name, style: theme.textTheme.bodyMedium)),
                if (m != null)
                  Text(m.group(2)!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
              ]),
            );
          }),
      ],
    );
  }
}
