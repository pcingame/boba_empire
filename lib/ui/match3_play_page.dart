/// Màn chơi Ghép 3 (chơi đơn): bàn cờ + mục tiêu/điểm/số nước, banner ở đáy.
///
/// Bàn cờ dùng chung với Đấu Trường qua [Match3Panel]/[Match3View] — không có
/// bàn cờ thứ hai trong app.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_service.dart';
import '../ads/banner_ad_box.dart';
import '../core/balance.dart';
import '../core/format.dart';
import '../core/match3_levels.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import '../state/match3_controller.dart';
import 'match3_board.dart';
import 'widgets/anim_assets.dart';
import 'widgets/clay.dart';
import 'widgets/one_shot_lottie.dart';

class Match3PlayPage extends ConsumerStatefulWidget {
  const Match3PlayPage({super.key, required this.level});

  final Match3Level level;

  @override
  ConsumerState<Match3PlayPage> createState() => _Match3PlayPageState();
}

class _Match3PlayPageState extends ConsumerState<Match3PlayPage> {
  bool _resultShown = false;
  bool _continuedWithAd = false;
  bool _goingNext = false;

  /// Đã bấm rời trang (Tạm nghỉ / Danh sách màn). Phần đuôi của [_showResult]
  /// PHẢI dừng lại: trang đang bị gỡ mà còn setState + nạp lại màn thì có lúc
  /// nó dựng lại bảng kết quả, và dialog đó nổi lên trên LƯỚI MÀN — đúng lỗi
  /// người chơi báo ("bấm Tạm nghỉ mà vẫn hiện Qua màn").
  bool _leaving = false;

  /// Người chơi đã chọn "Chơi nốt" sau khi đạt mục tiêu → đừng hỏi lại mỗi
  /// nước, chỉ hiện bảng kết quả lần nữa khi hết nước.
  bool _keepPlaying = false;

  @override
  void initState() {
    super.initState();
    // Sau frame đầu: provider autoDispose mới thực sự có mặt để nạp màn.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(match3ControllerProvider.notifier).load(widget.level);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final play = ref.watch(match3ControllerProvider);
    final controller = ref.read(match3ControllerProvider.notifier);

    // Kết thúc màn khi HẾT NƯỚC, hoặc ngay khi ĐẠT MỤC TIÊU — không bắt người
    // chơi đốt nốt số nước còn lại rồi mới được sang màn sau.
    final ended =
        play.finished || (play.goalReached && !_keepPlaying);
    if (ended && !_resultShown && play.level.id == widget.level.id) {
      _resultShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showResult(play));
    }

    final board = Match3Panel(
      view: Match3View(
        cells: play.cells,
        frames: play.frames,
        moveId: play.moveId,
        finished: play.finished,
      ),
      onSwap: controller.swap,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.m3Level(widget.level.id))),
      body: LayoutBuilder(builder: (context, box) {
        // Nằm ngang: xếp HUD sang bên cạnh, nhường TOÀN BỘ chiều cao cho bàn
        // cờ. Xếp dọc như lúc đứng thì bàn co lại còn bằng con tem trong khi
        // hai bên thừa mênh mông.
        final wide = box.maxWidth > box.maxHeight;
        if (wide) {
          return Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _Hud(play: play)),
                    Expanded(child: Center(child: board)),
                  ],
                ),
              ),
              const BannerAdBox(),
            ],
          );
        }
        return Column(
          children: [
            _Hud(play: play),
            Expanded(child: Center(child: board)),
            const BannerAdBox(),
          ],
        );
      }),
    );
  }

  Future<void> _showResult(Match3PlayState play) async {
    final l10n = AppLocalizations.of(context)!;
    final stars = play.stars;
    final (cash, gems) = ref
        .read(gameControllerProvider.notifier)
        .grantMatch3Result(widget.level.id, stars);

    final hasNext = stars >= 1 && widget.level.id < Balance.m3LevelCount;
    // Còn nước = vừa đạt mục tiêu giữa chừng → mời chơi nốt để săn thêm sao
    // (2★/3★ nằm ở 1.5x và 2x mục tiêu, dừng ngay là không bao giờ với tới).
    final canKeepPlaying = play.movesLeft > 0 && stars < 3;

    if (!mounted) return;
    // Qua màn thì ăn mừng bằng hiệu ứng có sẵn của app (thiếu file thì tự bỏ
    // qua — xem playEffect). 3 sao mới bắn pháo hoa cho "đã".
    if (stars > 0) {
      playEffect(
        context,
        stars >= 3 ? AnimAssets.fireworks : AnimAssets.confetti,
      );
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          stars == 0
              ? l10n.m3Lose
              : (canKeepPlaying ? l10n.m3GoalReached : l10n.m3Win),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Match3Stars(stars: stars, size: 40),
            const SizedBox(height: 8),
            Text(m3ProgressLabel(l10n, play)),
            // Còn nước và chưa 3 sao → nói rõ còn thiếu bao nhiêu, để "Chơi
            // nốt" là lựa chọn có thông tin chứ không phải đoán mò.
            if (canKeepPlaying) ...[
              const SizedBox(height: 4),
              Builder(builder: (context) {
                final next = match3NextStar(play.progress, play.level.target);
                if (next == null) return const SizedBox.shrink();
                final (star, needed) = next;
                return Text(
                  play.level.goal == Match3GoalKind.collect
                      ? l10n.m3NeedCollect(
                          needed, match3Icons[play.level.collectType], star)
                      : l10n.m3NeedScore(
                          formatNumber(needed.toDouble()), star),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }),
            ],
            const SizedBox(height: 8),
            if (cash > 0 || gems > 0)
              Text(
                '${l10n.m3Reward}: ${formatNumber(cash)} Xu'
                '${gems > 0 ? ' + $gems 💎' : ''}',
                textAlign: TextAlign.center,
              )
            else if (stars > 0)
              Text(l10n.m3NoReward, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          if (canKeepPlaying)
            TextButton(
              onPressed: () {
                _keepPlaying = true;
                Navigator.of(dialogContext).pop();
              },
              child: Text(l10n.m3KeepPlaying),
            ),
          // Thêm nước bằng quảng cáo: chỉ khi ĐÃ HẾT nước thật (còn nước mà mời
          // thêm nước thì vô nghĩa), chưa dùng lượt nào và chưa đạt 3 sao.
          if (!canKeepPlaying && !play.adContinueUsed && stars < 3)
            TextButton(
              onPressed: () => _continueWithAd(dialogContext),
              child: Text(l10n.m3AdMoves(Balance.m3AdExtraMoves)),
            ),
          if (!canKeepPlaying)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.m3Retry),
            ),
          // Qua màn thì lối đi chính là MÀN SAU; nếu không có màn sau thì
          // "Tạm nghỉ" lên làm nút chính.
          if (hasNext) ...[
            TextButton(
              onPressed: () => _leave(dialogContext),
              child: Text(l10n.m3Pause),
            ),
            FilledButton(
              onPressed: () {
                _goingNext = true;
                Navigator.of(dialogContext).pop();
              },
              child: Text(l10n.m3Next),
            ),
          ] else
            FilledButton(
              onPressed: () => _leave(dialogContext),
              child: Text(l10n.m3Pause),
            ),
        ],
      ),
    );
    // `_leaving`: đã rời trang thì KHÔNG đụng gì nữa (xem ghi chú ở khai báo).
    if (!mounted || _leaving) return;
    // Sang màn sau: thay luôn trang hiện tại để bấm Back không quay lại từng
    // màn đã chơi, và KHÔNG nạp lại màn cũ.
    if (_goingNext) {
      _goingNext = false;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => Match3PlayPage(level: Match3Level(widget.level.id + 1)),
        ),
      );
      return;
    }
    // Chơi nốt / vừa cộng nước bằng quảng cáo: chơi tiếp bàn ĐANG DỞ, KHÔNG
    // nạp lại màn.
    if (_continuedWithAd || _keepPlaying) {
      _continuedWithAd = false;
      setState(() => _resultShown = false);
      return;
    }
    // Chơi lại từ đầu: mở lại cả lời mời "Chơi nốt" của lượt mới, không thì
    // lượt sau đạt mục tiêu sẽ không báo gì.
    _keepPlaying = false;
    setState(() => _resultShown = false);
    ref.read(match3ControllerProvider.notifier).load(widget.level);
  }

  /// Đóng bảng kết quả rồi rời trang chơi về lưới màn.
  void _leave(BuildContext dialogContext) {
    _leaving = true;
    Navigator.of(dialogContext).pop();
    Navigator.of(context).pop();
  }

  /// Xem quảng cáo thưởng để chơi tiếp. Người đã mua "Gỡ quảng cáo" (hoặc đang
  /// VIP) được cộng thẳng — cùng khuôn với mọi chỗ dùng rewarded khác trong app.
  Future<void> _continueWithAd(BuildContext dialogContext) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final adFree = ref.read(gameControllerProvider).adFree;
    final outcome = adFree
        ? RewardOutcome.earned
        : await ref.read(adServiceProvider).showRewardedAd();
    if (outcome != RewardOutcome.earned) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.adNotReadySnack)));
      return;
    }
    _continuedWithAd = true;
    ref.read(match3ControllerProvider.notifier).addMovesFromAd();
    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
  }
}

/// "Điểm: 1.2K" ở màn tính điểm, "🧋 7/12" ở màn thu thập.
String m3ProgressLabel(AppLocalizations l10n, Match3PlayState play) {
  if (play.level.goal == Match3GoalKind.collect) {
    return '${match3Icons[play.level.collectType]} '
        '${play.collected}/${play.level.target}';
  }
  return '${l10n.m3Score}: ${formatNumber(play.score.toDouble())}';
}

/// Đầu màn chơi: số nước còn lại + thanh tiến độ tới 3 mốc sao.
///
/// Thay cho ba dòng chữ trần trước đây — người chơi cần thấy NGAY mình đang
/// cách mốc sao kế tiếp bao xa, đó là thứ quyết định bấm "Chơi nốt" hay không.
class _Hud extends StatelessWidget {
  const _Hud({required this.play});

  final Match3PlayState play;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final level = play.level;
    final full = match3StarThreshold(level.target, 3);
    final ratio = full <= 0 ? 0.0 : (play.progress / full).clamp(0.0, 1.0);
    // Số nước sắp hết thì đổi màu cảnh báo — tín hiệu rẻ mà hiệu quả.
    final low = play.movesLeft <= 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: ClayCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          // min: nằm ngang thì HUD đứng cạnh bàn cờ, không được kéo cao hết
          // khung rồi chừa một khoảng trống to đùng.
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Expanded + ellipsis: chiếm hết chỗ trống nên chip số nước
                // luôn nằm sát mép phải, và điểm dài ở màn cao bị cắt bằng "..."
                // thay vì đẩy tràn hàng (lớp lỗi tràn số đã gặp nhiều lần).
                Expanded(
                  child: Text(
                    m3ProgressLabel(l10n, play),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                ClayChip(
                  color: low ? scheme.errorContainer : null,
                  child: Text(
                    l10n.m3MovesLeft(play.movesLeft),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: low ? scheme.onErrorContainer : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _StarBar(ratio: ratio, stars: play.stars, level: level),
          ],
        ),
      ),
    );
  }
}

/// Thanh tiến độ có 3 mốc sao đặt đúng vị trí tỉ lệ của chúng.
class _StarBar extends StatelessWidget {
  const _StarBar({
    required this.ratio,
    required this.stars,
    required this.level,
  });

  final double ratio;
  final int stars;
  final Match3Level level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final full = match3StarThreshold(level.target, 3);
    // Vị trí (0..1) của cả 3 mốc sao trên thanh. Mốc 3 sao = 1.0 nên nằm đúng
    // cuối thanh — tính chung công thức thay vì đặt riêng bằng `right: 0`.
    final marks = [
      for (final star in [1, 2, 3])
        full <= 0 ? 0.0 : match3StarThreshold(level.target, star) / full,
    ];

    return LayoutBuilder(builder: (context, box) {
      const barH = 14.0; // dày thanh
      const starS = 18.0; // cạnh ngôi sao
      return SizedBox(
        // Khung cao ĐÚNG bằng ngôi sao, thanh căn giữa khung: trước đây khung
        // cao 24, thanh căn giữa (tâm y=12) còn sao đặt top:-1 (tâm y=8) nên
        // sao lệch lên 4px so với thanh.
        height: starS,
        child: Stack(
          children: [
            Align(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(barH),
                child: SizedBox(
                  height: barH,
                  width: box.maxWidth,
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(scheme.primary),
                  ),
                ),
              ),
            ),
            for (var i = 0; i < marks.length; i++)
              Positioned(
                // Tâm ngôi sao rơi đúng vào vị trí mốc trên thanh.
                left: (box.maxWidth * marks[i] - starS / 2)
                    .clamp(0.0, box.maxWidth - starS),
                // top+bottom = 0: sao cao bằng khung nên tự nằm giữa, cùng trục
                // với thanh.
                top: 0,
                bottom: 0,
                child: Icon(
                  stars > i ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: starS,
                  color: stars > i ? Colors.amber.shade700 : scheme.outline,
                ),
              ),
          ],
        ),
      );
    });
  }
}
