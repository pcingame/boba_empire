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
  chiến dịch Trân Châu Rơi (60 màn).
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
