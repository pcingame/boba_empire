/// Ảnh chụp BẤT BIẾN của trạng thái game để phát cho tầng UI.
///
/// Controller phát một snapshot mới sau mỗi thay đổi; widget dùng
/// `ref.watch(gameControllerProvider.select((s) => s.money))` để chỉ rebuild
/// đúng phần dữ liệu mình quan tâm (mục tối ưu Riverpod).
library;

class GameSnapshot {
  const GameSnapshot({
    required this.money,
    required this.gems,
    required this.incomePerSecond,
    required this.prestigeStars,
    required this.prestigeStarsAvailable,
    required this.offlineEarned,
    required this.catVisible,
    required this.boostRemainingSeconds,
    required this.vipVisible,
    required this.gemBoostLevel,
    required this.offlineCapLevel,
    required Map<String, int> levels,
  }) : _levels = levels;

  final double money;
  final double gems;

  /// Số Xu vừa kiếm lúc vắng mặt, >0 khi cần bật popup; UI gọi
  /// `acknowledgeOffline()` để về 0 sau khi đã hiển thị.
  final double offlineEarned;

  /// Thu nhập tự động mỗi giây (đã tính bonus prestige) — để hiển thị "+X/s".
  final double incomePerSecond;

  final int prestigeStars;

  /// Số Sao sẽ nhận nếu prestige ngay bây giờ (để bật/mờ nút Nhượng quyền).
  final int prestigeStarsAvailable;

  /// Con mèo Mưa vàng đang hiện trên màn hình hay không.
  final bool catVisible;

  /// Số giây còn lại của boost Mưa vàng (0 nếu không có) — để hiện đồng hồ ×3.
  final double boostRemainingSeconds;

  /// Khách VIP đang đứng chờ trên màn hình hay không.
  final bool vipVisible;

  /// Cấp vật phẩm Kim Cương "Tăng thu nhập" / "Kho lạnh offline".
  final int gemBoostLevel;
  final int offlineCapLevel;

  final Map<String, int> _levels;

  /// Cấp hiện tại của một nguồn thu. Trả `int` nên `.select` so sánh được,
  /// và không lộ map ra ngoài để tránh mutate ngoài ý muốn.
  int levelOf(String id) => _levels[id] ?? 0;
}
