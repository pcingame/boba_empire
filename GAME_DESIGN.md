# GAME_DESIGN — Đế Chế Trà Sữa (boba_empire)

Tài liệu thiết kế: mô tả **flow** và **kịch bản** game, đối chiếu với code hiện tại
(`lib/core`, `lib/state`, `lib/ui`). Mọi con số lấy từ `lib/core/balance.dart`.

- Thể loại: **Idle / Incremental / Tycoon-clicker**, chủ đề trà sữa.
- Nền tảng: Flutter (Android/iOS chính; desktop/web chạy được nhưng tắt Ads/IAP).
- Ngôn ngữ: 6 (vi, en, es, id, pt, th).
- Đối tượng: General 13+ (không child-directed).

---

## 1. Vòng lặp cốt lõi (core loop)

```
        ┌─────────────────────────────────────────────┐
        │                                             │
        ▼                                             │
   CHẠM LY  ──►  +Xu   ──►  MUA NÂNG CẤP nguồn thu     │
 (tapCup)          │         (buy)                     │
                   │           │                       │
                   │           ▼                       │
                   │     +Thu nhập/giây  ──►  tích Xu ──┘
                   │     (tick mỗi 1s, cả khi offline có cap)
                   │
                   ├──►  đủ Xu  ──►  MỞ GIAI ĐOẠN mới (unlockStage)
                   │                 → thêm 1–3 nguồn thu, đổi cảnh + tông màu
                   │
                   └──►  lifetimeEarnings tăng  ──►  NHƯỢNG QUYỀN (prestige)
                                                     → +Sao ⭐ (+2%/sao vĩnh viễn)
                                                     → reset tiền + cấp, giữ giai đoạn
```

**Nhịp phụ (retention / monetization):**

| Hệ thống | Chu kỳ | Thưởng |
|---|---|---|
| Nhiệm vụ (chuỗi 10 bước) | một lần | Kim Cương 💎 |
| Thành tựu (11 mốc) | một lần | 💎 |
| Điểm danh hằng ngày | mỗi ngày, streak 7 | 💎 (10→60) |
| Vòng quay may mắn | 1 free/ngày + xem QC | Xu / 💎 / x2-24h |
| Mèo Mưa vàng 🐱 | 3–5 phút | Golden Rush ×3 trong 2 phút |
| Khách VIP 🚗 | 4–7 phút | Xu lớn + 1–3 💎 |
| Quảng cáo thưởng 🎁 | tùy người chơi | x2-24h / 💎 / tua nhanh / tiền tức thì |

---

## 2. Tiền tệ

| | Ký hiệu | Nguồn thu | Chỗ tiêu |
|---|---|---|---|
| **Xu** | 🪙 | chạm ly, thu nhập/giây, offline, VIP, wheel, QC | nâng nguồn thu, mở giai đoạn |
| **Kim Cương** | 💎 | nhiệm vụ, thành tựu, điểm danh, VIP, wheel, heo đất, QC, IAP | Cửa hàng 💎, (không mua Xu) |
| **Sao nhượng quyền** | ⭐ | prestige (theo `√lifetimeEarnings`) | passive +2%/sao **và** Kho Sao (perk vĩnh viễn) |

`Xu`/`Kim Cương` là `double` để không tràn ở số lớn; hiển thị rút gọn `K/M/B/T/aa…`
(`lib/core/format.dart`).

---

## 3. Nguồn thu & nâng cấp

Mỗi nguồn thu (`GeneratorConfig`) có: `baseCost`, `costGrowth = 1.15`,
`incomePerLevelPerSecond`, `stage` (giai đoạn mở khóa).

- **Giá nâng cấp**: `cost(L) = baseCost · 1.15^L`
- **Thu nhập/giây của 1 nguồn**: `incomePerLevel · L · milestone(L)`
- **Mốc nhân bội (milestone)** — 2 hiệu ứng mỗi mốc (25 cấp):
  1. **Cục bộ**: nguồn đó **×2** thu nhập (L25 →×2, L50 →×4, L75 →×8…).
     Cấp 0–24 = ×1 (không đổi cân bằng đầu game).
  2. **"Mốc vàng" (toàn cục)**: từ **mốc thứ 2** (L50) trở đi, MỖI mốc bất kỳ
     nguồn thu đạt cộng **+3%** vào hệ số thu nhập **toàn cục** (cộng dồn, vĩnh
     viễn — kể cả sau prestige nếu vẫn còn cấp đó… thực ra prestige xoá cấp nên
     phải cày lại). Hiện ở chip `🌐 +X%` trên `_StageHeader`; `_MilestoneBar`
     đánh dấu `🌐` khi mốc kế đóng góp toàn cục.
  → Milestone giờ là trục tối ưu thật: dồn 1 nguồn tới L50/75/100 vừa ×2 cục bộ
  vừa +% mọi nguồn.
- UI gợi ý **"đáng mua nhất"** = nguồn có `thu nhập thêm / giá` cao nhất (viền + ⭐).

**Hệ số nhân toàn cục** (áp lên tổng thu nhập tự động):

```
income/s = Σ(nguồn) × (1 + mốc_vàng·0.03)      ← "Mốc vàng" (mục trên)
                     × (1 + sao·0.02)          ← prestige passive
                     × (1 + gemBoostLv·0.10)   ← Cửa hàng 💎 "Tăng thu nhập"
                     × (1 + prestigeIncomeLv·0.25) ← Kho Sao "Siêu thu nhập"
                     × (doubleIncomeOwned ? 2 : 1)  ← IAP x2 vĩnh viễn
                     × boost                    ← Golden Rush ×3 / x2-24h / VIP ×2
```

**12 nguồn thu / 6 giai đoạn:**

| Giai đoạn | Mở khóa (Xu) | Nguồn thu (base cost, thu nhập/cấp/giây) |
|---|---:|---|
| 1 — Xe đẩy vỉa hè | 0 | Trà đen (15, 0.5) |
| 2 — Kiosk cửa hàng nhỏ | 2 000 | Trân châu (100, 4) · Thạch (330, 14) · Pudding (1 100, 45) |
| 3 — Chuỗi cafe sang trọng | 500 000 | Trà sữa kem nướng (4 000, 160) · Matcha xô (12 000, 500) |
| 4 — Xưởng trà sữa nướng | 50 000 000 | Sữa tươi đường đen (40 000, 1 600) · Trà sữa nướng (130 000, 5 000) |
| 5 — Nhà máy phô mai tươi | 5 000 000 000 | Kem phô mai (430 000, 16 000) · Trà trái cây (1 400 000, 50 000) |
| 6 — Đế chế toàn cầu | 500 000 000 000 | Boba vàng (4 600 000, 160 000) · Trà sữa ngân hà (15 000 000, 520 000) |

Mở giai đoạn = trừ Xu, `stage++`, đổi ảnh nền + tông màu theme, thêm các nguồn thu
mới vào shop. Bố cục màn chính chia theo flex (cảnh quán 42 / shop 58 phần chỗ
còn lại) nên shop chỉ thêm dòng & tự cuộn — không "ăn" chỗ của cảnh quán.

---

## 4. Chạm ly (tap)

- `tapValue = 1` cố định. Mỗi chạm: `1 × (1+sao·0.02) × (1+gemBoostLv·0.10) ×
  (1 + prestigeTapLv·1.0) × boost`.
- Có hiệu ứng squish + bật, haptic, số "+X" bay lên, **COMBO ×N** khi chạm liên tục.
- Vai trò: đáng kể **đầu game** và trong **cửa sổ Golden Rush**; sau đó thu nhập
  tự động lấn át (trừ khi mua nhiều cấp "Siêu chạm").

---

## 5. Nhượng quyền (Prestige)

- **Sao khi prestige**: `stars_total = floor(0.05 · √lifetimeEarnings)`.
  `lifetimeEarnings` **không bao giờ reset** → chỉ tăng dần; số Sao **nhận thêm** =
  `stars_total − prestigeStars` hiện có.

  | lifetime | Sao tích lũy |
  |---:|---:|
  | 400 | 1 |
  | 10 000 | 5 |
  | 40 000 | 10 |
  | 1 000 000 | 50 |
  | 4 000 000 | 100 (= +200% income) |
  | 100 000 000 | 500 |

- **Khi prestige** (`prestige()` trong `simulation.dart`) — **hard reset**:
  - **Reset**: `money`, `levels`, **`stage` về 1** (trừ perk "Giữ giai đoạn").
  - **Giữ**: `prestigeStars`, `lifetimeEarnings`, `gemBoostLevel`,
    `offlineCapLevel`, cấp perk kho Sao, IAP, `questIndex`, `tapCount`,
    `buyCount`, thành tựu, **cốt truyện** (`storyChapter`, `storyChoiceA/B`,
    `rivalDefeated`, `rivalPressureSeconds` — xem §16).
  - → Mỗi vòng **tái trải nghiệm mở giai đoạn**; re-climb nhanh nhờ +2%/sao +
    perk kho Sao (giảm giá, vốn khởi nghiệp, giữ giai đoạn).

- **Kho Sao** (tiêu ⭐ mua perk vĩnh viễn — `spendable = tổng Sao − đã tiêu`;
  không đụng accounting prestige nên "tiêu rồi prestige" không lấy lại được).
  Giá cấp = `base · 2^cấp` Sao:

  | Perk | Hiệu ứng | base |
  |---|---|---:|
  | **Siêu thu nhập** | +25% thu nhập tự động / cấp | 3 |
  | **Siêu chạm** | +100% giá trị chạm / cấp | 5 |
  | **Siêu offline** | +25% thu nhập lúc vắng / cấp | 3 |
  | **Vốn khởi nghiệp** | sau prestige nhận Xu = `50 · 25^cấp` | 4 |
  | **Mua sỉ** | −3% giá nâng cấp mọi nguồn thu / cấp (sàn ×0.4) | 5 |
  | **Giữ giai đoạn** | sau prestige giữ tới GĐ `1 + cấp` (tối đa 5 cấp) | 8 |
  | **Tự động mua** | mở khoá công tắc auto-buy nguồn "đáng mua nhất" (1 cấp) | 12 |

---

## 6. Cửa hàng Kim Cương

Mở từ tab **"Cửa hàng"** ở thanh dưới.

**Nâng cấp** (giá `base · 2^cấp`):

| Vật phẩm | Hiệu ứng | Giá cấp đầu |
|---|---|---:|
| **Tăng thu nhập** | +10% thu nhập tự động vĩnh viễn / cấp | 5 💎 |
| **Kho lạnh offline** | +2 giờ trần tiền offline / cấp | 10 💎 |

**Hành động** (dùng ngay, lặp lại — sink 💎 chính):

| Vật phẩm | Hiệu ứng | Giá |
|---|---|---:|
| **Mở giai đoạn tức thì** | mở giai đoạn kế **bỏ qua chi phí Xu** | 40 / 120 / 300 / 700 / 1500 💎 (GĐ 2→6) |
| **Tua nhanh 💎** | +4 giờ sản xuất ngay, không cần xem QC | 30 💎 |

Dialog này cũng liệt kê các **gói IAP** (mục 11) + nút "Khôi phục mua hàng".

---

## 7. Sự kiện thời gian thực

| | Xuất hiện | Chờ | Cách nhận | Thưởng |
|---|---|---|---|---|
| **Mèo Mưa vàng 🐱** | mỗi 3–5 phút (ngẫu nhiên) | 12 s | chạm mèo | **Golden Rush ×3** toàn bộ thu nhập trong **2 phút** |
| **Khách VIP 🚗** | mỗi 4–7 phút | 15 s | chạm xe | **Xu** = max(60 s sản xuất, 10× tapValue) + **1–3 💎** — không cần xem QC |

Trạng thái mèo/VIP là **runtime, không persist** — thoát app giữa Golden Rush thì mất boost.

---

## 8. Thu nhập offline

- App tắt → khi mở lại, `applyOfflineEarnings` cộng `income/s × min(Δt, cap)`.
- **Cap**: `8 giờ` (base) `+ 2h/cấp Kho lạnh` `+ 4h nếu đang VIP`.
- **Chống lùi giờ**: `Δt ≤ 0` → cộng 0, chỉ cập nhật mốc.
- Popup "Bạn kiếm được X khi vắng mặt" → có nút **xem QC nhân đôi** (`claimDoubleOffline`).
- Offline áp: hệ số vĩnh viễn (sao, gemBoost, prestigeIncome, IAP x2) **+ perk
  "Siêu offline" (+25%/cấp) + VIP ×2 nếu còn hạn**. Không áp boost tạm thời
  (Golden Rush ×3, x2-24h QC) — đó là thưởng cho lúc chơi.

---

## 9. Nhiệm vụ · Thành tựu · Điểm danh · Vòng quay

### Nhiệm vụ (chuỗi tuyến tính, `lib/core/quests.dart`)

Làm lần lượt, thanh nhiệm vụ ở đầu panel shop. Xong chuỗi 10 bước → chuyển sang
**chuỗi lặp vô hạn**: "kiếm thêm `50M · 10^vòng` Xu", thưởng cố định 30 💎 —
đếm "kiếm THÊM" từ mốc `repeatQuestBaseline` (chốt lại mỗi lần nhận).

| # | Điều kiện | 💎 | # | Điều kiện | 💎 |
|---|---|---:|---|---|---:|
| 1 | chạm 25 lần | 5 | 6 | mua 25 nâng cấp | 10 |
| 2 | mua 3 nâng cấp | 5 | 7 | kiếm 100 000 Xu | 15 |
| 3 | kiếm 1 000 Xu | 8 | 8 | 60 cấp nâng cấp | 20 |
| 4 | 15 cấp nâng cấp | 8 | 9 | prestige 1 lần | 25 |
| 5 | đạt giai đoạn 2 | 15 | 10 | kiếm 10 000 000 Xu | 40 |

### Thành tựu (11 mốc, xét lại mỗi tick, `lib/core/achievements.dart`)

`earn 1K/1M/1B` (5/15/40💎) · `levels 50/200` (10/30💎) · `stage 2→6`
(10/25/40/70/120💎) · `prestige 1★` (20💎). Có chấm đỏ trên nút 🏆 khi mở khóa mới.

### Điểm danh hằng ngày (`lib/core/daily.dart`)

- Chu kỳ 7 ngày: **[10, 15, 20, 25, 30, 40, 60] 💎**, streak dài hơn quay vòng.
- Bỏ lỡ ≥ 1 ngày → streak reset về 1. So sánh theo **ngày UTC**.
- Popup tự hiện khi mở app nếu đã sang ngày mới (nhường popup hướng dẫn/offline).

### Vòng quay may mắn (`lib/core/wheel.dart`) — mở từ dialog "Kiếm thêm 🎁"

8 ô, chọn theo trọng số (tổng 100):

| Ô | Thưởng | Trọng số |
|---|---|---:|
| 1 | 5 💎 | 22 |
| 2 | 30 phút sản xuất (Xu) | 20 |
| 3 | 15 💎 | 16 |
| 4 | 2 giờ sản xuất | 12 |
| 5 | x2 thu nhập 24h | 8 |
| 6 | 25 💎 | 10 |
| 7 | 6 giờ sản xuất | 8 |
| 8 | **100 💎 (JACKPOT)** | 4 |

- **1 lượt miễn phí/ngày** (`freeSpinAvailable = dayIndex(now) > lastFreeSpinDay`).
- Hết lượt free → quay bằng **xem quảng cáo** (không tốn 💎).

---

## 10. Quảng cáo thưởng (rewarded ads)

Chỉ dùng **rewarded ad** (không interstitial/banner). Người đã mua **Gỡ QC** hoặc
đang **VIP** (`adFree`) nhận thẳng, không phải xem.

| Ưu đãi | Vị trí | Hiệu ứng |
|---|---|---|
| **x2 thu nhập 24h** | dialog "Kiếm thêm" | ×2 thu nhập tự động trong 24h (cộng dồn thời lượng) |
| **+15 💎** | dialog "Kiếm thêm" | nhận ngay 15 💎 |
| **Tua nhanh** | dialog "Kiếm thêm" | +4 giờ sản xuất (nhịp cơ bản) |
| **Tiền tức thì** | nút ở đầu trang | +15 phút sản xuất |
| **Nhân đôi tiền offline** | popup offline | +100% số Xu vừa nhận lúc vắng |
| **Quay lại vòng quay** | dialog vòng quay | thêm 1 lượt quay |

---

## 11. Mua bằng tiền thật (IAP)

| Sản phẩm | Loại | Nội dung |
|---|---|---|
| `boba_gems_small` | consumable | 100 💎 (~$0.99) |
| `boba_gems_medium` | consumable | 600 💎 (~$4.99) |
| `boba_gems_large` | consumable | 1 300 💎 (~$9.99) |
| `boba_remove_ads` | non-consumable | Bỏ qua mọi QC, vẫn nhận đủ thưởng |
| `boba_double_income` | non-consumable | **×2 thu nhập tự động vĩnh viễn** (áp cả offline) |
| `boba_vip30` | consumable | **VIP Pass 30 ngày**: gỡ QC + ×2 thu nhập + 50💎/ngày + +4h trần offline. Client-only (lưu mốc hết hạn), gia hạn nối tiếp |
| `boba_starter_pack` | non-consumable | Một lần: +300 💎 |
| `boba_piggy` | consumable | **Đập heo đất**: nhận toàn bộ 💎 đã tích (biến động) |

**Heo đất** (`lib/core/balance.dart` › Piggy): tự tích **theo thời gian** chơi/vắng
(≈ đầy sau `piggyFillHours = 24` giờ), **không theo Xu** — vì thu nhập lớn thì fill
tức thì, mất cảm giác chờ. Trần **300 💎**. Cần tích ≥ **40 💎** mới cho đập
(chống mua heo rỗng). Đập xong reset về 0.

**Xác thực biên nhận**: có `HttpReceiptVerifier` (bật qua `--dart-define
IAP_VERIFY_ENDPOINT`); rỗng → client-only (`NoopReceiptVerifier`).

---

## 12. Kịch bản người chơi

### Phiên đầu tiên (~10 phút)

1. Mở app → popup **"Cách chơi"** (8 gạch đầu dòng: chạm, mua, giai đoạn,
   nhượng quyền, mèo, VIP, offline, 💎). Đóng.
2. Chạm ly liên tục → đủ 15 Xu → mua **Trà đen** L1 (0.5 Xu/s tự động).
3. Nhiệm vụ #1 (chạm 25) + #2 (mua 3) hoàn thành nhanh → +10 💎.
4. Dồn Trà đen tới ~L21–22 (≈ vài phút) + chạm thêm → **2 000 Xu** →
   mở **Giai đoạn 2** (Kiosk). Cảnh đổi sang kiosk xanh, shop hiện thêm
   Trân châu / Thạch / Pudding.
5. Panel shop từ 1 dòng giãn lên 4 dòng (animate ~150ms). Mua Trân châu → thu
   nhập nhảy vọt (4 Xu/s/cấp so với 0.5).

### Ngày 1

- Mở lại → **popup tiền offline** (8h cap ở đầu). Xem QC nhân đôi.
- **Điểm danh** ngày 2 → +15 💎.
- Trong lúc chơi: mèo Mưa vàng xuất hiện → chạm → **Golden Rush ×3** 2 phút →
  chạm ly như điên + thu nhập tự động ×3.
- Mua **"Tăng thu nhập"** cấp 1 (5 💎) khi có đủ.
- Tích Xu tới 500K → **Giai đoạn 3**.

### Tuần 1 — vòng prestige đầu

- `lifetimeEarnings` vượt ~40 000 → nút **Nhượng quyền** sáng, xem trước ~10 ⭐.
- Prestige: mất tiền + cấp nguồn thu, **giữ giai đoạn**. Vào Kho Sao mua
  **"Siêu thu nhập"** cấp 1 (3 ⭐) → +25% vĩnh viễn.
- Cày lại nhanh hơn hẳn (×1.2 từ 10 sao + ×1.25 perk). Mỗi vòng prestige kế tiếp
  nhận nhiều ⭐ hơn (đường cong `√lifetime`).

### Dài hạn

- Giai đoạn 4–6 mở ra ở mốc 50M / 5B / 500B Xu — chủ yếu đạt được **sau vài vòng
  prestige** và/hoặc mua IAP.
- Mốc **milestone ×2 mỗi 25 cấp** trở thành trục tối ưu chính: dồn 1 nguồn tới
  L50, L75… thay vì rải đều.
- Retention: điểm danh (streak 💎), wheel free/ngày, VIP daily 💎, thành tựu còn lại.
- ⚠️ **Nhiệm vụ hết ở bước 10** (kiếm 10M) → thanh nhiệm vụ biến mất; mid/late game
  mất một hook.

---

## 13. Kiến trúc kỹ thuật (để đối chiếu khi tune)

```
lib/core/     ← HÀM THUẦN, không Flutter. "Linh hồn" mô phỏng, test không cần UI.
  balance.dart      TẤT CẢ con số (tune ở đây; sau có thể nạp từ JSON/Remote Config)
  models.dart       GameState (mutable "sổ cái") + config bất biến
  economy.dart      công thức đóng: cost, income/s, sao, milestone (không mutate)
  simulation.dart   NƠI DUY NHẤT mutate GameState (tap, tick, buy, prestige, offline)
  quests / achievements / daily / vip / wheel   — hệ thống phụ, hàm thuần

lib/state/    ← cầu Riverpod
  game_controller.dart   giữ GameState, Timer.periodic 1s, phát GameSnapshot bất biến
  game_snapshot.dart     ảnh chụp immutable cho UI (.select → rebuild tối thiểu)

lib/ui/       ← Flutter. home_page.dart = màn chính; còn lại là dialog.
lib/data/game_storage.dart   1 blob JSON qua SharedPreferences (local, schema v1)
lib/ads · lib/iap            interface trừu tượng + impl thật; stub trên desktop/web
```

- **Tick**: mỗi 1s cộng `income/s × dt`, cập nhật mèo/VIP/đối thủ, xét thành tựu,
  tự lưu mỗi 10 tick. Lưu ngay khi mua bằng 💎/⭐ hoặc app vào nền.
- **Save**: đóng dấu `lastSeenMillis` = lúc lưu → mốc "đã tính tiền tới đây".
  Save hỏng → coi như ván mới (không crash). **Chưa có** migration cho `_schemaVersion`.
- **Không có cloud save** — gỡ app = mất tiến trình.

---

## 14. Vấn đề phát hiện (review)

| # | Mức | Mô tả | Gợi ý |
|---|---|---|---|
| 1 | ~~Trung bình~~ ✅ P4 | ~~`bulkCost()` không widget nào gọi~~ → nối nút chọn chế độ **×1 / ×10 / MAX** trong shop (`_BuyModeSelector`); `buyUpgradeBulk` + `maxAffordableLevels`. |
| 2 | ~~Trung bình~~ ✅ P2 | ~~**VIP ×2** không áp thu nhập offline~~ → đã cho VIP ×2 + perk "Siêu offline" áp offline. x2-24h (QC) vẫn không áp (chủ ý — boost lúc chơi). |
| 3 | Nhỏ | **Golden Rush ×3** runtime-only, không persist → kill app giữa chừng là mất. | Persist `_boostUntilMillis` nếu muốn "công bằng". |
| 4 | ~~Nhỏ (doc)~~ ✅ P2 | ~~Prestige "soft" nhưng "Cách chơi" nói "restart"~~ → prestige giờ hard-reset stage; giữ giai đoạn là perk kho Sao tuỳ chọn. |
| 5 | ~~Nhỏ (doc)~~ ✅ P3 | ~~Comment ghi stage "1..3"~~ → sửa thành "1..6". |
| 6 | Trung bình | Save **local-only** (SharedPreferences, 1 blob). Không cloud sync, `_schemaVersion` có nhưng **không có code migrate** → save cũ/hỏng = ván mới. Gỡ app = mất sạch. | Thêm cloud save (Play Games / Game Center / Firebase) trước khi scale; viết migration path. |
| 7 | ~~Nhỏ (UX)~~ ✅ | ~~mid/late game mất hook~~ → thêm **cốt truyện 8 chương + đối thủ cạnh tranh** (§16): chương gắn vào mốc giai đoạn/prestige, sự kiện đối thủ định kỳ, 2 điểm rẽ nhánh cho perk nhỏ. `tapValue` vẫn cố định 1 (bình thường với thể loại). |
| 8 | ~~Nhỏ (UX)~~ ✅ P5 | ~~Chuỗi nhiệm vụ hữu hạn~~ → sau 10 bước là chuỗi "kiếm thêm" vô hạn (mục 9). |

---

## 15. Lịch sử tối ưu cơ chế

> ⚠️ Các con số mới **cần playtest** — đặt theo ước lượng, chưa tune bằng dữ liệu.

### Phase 1 — Sink 💎 & sửa số (đã làm)

- **Cửa hàng 💎** thêm 2 "hành động" (mục 6): *Mở giai đoạn tức thì* (40–1500 💎, bỏ
  qua tường Xu — sink lớn nhất) và *Tua nhanh 💎* (30 💎 / 4h, sink lặp lại). Giải
  quyết "💎 dồn đống không chỗ tiêu".
- **Heo đất**: đổi từ tích-theo-Xu (`0.0001/Xu` → đầy trong ~3 giây với thu nhập
  lớn) sang **tích-theo-thời-gian** (`piggyFillHours = 24`), cả khi chơi lẫn vắng.
- **Cap boost**: `Balance.maxTimeBoostMultiplier = 12` chặn stack Mưa vàng ×3 ·
  x2-24h · VIP ×2 vượt tay.

### Phase 2 — Chiều sâu prestige (đã làm)

- **Prestige hard-reset stage** (`stage` → 1). Mỗi vòng tái trải nghiệm mở giai
  đoạn. Fix finding #4.
- **Kho Sao 2 → 6 perk**: thêm *Siêu offline*, *Vốn khởi nghiệp*, *Mua sỉ*
  (−giá nâng cấp), *Giữ giai đoạn* (bù việc reset nặng) — xem bảng mục 5.
- **VIP ×2 + Siêu offline áp cho thu nhập offline** (`applyOfflineEarnings`). Fix
  finding #2.

### Phase 3 — Chiều sâu generator (đã làm)

- Milestone giờ **2 hiệu ứng**: giữ **×2 cục bộ** + thêm **"Mốc vàng"** — từ mốc
  thứ 2 (L50) mỗi mốc bất kỳ nguồn thu đạt cộng **+3% thu nhập toàn cục** (cộng
  dồn). `globalMilestoneMultiplier` nhân vào `effectiveIncomePerSecond`.
- **Không** thêm generator / đổi đường cong income của từng nguồn.
- UI: chip `🌐 +X%` ở `_StageHeader`, dấu `🌐` trên `_MilestoneBar`; gợi ý "thu
  nhập thêm khi mua" (`_globalIncomeMult`) đã tính cả hệ số này.

### Phase 4 — QoL: mua ×10 / MAX (đã làm)

- Thanh chọn **×1 / ×10 / MAX** (`_BuyModeSelector`) giữa `_StageHeader` và danh
  sách shop; áp cho MỌI dòng. Fix finding #1.
- `buyUpgradeBulk` (mua trọn N cấp, huỷ nếu thiếu tiền), `maxAffordableLevels`
  (đảo chuỗi cấp số nhân, có chỉnh sai số FP), `bulkIncomeGain` (thu nhập thêm
  qua N cấp — hiện đúng ở dòng shop). Tất cả tôn trọng perk "Mua sỉ".
- Chế độ mua lưu ở phiên (không persist), mặc định ×1.

### Phase 5 — Auto-buy + nhiệm vụ lặp lại (đã làm)

- **Perk "Tự động mua"** (kho Sao, 12 ⭐, 1 cấp): mở khoá công tắc trong shop
  (`_AutoBuyToggle`). Bật → mỗi tick `autoBuyBest` mua nguồn "đáng mua nhất"
  (`bestBuyGeneratorId`) tới khi hết tiền (cap 200 lượt/tick).
- **Nhiệm vụ lặp lại** (fix finding #8): sau chuỗi 10, `currentQuest` trả nhiệm
  vụ "kiếm thêm `50M·10^vòng` Xu" (30 💎/vòng); tiến độ đếm từ
  `repeatQuestBaseline`. Thanh nhiệm vụ giờ **luôn hiển thị**.
- `GameState` +3 field (`prestigeAutoBuyLevel`, `autoBuyEnabled`,
  `repeatQuestBaseline`), JSON back-compat.

**Còn lại**: persist Golden Rush (finding #3), cloud save (finding #6).

---

## 16. Cốt truyện & Đối thủ cạnh tranh

> ⚠️ Số rival + perk nhánh đặt theo ước lượng — **cần playtest**.

### Cốt truyện (`lib/core/story.dart`, prose ở `story_content.dart`)

8 chương, trigger bằng mốc **có sẵn** (không thêm mốc mới):

| # | Trigger | Nhân vật | Ghi chú |
|---|---|---|---|
| 1 | mở game | 👵 Bà Tư | luôn chờ ở ván mới |
| 2 | `stage ≥ 2` | 🧋 Bạn | |
| 3 | `stage ≥ 3` | 😼 Hải "Trân Châu" | **đối thủ vào truyện** (`rivalActive`) |
| 4 | `prestigeStars > 0` | ⭐ Bà Tư | |
| 5 | `stage ≥ 4` | 😼 Hải | |
| 6 | `stage ≥ 5` | 🤔 Bạn | **CHỌN A**: `craft` (+8% chạm) / `scale` (+8% thu nhập) |
| 7 | `stage ≥ 6` | 🌍 Bà Tư | |
| 8 | `rivalDefeated` | 🏆 Hải | **CHỌN B**: `acquire` (+8% thu nhập) / `identity` (+8% chạm) |

- Chương mở **tuần tự** (`pendingChapterId` dừng ở chương chưa thoả — không nhảy
  cóc). Chương lựa chọn **re-show** tới khi chọn (chống kẹt khi kill app giữa
  dialog); dialog modal, `barrierDismissible: false`.
- Cutscene = emoji lớn trong vòng tròn (không asset). Nút 📖 trên AppBar mở
  `story_log_dialog` để đọc lại chương đã mở.
- Perk nhánh fold vào `economy.storyChoice{Tap,Income}Multiplier` → `tap()` và
  `effectiveIncomePerSecond` (áp cả offline). Cộng dồn nếu 2 nhánh cùng trục.
- `es/id/pt/th` tạm fallback prose sang `en` — dịch sau. Chrome (nút, nhãn) đã
  dịch đủ 6 ngôn ngữ trong ARB.

### Đối thủ (`lib/core/rival.dart`)

- **Sức ép** = `sqrt(rivalPressureSeconds) · rivalPowerK`. `rivalPressureSeconds`
  **KHÔNG** cộng theo tổng thời gian chơi — chỉ: (a) +1/s khi có sự kiện đang
  chờ trả lời, (b) `pressureDelta` (âm) khi đối phó, (c) `+2400s` khi phớt lờ.
  → không phụ thuộc cày lâu/ngắn, dễ tune.
- **Thế trận** (`rivalStanding`): so sức ép với `Balance.rivalExpectedPower[stage]`
  → ahead / even / behind. Chip `⚔️` màu ở `_StageHeader` (Chương 3+, chưa hạ).
- **Sự kiện** (`RivalEventType`: priceWar / poachStaff / smearCampaign) nổ mỗi
  5–8 phút (khuôn mèo/VIP trong `game_controller`). Mỗi sự kiện 2 lựa chọn:
  - Option 0: trả **% Xu hiện có**, đẩy lùi vừa (`pressureDelta` −1500..−1800).
  - Option 1: trả **💎**, đẩy lùi mạnh + **buff tạm** (×1.15–1.2 trong ~3 phút).
  - Phớt lờ: đối thủ +2400s sức ép + **debuff tạm** ×0.9 trong 2 phút.
- Buff/debuff tạm là **runtime-only** (`_rivalModifier`, giống Golden Rush —
  kill app là mất; debuff mất khi kill là có lợi cho người chơi). Áp thu nhập
  online + chạm, **không** áp offline.
- **Hạ đối thủ** (`rivalDefeatable`): tới `stage 6` mà vẫn `ahead` → chốt
  `rivalDefeated = true`, dừng sự kiện, mở Chương 8.

### `GameState` +5 field (persisted, **giữ qua prestige**)

`storyChapter`, `storyChoiceA`, `storyChoiceB`, `rivalDefeated`,
`rivalPressureSeconds`. JSON back-compat (`?? 0 / ?? null / ?? false`).
`prestige()` không đụng tới (chỉ chạm money/levels/stage).

## 17. Mở rộng thế giới đợt 2 — giai đoạn 13-18 (2026-09-26)

> ⚠️ Số cân bằng đặt theo ước lượng — **cần playtest**. Lý do mở rộng: người chơi
> "phá đảo" (xem hết Chương 18 / đạt GĐ12) rất nhanh.

Cùng khuôn với đợt mở rộng GĐ7-12 (§16), chỉ thêm nội dung, **không đổi công
thức** prestige/offline/kinh tế.

- **6 giai đoạn mới** (mở khoá ×100 mỗi bậc): 13 Học viện Trà Sữa `5e25` · 14 Thành
  phố Trà Sữa `5e27` · 15 Quốc gia Trà Sữa `5e29` · 16 Liên minh thế giới `5e31` ·
  17 Hành tinh Trà Sữa `5e33` · 18 Chân lý Trà Sữa `5e35`.
- **12 nguồn thu mới** (2/giai đoạn), tiếp nhịp ~×3.3 giá / ×3.2 thu nhập. Ở cấp trần
  1000, giá cao nhất ~1e80 — test `stage_test.dart` khoá việc luôn dưới
  `economyOverflowGuardCap` (1e100).
- **10 chương mới (19-28)**, hồi "truyền nghề" sau khi hết đối thủ — thuần narrative
  (không có sự kiện đối thủ). 2 chương lựa chọn mới: **Ch.23** (`heritage` +8% chạm
  / `export` +8% thu nhập, trục E) và **Ch.28** (`recipe` +8% chạm / `people` +8%
  thu nhập, trục F). Prose vi/en, es/id/pt/th fallback en.
- **Mốc "phá đảo" của Bảng xếp hạng tốc độ vẫn là Chương 18**
  (`storyFinaleChapterId` trong `story.dart`), KHÔNG phải chương cuối danh sách —
  nếu để trượt theo thì entry cũ mất ý nghĩa và người vừa xong Ch.18 không được chốt.
- **Thành tựu**: thêm `stage_7`..`stage_18` (trước chỉ tới `stage_6`). Người chơi cũ
  đã ở GĐ12 sẽ được **trao bù ngay** thành tựu GĐ7-12 (~1260 💎) khi cập nhật.
- `formatNumber` mở rộng hậu tố tới `zz` (~1e93); `instantStageGemCost` có bậc riêng
  cho GĐ13-18 (2500 → 14000 💎); mỗi giai đoạn có màu theme riêng (`main.dart`).
- ~~**Chưa có**: art cảnh nền riêng cho GĐ7-18~~ ✅ xong 2026-09-28: đủ 18 cảnh
  trong `assets/scene/`, sinh bằng `scripts/make_scenes.py`, mỗi cảnh lấy tông
  theo màu chủ đề của giai đoạn đó trong `_seedForStage` (main.dart). GĐ17-18
  dùng nền vũ trụ (không có dải đất). Test `stage_scene_test.dart` khoá việc
  "mỗi giai đoạn phải có file cảnh".
- **Server**: trần `lifetime_earnings` của bảng xếp hạng nâng 1e50 → 1e100
  (`supabase/leaderboard_schema.sql`) — **phải chạy lại file SQL trên Supabase**.

## 18. Kỷ Nguyên (Ascension) — prestige tầng 2 (2026-09-26)

> ⚠️ Mọi số là **ước lượng, chưa playtest**. Ra đời vì người chơi phá đảo nhanh:
> cho một vòng lặp mới bọc ngoài Nhượng quyền (§5) sau khi hết nội dung (§17).

- **Mở khi** `lifetime kể từ lần Kỷ Nguyên trước ≥ 5e35` (`Balance.ascensionMinLifetime`,
  = mức mở GĐ18). Dùng lifetime chứ không dùng `stage` vì Nhượng quyền reset stage.
- **Điểm ⏳** = `floor(sqrt(lifetimeThêm / 5e35))` (1 ở ngưỡng, ×10 khi ×100 lifetime).
- **Reset**: Xu, cấp nguồn thu, giai đoạn, **Sao** và cấp 6 perk Kho Sao (giữ "Tự động
  mua"). **Giữ**: `lifetimeEarnings`, 💎 + vật phẩm 💎, thành tựu, cốt truyện, nhiệm vụ.
- **3 perk** (giá `base·2^cấp` ⏳, có trần cấp): Nguồn năng lượng (+50% thu nhập/cấp,
  trần 20) · Ngôi sao rực rỡ (bonus/Sao ×(1+0.25·cấp), trần 20) · Tinh tú dồi dào
  (k tích Sao ×(1+0.10·cấp), **trần 10**).
- **Lối vào**: nút trong dialog Nhượng quyền, chỉ hiện khi đã Kỷ Nguyên hoá hoặc tiến độ
  (thang log) ≥ 80%. Không thêm icon bottom bar.

### Hai bẫy thiết kế (đã có test khoá)

1. **Độ chính xác double**: sau Kỷ Nguyên `lifetimeEarnings` ~1e37 nên mỗi tick cộng vài Xu
   bị nuốt hoàn toàn (ulp ~1e21). Vì vậy KHÔNG tính bằng `lifetime − baseline` (Sao sẽ đứng
   yên ở 0 rất lâu) mà dùng bộ tích lũy riêng `GameState.ascensionLifetime`, tăng trong
   `_credit()`. Trước lần Kỷ Nguyên đầu vẫn dùng thẳng `lifetimeEarnings` → save/test cũ
   không đổi.
2. **Ràng buộc server**: `leaderboard_schema.sql` chặn `prestige_stars > floor(0.05·√lifetime)`.
   k hiệu dụng ở trần perk = 0.02·2 = 0.04 < 0.05, và lifetimeThêm ≤ lifetime → bất biến
   giữ nguyên, **không cần đổi SQL**. Nâng trần perk "Tinh tú dồi dào" tới k_eff > 0.05 thì
   phải nâng SQL trước (test `ascension_test.dart` sẽ báo).

Sau Kỷ Nguyên Sao trên bảng xếp hạng về 0 (xếp hạng theo `lifetime_earnings` nên không đổi).

## 19. Nhiệm vụ hằng ngày (2026-09-26)

> ⚠️ Số là **ước lượng, chưa playtest**. Mục tiêu: lý do mở app mỗi ngày (retention),
> bổ sung cho điểm danh (§9) và vòng quay 1 lượt free/ngày.

- **3 nhiệm vụ/ngày**, chọn xác định theo `dayIndex` (UTC, cùng quy ước điểm danh) nên
  kill/mở lại app không đổi bộ. 6 loại: Chạm ly (100-300) · Nâng cấp (10-40) · Kiếm Xu ·
  Bắt mèo Mưa vàng · Phục vụ khách VIP · Quay vòng quay (3 loại cuối: 1 lần).
- **Kiếm Xu dùng ngưỡng tương đối**: `max(500, thu nhập/giây × 30 phút)` chốt lúc sang ngày
  (kinh tế trải ~1e2..1e80, ngưỡng cố định vô nghĩa). Đếm trong `_credit()` → gồm cả
  thu nhập offline/thưởng.
- **Thưởng**: 8 💎/nhiệm vụ (Kiếm Xu 10) + **15 💎** khi nhận đủ cả 3 → ~39-41 💎/ngày.
  Cùng điểm danh (~28 💎/ngày) thì nguồn 💎 gần gấp đôi — **theo dõi lạm phát 💎**.
- Nhận thủ công bằng nút; vào từ chip "Nhiệm vụ" ở đầu màn chính (chấm đỏ khi có thứ nhận
  được). Không tự bật popup (chuỗi popup mở app đã dài). Không có nhiệm vụ xem quảng cáo.
- Nhượng quyền/Kỷ Nguyên KHÔNG reset tiến độ ngày; "Nâng cấp" đếm số lần mua, không đếm cấp.

**Bẫy đã gặp (có test khoá):** khi mở app, `_rollDaily()` phải chạy TRƯỚC
`applyOfflineEarnings` — nếu sau, Xu lúc vắng cộng vào bộ của ngày cũ rồi bị xoá ngay khi
sang ngày. Test đã mutation-check (đảo thứ tự thì fail).

---

*Cập nhật tài liệu này khi đổi `balance.dart` hoặc thêm hệ thống.*

## 20. Đấu Trường — dạng "Trân Châu Rơi" / Falling Pearls (2026-09-26, mã nội bộ: match3)

Dạng PK thứ 2 cạnh "Đua chạm". (Bản đầu là Xếp khối kiểu Tetris — hiểu nhầm yêu cầu, đã thay bằng Ghép 3; còn trong git history `30c4417`.)
Chọn dạng ở màn Đấu Trường trước khi ghép trận (hàng đợi tách theo dạng).

- **Luật**: bảng 8×8, 5 loại ô (🧋 🟤 🍓 🥭 🍵). Đổi 2 ô kề nhau (chạm-chạm hoặc vuốt) để tạo dãy ≥3 cùng loại; ô xoá →
  các ô trên rơi xuống → bù ô mới từ đỉnh → tự xoá tiếp nếu tạo dãy mới (dây chuyền). Nước không tạo dãy bị bỏ qua.
- **Điểm**: mỗi ô xoá = 10 × số bước dây chuyền (bước 2 nhân 2, bước 3 nhân 3…). 60 giây, điểm cao hơn thắng.
- **Công bằng**: server sinh chuỗi 2000 số (`arena_matches.seq`): 64 số đầu là bảng đầu (giống nhau cho cả 2 người,
  không có dãy sẵn), phần còn lại là luồng bù ô của từng người.
- **Chống gian lận**: như dạng chạm — server replay log `swap` (`arena_m3_replay`), không tin điểm client. Nước vô hiệu chỉ
  bị bỏ qua. Trần 150 nước/người, tối đa 4 nước/giây.
- Luật ở `lib/arena/match3_rules.dart` ⇔ `supabase/arena_schema.sql`, khớp bằng vector vàng
  (`test/arena/match3_rules_test.dart` và khối comment cuối file SQL) + fuzz 300 ván qua RPC.
- Thưởng 💎 và bảng xếp hạng Đấu Trường dùng chung với dạng chạm (tính từ `arena_matches.winner`).
- **Tự xáo khi hết nước** ✅ 2026-09-28: `Match3Board.trySwap` gọi `reshuffle()`
  ngay khi nước vừa đi làm bàn hết nước, và `arena_m3_shuffle` trong SQL làm y
  hệt (có vector vàng khoá hai bên). Đặt trong `trySwap` vì đó là điểm duy nhất
  cả ba đường đi của client đều qua (đánh trực tiếp / replay log / tính điểm
  đối thủ).
  ⚠️ Đo được: quét 4000 hạt giống × 150 nước (~600k nước) KHÔNG lần nào bàn bí;
  ép bằng chuỗi bù 2-3 loại cũng không bí. Đây là **lưới an toàn**, không phải
  lỗi người chơi hay gặp — ghi chú cũ trong ROADMAP nói "kẹt tới hết 60 giây"
  là đúng về lý thuyết nhưng gần như không xảy ra.
- Chưa làm: xem bảng đối thủ. Chưa playtest cân bằng.

## 21. Bảng xếp hạng tốc độ "Hồi 2" (2026-09-26), mở rộng "Hồi 3" (§25)

Bảng Tốc độ cốt truyện có 3 tab: **Hồi 1** (tới Chương 18, `storyFinaleChapterId`, bảng cũ giữ nguyên), **Hồi 2**
(tới Chương 28, `storyExtendedFinaleChapterId`) và **Hồi 3** (tới Chương 36, `storyThirdActFinaleChapterId`, xem §25). Thời gian
= tổng giây thực tế từ lần đầu chơi (`firstPlayedMillis`) tới lúc xem xong chương cuối, ghi 1 lần (`storyCompleteSeconds` /
`storyExtCompleteSeconds` / `storyThirdActCompleteSeconds`). Ba bảng Supabase riêng (`story_speedrun_entries` /
`story_speedrun2_entries` / `story_speedrun3_entries`), cùng khuôn (`SpeedrunBoard` enum), không anti-cheat. Save đã qua chương
cuối nhưng chưa có mốc được bù khi mở app (cao hơn thực tế một chút); save không có `firstPlayedMillis` thật thì không bù
(tránh mốc ~1 giây).

## 22. Số người đang online ở Đấu Trường (2026-09-26)

Màn chờ và màn ghép trận hiện "🟢 N người đang online" (N gồm cả bạn, 1 người vẫn hiện; chưa kết nối/lỗi thì ẩn). Dùng Supabase
Realtime Presence trên kênh công khai `arena-lobby` (không có bảng/SQL): chỉ đếm người đang MỞ trang Đấu Trường, mỗi người 1 kết nối
realtime (gói free ~200 kết nối cùng lúc). Provider `arenaOnlineCountProvider` (autoDispose) giữ kết nối suốt lúc trang mở.

## 23. Hành trình Trân Châu Rơi — chơi đơn có màn (2026-09-28)

> ⚠️ Số cân bằng là **ước lượng, chưa playtest** (như mọi đợt trước). Toàn bộ
> nằm trong Remote Config nên tune được không cần nộp bản mới — xem SETUP.md §2b.

Tab thứ 5 ở thanh dưới. Tên hiển thị: **Trân Châu Rơi** — dùng chung tên với dạng PK cùng lối chơi ở Đấu Trường, thay cho tên kỹ thuật "Ghép 3" (đổi 2026-09-28). Thiết kế đầy đủ + phần cố ý hoãn: `PROPOSAL_MATCH3_LEVELS.md`.

- **Dùng lại nguyên luật** `lib/arena/match3_rules.dart` và bàn cờ `Match3Panel`
  (trước là `ArenaMatch3Panel`) — bàn cờ giờ nhận `Match3View` nên Đấu Trường và
  chơi đơn cùng dùng một widget.
- **Màn sinh bằng công thức** (`lib/core/match3_levels.dart`), không có bảng dữ
  liệu: 60 màn, mỗi màn 20 nước, mục tiêu 1★ = `900·1.12^(n-1)`, 2★ =
  `m3Star2Mult` (1.25×), 3★ = `m3Star3Mult` (1.6×). Hai mốc sao hạ từ 1.5×/2×
  xuống (2026-09-28) vì chơi thật thấy khắt khe quá — đều là nút vặn Remote
  Config, tune tiếp không cần nộp bản mới. Bàn tất định theo `seed = id·7919` → ai chơi màn n cũng gặp đúng bàn đó.
- **Thưởng chỉ trả LẦN ĐẦU** đạt mỗi mốc sao (`applyMatch3Result` trong
  `simulation.dart`). Bàn tất định nên chơi lại được đúng điểm cũ — thưởng lặp
  lại là máy in Xu/💎. Xu theo ngưỡng tương đối (thu nhập/giây × 600s × số sao),
  💎 chỉ khi 3★ (3 💎/màn, trọn đời 180 💎).
- `GameState.m3Stars` (chỉ số = màn − 1, giá trị 0..3), giữ qua Nhượng quyền và
  Kỷ Nguyên, tự đi theo cloud save.
- **Hết nước đi thì tự xáo bàn** (`Match3Board.reshuffle`). CHỈ chơi đơn được
  dùng: `arena_m3_replay` replay cả trận chỉ từ seq + log nước đi, client tự xáo
  giữa trận PvP là bàn lệch server. Đấu Trường vẫn kẹt như cũ (ROADMAP P2 §9).
- **Âm thanh khi ăn ô** (2026-09-28): phát ngay lúc ô nổ, cạnh rung haptic đã
  có sẵn trong `Match3Panel._play` — một chỗ nên cả Đấu Trường lẫn chơi đơn đều
  có. Dùng lại 3 SFX sẵn có, to dần theo độ "đã": ăn lẻ `tap`, dây chuyền `buy`,
  nổ ≥8 ô (kẹo đặc biệt) `reward`. Không cần chống dồn tiếng vì hai bước dây
  chuyền cách nhau ~390ms.
- **Bảng xếp hạng** (2026-09-28): xếp theo TỔNG SAO của Hành trình, vào bằng
  nút 🏆 trên AppBar của tab. Không xếp theo "điểm cao nhất một màn" vì bàn cờ
  tất định — điểm cao nhất chỉ đo được ai chịu chơi lại một màn nhiều lần.
  `supabase/m3_leaderboard_schema.sql` + `lib/leaderboard/m3_leaderboard_*`,
  cùng khuôn bảng tốc độ cốt truyện (top tuyệt đối, dùng chung tên người chơi).
  Chặn gian lận bằng CHECK: `stars <= levels_cleared * 3` (mỗi màn tối đa 3 sao)
  và trigger chỉ cho sao TĂNG (chơi lại bằng save cũ không đạp hạng của mình).
  ⚠️ Phải chạy file SQL trên Supabase thì bảng mới hoạt động.
- **Hướng dẫn** (2026-09-28): `match3_how_to_dialog.dart`, 7 gạch đầu dòng —
  đổi ô, mục tiêu, giới hạn nước, dây chuyền, kẹo đặc biệt, mốc sao + "Chơi
  nốt", thưởng chỉ trả lần đầu. Tự hiện LẦN ĐẦU mở tab (`GameState.m3HowToSeen`,
  cùng khuôn `tutorialSeen`), sau đó mở lại bằng nút ? trên AppBar.
- **Giao diện**: lưới màn dùng bộ `Clay*` cho đồng bộ với phần còn lại của app,
  có chip tổng sao, viền nổi ở màn đang chơi và tự cuộn tới màn đó khi mở. Màn
  chơi có HUD gồm tiến độ + chip số nước (đổi màu khi còn ≤3) + **thanh sao** đặt
  đúng vị trí tỉ lệ của 3 mốc. Qua màn thì bắn hiệu ứng có sẵn (confetti, 3 sao
  thì pháo hoa).
- **Bàn cờ co theo CHIỀU CAO ĐƯỢC CẤP**, không theo nửa chiều cao màn hình —
  nếu không thì banner ăn chỗ là tràn khung. Khung rộng hơn cao thì HUD chuyển
  sang đứng cạnh bàn cờ (xếp dọc ở khung ngang làm bàn co còn 0.61 lần). App
  đã khoá màn dọc trên điện thoại (xem dưới), nhưng nhánh này vẫn dùng tới ở
  bản desktop/web và cửa sổ chia đôi.
- **Banner quảng cáo** ở đáy cả hai màn của tab này (`lib/ads/banner_ad_box.dart`),
  tôn trọng `adFree`; unit id thật chưa tạo → release chưa hiện banner.
- **Kẹo đặc biệt** (chỉ chơi đơn): ghép 4 → 💥 **bom chéo** (nổ cả hàng và cột),
  ghép ≥5 → 🌈 **bom màu** (nổ mọi ô cùng loại). Kẹo sinh ngay tại ô người chơi
  vừa đổi tới, mang loại gốc nên ghép nó như ô thường; nổ dây chuyền được với
  nhau. Mã hoá thẳng trong mảng ô (`m3CrossBase`/`m3ColorBase` + loại) nên
  frame/hoạt ảnh không đổi kiểu dữ liệu.
  **Đấu Trường KHÔNG bật** (`Match3Board.initial(..., specials: false)` mặc
  định) vì `arena_m3_replay` trong SQL không biết luật kẹo — vector vàng
  Dart↔SQL là thứ khoá điều này.
- **Hai kiểu mục tiêu**: *đạt X điểm* (mặc định) và *thu thập N ô loại X* —
  cứ `Balance.m3CollectEvery` (3) màn thì một màn kiểu thu thập, loại ô xoay
  vòng qua cả 5 loại. Cả hai dùng CHUNG thang sao (1× / `m3Star2Mult` /
  `m3Star3Mult`) nên "Chơi nốt" và
  công thức thưởng không phải phân nhánh. Engine chỉ thêm `Match3Move.cleared`
  (đếm ô đã xoá theo loại) — KHÔNG đụng điểm/rơi/bù nên `arena_m3_replay` (SQL)
  không phải sửa, vector vàng vẫn khớp.
- **Màn kết thúc ngay khi đạt mục tiêu**, không bắt đốt nốt số nước còn lại.
  Hộp thoại lúc đó có 3 lối: **Màn sau** (nút chính) · **Chơi nốt** (dùng nốt
  số nước để săn 2★/3★, kèm dòng **"còn thiếu N điểm nữa là 2★"**
  (`match3NextStar`) để lựa chọn đó có thông tin — dừng ngay ở mốc 1★ thì không bao giờ
  với tới) · **Tạm nghỉ**. Chọn "Chơi nốt" thì không hỏi lại mỗi nước, chỉ hiện
  lại khi hết nước.
- **Rewarded "xem QC: +5 nước"** ở bảng kết quả, chỉ hiện khi ĐÃ HẾT nước thật (còn
  nước mà mời thêm nước thì vô nghĩa), chưa đạt 3★ và chưa dùng lượt nào. Chơi tiếp bàn đang dở (giữ điểm + bàn cờ). **1 lần mỗi
  lượt chơi** — không giới hạn thì xem đủ quảng cáo là qua mọi màn. Dùng lại
  `AdService.showRewardedAd()`, `adFree` được cộng thẳng.

## 24. Khoá màn dọc (2026-09-28)

Toàn bộ game thiết kế cho màn dọc, nên khoá ở tầng NATIVE cho cả hai nền tảng
thay vì gọi `SystemChrome.setPreferredOrientations` lúc chạy — không có cú xoay
loé lên lúc mở app và không tốn thêm gì ở khởi động:

- Android: `android:screenOrientation="portrait"` trên `.MainActivity`
  (khoá kể cả khi máy đang bật tự xoay).
- iOS: `UISupportedInterfaceOrientations` chỉ còn `UIInterfaceOrientationPortrait`.
  Không vướng yêu cầu 4 hướng của iPad vì `TARGETED_DEVICE_FAMILY = 1`
  (chỉ iPhone).

Bố cục ngang của màn chơi Ghép 3 KHÔNG bỏ đi: bản desktop/web và cửa sổ chia đôi
vẫn có thể rộng hơn cao.

## 25. Hồi 3 — "Vòng Lặp Vĩnh Cửu" (Chương 29-36, chưa playtest)

> ⚠️ Ngưỡng là **ước lượng, chưa playtest**. Lý do: Hồi 2 (§17) thuần narrative
> theo mốc giai đoạn, nhưng GĐ18 đã là trần kinh tế (§18 Kỷ Nguyên) — Hồi 3
> không còn mốc giai đoạn nào để gắn vào, nên chuyển sang 2 mốc SẴN CÓ khác
> vẫn tăng đều sau đó: số lần Kỷ Nguyên và tiến độ Hành trình Trân Châu Rơi
> (§23) — chương gating = "thử thách" thay vì chỉ đọc.

- **8 chương mới (29-36)**, nhân vật mới **🌀 Thầy Cả** (người giữ "Vòng Lặp
  Vĩnh Cửu") — thuần narrative, không có sự kiện đối thủ song song (đối thủ đã
  hết vai trò từ Hồi 2). Bản đầu chỉ có 6 chương (29-34, ngưỡng 15/30/45 màn,
  3 lần Kỷ Nguyên) — kéo dài + dàn ngưỡng đều hơn trên phạm vi rộng hơn của cả
  chiến dịch Trân Châu Rơi (60 màn; **2026-10-07: 80 màn**, 25 nước, mục tiêu điểm tăng ×1.08 mỗi màn nhưng chặn ở `Balance.m3TargetCap` = 24.000 — mô phỏng tham lam chỉ được ~15-20k điểm/25 nước ở mọi màn; ⚠️ chưa playtest).
- **2 trigger mới** trong `StoryTrigger`: `ascension` (`GameState.ascensionCount
  >= value`) và `m3Level` (đã qua màn `value` của Trân Châu Rơi với ≥1★,
  `GameState.m3Stars[value - 1] > 0`). `StoryChapter.stageValue` đổi tên thành
  `StoryChapter.value` (generic cho cả 3 loại trigger cần ngưỡng số) — an toàn
  vì trường này chỉ dùng nội bộ `story.dart`.
- **Ngưỡng từng chương** (xen kẽ 2 loại mốc): Ch.29 Kỷ Nguyên ≥1 · Ch.30 qua
  màn 10 · Ch.31 Kỷ Nguyên ≥2 · Ch.32 qua màn 25 · Ch.33 Kỷ Nguyên ≥3 · Ch.34
  qua màn 40 · Ch.35 qua màn 55 · Ch.36 Kỷ Nguyên ≥4 (chương lựa chọn, **trục
  G**: `secret` giữ bí mật hội +8% chạm / `open` mở cho tất cả +8% thu nhập,
  vĩnh viễn — cùng khuôn perk A-F).
- **Mốc "phá đảo" Hồi 3** = `storyThirdActFinaleChapterId` (= 36, KHÔNG dùng
  `storyChapters.last.id`, cùng lý do như Hồi 1/2 — mở rộng tiếp về sau không
  làm trượt mốc). Bảng xếp hạng tốc độ thêm tab thứ 3 (§21), field
  `storyThirdActCompleteSeconds`, chốt trong `_stampStoryFinales` (GameController)
  y hệt 2 mốc trước.
- `GameState` +2 field (persisted, giữ qua prestige/Kỷ Nguyên): `storyChoiceG`,
  `storyThirdActCompleteSeconds`. JSON back-compat (`?? null`).
- **Server**: bảng mới `story_speedrun3_entries` + RPC `story_speedrun3_top`
  (`supabase/story_speedrun3_schema.sql`, cùng khuôn story_speedrun2) —
  **phải chạy file SQL trên Supabase** thì tab "Hồi 3" mới hoạt động.
- Prose vi/en đầy đủ; es/id/pt/th tạm fallback sang `en` (cùng quy ước mọi đợt
  mở rộng trước). Nhãn tab + thông báo "chưa hoàn thành" dịch đủ 6 ngôn ngữ
  trong ARB (`storySpeedrunTabExt2`, `storySpeedrunExt2NotCompletedYet`).

## 26. Phụ kiện sưu tập — "Kho phụ kiện" (2026-10-01, chưa playtest)

> ⚠️ Trọng số độ hiếm + số 💎 quy đổi trùng là **ước lượng, chưa playtest**.
> Mục đích: sink cosmetic thuần cho Xu/thời gian chơi cuối game, không đụng
> cân bằng kinh tế (khác gem shop/redeem — không có tác dụng lên số liệu).

> **Cập nhật 2026-10-17:** phụ kiện KHÔNG còn cosmetic thuần — món đang *mang* cho buff nhỏ theo
> họ, xem §40. Bộ sưu tập, BXH Sưu tập và Chợ không đổi.

> **Cập nhật 2026-10-06:** danh mục lên **160 món** (75 thường · 46 hiếm · 30 sử thi · 9 huyền thoại); mốc sưu tập thêm 80/100/120/140/160 (thưởng 300/500/800/1100/1500 Xu Chợ, tổng 4570) — SQL `claim_collection_milestone` PHẢI chạy lại. Các con số 50/80 món bên dưới là lịch sử.

- **50 món** (`lib/core/accessories.dart`), chia 4 độ hiếm: 25 thường · 13
  hiếm · 9 sử thi · 3 huyền thoại (nâng từ 16 lên 50 — 2026-10-01 — lúc chốt
  kế hoạch Chợ Phụ kiện ở `PROPOSAL_ACCESSORY_MARKET.md`, muốn sưu tập đủ
  dài hơi để chợ có ý nghĩa). Chỉ id + emoji ở tầng dữ liệu — tên hiển thị
  dựng ở `l10n_ext.dart` (`accessoryName`/`accessoryRarityLabel`), cùng khuôn
  `generatorName`/`achievementDesc`, dịch đủ 6 ngôn ngữ trong ARB.
- **Rớt khi nhận thưởng "xong cả 3 nhiệm vụ ngày"** (`claimDailyBonus` trong
  `game_controller.dart`) — CỐ Ý không hook vào chuỗi nhiệm vụ chính 10 bước +
  lặp vô hạn (đã có lịch sử bug tràn số, xem int-pow-overflow-quest-zero
  memory) để giữ 2 hệ thống tách biệt. Random 2 tầng (`rollAccessory`, cùng
  khuôn `spinWheel` ở wheel.dart): chọn độ hiếm theo trọng số trước, rồi chọn
  đều trong nhóm đó.
- **Trùng món đã có** → quy đổi `Balance.duplicateAccessoryGems` (2 💎) thay
  vì lãng phí lượt rớt, không thêm bản ghi trùng vào `GameState.ownedAccessories`.
- **Không có "vừa nhận được X" popup** — cố ý đơn giản hoá (cùng triết lý
  "không tự bật popup, chuỗi mở app đã dài" đã ghi ở `daily_quests_dialog.dart`).
  Người chơi kiểm tra bằng cách mở "Kho phụ kiện".
- **UI**: `accessory_inventory_page.dart` (lưới 3 cột, ô khoá hiện "❔"/"???",
  FittedBox co cụm emoji+tên+độ hiếm — tên dịch dài ở vài ngôn ngữ (VD
  "Unicórnio Pequeno") tại cỡ chữ lớn từng làm tràn RenderFlex, xem
  shop-tile-overflow-pattern memory, cùng lớp bug với cột hạng bảng xếp hạng
  chính) và `accessory_leaderboard_page.dart` (xếp theo SỐ MÓN KHÁC NHAU đã
  có, top tuyệt đối, cùng khuôn `m3_leaderboard_page.dart`). Vào từ
  `compete_hub_dialog.dart`.
- **Danh hiệu top 20** (2026-10-01): hạng 1-3 hiện 🥇🥈🥉, hạng 4-20 hiện 🏅,
  kèm nhãn "Top 20 Sưu Tập" — suy thẳng từ `rank` mà RPC
  `accessory_leaderboard_top` đã trả (`row_number()` có sẵn), không cần
  cột/bảng mới. Hạng 21 trở đi không có danh hiệu.
- **Server**: bảng mới `accessory_leaderboard_entries` + RPC
  `accessory_leaderboard_top` (`supabase/accessory_leaderboard_schema.sql`,
  cùng khuôn m3_leaderboard: trigger chặn hạ cấp, CHECK `owned_count <= 50`
  khớp đúng số món trong danh mục — **nâng danh mục lên >50 món thì PHẢI nâng
  trần CHECK này trước**) — **phải chạy file SQL trên Supabase**.
- `GameState` +1 field (persisted, giữ qua prestige/Kỷ Nguyên/Ascension,
  KHÔNG cho xoá): `ownedAccessories`. JSON back-compat (`?? []`).
- **Scope cố ý cắt bớt so với ý tưởng gốc**: KHÔNG có market giao dịch giữa
  người chơi (P2P) — rủi ro gian lận cao (tự bán cho tài khoản phụ để rửa
  Xu/💎, cùng lớp rủi ro đã gặp ở leaderboard/Đấu Trường) nên để riêng thành
  giai đoạn 2 — đã code xong (2026-10-01), xem §27 và
  [`PROPOSAL_ACCESSORY_MARKET.md`](PROPOSAL_ACCESSORY_MARKET.md).

## 27. Chợ Phụ kiện (2026-10-01, đã code xong — chờ deploy SQL + test)

Thiết kế đầy đủ ở [`PROPOSAL_ACCESSORY_MARKET.md`](PROPOSAL_ACCESSORY_MARKET.md)
(gồm 4 quyết định đã chốt ở §9 file đó: giá tự do 1-100,000, không cấp Xu Chợ
khởi điểm, món đang đăng bán vẫn tính vào bảng xếp hạng Sưu tập, không giới
hạn giao dịch/ngày). Điểm mấu chốt:

- **Đơn vị "Xu Chợ"** tách biệt hoàn toàn khỏi Xu/💎 thật, không đổi ngược
  được — triệt tiêu động cơ rửa tiền (2 tài khoản thông đồng) ngay từ thiết
  kế thay vì phải dò từng kiểu gian lận như Đấu Trường đã phải làm.
- **RPC `register_accessory_drop`** (phát hiện lúc code, không có trong bản
  phác thảo đầu): server phải biết ai sở hữu món gì TRƯỚC khi cho đăng bán,
  nếu không thì 2 tài khoản thông đồng có thể đăng bán id bất kỳ (kể cả chưa
  từng rớt) để bơm phụ kiện giả cho nhau. Gọi ngay lúc `claimDailyBonus` rớt
  món MỚI (fire-and-forget, không chặn thưởng cục bộ nếu lỗi mạng) + đối
  chiếu lại mỗi lần mở Chợ (bù món có từ trước khi Chợ ra đời, hoặc bù lần
  gọi bị lỗi mạng trước đó).
- **3 RPC giao dịch** (`list_accessory`/`buy_listing`/`cancel_listing`,
  `supabase/accessory_market_schema.sql`): `buy_listing` khoá hàng `for
  update` trước khi đổi gì (chặn 2 người mua cùng lúc 1 listing, bài học từ
  `pushIfCurrent` ở Cloud Save) và chặn tự mua chính mình.
- **Bảng xếp hạng Sưu tập đổi cách tính** (`getMyOwnedCount` ở
  `accessory_leaderboard_page.dart` giờ là async): cộng thêm số listing
  `active` của chính mình, không chỉ đếm `ownedAccessories.length` cục bộ
  như GĐ1 — món đang rao bán vẫn tính là "của mình" tới khi có người mua
  thật, tránh đăng bán làm tụt hạng ngay lập tức (sẽ khiến market chết yểu
  vì ai cũng ngại bán).
- **UI**: `accessory_market_page.dart`, 2 tab "Chợ" (duyệt + mua, ẩn listing
  của chính mình) và "Của tôi" (ví Xu Chợ + listing đang bán, nút huỷ + danh
  sách phụ kiện đang sở hữu có thể đăng bán). Vào từ icon 🏬 trên AppBar của
  `accessory_inventory_page.dart`, cạnh nút 🏆 xếp hạng.
- `GameController` +2 hàm mutate local (`removeOwnedAccessoryLocally`/
  `addOwnedAccessoryLocally`, gọi sau khi RPC Supabase xác nhận thành công,
  lưu ngay bằng `saveNow()` để giảm cửa sổ "hồi sinh" món đã bán qua đồng bộ
  đa máy — xem PROPOSAL §5).
- **Server**: 4 bảng mới (`accessory_wallets`, `accessory_server_ownership`,
  `accessory_listings`, `accessory_market_trades`) + 4 RPC
  (`supabase/accessory_market_schema.sql`, độc lập với
  `accessory_leaderboard_schema.sql`) — **phải chạy file SQL trên Supabase**.
- Prose/chrome dịch đủ 6 ngôn ngữ trong ARB (19 khoá `market*`).
- Test: `test/market/accessory_market_repository_test.dart` (parse model) +
  `test/ui/accessory_market_page_test.dart` (controller giả, cùng khuôn
  `story_speedrun_tabs_test.dart`) — không có test cho chính các RPC Postgres
  (cần Supabase thật/mock, chưa làm; CHECK/trigger trong file SQL là tuyến
  phòng thủ duy nhất, giống mọi schema khác trong repo này).

### 27b. Phí sàn 1% + nạp Xu Chợ bằng Xu/💎 (2026-10-01, đã code + test Dart — SQL chưa deploy)

- **Phí sàn: 1%, tối thiểu 1 Xu Chợ** — `greatest(1, ceil(price/100))` trong
  `buy_listing()`. Người mua trả đúng giá niêm yết, người bán nhận giá − phí,
  `accessory_market_trades` ghi giá niêm yết. Hệ quả làm tròn: giá ≤ 100 đều
  mất đúng 1 Xu Chợ (giá 1 → người bán nhận 0; giá 100 → 1%; giá 101 → 2).
- **Nạp Xu Chợ MỘT CHIỀU**: RPC `credit_market_coins(p_amount)` chỉ cộng ví
  người gọi (1..100000), không có chiều ngược lại → Xu Chợ không rút ra thành
  Xu/💎 thật được (xem PROPOSAL §0).
  - 💎: `Balance.marketCoinsPerGem = 10` (1 💎 = 10 Xu Chợ).
  - Xu: tương đối theo thu nhập/giây hiện tại, `Balance.marketCoinsIncomeSeconds
    = 60` (giá = số Xu Chợ × 60 × thu nhập/giây) — Xu trải ~1e2..1e100 nên
    không dùng tỉ giá cố định.
- **Bất biến**: Xu/💎 cục bộ chỉ bị trừ SAU khi RPC thành công. Supabase chưa
  sẵn sàng, chi phí không hữu hạn/tràn, hoặc lượng ≤ 0 → trả `false`, không gọi
  RPC, không trừ gì (fail-closed). UI không bật nút xác nhận khi chi phí không
  hữu hạn.
- **Deploy**: `supabase/accessory_market_schema.sql` là artifact — phải chạy lại
  trên Supabase (idempotent) thì phí 1% và `credit_market_coins` mới có hiệu
  lực. Test Dart: `test/state/game_controller_test.dart` (nhóm "Supabase chưa
  sẵn sàng"); RPC Postgres chưa có test tự động.

### 27c. Bản sao dư phụ kiện + điểm nhấn Chợ (2026-10-02, đã code + test Dart — SQL chưa deploy)

- **Bản dư**: rớt trùng vẫn được 2 💎 **và** cộng 1 bản dư vào
  `GameState.accessorySpares` (id → số bản dư). Bán/mua/huỷ đăng chỉ đụng bản
  dư trước; món chỉ mất khỏi kho khi bán nốt bản đầu. Kho/Chợ hiện `×N`.
- **Server**: `accessory_server_ownership.copies`; RPC `register_accessory_copies`
  (idempotent, chỉ nâng) dùng lúc rớt và lúc đối chiếu khi mở Chợ;
  `list_accessory` trừ 1, xoá hàng khi về 0; `buy_listing`/`cancel_listing` cộng 1.
- **Bảng Sưu tập** đếm món KHÁC NHAU = hợp(kho, đang bán), không cộng dồn.
- **Điểm nhấn**: chấm đỏ + banner màn chính khi có listing mới (hiếm nhất),
  dải "Vừa bán" (`recent_market_trades`, ẩn danh), danh hiệu "Thương gia tuần"
  (`market_weekly_top_seller`, chỉ là danh hiệu).
- **Push "món đã bán"** (code xong, chưa deploy): `firebase_messaging` → token
  gửi qua RPC `register_push_token` (lúc đăng bán thì xin quyền, lúc mở Chợ chỉ
  đăng ký lại nếu đã cấp) → bảng `push_tokens`; Database Webhook INSERT trên
  `accessory_market_trades` gọi Edge Function `supabase/functions/notify-market-sale`
  (FCM HTTP v1, 6 ngôn ngữ, số Xu nhận = giá − phí). Các bước deploy ở đầu file index.ts.
- **Chưa làm**: popup lúc rớt món (hiện chưa có popup rớt phụ kiện).

## 28. Nhiệm vụ tuần + hồ sơ người chơi (2026-10-11, chưa playtest)

- **Nhiệm vụ tuần** (`lib/core/weekly_quests.dart`, UI `weekly_quests_dialog.dart`, mở bằng nút trong hộp thoại Nhiệm
  vụ ngày): tuần bắt đầu thứ Hai 00:00 UTC; mỗi tuần chọn xác định 3/6 loại — Nhượng quyền ×2, thắng 5 màn Ghép 3, 3
  giao dịch Chợ (đăng bán hoặc mua), nhận thưởng 5 nhiệm vụ ngày, quay vòng quay ×10, mua 300 nâng cấp. Mỗi cái 50💎;
  nhận đủ 3 mở rương tuần: 150💎 + 1 phụ kiện Hiếm trở lên. Chấm đỏ ở chip Nhiệm vụ đã gộp cả tuần. Số liệu là
  ước lượng — cần playtest.
- **Hồ sơ người chơi:** bấm một dòng ở BXH Thu nhập/Trân châu/Speedrun/VIP (hoặc nút "Hồ sơ" ở hộp thoại xem bộ sưu tập)
  → hạng + điểm ở 5 bảng cá nhân qua RPC `player_profile`; có nút "Xem trên web" (`?player=`). Bảng Hội/Đấu Trường chưa có.

## 29. Tự động chạm (2026-10-12, chưa playtest)

Góp ý thật của người chơi ("tap tay mỏi quá", xin auto click). Cơ chế:
- **Bật**: xem 1 QC → 10 phút (`Balance.autoTapAdMs`), cộng dồn tối đa 1 giờ (`autoTapMaxMs`); hoặc **VIP ≥ 3**
  (`autoTapVipLevel`) bật vĩnh viễn. Mốc hết hạn lưu ở `GameState.autoTapUntilMillis` (persist, save cũ → 0).
- **Tốc độ**: `autoTapPerSecond` = 2 lần/giây × `autoTapEfficiency` = 50% một lần chạm tay (chạm tay vẫn lợi hơn).
  Công thức dùng chung với chạm tay (`tapGain` trong core/simulation.dart): Sao, perk chạm, nhân vĩnh viễn, Mưa vàng đều áp.
- **CHỈ cộng Xu**: KHÔNG tăng `tapCount`, tiến độ nhiệm vụ, điểm Hội, điểm sự kiện, thành tựu — điểm Hội là +1/lần
  chạm nên tự chạm sẽ cày đầy mốc tuần (120k) trong vài giờ. Test chặn hồi quy (`test/state/auto_tap_test.dart`).
- Chạy trong `_onTick` (không áp khi offline; dt bị cắt 5 giây để nhịp trễ không thành cú cộng lớn).
- UI: hàng "🤖 Tự động chạm 10 phút" trong hộp Kiếm thêm; chip `🤖 mm:ss` / `🤖 VIP` trong cảnh quán.
- ⚠️ Mọi số là ước lượng chưa playtest (xem `Balance`).

## 30. Thử thách hằng ngày (2026-10-12, chưa playtest)

Góp ý người chơi: "tăng nhiệm vụ / tăng độ khó nhiệm vụ (tăng cả thưởng)". 2 nhiệm vụ KHÓ mỗi ngày, chọn xác định theo
ngày (UTC) như nhiệm vụ ngày (`core/challenges.dart`), hiện thành mục "🔥 Thử thách" ở cuối hộp Nhiệm vụ ngày.
- Loại: Chạm 800–1200 · Nâng cấp 120–200 · Bắt 4–6 mèo Mưa vàng · Phục vụ 3–5 khách VIP · Thắng 2–4 màn Trân Châu Rơi
  (≥1★). Luôn cao hơn trần mục tiêu của nhiệm vụ ngày cùng loại (test chặn).
- Thưởng 25 💎/cái (`Balance.challengeRewardGems`, ≈3× nhiệm vụ ngày) + 30 💎 khi nhận cả 2 (`challengeBonusGems`).
  ⚠️ Mọi số là ước lượng chưa playtest — theo dõi lượng 💎 phát ra/ngày (tối đa 80).
- Không thêm trường lưu: dùng lại `dailyProgress`/`dailyClaimed` (khoá `challenge:*`; riêng thắng màn dùng khoá `m3Win`)
  nên tự xoá khi sang ngày. Tự động chạm KHÔNG tính (xem §29). Chấm đỏ nhiệm vụ cộng cả thử thách xong chưa nhận.

## 31. Thưởng top bảng xếp hạng theo tuần (2026-10-12, chưa playtest)

Góp ý người chơi: "thưởng cho top 1,2,3 BXH". Bốn bảng TÍCH LŨY (Thu nhập, Trân Châu Rơi, Sưu tập, VIP — không gồm Phá đảo
vì là thời gian nhanh nhất): mỗi tuần top 3 nhận **300 / 200 / 100 💎** (`core/lb_rewards.dart`, khớp SQL).
- **Server** (`supabase/leaderboard_rewards_schema.sql`): lần đầu có người gọi `lb_reward_status()` trong tuần mới thì
  server CHỤP top 3 từng bảng (lười, không cần cron; tuỳ chọn pg_cron 00:00 thứ Hai). Ai trong ảnh chụp nhận được trong
  tuần chụp + tuần kế (`lbRewardValidWeeks` = 2), MỘT lần cho mỗi (tuần, bảng) (`lb_reward_claim`). Cùng điểm → nộp sớm hơn xếp trên.
- **Chống gian lận**: điểm BXH do client tự khai nên chỉ tài khoản đã LIÊN KẾT email (không ẩn danh) và điểm > 0 vào ảnh chụp.
- **Client**: nhận → server xác nhận RỒI mới cộng 💎 cục bộ (`grantLeaderboardRewardGems`); bấm đúp được chặn; lỗi bị nuốt.
  UI: dòng "Thưởng top tuần" trong hộp Thi đấu (có chấm đỏ, cũng bật chấm đỏ nút Thi đấu), tải khi mở app/quay lại (10 phút).
- ⚠️ Tối đa 4 bảng × 600 = 2400 💎/tuần phát ra cho cả game; người ở top nhận lặp lại mỗi tuần (bảng tích lũy ít đổi top).
  ⚠️ Số liệu ước lượng chưa playtest. Kiểm server: `scripts/test_lb_rewards_sql.sh`.

## 32. Trao đổi vật phẩm ở Chợ (2026-10-12, chưa playtest)

Góp ý người chơi: "thêm tính năng trao đổi vật phẩm", "Chợ toàn vô hạn xu". Tab thứ 3 "Trao đổi" trong Chợ: đổi MÓN LẤY MÓN, không qua Xu Chợ.
- **Đề nghị**: người đăng đưa món X (ký quỹ — rời `accessory_server_ownership` ngay) và nói muốn món Y (cụ thể). Tối đa 5 đề nghị mở/người
  (`swapMaxOpen`, khớp `swap_max_open()`), sống 3 ngày như tin đăng (`market_listing_days()`), hết hạn thì món về kho.
- **Nhận**: người khác đang có Y và bấm Đổi (nút khoá nếu chưa có Y) → MỘT transaction ở server: Y sang người đăng, X sang người nhận.
  Không phí, không ai tự nhận đề nghị của mình. Máy người nhận cập nhật kho ngay; máy người đăng nhận món qua `swap_collect()`
  khi mở Chợ — hai pha thêm-local-rồi-ack như `expire_my_listings` (app tắt giữa chừng không mất món, tối đa dư 1 bản).
- Server: `supabase/accessory_swap_schema.sql` (sau accessory_market_schema). Kiểm: `scripts/test_swap_sql.sh`.
- ⚠️ Cùng mức tin cậy với Chợ: số bản sao do client tự khai (`register_accessory_copies`), nên người gian lận có thể khai món ảo rồi đổi lấy món thật.
  Chưa có: thông báo đẩy khi đề nghị được nhận, "muốn bất kỳ món độ hiếm X", gợi ý theo danh sách muốn có.

## 33. Animation, khách đi ngang cảnh và boa (2026-10-14, chưa playtest)

Kế hoạch đầy đủ ở `PLAN_ANIMATION.md`. Tóm tắt phần ảnh hưởng chơi:
- **Mức hiệu ứng** (Tắt/Thấp/Vừa/Cao; Cài đặt → "Hiệu ứng động"): tự chọn theo RAM/đời máy lúc mở app, tự hạ khi >15% khung chậm, người chơi chỉnh tay được. Chỉ là hình ảnh — không đổi cân bằng.
- **Khách đi ngang** (giai đoạn 1–12): 3 kiểu, thưa dần theo mức hiệu ứng (Cao 6–14s, Vừa 12–26s, Thấp 45–70s giữa hai lượt).
- **Boa** (có tác động kinh tế nhỏ): ~70% khách mang bong bóng 💲 trên đầu khi hết thời gian hồi; bấm → nhận
  `walkerTipSeconds`=8 giây sản xuất (sàn `walkerTipFloorTaps`=5 lần chạm), CHỈ Xu, không 💎. Thời gian hồi
  `walkerTipCooldownMs`=90s (chỉ trong bộ nhớ) ⇒ tối đa ~9% thu nhập thêm (khách VIP ~18%).
  Người chơi để mức hiệu ứng Tắt thì không có khách nên không nhận boa — chấp nhận (boa chỉ là thưởng nhỏ cho người nhìn màn chính).
  ⚠️ Số liệu ước lượng, chưa playtest; cân nhắc hạ nếu tổng với VIP quá hào phóng.

## 34. Công thức pha chế — trò luyện nhớ (2026-10-14, lộ trình A, chưa playtest)

Mở rộng game bằng trò ghi nhớ công thức. Dữ liệu: `scripts/data/recipes_source.md` (100 món, chủ dự án cung cấp) → `scripts/make_recipes.py` → `assets/recipes/recipes.json`. Mới chơi được nhóm 1 (20 món trà sữa truyền thống, `recipePlayableGroups`); 80 món còn lại đã có sẵn trong dữ liệu.
- **Vào**: tab "Trò chơi" (cuối thanh dưới, trước là tab "Trân châu") → hộp gộp 2 trò: Trân Châu Rơi + Công thức pha chế (hiện số món cần ôn hôm nay). `lib/ui/games_hub_dialog.dart`, cùng kiểu hộp Thi đấu. Màn: tiến độ "Thạo n/20", số món cần ôn hôm nay, nút Luyện tập, danh sách món kèm bậc; bấm món xem thẻ công thức (nguyên liệu + lượng + lịch ôn).
- **Bậc thuộc** (0 Mới → 1 Quen → 2 Thuộc → 3 Thạo) theo ôn cách quãng: chỉ khi món ĐẾN HẠN ôn (`dueDay`) câu trả lời mới đổi bậc — đúng: lên một bậc, hẹn sau 0/1/3/7 ngày (`recipeIntervalDays`); sai: xuống một bậc, ôn lại ngay. Món chưa tới hạn chỉ để luyện (có báo) ⇒ không cày một món lên bậc trong một buổi; chạm Thạo cần ≥ 4 ngày.
- **Buổi luyện** 8 câu trắc nghiệm 4 lựa chọn: ưu tiên món đến hạn (bậc thấp trước), thiếu thì bù món chưa tới hạn. Loại câu theo bậc: Mới = điền nguyên liệu còn thiếu (thấy lượng); Quen = đoán lượng; Thuộc/Thạo = chọn công thức đầy đủ đúng (3 bản sai lệch đúng một chi tiết) xen câu đoán lượng. Bậc ghi ngay sau mỗi câu (thoát giữa chừng không mất).
- **Thưởng** (chỉ khi LẦN ĐẦU đạt bậc cao hơn mọi lần trước của món — `best`, nên sai-rồi-đúng-lại không thưởng lần hai): Xu = 30/60/120 giây sản xuất ở bậc 1/2/3 (sàn 5/10/20 lần chạm); thêm 3 💎 ở bậc Thạo. Tổng tối đa một lần duy nhất: 20 món × (Xu + 3💎) = 60 💎. ⚠️ số liệu ước lượng.
- **Lưu**: `GameState.recipeProgress` (id → `[box, dueDay, best]`) — đi theo save/cloud; mục hỏng bị bỏ khi đọc.
- **Ngôn ngữ**: giao diện đủ 7 thứ tiếng; TÊN món/nguyên liệu chỉ có tiếng Việt (nội dung dữ liệu) — người chơi ngôn ngữ khác thấy tên Việt.
- **Chưa làm** (lộ trình B–D trong thảo luận): kéo-thả pha theo đơn khách, nối khách đi ngang/thực đơn, BXH, PK Đấu Trường, nhóm 2–5, hình nguyên liệu riêng (đang dùng emoji + chữ).

### 34b. Công thức pha chế — đợt 1: quảng cáo + nhiệm vụ (2026-10-14, chưa playtest)
- **Banner** dưới màn luyện (cùng `BannerAdBox` với Trân Châu Rơi; tự ẩn khi gỡ QC/VIP hoặc không phải di động), cách nút "Câu tiếp" 8dp để khỏi bấm nhầm.
- **Gợi ý 50:50** (xem quảng cáo thưởng): bỏ 2 đáp án sai của câu hiện tại, mỗi câu một lần. Câu dùng gợi ý **không tính bậc, không thưởng** (`answerRecipe(hinted: true)`) — nếu không người chơi mua bậc bằng quảng cáo và phá ôn cách quãng.
- **Nhân đôi Xu thưởng** ở màn tổng kết (xem QC, một lần mỗi buổi; chỉ Xu, không 💎).
- **Nhiệm vụ**: ngày — "Hoàn thành 1 buổi luyện công thức" thay nhiệm vụ cuối vào các ngày CHẴN từ 2026-10-20 (`recipeQuestsStartDay`); tuần — nhiệm vụ cuối luôn là công thức, luân phiên "4 buổi" / "lên bậc 6 công thức" theo tuần chẵn/lẻ từ tuần đó. Trước mốc, bộ chọn giữ y thuật toán cũ (các ngày/tuần đã qua không đổi). Một buổi chỉ được tính khi có ≥ 1 câu thật sự tính bậc (món đến hạn, không dùng gợi ý) — buổi chỉ-luyện không cày được nhiệm vụ.
- Cập nhật app giữa ngày/tuần đúng vào mốc có thể làm bộ nhiệm vụ đổi một lần (không tránh được vì bộ chọn xác định theo ngày).
- **Chưa làm** (đợt 2–3): BXH "Thợ pha chế" + thưởng top tuần, rương phụ kiện theo mốc, chuỗi ngày ôn + cứu chuỗi, thông báo nhắc.

### 34c. Công thức pha chế — đợt 2: BXH Thợ pha chế + thưởng top tuần + rương phụ kiện (2026-10-14, chưa playtest)
- **BXH "Thợ pha chế"**: xếp theo SỐ MÓN ĐÃ TỪNG đạt Thạo (`recipeMasteredEver`, đếm theo `best` ⇒ chỉ tăng; hoà thì ai nộp sớm hơn xếp trên). Vào từ biểu tượng cúp ở màn công thức. Server: `supabase/recipe_leaderboard_schema.sql` (trần 100 = số món, trigger không-hạ-cấp, RLS chỉ hàng của mình, top kẹp 100); dùng chung tên người chơi/khung/huy hiệu với các bảng khác.
- **Thưởng top tuần**: thành bảng thứ 5 (`LbBoard.recipes`) trong `leaderboard_rewards_schema.sql` — top 3 nhận 300/200/100💎 như 4 bảng kia, chỉ tài khoản đã liên kết email và > 0 món. Tuần đã chụp trước khi chạy SQL mới sẽ chưa có bảng này (tuần sau mới có).
- **Rương phụ kiện theo mốc** `recipeAccessoryMilestones`: món Thạo (từng) thứ 5 → Hiếm+, 10 → Sử thi+, 20 → Huyền thoại; nhận TỰ ĐỘNG một lần mỗi mốc (cờ `recipeMilestonesClaimed` trong save), có hiệu ứng nhận phụ kiện và dòng báo ở màn luyện.
- ⚠️ **Chống gian lận hạn chế**: số món Thạo do client tự khai như các bảng khác; "đạt Thạo cần ≥ 4 ngày" không kiểm được ở server vì không biết ngày bắt đầu luyện. Ràng buộc kiểm được: 0..100, chỉ tăng, ảnh chụp thưởng chỉ nhận tài khoản liên kết email.
- **Triển khai**: chạy `recipe_leaderboard_schema.sql` TRƯỚC rồi `leaderboard_rewards_schema.sql` (idempotent, bản mới có CHECK 5 bảng). Kiểm bằng `scripts/test_lb_rewards_sql.sh` (đã gồm kịch bản BXH + thưởng bảng thứ 5).
- **Chưa làm**: bản web của BXH này, hồ sơ người chơi web hiển thị hạng Thợ pha chế (`player_profile_schema.sql`), tool admin xem bảng mới.

### 34d. Công thức pha chế — đợt 3: chuỗi ngày ôn, cứu chuỗi, nhắc ôn (2026-10-14, chưa playtest)
- **Chuỗi ngày ôn** (`RecipeStreak`: số ngày, ngày ôn gần nhất, kỷ lục — lưu trong save): +1 mỗi ngày (UTC, như điểm danh) có ít nhất một câu THẬT SỰ được tính bậc (món đến hạn, không dùng gợi ý); lỡ ≥ 1 ngày thì bắt đầu lại từ 1. Hiện ở màn công thức ("🔥 Chuỗi ôn: N ngày" + "hôm nay đã/chưa ôn") và ở phản hồi câu đầu tiên mỗi ngày.
- **Thưởng mốc** `recipeStreakMilestoneGems`: 3→10💎, 7→30, 14→60, 30→150 — CHỈ khi vượt kỷ lục cũ, nên đứt rồi gây lại không nhận lặp.
- **Cứu chuỗi**: lỡ ĐÚNG một ngày và chuỗi ≥ 2 → thẻ "Bạn lỡ một ngày…" với hai cách: trả `recipeStreakRestoreGems` = 30💎, hoặc xem quảng cáo thưởng (người gỡ QC/VIP cứu thẳng). Cứu xong chuỗi +1 (coi ngày lỡ như đã ôn), câu ôn hôm nay nối tiếp thành +1 nữa; không cứu lại được. Lỡ ≥ 2 ngày thì mất.
- **Nhắc ôn** (thông báo cục bộ, id 8, xin quyền như các nhắc khác): một lần lúc 20:00 giờ máy — "chuỗi N ngày sắp mất" (chuỗi ≥ 2 mà hôm đó chưa ôn) ưu tiên hơn "N món đến hạn ôn". Người chưa từng luyện không bị nhắc. Lập kế hoạch ở `lib/notify/recipe_reminder.dart` (thuần, có test).
- ⚠️ Giá 30💎 và các mốc ước lượng, chưa playtest.

### 34e. Công thức pha chế — animation (2026-10-14, chưa xem trên máy thật)
Mọi chuyển động theo mức hiệu ứng (`EffectsQuality`/`reduceMotion`, xem PLAN_ANIMATION.md): Tắt = không có gì chuyển động, Thấp bỏ hiệu ứng nặng, và `playEffect` có trần số hiệu ứng cùng lúc.
- **Buổi luyện**: lựa chọn SAI lắc ngang, đáp án ĐÚNG nảy; đúng → tia sáng nhỏ tại ô vừa chọn; lên bậc → hiệu ứng lên cấp (nặng); mốc chuỗi 💎 → tia 💎; đạt mốc rương phụ kiện → pháo giấy + hiệu ứng nhận phụ kiện; đúng cả buổi → pháo giấy ở tổng kết. Chuyển câu trượt + mờ; thanh tiến độ và thanh "Thạo" chạy mượt; điểm tổng kết đếm lên.
- **Màn công thức**: cốc trà bốc hơi (Lottie `steam`, qua nhịp chung 30Hz, tắt thì về ☕ tĩnh), thẻ món hiện dần, chip bậc nảy khi tăng, hàng chuỗi nảy khi tăng, thẻ cứu chuỗi nảy hai nhịp khi hiện.
- **Không ép vẽ khung khi đứng yên** (có test): mọi animation đều hữu hạn; riêng cốc hơi nước lặp nhưng dừng khi bị trang khác phủ lên.
- Sửa kèm: vùng câu hỏi dùng cuộn thường (không dựng lười) và sau khi trả lời tự cuộn tới đáp án đúng — trước đó ở màn thấp/chữ to đáp án đúng có thể nằm ngoài tầm nhìn sau khi bảng phản hồi ở đáy hiện ra.

### 34f. Công thức pha chế — làm đẹp giao diện (2026-10-15)
- Màn công thức: thẻ tóm tắt nổi (tiêu đề lớn, thanh "Thạo" dày có 3 hòm quà mốc 5/10/20 sáng/mờ, viên thuốc "N món cần ôn" và "🔥 chuỗi", nút Luyện tập to có biểu tượng); mỗi món có vạch màu theo bậc ở mép trái, emoji nguyên liệu lớn hơn, chip bậc sát mép phải (lỗi cũ: Flexible chia đôi chỗ với Expanded làm chip nằm lưng chừng).
- Buổi luyện: câu hỏi trong "phiếu gọi món" (🧋), lựa chọn là thẻ nổi có huy hiệu A–D → ✓/✗ sau khi trả lời, công thức đầy đủ vẽ thành các hàng emoji + tên + lượng (thay vì chữ thô), khung phản hồi ngả xanh/đỏ kèm 🎉/💡; tổng kết có 🏆/🎉/💪 và 1–3 sao theo tỉ lệ đúng.
- BXH: 🥇🥈🥉 cho top 3, hàng của mình có viền màu chủ đạo.

### 34g. Công thức pha chế — mở cả 5 nhóm (100 món) (2026-10-15, chưa playtest)
- **5 nhóm × 20 món** (Trà sữa truyền thống, Trà trái cây, Latte và đồ uống sữa, Cà phê và espresso, Đồ uống đặc biệt), mở THEO THỨ TỰ: nhóm 1 mở sẵn; nhóm kế mở khi nhóm ngay trước có ≥ `recipeGroupUnlockLearned` = 10 món từng đạt bậc Thuộc (`best` ≥ 2) — đếm theo `best` nên đã mở là mở mãi. Lý do: nếu mở cả 100 món ngay, buổi luyện (8 câu, ưu tiên món đến hạn — món mới đều "đến hạn") sẽ rải ngẫu nhiên khắp 100 món và gần như không ôn lại được món nào.
- Hiển thị: nhóm đã mở có tiêu đề + danh sách; nhóm KẾ TIẾP hiện dòng khoá có tiến độ "x/10"; các nhóm xa hơn chỉ "🔒 tên nhóm". "Thạo n/N", thanh mốc, số món cần ôn, buổi luyện, hộp Trò chơi đều chỉ tính nhóm đã mở. Cuối buổi vừa mở nhóm mới → thẻ "🔓 Đã mở nhóm mới" + pháo giấy.
- Đáp án nhiễu lấy từ CÙNG nhóm (đồ cà phê nhiễu bằng nguyên liệu cà phê). Emoji: mọi nguyên liệu của 100 món đều có emoji riêng (test kiểm).
- Rương phụ kiện mở rộng: 5 → Hiếm, 10 → Sử thi, 20/40/60/80/100 → Huyền thoại. BXH Thợ pha chế trần 100 (SQL đã khớp) — KHÔNG cần chạy lại SQL.
- Tên món/nguyên liệu/nhóm vẫn chỉ tiếng Việt (nội dung dữ liệu). Chưa làm: hình nguyên liệu riêng, PK, kéo-thả pha theo đơn.

### 34h. Công thức pha chế — tên món/nguyên liệu/nhóm đủ 7 ngôn ngữ (2026-10-15)
- Dịch 100 tên món + 96 nguyên liệu + 5 nhóm sang en/es/id/ko/pt/th (vi là dữ liệu gốc). Nguồn: `scripts/data/recipe_names.py` → `python3 scripts/make_recipe_names.py` → `assets/recipes/names.json` (script kiểm đủ/khớp với recipes.json).
- Dữ liệu gốc (tiếng Việt) vẫn là KHOÁ ra đề và so đáp án; bản dịch chỉ dùng HIỂN THỊ (`RecipeNames`/`RecipeLabels` trong `lib/core/recipe_names.dart`). Thiếu bản dịch / chưa nạp xong / lỗi nạp → rơi về tên tiếng Việt, không bao giờ trống. Đơn vị và lượng (g, ml) không đổi theo ngôn ngữ.
- Test: đủ và khớp dữ liệu gốc ở cả 6 ngôn ngữ, không trùng nhãn trong cùng ngôn ngữ, đúng chữ viết (không sót tiếng Việt ở en/es/id/pt; có chữ Hàn/Thái ở ko/th), độ dài ≤ 48 ký tự; giao diện hiện tên đã dịch ở hộp thẻ, đề, lựa chọn, công thức đầy đủ.
- ⚠️ Bản dịch do AI soạn, CHƯA có người bản ngữ rà — nên nhờ người bản ngữ xem tên nguyên liệu/món ở ko, th, id trước khi phát hành rộng. Một số cách gọi cố ý giữ như tên thông dụng (Bac Xiu, Thai tea, Boba).

### 34i. Công thức pha chế — "Pha theo đơn" kéo-thả (2026-10-15)
- Trò RIÊNG trong hộp Trò chơi (mục `games-orders`, cạnh Trân Châu Rơi và Công thức; cúp BXH ở thanh trên, qua cổng email). Buổi 5 đơn: khách gọi một món, người chơi kéo (hoặc chạm) nguyên liệu từ khay vào ly, đặt lượng bằng thanh trượt theo mức rời rạc (`amountSteps`, mọi lượng trong dữ liệu đều nằm trên thanh — test kiểm), bấm "Phục vụ".
- Logic thuần ở `lib/core/recipe_orders.dart` (chọn món dùng chung `pickRecipes` với trắc nghiệm): gợi ý giảm theo bậc (Mới: công thức mẫu → Quen: chỉ tên → Thuộc: chỉ số lượng → Thạo: không gợi ý), khay = nguyên liệu của món + nhiễu cùng nhóm (+2…+5 theo bậc), dung sai lượng ±1 mức ở bậc Mới/Quen, đúng từng mức từ bậc Thuộc. Thiếu/thừa nguyên liệu là sai.
- Ghi bậc/thưởng/chuỗi/nhiệm vụ qua cùng `answerRecipe` + `completeRecipeSession` như trắc nghiệm (đúng = đủ, không thừa, lượng trong dung sai). 3 sao = mọi lượng chính xác.
- Gợi ý bằng QC (`order-hint`, chỉ khi đơn chưa có công thức mẫu): hiện công thức mẫu đầy đủ; đơn đó `answerRecipe(hinted: true)` ⇒ không tính bậc, không vào BXH. Nhân đôi Xu thưởng cuối buổi bằng QC (`order-double`), giống trắc nghiệm.
- **BXH Pha theo đơn** (tab thứ hai của `RecipeLeaderboardPage`, `RecipeBoard.orders`): xếp theo số món ĐÃ TỪNG pha 3 sao mà không thấy công thức mẫu (không bậc Mới, không gợi ý QC) — `GameState.recipeOrderPerfect` (id không trùng, chỉ tăng; ghi qua `recordOrderPerfect`). SQL `supabase/recipe_order_leaderboard_schema.sql` (PHẢI chạy), ghi bắt buộc `is_linked_user()` ngay ở server. Chưa có thưởng top tuần cho bảng này (bảng thưởng vẫn 5 bảng).
- **Mọi BXH cần liên kết email**: lối vào BXH Thợ pha chế (cúp ở màn công thức) vừa được thêm `ensureOnlineLinked`; test `online_gate_entrypoints_test.dart` giờ TỰ DÒ mọi hàm `show*Leaderboard/Speedrun` và đòi cổng ở nơi gọi (trừ BXH Hội nằm trong trang Hội). Các bảng cũ vẫn chỉ chặn ở app, chưa ép ở server (bảng mới thì ép).
- Giao diện: `lib/ui/recipe_order_page.dart`; test `test/core/recipe_orders_test.dart`, `test/ui/recipe_order_ui_test.dart`, `test/ui/recipe_leaderboard_page_test.dart`, SQL qua `scripts/test_lb_rewards_sql.sh`.

### 34j. Pha theo đơn — cảm giác pha + khách đứng quầy (2026-10-15)
- **Ly nhiều lớp** (`OrderCup` trong `lib/ui/widgets/order_visuals.dart`): mỗi nguyên liệu một lớp màu (`ingredientColor`, theo từ khoá như `ingredientEmoji`), lớp mới dâng lên mượt; tổng vượt 100% thì co lại cho vừa.
- **Giữ để rót**: bảng đặt lượng có nút `order-hold` — chạm nhẹ = 1 mức, giữ càng lâu càng nhanh (170→110→70 ms/mức, rung nhẹ mỗi mức), thả là dừng; "Rót lại" về 0; thanh trượt vẫn còn để chỉnh tinh. Rót từ ly rỗng; vẫn dùng đúng các mốc lượng cũ nên chấm điểm không đổi.
- **Đậy nắp + lắc ly** ~1 giây sau "Phục vụ" rồi mới chấm (khoá sửa nguyên liệu trong lúc đó). Tắt/giảm hiệu ứng ⇒ chấm ngay.
- **Khách đứng quầy** (`OrderCustomer`): avatar emoji (ổn định theo món + số thứ tự đơn) trượt vào, bong bóng nói đơn, nét mặt 🙂 chờ → 😍 hoàn hảo / 😊 đạt / 😕 sai (nảy khi vui, lắc khi buồn). ⚠️ Là emoji + animation Flutter, KHÔNG phải Lottie nhân vật: bộ `customer_walking*` chỉ có cảnh đi bộ, chưa có tư thế đứng/phản ứng — muốn đẹp hơn cần thêm asset.
- Test: `test/ui/order_visuals_test.dart`, `test/ui/recipe_order_motion_test.dart` (bật animation), mở rộng `recipe_order_ui_test.dart`.

### 34k. Pha theo đơn — vạch mốc, topping rơi, combo, thử thách hằng ngày (2026-10-15)
- **Vạch mốc theo bậc** (bảng đặt lượng): bậc Mới (hoặc đã xem công thức mẫu bằng QC) có thước chia + vạch XANH ở đúng lượng của công thức; bậc Quen chỉ có thước; Thuộc/Thạo ẩn hết. Nguyên liệu gây nhiễu không có vạch mốc. Vạch chia ở mọi 3 mức (thước thang `0.9` chiều cao ly).
- **Topping rơi** (`isTopping`: trân châu, thạch, pudding, oreo, đậu đỏ): cho vào ly thì ~7 viên rơi xuống mặt nước (animation hữu hạn, tắt khi giảm chuyển động).
- **Combo**: đơn HOÀN HẢO không gợi ý liên tiếp trong buổi; từ combo 2 có tip Xu = boa-nền × 0.5/1/1.5/2 (kẹp ở combo 5) — `orderComboTipFactor`, `grantOrderTip`. Tip chỉ trả khi đơn thật sự được tính bậc (món đến hạn ôn) để không cày bằng món dễ lặp lại; ngoài ra vẫn hiện chip "🔥 Combo ×n". Sai hoặc dùng gợi ý QC thì đứt. ⚠️ hệ số ước lượng.
- **Thử thách hằng ngày** (mục `games-daily` trong hộp Trò chơi; `RecipeOrderPage(daily: true)`): 3 đơn CỐ ĐỊNH theo ngày UTC cho mọi người (`buildDailyOrders`, gieo `Random(day*7919+17)` trên nhóm 1; ⚠️ đổi cách chọn = đổi đề của mọi người), như bậc Thạo (không gợi ý, 5 nhiễu, đúng từng mức). Điểm đơn 0..100 (`scoreOrder`: đúng 1, lệch 1 mức 0.5, thiếu 0, thừa −0.5), tổng 0..300. MỖI NGÀY MỘT LẦN (`recipeDailyDay/Score`); không ghi bậc, không combo, không vào BXH Pha theo đơn. Thưởng `completeDailyChallenge`: 5💎 + Xu tỉ lệ điểm.
- **BXH hôm nay** (tab thứ ba, `RecipeBoard.daily`): `supabase/recipe_daily_schema.sql` (**PHẢI chạy**). Mỗi (người, ngày) một hàng bất biến (chỉ policy INSERT; app nộp bằng upsert DO NOTHING), ngày do SERVER đặt, ghi cần liên kết email; top chỉ tính hôm nay (ngày server UTC, cùng cách tính `dayIndex`).
- **Chưa làm (để mai)**: mục 9 chia sẻ ly vừa pha, mục 10 trang trí quầy bằng phụ kiện; khách vẫn là emoji (chưa Lottie đứng quầy); thưởng top tuần cho BXH Pha theo đơn / Hôm nay.

### 34l. Pha theo đơn — Giờ cao điểm (2026-10-16)
- **Tùy chọn** (công tắc `order-rush-toggle`, chỉ hiện ở đơn đầu khi ly còn trống; KHÔNG có trong thử thách ngày để BXH công bằng). Bật thì mỗi đơn có thanh kiên nhẫn `order-patience` (xanh → cam → đỏ), `orderPatienceSeconds(n) = 20 + 8n` giây (n = số nguyên liệu). Đồng hồ tạm dừng khi bảng đặt lượng mở / đang xem QC / đang đậy nắp.
- **Hết giờ**: khách bỏ đi, ly bị chấm NGUYÊN TRẠNG (ly trống thì sai) như phục vụ bình thường ⇒ vẫn ảnh hưởng bậc thuộc như đáp sai; đứt combo; không tip. Dòng "⏰ Hết giờ!" trong phản hồi.
- **Thưởng**: đơn hoàn hảo, không gợi ý, KỊP GIỜ và tính bậc (món đến hạn — chống cày) nhận tip `orderRushBonusFactor` (=1 boa-nền) cộng vào tip combo (`grantOrderTip(combo, rush:)`). ⚠️ hệ số và thời gian là ước lượng, chưa playtest.
- **Chưa làm**: khách Lottie đứng quầy (cần asset mới); thưởng top tuần cho BXH Hôm nay (điểm theo ngày, không cộng dồn — chưa có thiết kế phù hợp).

### 34m. Pha theo đơn — đơn lễ hội (2026-10-16)
- Trong dịp lễ (`activeFestival`), buổi Pha theo đơn thường có thêm MỘT "đơn lễ hội" ở cuối (6 đơn thay vì 5): chip `order-festival` + khách mang emoji của dịp. Chỉ ở chế độ thường (không có trong thử thách ngày).
- Món theo chủ đề dịp: `festivalRecipeIds` (recipe_orders.dart), toàn món nhóm 1–2; xoay theo ngày; bỏ món đã có trong buổi; không có món hợp lệ ⇒ không thêm đơn. **Thêm dịp lễ mới ở `accessories.dart` ⇒ phải thêm dòng ở đây** (test `đơn lễ hội` bắt thiếu).
- Là đơn bình thường (ghi bậc, gợi ý, Giờ cao điểm, combo). Thưởng: hoàn hảo + không gợi ý + tính bậc ⇒ tip `orderFestivalBonusFactor` (=2 boa-nền) cộng dồn với combo/rush. KHÔNG cộng điểm sự kiện (giữ nguyên bài toán 100 < 115 điểm của `event_quests`). ⚠️ hệ số ước lượng, chưa playtest.
- Kèm sửa: dòng nguyên liệu trong ly (tên + lượng) giờ co được, tránh tràn 13px ở 320px/chữ 1.5×.
- **Chưa làm**: khách Lottie đứng quầy (cần asset mới); thưởng top tuần cho BXH Hôm nay (điểm theo ngày, không cộng dồn — chưa có thiết kế phù hợp).

### 34n. Pha theo đơn — khoe ly, kệ trưng bày, thưởng top tuần (2026-10-16)
- **Khoe ly** (`order-share`): đơn 3 sao (cả thử thách ngày) có nút mở `CupCard` (ly đậy nắp đúng màu các lớp + tên món + 3 sao) → chụp bằng RepaintBoundary, chia sẻ qua `shareImageProvider` (cùng khuôn thẻ sưu tập), lời kèm `bobaempiregame.com`. ⚠️ tên file ảnh chia sẻ dùng chung `boba_collection.png`.
- **Kệ trưng bày** (`order-shelf`, `lib/core/recipe_counter.dart`): đầu màn đơn hiện phụ kiện đang trưng bày ở màn chính + chỗ phụ mở theo số món Thạo (10 / 30 / 60 ⇒ +1/+2/+3, lấy món hiếm nhất còn lại, cả độc quyền lễ hội). Chỉ để ngắm — không ảnh hưởng chơi. Chưa có phụ kiện thì ẩn; chưa đủ mốc thì có dòng nhắc "Thạo N món để mở thêm 1 chỗ".
- **Thưởng top tuần cho BXH Pha theo đơn**: thêm `orders` vào `leaderboard_rewards_schema.sql` (CHECK + snapshot từ `recipe_order_leaderboard_entries.perfected`) và `LbBoard.orders` (300/200/100💎). **PHẢI chạy lại `leaderboard_rewards_schema.sql`** (idempotent; sau `recipe_order_leaderboard_schema.sql`). Bảng "Hôm nay" cố ý KHÔNG có thưởng tuần.
- **Chưa làm**: khách Lottie đứng quầy (cần asset mới); thưởng cho BXH Hôm nay.

### 34o. Khách đi ngang gọi món — lộ trình C (2026-10-16, chưa playtest)
- Khách đi ngang cảnh quán (GĐ1–12) không mang boa thì 40% có **bong bóng 🧋** (`walker-order`). Chạm → `showRecipeOrderFor`: Pha theo đơn buổi **MỘT đơn**, món chọn bằng `pickRecipes` (đến hạn trước, bậc thấp trước) trong các nhóm đã mở. Đơn tính bậc/nhiệm vụ như đơn thường — chỉ khi món ĐẾN HẠN ôn (`counted`), nên không cày được bằng cách bấm liên tục. Không cần SQL, không có thưởng riêng.
- Không có art mới. Chưa làm: hiện tên món trên bong bóng, thực đơn quán tăng thu nhập thụ động (đã bỏ khỏi phạm vi).

### 34p. PK Công thức — lộ trình D (2026-10-16, chưa playtest)
- Dạng thứ 3 của Đấu Trường (`ArenaMode.recipe`, hàng đợi riêng): ghép 2 người, server chọn **5 món KHÁC nhau của nhóm 1** (ai cũng đã mở; lưu ở `arena_matches.seq`), cả hai pha CÙNG 5 đơn, trận **180 giây**. Mỗi đơn là một đơn Pha theo đơn bậc Thạo (không gợi ý, lượng phải đúng); khay/thứ tự khay mỗi người một khác.
- **Chấm ở server**: `arena_submit_order(match, idx, tên[], lượng[])` chấm bằng `arena_recipe_order_score` (khớp `scoreOrder`: đúng +1, lệch 1 mức +0.5, thừa −0.5, chia số nguyên liệu, 0..100/đơn), ghi `arena_actions.score`. Mỗi đơn nộp MỘT lần, chỉ trong giờ. Điểm trận = tổng 5 đơn (tối đa 500). Hòa ⇒ `winner` null.
- Xong cả hai đủ 5 đơn thì chốt sớm (`arena_resolve_match` cho phép trước `ends_at` riêng dạng này); không thì chờ hết giờ — đơn chưa làm tính 0.
- Màn Đấu Trường dạng này: đầu trận (đồng hồ + điểm hai bên, như Trân Châu Rơi) + dòng tiến độ + nút **Vào pha** (mở `RecipeOrderPage(pk:)`; tự đóng khi hết giờ hoặc xong đơn 5; thoát giữa chừng thì vào lại, đơn đã nộp được bỏ qua). Thưởng 💎 và BXH dùng chung với 2 dạng kia.
- ⚠️ **Giới hạn chống gian lận**: công thức là dữ liệu công khai nên script có thể nộp đáp án hoàn hảo. Server chỉ chặn nộp tức thì (mỗi đơn phải cách mốc trước ≥ 1 giây × số nguyên liệu, `too fast`) — script biết chờ vẫn thắng được. Muốn chặt hơn: thưởng 💎 theo hạng thay vì theo trận, hoặc đổi sang đề có yếu tố người chơi (không công khai).
- **PHẢI chạy lại `supabase/arena_schema.sql`** (idempotent; thêm bảng `arena_recipes`, 3 cột `arena_actions`, hàm chấm/nộp, sửa ghép trận + chốt trận). Test: `scripts/test_arena_recipe_sql.sh` (Postgres tạm) + `test/arena/arena_recipe_score_test.dart` (vector Dart⇔SQL và đối chiếu dữ liệu món/bước lượng trong SQL với assets).
- Đổi danh sách món nhóm 1 ở `recipes.json` ⇒ phải cập nhật INSERT `arena_recipes` (test sẽ đỏ nhắc).

## 35. Hồi 4 — "Đại Hội Tay Nghề" (Chương 37-46, 2026-10-16, chưa playtest)

> ⚠️ Ngưỡng là **ước lượng, chưa playtest**. Ý tưởng (góp ý người chơi 2026-10-12: "hết nội dung sau Kỷ Nguyên 4"): 10 "màn",
> MỖI MÀN phải vượt qua một mốc của các trò chơi nhỏ — không chương nào mở bằng Xu/thời gian chờ.

- **Nhân vật**: vẫn **🌀 Thầy Cả** (mở Đại Hội Tay Nghề, 10 thử thách). Prose có đủ 7 ngôn ngữ (vi/en viết tay; es/id/pt/th/ko do máy dịch, **chưa có người bản ngữ duyệt**) — riêng Hồi 4; các chương cũ ngoài vi/en vẫn fallback `en`.
- **Mốc từng chương** (xen kẽ 4 trò, leo thang): 37 Thạo **5** món (Công thức) · 38 qua màn **65** Trân Châu Rơi · 39 pha hoàn hảo **5** món (Pha theo đơn) · 40 Thử thách hằng ngày **2** ngày · 41 Thạo **20** món · 42 màn **75** · 43 hoàn hảo **15** món · 44 thử thách **5** ngày · 45 Thạo **50** món · 46 hoàn hảo **40** món (chương lựa chọn, **trục H**).
- **3 trigger mới** trong `StoryTrigger`: `recipeMastered` (`recipeMasteredEver(recipeProgress)` ≥ value, tính món TỪNG Thạo nên tụt bậc không làm mất mốc), `orderPerfect` (`recipeOrderPerfect.length`), `dailyDone` (`GameState.recipeDailyCount`, +1 mỗi NGÀY làm thử thách trong `completeDailyChallenge`). `storyTriggerMet`/`storyUnlockProgress` thêm 3 tham số named mặc định 0 (không vỡ chỗ gọi cũ); Nhật ký hiện điều kiện + thanh tiến độ cho chương kế.
- **Trục H (Chương 46)**: `mastery` (+8% giá trị chạm) / `spirit` (+8% thu nhập tự động), vĩnh viễn, cộng dồn với A-F.
- **Sửa kèm (lỗi có sẵn)**: lựa chọn **trục G (Chương 36)** hứa +8% nhưng `economy.dart` KHÔNG áp ⇒ giờ áp (`secret` → chạm, `open` → thu nhập). Người đã chọn G được buff đúng như mô tả.
- **Mốc "phá đảo" Hồi 4** = `storyFourthActFinaleChapterId` (=46), `GameState.storyFourthActCompleteSeconds`, chốt trong `_stampStoryFinales`; bảng Tốc độ có tab thứ 4; web (`docs/assets/site.js`) và `tools/admin.html` gộp thêm bảng 4.
- **Server**: `supabase/story_speedrun4_schema.sql` (**PHẢI chạy** thì tab "Hồi 4" mới có dữ liệu; cùng khuôn story_speedrun3: insert-only, 1 mốc/người, CHECK > 0; đã thử trên Postgres tạm: idempotent, trùng/giả danh/0/sửa đều bị chặn, anon đọc được top).
- GameState +3 field (giữ qua prestige/Kỷ Nguyên, JSON back-compat): `storyChoiceH`, `storyFourthActCompleteSeconds`, `recipeDailyCount`.
- Chương mở khi người chơi hoàn tất hành động ở trò chơi nhỏ (snapshot được dựng lại ngay) ⇒ cutscene hiện ở lần về màn chính kế tiếp, không cần chờ tick.
- **Kiểm thử đã làm**: chơi suốt Hồi 4 bằng API thật của controller (đường `answerRecipe` thật cho mốc món Thạo, `recordOrderPerfect`, `completeDailyChallenge` qua nhiều ngày), cutscene tự hiện trên màn chính khi xong mốc, Chương 46 chọn nhánh + chốt mốc + lưu đĩa, Nhật ký/cutscene không tràn 7 ngôn ngữ ở 320px/chữ 1.5×.
- **Giờ cao điểm đứng khi có popup che màn** (`ModalRoute.isCurrent`): cutscene Hồi 4 có thể bật giữa lúc pha đơn (vừa đủ mốc) — khách không bỏ đi lúc người chơi đang đọc.
- **Đã sửa (2026-10-16)**: header giai đoạn (`_StageHeader`) tràn 4.7px ở en/es/id/pt, 320px, chữ 1.5×, giai đoạn 18 — chỗ chừa cho chip chế độ mua + chip đối thủ là hằng số, giờ nở theo cỡ chữ hệ thống. Cùng ngày sửa tiếp `_MoneyHeader`: ở chữ 2.0×, 320px nhóm chip VIP/💎 nở rộng đẩy nút ⚙ ra ngoài màn ~39px (bấm không tới) — giờ nhóm này giới hạn 40% bề ngang hàng và co chữ khi chữ hệ thống >1.25× (chữ thường giữ nguyên bố cục).

## 36. Ép liên kết email ở SERVER cho mọi bảng xếp hạng (2026-10-15)
- Trước: chỉ các bảng mới (Pha theo đơn, Thử thách ngày) ép ở server; bảng cũ chỉ ép ở app ⇒ bản app cũ / client giả vẫn ghi được bằng tài khoản ẩn danh.
- Giờ `is_linked_user()` (security definer, đọc `auth.users.is_anonymous`) được định nghĩa ở MỌI schema cần nó (`create or replace`, chạy file nào trước cũng được) và chặn ghi ở: policy INSERT/UPDATE của `leaderboard_entries` (thu nhập), `m3_leaderboard_entries`, `accessory_leaderboard_entries`, `recipe_leaderboard_entries`, 4 bảng Phá đảo `story_speedrun{,2,3,4}_entries`; RPC `submit_vip_exp` và `event_leaderboard_submit` (lỗi `email link required`); và `leaderboard_claim_reward()` (hạng cũ nhận 💎) trả 0 cho tài khoản chưa liên kết.
- Nâng cấp ẩn danh → liên kết giữ nguyên `user_id` nên hàng cũ của người đã liên kết vẫn ghi được. Hàng CŨ của tài khoản ẩn danh vẫn còn trên bảng (chỉ chặn GHI mới) — dọn bằng SQL tay (xem memory anon-leaderboard-cleanup).
- **PHẢI chạy lại 10 file SQL trên Supabase** (idempotent): leaderboard_schema, m3_leaderboard_schema, accessory_leaderboard_schema, recipe_leaderboard_schema, story_speedrun_schema, story_speedrun2_schema, story_speedrun3_schema, story_speedrun4_schema, event_leaderboard_schema, accessory_market_schema. Không ép: Đấu Trường (PK) và Hội (có luồng riêng).
- Test: `supabase/tests/linked_enforce_scenarios.sql` (chạy trong `scripts/test_lb_rewards_sql.sh`: ẩn danh bị chặn insert/update/RPC, đã liên kết ghi bình thường, đọc công khai vẫn được; đã đột biến từng cổng để thấy test đỏ) + `test/leaderboard/linked_enforce_test.dart` (quét mọi schema, chặn thêm bảng/RPC mới mà quên cổng). Stub `auth.users` của `test_market_sql.sh`/`test_swap_sql.sh` thêm cột `is_anonymous` cho giống Supabase thật.
- **Chạy SQL bằng script** thay vì dán tay: `scripts/deploy_supabase_sql.sh` (cần `SUPABASE_DB_URL` = chuỗi kết nối DATABASE cổng 5432; `--dry-run` để xem trước, `-y` bỏ xác nhận, truyền tên file để chạy vài file). Mỗi file chạy trong một giao dịch, dừng ngay khi lỗi; không in mật khẩu. Đã thử trên Postgres tạm (chạy 2 lần, file hỏng hoàn tác, từ chối cổng 6543).
- **Tên file ảnh chia sẻ** không còn dùng chung: `shareImageProvider` nhận thêm tham số `fileName` (`boba_collection.png` cho thẻ sưu tập, `boba_cup.png` cho thẻ ly).

## 37. Thưởng tuần cho bảng Thử thách ngày — top 10 (2026-10-15)
- Bảng "Hôm nay" chỉ hiện điểm của HÔM NAY nên không dùng cách chụp "top hiện tại" như các bảng cộng dồn. Thưởng tính theo **TỔNG điểm Thử thách ngày của cả TUẦN TRƯỚC** (thứ Hai–Chủ nhật UTC, cộng mọi ngày làm), **top 10**, chỉ tài khoản đã liên kết email.
- Thưởng: hạng 1-3 = 300 / 200 / 100 💎 (như các bảng khác), **hạng 4-10 = 50 💎** (`lb_reward_gems_for(board, rank)` ở SQL ↔ `lbRewardGemsForBoard` ở Dart, test so khớp). Nhận một lần/(tuần, bảng), còn hạn 2 tuần như cũ. Các bảng khác vẫn top 3.
- SQL `leaderboard_rewards_schema.sql` (**PHẢI chạy lại**): CHECK `board` thêm `'daily'`, CHECK `rank` nới 1..10, hàm snapshot thêm khối `daily` (tuần trước = `[thứ Hai - 7, thứ Hai)` tính bằng số ngày từ epoch, cùng cách tính `dayIndex`), claim/status dùng `lb_reward_gems_for`. Snapshot là "lười" theo tuần (lần gọi `lb_reward_status()` đầu tiên của tuần mới) ⇒ bảng `daily` bắt đầu có thưởng từ tuần đầu tiên SAU khi chạy SQL.
- App: `LbBoard.daily`; hộp thưởng có ghi chú top 10 và hạng 4-10 hiện 🏅 (trước đây rơi về 🥉 vì kẹp chỉ số); tab "Hôm nay" có dòng gợi ý "thưởng tính theo tổng điểm cả tuần"; lời giới thiệu hộp thưởng sửa lại cho đủ 6 bảng cộng dồn (trước ghi "năm bảng").
- Kèm sửa: `_ErrorView` của bảng xếp hạng công thức cuộn được (dòng gợi ý mới làm nó tràn dọc 20-44px ở id/pt, 320px, chữ 1.5×).
- Test: kịch bản SQL (12 người liên kết + 1 ẩn danh: D02 cộng 3 ngày vượt D01, hạng 11 và điểm tuần này không tính, ẩn danh bị loại, 💎 theo hạng, nhận/nhận lại/không đủ điều kiện) + đột biến 5 chỗ; test Dart so khớp hằng số, hộp thưởng, gợi ý ở tab.

## 38. Khách chibi vẽ bằng code (2026-10-15)
- Thay avatar emoji của khách ở Pha theo đơn bằng nhân vật **chibi tròn dễ thương vẽ bằng `CustomPainter`** (`lib/ui/widgets/chibi_customer.dart`) — không cần file Lottie/ảnh, không vướng bản quyền, vài KB code.
- **Diện mạo theo `seed`** (`ChibiLook.fromSeed`, thuần, có test): 5 màu da × 7 màu tóc × 7 màu áo × 5 kiểu tóc (mái ngố / búi / hai bím / rẽ ngôi / bob) × đeo kính hay không; seed liền kề (id món + chỉ số đơn) không ra hai người giống nhau.
- **Nét mặt theo tâm trạng** (`CustomerMood`): chờ (mắt tròn có điểm sáng, cười mỉm) · hài lòng (mắt cười ^ ^) · hoàn hảo (mắt cười + miệng há có lưỡi, má hồng đậm) · buồn (mếu + giọt nước mắt). **Sốt ruột** (`impatient`, chỉ khi đang chờ): mím miệng lượn sóng, giọt mồ hôi, nghiêng đầu — bật ở Giờ cao điểm khi còn <25% kiên nhẫn.
- **Chuyển động**: chu kỳ 4 giây thở (nhấp nhô) + một lần chớp mắt; sốt ruột thì nhấp nhô nhanh gấp 4. Tắt hẳn (không tạo controller) khi giảm chuyển động của máy / chất lượng hiệu ứng "tắt" / test ⇒ không animation lặp. Khung hình vẽ lại nhờ `repaint: animation`, không `setState`.
- Giữ nguyên huy hiệu mặt cười ở góc, nảy khi vui / lắc khi buồn, trượt vào quầy. Khách lễ hội: emoji dịp (🦇🎃…) thành **phụ kiện đội trên đầu** (`OrderCustomer.avatar`, trước là cả avatar).
- Cố ý không vẽ lông mày (tóc phủ sát mắt, mày bị che/lòi nét lạ — xem ảnh thử khi làm).
- Test (`test/ui/chibi_customer_test.dart` + 1 test ở `recipe_order_ui_test.dart`): đa dạng/ổn định diện mạo, mỗi tâm trạng vẽ ra ảnh khác, thở và chớp mắt tách riêng bằng cặp pha cùng độ nhấp nhô, không rò ticker, không tràn ở 320px/chữ 2×, sốt ruột bám theo thanh kiên nhẫn; đột biến 6 chỗ đều đỏ.
- Nếu sau này có Lottie thật: thay `ChibiCustomer` trong `OrderCustomer`; API trạng thái (`mood`, `impatient`, `seed`) giữ nguyên.

## 39. Hướng dẫn cách chơi các trò nhỏ (2026-10-15)
- Trước đây chỉ Trân Châu Rơi (`match3_how_to_dialog.dart`) và Kho phụ kiện có hướng dẫn. Thêm 3 bảng cùng khuôn ở `lib/ui/minigame_how_to_dialogs.dart`: **Công thức** (ôn cách quãng, 4 bậc, câu hỏi theo bậc, luyện tập vs tính bậc, thưởng/rương, chuỗi ngày, mở nhóm — 6 bước), **Pha theo đơn** (kéo/chạm, giữ để rót, chấm điểm, gợi ý giảm dần + dung sai theo bậc, ghi bậc + QC, combo, Giờ cao điểm, đơn lễ hội + khoe ly + BXH — 8 bước), **Thử thách hằng ngày** (đề chung, không gợi ý, cách tính điểm, mỗi ngày một lần, bảng Hôm nay + thưởng tuần — 5 bước). Các bước đánh số; số liệu (số ngày ôn 1/3/7, số món mở nhóm, điểm tối đa, 💎 thưởng) lấy từ hằng số thật của game nên không lệch khi chỉnh cân bằng.
- **Hai cách mở**: nút ? ở thanh tiêu đề (`HowToButton`: hub Công thức, Pha theo đơn, Thử thách ngày) và **tự hiện lần đầu** vào trò (`HowToOnce`, ghi nhớ trong `GameState.howToSeen` — danh sách `recipes|orders|daily`, mỗi trò MỘT cờ riêng; Trân Châu Rơi giữ cờ cũ `m3HowToSeen`). Thử thách ngày KHÔNG tự hiện khi chỉ xem lại điểm đã làm hôm nay và không đánh dấu đã xem. Một popup tại một thời điểm (không chồng với cutscene vì chỉ tự hiện khi người chơi chủ động vào trò).
- Đủ 7 ngôn ngữ (vi/en viết tay; es/id/ko/pt/th do máy dịch, **chưa có người bản ngữ duyệt**): 23 khoá ARB `howTo*`.
- Test: `test/ui/minigame_how_to_test.dart` (mở/đóng, số bước, số liệu thật, tự hiện một lần + cờ riêng + lưu đĩa, xem lại điểm không tự hiện, không tràn 3 trò × 7 ngôn ngữ ở 320px/chữ 1.5×; đột biến 5 chỗ đều đỏ) và `game_storage_test` (lưu/đọc/lọc `howToSeen`). `debugAutoShowHowTo` mặc định tắt trong test (`flutter_test_config.dart`).

## 40. Bộ trang bị phụ kiện — loadout (2026-10-17, chưa playtest)

> ⚠️ Mọi số là **ước lượng, chưa playtest** (nằm hết trong `Balance.loadout*`). Lý do thiết kế, bảng
> sức mạnh mẫu và rủi ro: [`PROPOSAL_ACCESSORY_LOADOUT.md`](PROPOSAL_ACCESSORY_LOADOUT.md).

- Hệ thống **trưng bày quanh cốc** có sẵn (`equippedAccessories`, 3 ô + 1 ô VIP) nay còn cho buff. Không
  thêm bảng/SQL; không đổi BXH.
- **4 họ** (`lib/core/accessory_loadout.dart`, mỗi món thuộc đúng một họ — test khoá cả **208 món**:
  160 chính + 28 lễ hội + 12 cửa hàng Hội + 8 VIP): 🔥 Nhiệt huyết = giá trị chạm (cả Tự động chạm) ·
  ✨ Lấp lánh = thu nhập tự động · 🌿 Yên bình = thu nhập offline · 💎 Tinh tế = giảm giá nâng cấp.
  Gán **luân phiên trong từng độ hiếm** để họ nào cũng đủ 4 độ hiếm — nên tên họ trung tính, KHÔNG theo
  hình (gán theo chủ đề thì họ "ngọt" gần như không có Sử thi/Huyền thoại). Thêm món MỚI phải thêm vào một
  danh sách họ, test sẽ đỏ nếu quên.
- **Điểm** theo độ hiếm 1 / 2.5 / 5 / 10; buff = tổng điểm trong họ × %/điểm × combo, rồi kẹp trần:
  chạm 2%/điểm (trần +80%) · thu nhập 1% (+40%) · offline 2% (+80%) · giảm giá 0.4% (−10%).
- **Combo** cùng họ: 2 món ×1.10 · 3 ×1.25 · 4 ×1.50. Mỗi món tính một lần; id lạ bị bỏ qua.
- **Điểm nối** (mỗi buff đúng MỘT chỗ): `tapGain` (simulation) · `effectiveIncomePerSecond` (economy) ·
  `applyOfflineEarnings` (simulation) · `upgradeCostMultiplierFor` (economy; giảm giá cộng chung với "Mua
  sỉ" rồi mới kẹp sàn ×0.4). Offline tính theo bộ ĐANG mang lúc mở app (người chơi chưa kịp đổi).
- **Khoá đổi**: lấp ô trống luôn được; tháo/thay chỉ khi hết khoá, rồi khoá `equipSwapLockMinutes`
  (30) phút. Xem QC mở khoá ngay; gỡ QC/VIP mở thẳng. `GameState.equipLockUntilMillis` (kẹp ≤ now+30′ khi
  nạp). Bán nốt bản cuối tự gỡ KHÔNG bị tính là tháo. API: `tryToggleEquippedAccessory` → `EquipResult`.
- **UI**: thẻ "Bộ trang bị" đầu Kho (ô đang mang, dòng buff + combo, đếm ngược khoá), biểu tượng họ trên
  mỗi ô, hộp xác nhận tháo, hộp mở khoá. Chuỗi hướng dẫn `accessoryHtp1` đã sửa (từng nói "không tăng thu nhập").
- **Cố ý chưa làm**: họ "Vận may", ô thứ 4 mở theo mốc sưu tập, Tinh luyện bằng bản sao dư. Cần theo dõi
  **giá Chợ** sau khi ra (món có tác dụng → cầu tăng; người chơi đã than giá luôn max).

## 41. Tinh chất 🧪 & Bí quyết

- **Tinh chất**: một loại tiền, chỉ kiếm từ trò nhỏ: bậc Công thức mới (= số bậc, một lần), đơn Pha theo đơn 3★ không gợi ý (+1, ≤10/ngày), Thử thách ngày (+5), nhân đôi bằng QC (cùng trần), sao Ghép 3 tăng thêm (+1/sao). Trần chung nguồn lặp lại 20/ngày (`Balance.essence*`).
- **Bí quyết**: 18 giai đoạn × 5 bậc, +8%/bậc thu nhập giai đoạn đó, giá 10/20/40/80/160 🧪. Giữ qua Nhượng quyền và Kỷ Nguyên. Màn `MasteryPage`, mở từ nút 🧪 ở hub Công thức và hành trình Ghép 3.
- Nối vào `baseIncomePerSecond` (theo `config.stage`), gợi ý "đáng mua nhất" và chỉ báo ô cửa hàng. Đồng bộ cloud: tiến độ Tinh chất tham gia phát hiện xung đột. Mọi số chưa playtest. Logic: `lib/core/essence.dart`.
