/// Đường dẫn tất cả file animation. Thả file cùng tên vào `assets/anim/` là
/// game tự dùng — thiếu file thì tự bỏ qua (one-shot) hoặc về emoji (Mascot).
///
/// Xem `assets/anim/README.md` để biết từng file dùng ở đâu + từ khóa tải.
class AnimAssets {
  AnimAssets._();

  // --- Nhân vật lặp (dùng qua Mascot) — thiếu file thì về emoji ---
  static const String cup = 'assets/anim/bubbletea.json';
  static const String cat = 'assets/anim/cat.json';
  static const String car = 'assets/anim/car.json';

  // --- Hiệu ứng một lần (dùng qua playEffect) — thiếu file thì bỏ qua ---
  static const String coins = 'assets/anim/coins.json';
  static const String confetti = 'assets/anim/confetti.json';
  static const String celebration = 'assets/anim/celebration.json';
  static const String fireworks = 'assets/anim/fireworks.json';

  // --- Bộ thêm 2026-10-14 (chưa nối vào màn nào; xem PLAN_ANIMATION.md) ---
  static const String coinFly = 'assets/anim/coin_fly.json';
  static const String sparkle = 'assets/anim/sparkle.json';
  static const String levelUp = 'assets/anim/level_up.json';
  static const String gemBurst = 'assets/anim/gem_burst.json';
  static const String giftOpen = 'assets/anim/gift_open.json'; // 16:9, 5s
  static const String crown = 'assets/anim/crown.json'; // 60fps, 5.3s
  static const String steam = 'assets/anim/steam.json'; // cốc + hơi nước, lặp
  static const String customerWalking = 'assets/anim/customer_walking.json'; // 1080px, 60fps
  static const String customerWalking2 = 'assets/anim/customer_walking_2.json'; // người dắt chó (ảnh PNG)
  static const String customerWalking3 = 'assets/anim/customer_walking_3.json'; // doanh nhân xách cặp
}
