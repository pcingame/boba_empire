/// Hướng dẫn lần đầu kiểu tương tác (chỉ tay ngay trên màn chơi) thay cho hộp
/// thoại chữ. Bước được SUY RA từ trạng thái game nên không cần lưu thêm gì ngoài
/// `tutorialSeen`: tắt app giữa chừng thì mở lại hướng dẫn tiếp đúng chỗ.
library;

enum TutorialStep {
  /// Không hiện (đã xem/bỏ qua).
  none,

  /// Chạm cốc để kiếm Xu cho tới khi đủ tiền mua nâng cấp đầu tiên.
  tap,

  /// Đủ tiền: chỉ vào nút mua của nguồn thu đầu tiên.
  buy,

  /// Đã mua: giải thích Xu tự chảy mỗi giây, chờ người chơi bấm "Đã hiểu".
  explain,
}

/// [firstLevel] = cấp của nguồn thu đầu tiên, [canAffordFirst] = đủ tiền mua 1 cấp.
TutorialStep tutorialStepFor({
  required bool seen,
  required int firstLevel,
  required bool canAffordFirst,
}) {
  if (seen) return TutorialStep.none;
  if (firstLevel > 0) return TutorialStep.explain;
  return canAffordFirst ? TutorialStep.buy : TutorialStep.tap;
}
