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
}
