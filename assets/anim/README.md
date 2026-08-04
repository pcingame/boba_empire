# Animation Lottie cho nhân vật

Thả file `.json` (Lottie) vào thư mục này để thay emoji bằng animation.

Tên file mà game sẽ tự tìm (chưa có thì dùng emoji fallback):

| File | Nhân vật | Emoji fallback |
|------|----------|----------------|
| `cup.json` | Ly trà sữa (nút "Chạm pha trà") | 🧋 |

Sau khi thêm file: chạy `flutter pub get` rồi hot **restart** (không phải hot reload).

## Nguồn asset free
- https://lottiefiles.com/free-animations/bubble-tea
- License: Lottie Simple License — được dùng thương mại, không bắt buộc ghi công.

Xem `lib/ui/widgets/mascot.dart` để biết cách thêm nhân vật mới.
