# Đế Chế Trà Sữa (boba_empire)

Game idle/clicker xây chuỗi trà sữa, viết bằng Flutter. Android · iOS
(desktop/web chạy được để phát triển, quảng cáo & IAP dùng stub).

<https://bobaempiregame.com>

## Chạy

```sh
flutter pub get
flutter run
flutter test        # 470 test, không cần thiết bị
flutter analyze
```

## Tài liệu

| File | Nội dung |
|---|---|
| `GAME_DESIGN.md` | Tài liệu gốc về vòng lặp, kinh tế, mọi hệ thống — đọc trước khi tune số |
| `ROADMAP.md` | Việc tiếp theo, xếp theo ROI |
| `SETUP.md` | Cấu hình AdMob / IAP thật trước khi phát hành |
| `RELEASE_CHECKLIST.md`, `IOS_APP_STORE_CHECKLIST.md` | Quy trình nộp store |
| `PROPOSAL_*.md` | Thiết kế của Đấu Trường, cloud save, bảng xếp hạng, analytics |
| `supabase/*.sql` | Schema backend (chạy tay trên Supabase SQL Editor) |

## Cấu trúc `lib/`

```
core/     hàm thuần, không Flutter — balance.dart giữ TẤT CẢ con số
state/    cầu Riverpod: GameController (tick 1s) → GameSnapshot bất biến
ui/       màn hình & dialog; home_page.dart là màn chính
ads/ iap/ audio/     interface trừu tượng + impl thật (stub trên desktop/web)
arena/ leaderboard/ data/   tính năng có backend Supabase
l10n/     6 ngôn ngữ (vi/en/es/id/pt/th), sinh từ ARB
```
