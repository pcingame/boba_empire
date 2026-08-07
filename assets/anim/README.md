# Animation Lottie cho game

Thả file `.json` (Lottie) đúng tên vào thư mục này là game tự dùng.
Chưa có file → tự bỏ qua (hiệu ứng) hoặc về emoji (nhân vật). Không phải sửa code.

Sau khi thêm file: `flutter pub get` rồi hot **restart** (không phải hot reload).

## Nhân vật (lặp — thiếu file thì về emoji)

| File | Chỗ dùng | Emoji | Từ khóa LottieFiles |
|------|----------|-------|---------------------|
| `bubbletea.json` | Ly "Chạm pha trà" | 🧋 | `bubble tea`, `boba` |
| `cat.json` | Mèo Mưa vàng | 🐱 | `lucky cat`, `maneki neko`, `waving cat` |
| `car.json` | Khách VIP | 🚗 | `luxury car`, `sports car` |

## Hiệu ứng một lần (thiếu file thì bỏ qua, không lỗi)

| File | Kích hoạt khi | Từ khóa LottieFiles |
|------|---------------|---------------------|
| `coins.json` | Chạm pha trà | `coins`, `coin burst`, `gold coins` |
| `confetti.json` | Mua nâng cấp | `confetti`, `success`, `party popper` |
| `celebration.json` | Mở khóa giai đoạn | `grand opening`, `celebration`, `level up` |
| `fireworks.json` | Nhượng quyền (prestige) | `fireworks`, `star burst` |

## Nguồn & license
- https://lottiefiles.com/free-animations/ (search từ khóa ở trên)
- **Lottie Simple License** (bản free): dùng thương mại OK, không bắt buộc ghi công.
- Ưu tiên file nhẹ (< ~300KB) nếu hiển thị nhiều cái cùng lúc.

## Code liên quan
- Nhân vật lặp: `lib/ui/widgets/mascot.dart` (+ đường dẫn ở `anim_assets.dart`)
- Hiệu ứng một lần: `lib/ui/widgets/one_shot_lottie.dart` — gọi `playEffect(context, AnimAssets.xxx)`
