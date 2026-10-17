# PROPOSAL — Tinh luyện phụ kiện: biến bản dư + 🧪 thành sức mạnh

> Trạng thái: **ĐÃ LÀM 2026-10-17 (chưa commit/playtest)** theo khuyến nghị cả 3 câu (+25%/cấp tối đa 3, cấp không chuyển theo giao dịch, không tinh luyện bằng 💎) — `GAME_DESIGN.md` §43. Mọi số là ước lượng chưa playtest, sẽ nằm trong `Balance`.
> Ngày: 2026-10-17. Là phần "cố ý làm sau" của `PROPOSAL_ESSENCE_MASTERY.md` §6; nối bộ trang bị
> (`GAME_DESIGN.md` §40) với Tinh chất (§41).

## 1. Vấn đề
- Bản dư của phụ kiện chỉ có hai lối ra: bán ở Chợ (giá kịch trần, "toàn vô hạn xu") hoặc đổi món ở Chợ
  trao đổi. Chưa có chỗ **tiêu** bản dư trong chính game.
- 🧪 Tinh chất hiện chỉ có một chỗ tiêu (Bí quyết, theo giai đoạn). Bộ sưu tập phụ kiện lớn (208 món) nhưng
  mỗi món chỉ có "có / không có".

## 2. Thiết kế
- **Mỗi món có cấp tinh luyện 0–3.** Mỗi cấp **+25% điểm** của món đó trong bộ trang bị (cấp 3 = ×1.75).
  Điểm của món (theo độ hiếm 1 / 2.5 / 5 / 10) vẫn cộng vào họ, nhân combo, rồi **kẹp trần họ như cũ** —
  tinh luyện **không nâng trần nào**, chỉ giúp chạm trần sớm hơn bằng ít món/độ hiếm thấp hơn.
- **Giá mỗi cấp** = bản dư của **chính món đó** + 🧪:

| Cấp | Bản dư cần | 🧪 |
|---|---:|---:|
| 1 | 1 | 15 |
| 2 | 2 | 40 |
| 3 | 3 | 100 |

  Đủ 3 cấp = 6 bản dư + 155 🧪 cho một món. Giá không phụ thuộc độ hiếm (món hiếm vốn đã khó có bản dư).
- **Giữ qua Nhượng quyền/Kỷ Nguyên** (như phụ kiện). Cấp **không chuyển theo giao dịch**: bán/đổi món ở Chợ
  vẫn chuyển bản dư, người nhận bắt đầu từ cấp 0 (chống mua món đã tinh luyện về dùng ngay, và chống lách giá).
- **Không hoàn tác.** Một lần nâng là trừ luôn bản dư + 🧪.
- UI: trong Kho phụ kiện, chạm món → hộp chi tiết có nút "Tinh luyện" kèm giá và cấp hiện tại; ô món hiện
  ✦ theo cấp; thẻ Bộ trang bị hiện điểm đã tính tinh luyện.

## 3. Mức sức mạnh và va chạm
- Trần họ không đổi (chạm +80% / thu nhập +40% / offline +80% / giá −10%), nên **không có buff mới vượt
  trần hiện tại**. Với thu nhập: 4 món huyền thoại (4×10×combo 1.5 = 60 điểm) đã vượt trần 40 điểm; tinh luyện
  chủ yếu có ích cho người chơi có nhiều món **thường/hiếm** (ví dụ 4 món hiếm 10 điểm ×1.5 = 15 → cấp 3 lên
  26 điểm).
- **Sink cho Chợ**: mỗi món tinh luyện đủ cấp rút 6 bản dư khỏi lưu thông → giảm nguồn cung các món rẻ,
  giúp giá bớt kịch trần.
- 🧪 có hai chỗ tiêu: Bí quyết (thu nhập theo giai đoạn) và Tinh luyện (sức mạnh bộ trang bị). Thu nhập
  15–25 🧪/ngày ⇒ đủ cấp 1 một món mỗi ngày nhưng không thể vừa đầy Bí quyết vừa tinh luyện hết — đó là
  lựa chọn có chủ đích.

## 4. Rủi ro
| Rủi ro | Biện pháp |
|---|---|
| Tiêu nhầm bản đang rao ở Chợ | Chỉ tiêu bản dư **còn trong kho** (không tính bản đã ký quỹ / đang rao) |
| Cấp tinh luyện bị mất khi đổi máy | Lưu trong save + `cloudSaveLooksDifferent` đã so tiến độ Tinh chất; thêm tổng cấp tinh luyện vào so sánh |
| Tràn số / NaN | Hệ số mỗi món ∈ [1, 1.75], điểm vẫn kẹp trần họ |
| Save cũ | Field `refineLevels` mặc định `{}` (`?? {}`), id lạ bị bỏ qua, cấp kẹp 0–3 |
| Phụ kiện bị gỡ khỏi danh mục sau này | Bỏ qua id không còn trong danh mục (như `accessoryOrNull`) |

## 5. Phạm vi triển khai
`Balance.refine*` · `GameState.refineLevels` + JSON · hàm thuần `lib/core/accessory_refine.dart`
(`refineMultiplier`, `refineCost`, `tryRefine`) · `loadoutBuffs` nhận cấp để nhân điểm · controller
`refineAccessory` · UI hộp chi tiết + ✦ · 7 ngôn ngữ · so sánh cloud · test (giá, hệ số, trần họ không đổi,
giữ qua Nhượng quyền/Kỷ Nguyên, save cũ/hỏng, không tiêu bản đang rao, UI 320px). Không cần SQL.

## 6. Câu hỏi cần chốt
1. **+25%/cấp, tối đa cấp 3 (×1.75)** và giá 15/40/100 🧪 + 1/2/3 bản dư: ổn chưa?
2. **Cấp không chuyển theo giao dịch** (khuyến nghị) hay đi theo món?
3. Có cho **tinh luyện bằng 💎** thay bản dư khi thiếu không (khuyến nghị: **không** — tránh pay-to-win ngầm)?
