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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.m3Level(widget.level.id))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Mỗi ô bọc Flexible + ellipsis: số điểm lớn ở màn cao không
                // đẩy tràn hàng (lớp lỗi tràn số đã gặp nhiều lần trong app).
                Flexible(
                  child: Text(
                    '${l10n.m3Score}: ${formatNumber(play.score.toDouble())}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.m3Target(
                      formatNumber(widget.level.target.toDouble()),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.m3MovesLeft(play.movesLeft),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Match3Panel(
                view: Match3View(
                  cells: play.cells,
                  frames: play.frames,
                  moveId: play.moveId,
                  finished: play.finished,
                ),
                onSwap: controller.swap,
              ),
            ),
          ),
          const BannerAdBox(),
        ],
      ),
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
            Text(
              '★' * stars + '☆' * (3 - stars),
              style: const TextStyle(fontSize: 28, color: Colors.amber),
            ),
            const SizedBox(height: 8),
            Text('${l10n.m3Score}: ${formatNumber(play.score.toDouble())}'),
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
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
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
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: Text(l10n.m3Pause),
            ),
        ],
      ),
    );
    if (!mounted) return;
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
