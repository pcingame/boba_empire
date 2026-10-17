# PROPOSAL — Tinh chất & Bí quyết: nối các trò nhỏ vào kinh tế chính

> Trạng thái: **ĐÃ LÀM 2026-10-17 (chưa commit/playtest)** — `GAME_DESIGN.md` §41. Lệch so với đề xuất: hộp Công thức là 1–3 (không 1–5); nhân đôi QC chỉ ở Pha theo đơn/Thử thách; lối vào là nút 🧪 ở AppBar hub Công thức + hành trình Ghép 3 (không chip ở trang chủ); `marginalIncomePerSecond` không đổi (gợi ý mua nhân hệ số ở tầng gọi). Mọi con số là **ước lượng chưa playtest** — khi làm sẽ nằm hết
> trong `Balance`. Ngày: 2026-10-17. Là mục 3 trong danh sách "thêm chiều sâu" (mục 1 = bộ trang bị,
> đã làm: `GAME_DESIGN.md` §40).

## 1. Vấn đề

Công thức, Pha theo đơn, Thử thách ngày, Ghép 3 hiện thưởng **Xu theo thu nhập** (`recipeRewardSeconds`,
`m3RewardIncomeSeconds`…), đôi khi 💎 và rương phụ kiện. Xu chảy vào ví rồi hoà lẫn với thu nhập thường:
chơi trò nhỏ không cho người chơi một **lựa chọn** nào trong vòng lặp chính, nên nó chỉ là "nhiệm vụ
làm cho đủ". Mục tiêu: trò nhỏ tạo ra thứ **có chỗ tiêu có chủ đích**, và chỗ tiêu đó kéo theo quyết định.

## 2. Thiết kế

### 2.1 Một loại tiền mới: 🧪 Tinh chất

- **Chỉ kiếm từ trò nhỏ** — không bán ở cửa hàng 💎, không có trong IAP (tránh pay-to-win ngầm).
- **Một loại duy nhất**, không tách theo trò: tách ra thì người chơi phải chơi cả bốn trò mới tiêu được,
  mà mục tiêu là *chọn trò mình thích* vẫn có tiến triển.
- Số nguyên nhỏ (hàng chục/ngày), không thể tràn số.

| Nguồn | Tinh chất | Giới hạn |
|---|---:|---|
| Công thức: lần đầu đạt bậc mới của một món | **= số bậc** (1–5) | tự giới hạn (mỗi món mỗi bậc một lần) |
| Pha theo đơn: mỗi đơn đạt 3★ | **+1** | tối đa **10/ngày** |
| Thử thách ngày: hoàn thành | **+5** | 1 lần/ngày |
| Ghép 3: lần đầu qua màn (theo số sao) | **+1/sao** (tối đa 3) | tự giới hạn (mỗi màn một lần) |
| Xem QC sau buổi chơi: **nhân đôi** Tinh chất của buổi đó | ×2 | cùng giới hạn ngày (không vượt trần) |

Người chơi trò nhỏ đều đặn kiếm ≈ **15–25 🧪/ngày**.

### 2.2 Chỗ tiêu: "Bí quyết" theo giai đoạn

- Mỗi **giai đoạn** (18 giai đoạn) có **5 bậc Bí quyết**. Mỗi bậc: **+8% thu nhập** của mọi nguồn thuộc
  giai đoạn đó (tối đa **+40%** mỗi giai đoạn).
- Giá bậc: **10 / 20 / 40 / 80 / 160** 🧪 (310 để đầy một giai đoạn).
- **Giữ qua Nhượng quyền và Kỷ Nguyên** (là tiến độ meta như 💎 và thành tựu), không reset.
- Chọn theo giai đoạn (không theo từng nguồn thu trong 36 nguồn) để màn hình là 18 dòng, không phải 36.

**Vì sao đây là quyết định thật**: Nhượng quyền reset giai đoạn về 1 nhưng Bí quyết ở lại. Dồn vào giai
đoạn **cao** cho thu nhập lớn nhất lúc đẩy cuối vòng; dồn vào giai đoạn **thấp** rút ngắn đoạn leo lại sau
mỗi lần reset. Hai chiến lược khác nhau, tuỳ thói quen Nhượng quyền của người chơi.

### 2.3 Tốc độ tiến triển

| Mốc | Tinh chất | Mất khoảng |
|---|---:|---|
| Bậc 1 của một giai đoạn | 10 | ~½–1 ngày |
| Đầy 1 giai đoạn (+40%) | 310 | ~2 tuần |
| Đầy 3 giai đoạn hay dùng | 930 | ~6–8 tuần |
| Đầy cả 18 | 5 580 | ~8 tháng (mục tiêu dài hạn, ít ai đạt) |

Bậc đầu đến nhanh (phần thưởng sớm), bậc cuối rất chậm (đích dài hơi).

## 3. Mức sức mạnh và va chạm với phần khác

- Tối đa thực tế ≈ **+40%** thu nhập khi đẩy cuối vòng (vì chỉ giai đoạn hiện tại chiếm phần lớn thu
  nhập), tương đương **một nấc** "Siêu thu nhập" (+25%) đến hai nấc. So với Kỷ Nguyên +50%/cấp (trần 20)
  thì nhỏ. Cùng cỡ với trần bộ trang bị (+40% thu nhập), nhân chồng lên nhau: tổng ×1.96 ở mức tối đa cả
  hai — vẫn nhỏ so với các hệ số cấp 10^n của Sao/Kỷ Nguyên.
- **BXH**: không đổi cấu trúc; Sao/Kỷ Nguyên chi phối xếp hạng nhiều bậc 10, Bí quyết chỉ ±vài %.

## 4. Rủi ro & cách chặn

| Rủi ro | Biện pháp |
|---|---|
| **Cày/lạm dụng QC** (xem QC → nhiều 🧪 → mạnh hơn) | Trần ngày áp cả với nhân đôi QC; nguồn lặp lại đều có trần; nguồn một-lần tự giới hạn tổng đời. |
| **Đổi chữ ký hàm thu nhập biên** | `marginalIncomePerSecond(config, level)` cho gợi ý "đáng mua nhất" hiện không biết state → phải thêm hệ số Bí quyết, nếu không gợi ý sẽ lệch (có `marginal_income_test`). Tìm hết nơi gọi bằng codegraph trước khi đổi. |
| **Đồng bộ đám mây mất 🧪** | Bài học `cloud-sync-ignores-gems`: xung đột chỉ so `lifetimeEarnings` nên 💎 từng bị bỏ qua. **Phải đưa Tinh chất + bậc Bí quyết vào điều kiện so sánh** khi thêm field. |
| **Tràn số / NaN** | Hệ số mỗi giai đoạn ∈ [1, 1.40], số nguyên, bậc kẹp 0–5; test biên save 1e300. |
| **Save cũ / bản app cũ** | Field mặc định 0 (`?? 0`, `?? {}`); id giai đoạn lạ bị bỏ qua. |
| **Trò nhỏ thành nghĩa vụ** | Không có buff nào *chỉ* kiếm được ở một trò; thích trò nào cũng có tiến triển (một loại tiền). |
| **Cân bằng 3 hệ cùng lúc** (loadout + Bí quyết + perk) chưa playtest | Mọi số trong `Balance`; tách `Balance.essence*`; ra bản thử nhỏ rồi theo dõi tốc độ vượt giai đoạn. |

## 5. Phạm vi triển khai (khi duyệt)

1. `balance.dart`: nguồn 🧪, trần ngày, giá bậc, %/bậc.
2. `GameState`: `essence` (int), `masteryTiers` (giai đoạn → bậc), bộ đếm ngày cho trần (`essenceDayIndex`,
   `essenceEarnedToday`); lưu/đọc có tương thích ngược; kẹp khi nạp.
3. Hàm thuần `lib/core/essence.dart`: `masteryMultiplier(stage, tiers)`, giá bậc, `grantEssence` (tôn trọng
   trần ngày), `buyMastery`.
4. Nối vào `baseIncomePerSecond` (theo `config.stage`) + `marginalIncomePerSecond`.
5. Nối nguồn 🧪 vào 4 chỗ phát thưởng trò nhỏ (Công thức, Pha theo đơn, Thử thách ngày, ván Ghép 3), kèm
   dòng "+N 🧪" ở màn kết quả và nút nhân đôi bằng QC.
6. UI: màn **Bí quyết** (18 dòng, tiến độ bậc, nút nâng, số 🧪), lối vào từ hub Công thức + chip số 🧪.
   7 ngôn ngữ.
7. Điều kiện so sánh đồng bộ đám mây gồm 🧪 + bậc.
8. Không cần SQL.

**Test**: trần ngày (kể cả nhân đôi QC); giá và hệ số theo bậc; hệ số vào thu nhập đúng giai đoạn;
`marginalIncome` khớp; giữ qua Nhượng quyền + Kỷ Nguyên; hữu hạn ở save cực lớn; tương thích save cũ;
đồng bộ đám mây không mất 🧪; layout 320px × chữ 1.5 × 7 ngôn ngữ.

## 6. Cố ý chưa làm

- **Tinh luyện phụ kiện** (dùng 🧪 + bản sao dư nâng điểm một món lên đến ×1.75): nối thẳng vào bộ trang bị
  và là chỗ tiêu thứ hai cho cùng loại tiền, đồng thời là **sink cho bản dư** (giúp Chợ bớt lạm phát). Thêm
  sau khi Bí quyết ổn định.
- **Bí quyết theo từng nguồn thu** (36 dòng) hoặc hiệu ứng riêng mỗi nguồn: nặng UI, chưa chứng minh cần.
- **Tinh chất theo loại trò**: đã loại ở §2.1.

## 7. Câu hỏi cần chốt trước khi code

1. **Một loại Tinh chất** (khuyến nghị) hay tách theo trò?
2. **Bí quyết theo giai đoạn**, +8%/bậc × 5 bậc, giá 10→160: ổn chưa?
3. **Giữ qua cả Nhượng quyền lẫn Kỷ Nguyên** (khuyến nghị) hay reset ở Kỷ Nguyên?
4. **Nhân đôi bằng QC** có trần ngày: giữ hay bỏ ở bản đầu?
