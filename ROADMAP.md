# ROADMAP — mở rộng & tối ưu (2026-09-28)

Ghi lại để làm tiếp, không cần khảo sát lại repo từ đầu. Xếp theo ROI, không
theo "thứ tự thấy hay". Cập nhật trạng thái tại chỗ (như `DOMAIN_TODO.md`).

## Nhận định trước khi làm

Game **không thiếu nội dung**: 18 giai đoạn, 36 nguồn thu, 28 chương, Kỷ Nguyên,
Đấu Trường 2 dạng, mini-game đơn hàng, 4 bảng xếp hạng, cloud save, 6 ngôn ngữ.
Nhưng `analytics_events` chỉ có **2 device** — gần như toàn bộ là máy dev.

⇒ Đợt mở rộng thứ 3 (GĐ19+, chương 29+) là việc **giá trị thấp nhất** hiện giờ,
và còn đụng trần: GĐ18 ở cấp 1000 đã ~1e80, `Balance.economyOverflowGuardCap`
là 1e100 → thêm 6 giai đoạn ×100/bậc là chạm trần, phải đổi công thức chứ không
chỉ thêm data. Ưu tiên phải là: **giữ người chơi quay lại** + **tune được số mà
không cần nộp store**.

---

## P0 — Tối ưu, diff nhỏ ✅ XONG 2026-09-28

| # | Việc | Verify |
|---|---|---|
| 1 | ✅ **Cold start bị chặn bởi AdMob.** `main.dart:69` `await AdBootstrap.initialize()` chạy TRƯỚC `runApp`, bên trong nó `await _gatherConsent()` → `loadAndShowConsentFormIfRequired`. Người EEA thấy màn hình trắng tới khi bấm xong form consent; ngoài EEA vẫn ăn 1 round-trip mạng. Sửa: `unawaited()` sau `runApp`, `RealAdService` chờ cờ ready. | Đo time-to-first-frame trước/sau (`flutter run --profile`, hoặc log timestamp ở `main` và `HomePage.initState`) |
| 2 | ✅ **`ShaderMask` bọc cả shop list** (`home_page.dart:1113`) → `saveLayer` mỗi frame khi cuộn, gần như luôn bật từ GĐ3 trở lên. Thay bằng gradient overlay tĩnh (`Stack` + `IgnorePointer`). | DevTools raster time khi cuộn shop, máy Android yếu |
| 3 | ✅ `ListView(children: tiles)` → `ListView.builder` (`home_page.dart:1108`). 36 tile hiện dựng eager mỗi lần shop rebuild. | `flutter test` xanh, cuộn thấy không đổi |
| 4 | ✅ Dọn `assets/plan-update/` (rỗng) + `README.md` còn là template Flutter mặc định | — |

Cách sửa #1: `AdBootstrap.initialize()` không await nữa; Future của nó truyền
vào `RealAdService(ready:)`, `_load()` await nó trước khi gọi `RewardedAd.load`
(load trước khi SDK init sẽ thất bại). #2 dùng `Stack` + gradient `canvasColor`
(chính là màu `Material` bọc ngoài vẽ) thay cho `ShaderMask`.

**Đã kiểm, KHÔNG phải vấn đề — đừng tối ưu:** app size (assets bundle chỉ ~2,3MB;
12MB `assets/store` không khai báo trong pubspec nên không vào app), autosave
(1 `jsonEncode`/10s), tick 1s + `.select()` đã lọc rebuild tốt (33 chỗ `.select`
trên 28 `ref.watch` trong `home_page.dart`).

## P1 — Mở khoá việc tune ✅ #5, #6 XONG 2026-09-28 (#7 chờ bạn)

| # | Việc | Lý do |
|---|---|---|
| 5 | ✅ **Firebase Remote Config** override ~8 hằng số nóng trong `balance.dart` (`milestoneStep`, `prestigeK`, `bonusPerStar`, spawn rate mèo/VIP/đơn hàng, reward 💎/ngày) | Backlog #3/#12 "cần playtest" đứng im nhiều tuần vì mỗi lần đổi số = nộp store + chờ review iOS. Firebase đã init sẵn (Crashlytics) → chỉ thêm 1 dep + 1 hàm `Balance.hot(key, default)` |
| 6 | ✅ **Thông báo local** (`flutter_local_notifications`): trần offline đã đầy · vòng quay free reset · nhiệm vụ ngày mới | Hiện **không có** kênh kéo người chơi về (pubspec không có dep thông báo nào). Với idle game đây là đòn retention lớn nhất, và không cần thêm nội dung nào |
| 7 | ⏳ Xong 5 bước còn lại trong `DOMAIN_TODO.md` (DNS Namecheap + GitHub Pages) | Landing page đã dựng mà domain chưa trỏ |

**Còn phải làm bằng tay để #5 có tác dụng:** dán `remote_config_template.json`
vào Firebase Console (Remote Config → *Edit as JSON*) — các bước ở `SETUP.md`
§2b. Chưa làm thì app vẫn chạy bằng số biên dịch sẵn.

**Chưa kiểm được trong máy:** thông báo lúc NỔ thật (alarm không chính xác có
cửa sổ ±1h; máy ảo Google Play không root được để tua đồng hồ). Đã kiểm: lịch
vào đúng AlarmManager qua receiver của plugin, đúng mốc giờ, quyền xin được.

## Ngoài kế hoạch — Hành trình Ghép 3 ✅ XONG 2026-09-28

Yêu cầu trực tiếp của người dùng (dạng Ghép 3 khá ăn khách): tab thứ 5, 60 màn
chơi đơn, banner quảng cáo trong lúc chơi. Thiết kế: `PROPOSAL_MATCH3_LEVELS.md`,
tóm tắt vận hành: `GAME_DESIGN.md` §23.

Kéo theo: mục **#9 dưới đây (tự xáo khi hết nước) vẫn CÒN** cho Đấu Trường —
xáo bàn đã viết nhưng chỉ chơi đơn dùng được, PvP cần viết cùng logic trong
`arena_m3_replay` (SQL) mới dùng được.

Việc tay trên AdMob console: ✅ xong 2026-09-28 — Banner ad unit đã tạo cho cả
2 nền tảng và điền vào `lib/ads/ad_config.dart`; tần suất làm mới để mặc định
60 giây (xem lý do ở SETUP.md §1). Không còn việc gì phải bấm.

## P2 — Mở rộng, sau khi P1 có số liệu

| # | Việc | Ghi chú |
|---|---|---|
| 8 | **Art cảnh cho GĐ7-18** — cả 12 giai đoạn đang dùng lại `stage6.png` (§17 GAME_DESIGN) | Người chơi tới GĐ7+ thấy "hết game" về mặt hình ảnh. Có `scripts/make_scenes.py` rồi → rẻ nhất nhóm này |
| 9 | Đấu Trường Ghép 3: **tự xáo khi hết nước đi** (giờ chỉ báo "Hết nước đi!" rồi kẹt tới hết 60s) | Lỗ UX thật, không phải tính năng thêm. Kẹo đặc biệt / xem bảng đối thủ để sau |
| 10 | **Bảng xếp hạng tỉ lệ thắng Đấu Trường** | `arena_matches.winner` đã verify server-side → gần như chỉ là 1 view SQL + 1 tab |
| 11 | **Sự kiện giới hạn thời gian** (cuối tuần ×2, mùa lễ) qua Remote Config ở #5 | Vòng lặp retention tái sử dụng mãi, không phải sản xuất nội dung mới mỗi đợt |
| 12 | ~~Đợt mở rộng 3 (GĐ19+, chương 29+)~~ | **Hoãn**: chạm trần `economyOverflowGuardCap` (1e100) + nội dung mới vô nghĩa khi funnel chưa có ai |

---

Gate trước mỗi lần ship: `flutter analyze` sạch + `flutter test` (60 file test) xanh.
