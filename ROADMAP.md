# ROADMAP — mở rộng & tối ưu (cập nhật 2026-09-29)

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

**Còn phải làm bằng tay để #5 có tác dụng:** tạo tham số `boba_remote_config`
kiểu JSON trên Firebase Console và dán `remote_config_template.json` vào —
các bước ở `SETUP.md` §2b. Chưa làm thì app vẫn chạy bằng số biên dịch sẵn.

**Chưa kiểm được trong máy:** thông báo lúc NỔ thật (alarm không chính xác có
cửa sổ ±1h; máy ảo Google Play không root được để tua đồng hồ). Đã kiểm: lịch
vào đúng AlarmManager qua receiver của plugin, đúng mốc giờ, quyền xin được.

## Ngoài kế hoạch — Hành trình Trân Châu Rơi (Ghép 3) ✅ XONG 2026-09-28

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
| 8 | ✅ **Art cảnh cho GĐ7-18** (xong 2026-09-28) — cả 12 giai đoạn đang dùng lại `stage6.png` (§17 GAME_DESIGN) | Người chơi tới GĐ7+ thấy "hết game" về mặt hình ảnh. Có `scripts/make_scenes.py` rồi → rẻ nhất nhóm này |
| 9 | ✅ **Tự xáo khi hết nước đi** (xong 2026-09-28) | Làm ở cả Dart lẫn SQL, có vector vàng khoá. NHƯNG đo được: 600k nước không lần nào bàn bí — đây là lưới an toàn, không phải lỗ UX hay gặp như ghi chú ban đầu |
| 10 | **Bảng xếp hạng tỉ lệ thắng Đấu Trường** | `arena_matches.winner` đã verify server-side → gần như chỉ là 1 view SQL + 1 tab |
| 11 | ✅ **Sự kiện giới hạn thời gian** (cuối tuần ×2, mùa lễ) qua Remote Config ở #5 — xong 2026-09-29 (`eventIncomeMult`/`eventStartMillis`/`eventEndMillis`, tự tắt hết cửa sổ) | Vòng lặp retention tái sử dụng mãi, không phải sản xuất nội dung mới mỗi đợt |
| 12 | ~~Đợt mở rộng 3 (GĐ19+, chương 29+)~~ | **Hoãn**: chạm trần `economyOverflowGuardCap` (1e100) + nội dung mới vô nghĩa khi funnel chưa có ai |

**Cũng đã xong 2026-09-29, ngoài bảng trên:** mở rộng #6 (thông báo local) thêm 2
mốc D3/D7 (vắng 3/7 ngày) — trước đó lịch chỉ phủ ~24-30h, rời app quá 1 ngày là
không bao giờ nhận thêm thông báo. Cả #6 mở rộng lẫn #11 nằm trong 1.0.4+7, đang
chờ Apple duyệt — số liệu hoạt động ở P3 dưới đây CHƯA phản ánh hai thứ này.

---

## P3 — Thu hút người chơi + Tăng lợi nhuận (2026-09-29)

### Nhận định (số liệu thật, Supabase + iTunes lookup, đo hôm nay)

- **1255 người chơi tổng**, hoạt động đang **giảm dần**: 277→235→191→174→123
  (25→29/09, đơn vị "mở bảng xếp hạng chính/ngày" — proxy DAU, không phải DAU
  thật).
- **iOS-only**: App Store đang live `1.0.3`; Play Store `play.google.com/.../
  com.pcingame.bobaempire` trả **404** — chưa từng publish, kể cả ở dạng
  closed testing.
- **IAP:** iOS đã tạo đủ 8 product (2026-09-29, user tự làm) — ⚠️ chưa xác
  nhận giá theo vùng/Sandbox test. **Android vẫn chưa có gì** (đợi Play
  publish). Trước hôm nay: doanh thu = 100% quảng cáo; giờ iOS CÓ THỂ đã bán
  được, nhưng `real_iap_service.dart` vẫn dùng `NoopReceiptVerifier`
  (client-only) — xác thực server-side càng cấp thiết hơn từ lúc này.
- `1.0.4` (D3/D7, sự kiện giới hạn thời gian, vá trần Sao int64) đang chờ Apple
  duyệt — số hoạt động ở trên chưa phản ánh được tác dụng của hai đòn bẩy
  retention lớn nhất vừa ship.
- Trân Châu Rơi: 1 người từng mở bảng xếp hạng. Đấu Trường: 0 trận xác nhận
  được qua REST (RLS chỉ cho thấy trận của chính mình). Còn quá sớm để kết
  luận đây là lỗ hổng UX hay đơn giản là chưa đủ người biết.

⇒ Đòn bẩy lớn nhất lúc này **không phải thêm tính năng** — là mở hai vòi đang
**tắt hẳn**: bán được hàng (IAP) và tiếp cận được nửa thị trường còn lại
(Android). Thêm nội dung mới lúc doanh thu = 0 và phân phối = 1 nền tảng là
tối ưu sai chỗ.

### Việc PHẢI làm trên console — tôi không có quyền, chỉ hỗ trợ số liệu/format

| # | Việc | Vì sao ưu tiên nhất |
|---|---|---|
| 13a | ✅ Tạo đủ 8 product IAP trên **App Store Connect** (iOS) — user xong 2026-09-29 | — |
| 13b | 🔴 Tạo đủ 8 product IAP trên **Play Console** (Android) | Đợi #15 (Play chưa publish thì chưa tạo được product) |
| 14 | 🔴 Giá theo vùng (hạ 20-40% cho ID/BR/TH/VN) — số gợi ý cụ thể có sẵn ở SETUP.md §"Giá đề xuất", chỉ cần điền. **Chưa xác nhận đã bật cho iOS chưa** | Không làm thì mất chuyển đổi đúng ở các thị trường game đang có người chơi thật (nickname trong leaderboard áp đảo tiếng Việt) |
| 15 | 🔴 Publish **Google Play** (tài khoản dev $25 một lần + qua review) | Android áp đảo thị phần ở VN — bỏ Android là bỏ phần lớn nhất của chính thị trường mục tiêu game đang nhắm tới |
| 16 | 🟡 Sandbox tester (iOS) — mua thử không mất tiền trước khi để người dùng thật mua. **Chưa xác nhận đã test chưa** | Lỡ tự mua bằng tiền thật lúc test là tốn oan |

### Việc tôi làm được ngay, không cần đợi bạn

| # | Việc | Vì sao |
|---|---|---|
| 17 | ✅ **XÁC THỰC THẬT ĐÃ CHẠY 2026-09-30**: server cục bộ `VERIFY_MODE=prod` (khoá App Store Server API thật) + đường hầm cloudflared + app thật mua Sandbox — 6/6 yêu cầu thành công, 💎 cộng đúng, App Store Server API xác nhận hoạt động đúng với StoreKit 2. ⏳ Còn deploy lên hạ tầng thật + Play + Supabase replay store trước khi bật cho bản phát hành, xem RELEASE_CHECKLIST §4 | Phát hiện quan trọng lúc viết code: `verifyReceipt` cũ đã BỊ HỎNG với bản plugin hiện tại (gửi JWS StoreKit 2, không phải base64 receipt) — không phải "sắp lỗi thời" như README cũ ghi |
| 18 | Điều tra Đấu Trường 0 trận / Trân Châu Rơi 1 người — treo từ phiên trước | Cần biết là do KHÁM PHÁ (không ai biết tồn tại) hay HỨNG THÚ (biết mà không thích) trước khi quyết định đầu tư thêm hay dừng |
| 19 | Đo lại đường cong hoạt động ~2 tuần sau khi `1.0.4` lên (mốc so sánh: đường cong hiện tại 277→123) | Chưa có số liệu thật về hiệu quả D3/D7 + sự kiện giới hạn thời gian — hai thứ tốn công nhất vừa ship |

### KHÔNG nên làm lúc này

- Thêm nội dung mới (GĐ19+, nguồn thu mới theo trend...) — lý do ở đầu file vẫn
  đúng, giờ càng rõ hơn: đến IAP còn chưa tồn tại thì thêm nội dung không phải
  nút thắt.
- Quảng cáo trả phí (TikTok/Facebook Ads) trước khi Play Store sống — một nửa
  lưu lượng trả tiền sẽ đổ vào một cửa hàng không tồn tại.

---

Gate trước mỗi lần ship: `flutter analyze` sạch + `flutter test` (60+ file test) xanh.
