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

Mở giai đoạn = trừ Xu, `stage++`, đổi ảnh nền + tông màu theme, hiện các nguồn thu
mới trong shop (panel tự giãn mượt bằng `AnimatedSize`).

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
    `buyCount`, thành tựu.
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

- **Tick**: mỗi 1s cộng `income/s × dt`, cập nhật mèo/VIP, xét thành tựu, tự lưu
  mỗi 10 tick. Lưu ngay khi mua bằng 💎/⭐ hoặc app vào nền.
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
| 7 | Nhỏ (UX) | `tapValue` cố định 1, chỉ scale qua perk "Siêu chạm"/boost → nút "Chạm pha trà" (hero interaction) mất ý nghĩa kinh tế sau ~1 phút. | Bình thường với thể loại; cân nhắc 1 nâng cấp "giá trị chạm" bằng Xu để giữ nút sống. |
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

**Còn lại**: auto-tap (finding #7 — chưa làm), persist Golden Rush (finding #3),
cloud save (finding #6).

---

*Cập nhật tài liệu này khi đổi `balance.dart` hoặc thêm hệ thống.*
