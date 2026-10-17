# PROPOSAL — Phụ kiện thành "bộ trang bị" (loadout) có đánh đổi

> Trạng thái: **ĐÃ LÀM (2026-10-17), chưa playtest** — xem `GAME_DESIGN.md` §40. Mọi con số là **ước lượng chưa playtest** (cùng tình trạng
> các hệ thống §26–34 trong `GAME_DESIGN.md`) — vì vậy tất cả nằm trong `Balance` để chỉnh được.
> Ngày: 2026-10-17.

## 1. Vấn đề

Quyết định thật sự trong vòng lặp chính chỉ có: mua nguồn thu nào, dồn mốc ×2 nào, khi nào Nhượng
quyền — gần như có đáp án tối ưu cố định (đã có Tự động mua). 160 phụ kiện thì là **sưu tập thuần**
(`GAME_DESIGN.md` §26: "cosmetic thuần, không đụng cân bằng"), nên Chợ/vòng quay/rương phụ kiện không
trả lời được câu hỏi "tôi cần món NÀO và vì sao".

## 2. Hiện trạng đã có (không phải làm lại)

- `GameState.equippedAccessories`: id đang **trưng bày quanh cốc**, tối đa
  `Balance.maxEquippedAccessories = 3` (+`vipExtraEquipSlots = 1` nếu VIP) — `maxEquippedFor()`.
- `toggleEquippedAccessory()` (game_controller.dart): bật/tắt, có kiểm tra sở hữu + số chỗ.
- Khi nạp save đã dọn món không còn sở hữu / quá số chỗ; bán nốt bản cuối thì tự gỡ khỏi trang bị.
- Id lạ (từ bản app mới hơn) đã có guard `_known` — **phải giữ** khi thêm hiệu ứng.

→ Đề xuất = **gắn hiệu ứng vào hệ thống này**, không thêm bảng/slot mới.

## 3. Thiết kế

### 3.1 Bốn "họ" phụ kiện, mỗi họ một loại buff

| Họ | Chủ đề | Buff | Chạm vào |
|---|---|---|---|
| 🍰 **Ngọt** | bánh, kẹo, trái cây | **Giá trị chạm** (cả Tự động chạm vì dùng chung `tapGain`) | `tapGain` (simulation.dart) |
| 🏮 **Trang trí** | đèn, cờ, chuông, đồ vật | **Thu nhập tự động** | `effectiveIncomePerSecond` (economy.dart) |
| 🌿 **Thiên nhiên** | lá, hoa, thú, thời tiết | **Thu nhập offline** | `applyOfflineEarnings` (simulation.dart) |
| 👒 **Phục sức** | mũ, nơ, kính, khăn | **Giảm giá nâng cấp** nguồn thu | `upgradeCostMultiplier` (economy.dart) |

- Mỗi món thuộc **đúng 1 họ** (bảng tĩnh `accessoryFamily` trong accessories.dart, 160 dòng; chia
  gần đều ~40 món/họ, huyền thoại 9 món chia 2/2/2/3; một lượt rà tay theo emoji/tên).
- Thưởng Công thức/Ghép 3 **không cần buff riêng**: thưởng Công thức đã tính theo giây sản xuất
  (`recipeRewardSeconds`), nên buff Thu nhập tự động đã lan sang.
- Họ thứ 5 "Vận may" (tăng tỉ lệ rớt Sử thi+) **để sau**: chạm vòng sưu tập/Chợ, rủi ro lạm phát.

### 3.2 Sức mạnh theo độ hiếm ("điểm")

| Độ hiếm | Thường | Hiếm | Sử thi | Huyền thoại |
|---|---:|---:|---:|---:|
| Điểm / món | 1 | 2.5 | 5 | 10 |

| Buff | % mỗi điểm | **Trần** |
|---|---:|---:|
| Thu nhập tự động | +1% | **+40%** |
| Giá trị chạm | +2% | **+80%** |
| Thu nhập offline | +2% | **+80%** |
| Giảm giá nâng cấp | −0.4% | **−10%** |

Cộng **cộng dồn** trong từng họ (tổng điểm × %/điểm), rồi nhân vào công thức như một thừa số riêng.

### 3.3 Combo cùng họ (đánh đổi: chuyên môn hoá ↔ đa dạng)

Số món **cùng họ** đang trang bị nhân buff của họ đó: **2 món ×1.10 · 3 món ×1.25 · 4 món ×1.50**.
Trộn họ khác nhau thì mỗi buff nhỏ nhưng phủ nhiều mặt; dồn một họ thì mạnh một mặt. Mỗi món chỉ
trang bị một lần (bản sao dư không cộng thêm).

### 3.4 Đổi trang bị có chi phí thời gian (để loadout là quyết định thật)

Không có chi phí thì người chơi luôn đổi sang bộ tối ưu cho việc đang làm (chạm ↔ nhàn rỗi) — thành
việc vặt, không phải chiều sâu. Quy tắc:
- **Lấp ô trống: luôn được.** **Tháo/thay món: chỉ khi hết khoá**; mỗi lần tháo/thay khoá
  **30 phút** (`Balance.equipSwapLockMinutes`).
- Xem quảng cáo thưởng để **mở khoá ngay** (nối với chủ đề kiếm tiền QC; người gỡ QC/VIP mở thẳng).
- Offline luôn tính theo bộ đang mang **lúc rời game** (tính ở lần mở app kế tiếp, trước khi người
  chơi kịp đổi) → quyết định thật: "trước khi tắt app, mang bộ 🌿".

### 3.5 Mở ô

Giữ nguyên **3 ô + 1 ô VIP** (không đụng monetization hiện có). Ô thứ 4 cho người không VIP: **để sau**
(ứng viên: mốc sưu tập 120 món, đã có sẵn trong `collectionMilestones`).

## 4. Mức sức mạnh thực tế (3 ô, họ Thu nhập tự động)

| Người chơi | Bộ | Điểm | Combo | Buff |
|---|---|---:|---:|---:|
| Mới | 3 thường, trộn 3 họ | 1+1+1 | — | +1% mỗi mặt |
| Trung bình | 2 hiếm + 1 sử thi cùng họ | 10 | ×1.25 | **+12.5%** |
| Cuối | 1 huyền thoại + 2 sử thi cùng họ | 20 | ×1.25 | **+25%** |
| Lý thuyết tối đa (3 ô) | 3 huyền thoại cùng họ | 30 | ×1.25 | +37.5% (< trần 40%) |
| Lý thuyết tối đa (VIP, 4 ô) | 4 huyền thoại cùng họ | 40 | ×1.50 | 60% → **kẹp 40%** |

**So với phần còn lại**: Siêu thu nhập +25%/cấp, Kỷ Nguyên +50%/cấp (trần 20), Sao +2%/sao, Mốc vàng
+3%/mốc. Bộ phụ kiện điển hình ≈ **một nấc perk**, không phải một bước ngoặt → không làm trượt
tiến trình hay BXH (BXH bị chi phối bởi Sao/Kỷ Nguyên, cỡ nhiều bậc 10). Vì huyền thoại chỉ có 9 món
chia 4 họ, bộ tối đa gần như không đạt được.

## 5. Rủi ro & cách chặn

| Rủi ro | Biện pháp |
|---|---|
| **Lạm phát Chợ** — món có tác dụng → cầu tăng; người chơi đã than "cái gì cũng max giá" (trần 100000) | Buff nhỏ + trần thấp; món thường chỉ +1% nên giá không bị kéo. **Theo dõi giá trung bình 7 ngày sau khi ra**; nếu trượt, hạ %/điểm hoặc thêm sink (xem §7). |
| **Pay-to-win** — 💎 → Xu Chợ → mua món | Trần 40% (+VIP chỉ thêm 1 ô); không có cửa mua trực tiếp buff. Ghi rõ trong ghi chú App Review nếu cần. |
| **Tràn số / NaN** (từng làm âm Xu: `negative-money-overflow-bug`) | Mỗi buff tính bằng cộng điểm rồi `clamp` về trần, kết quả hữu hạn; thừa số nằm trong [1, 1.8]. Test biên với save 1e300. |
| **Đảo ngược "cosmetic thuần"** đã ghi ở §26 | Cập nhật §26 khi làm. Cosmetic vẫn còn (trưng bày quanh cốc), chỉ thêm tác dụng. |
| **Hồi quy giá nâng cấp** (`upgradeCostMultiplier` có sàn ×0.4 của perk Mua sỉ) | Cộng giảm giá phụ kiện **vào cùng phép trừ** rồi mới kẹp sàn 0.4 → sàn không bị vượt. Cần tìm hết nơi gọi hàm (codegraph_callers) trước khi đổi chữ ký. |
| **Đồng hồ máy** (lùi giờ để né khoá 30 phút) | Chấp nhận (chỉ ảnh hưởng chính họ, buff nhỏ). Kẹp `equipLockUntilMillis ≤ now + 30 phút` khi nạp để save lỗi không khoá vĩnh viễn. |
| **Save cũ** | Người đang trưng bày món nào sẽ **tự nhận buff nhỏ** (quà bất ngờ, không hại). Thêm `equipLockUntilMillis` mặc định 0, đọc `?? 0`. |
| **Đồng bộ đám mây** | Field mới theo khuôn `equippedAccessories` (đã sync). Bài học `cloud-sync-ignores-gems`: kiểm lại điều kiện xung đột khi thêm field. |

## 6. Phạm vi triển khai (khi duyệt)

1. `balance.dart`: hằng số (điểm theo độ hiếm, %/điểm, trần, combo, `equipSwapLockMinutes`).
2. `accessories.dart`: `AccessoryFamily` + bảng `accessoryFamily` (160 món) + hàm thuần
   `loadoutBuffs(equipped) → LoadoutBuffs {income, tap, offline, discount}`.
3. Nối vào 4 chỗ: `tapGain`, `effectiveIncomePerSecond`, `applyOfflineEarnings`, `upgradeCostMultiplier`.
4. `GameState.equipLockUntilMillis` + `toggleEquippedAccessory` theo quy tắc §3.4 + mở khoá bằng QC.
5. UI Kho phụ kiện: thanh "Bộ trang bị" (4 ô), nhãn họ + buff trên mỗi ô, dòng tổng hợp
   "🏮 +12.5% thu nhập · combo ×1.25", đếm ngược khoá. 7 ngôn ngữ.
6. Không cần SQL/Supabase mới (không đổi BXH, không đổi server).
7. Cập nhật `GAME_DESIGN.md` §26 và thêm mục mới.

**Test (đều là hàm thuần nên rẻ):** bảng điểm/combo/trần; không vượt trần; tổng hữu hạn với save
cực lớn; sàn giá ×0.4; offline dùng bộ lúc rời; quy tắc khoá (lấp trống / thay / hết khoá / QC /
kẹp thời gian); id lạ không crash; mỗi món có đúng một họ (test khoá bảng 160 dòng khớp danh mục);
layout 320px × chữ 1.5 × 7 ngôn ngữ (bài học `shop-tile-overflow-pattern`).

## 7. Cố ý chưa làm (và khi nào thêm)

- **Tinh luyện** (dùng bản sao dư nâng cấp món, +50%/cấp, tối đa 3): sink cho bản dư + thêm chiều
  sâu. Thêm khi dữ liệu cho thấy Chợ lạm phát hoặc bản dư tồn đọng.
- **Họ "Vận may"** và **ô thứ 4 mở theo sưu tập**: thêm khi loadout ổn định.
- **Combo theo bộ chủ đề cụ thể** (VD "Trà đào"): cần gán chủ đề 160 món — nặng, chưa chứng minh cần.

## 9. Khác với đề xuất lúc làm thật

- **Tên 4 họ trung tính** (🔥 Nhiệt huyết · ✨ Lấp lánh · 🌿 Yên bình · 💎 Tinh tế), không phải
  Ngọt/Trang trí/Thiên nhiên/Phục sức: gán theo chủ đề làm họ "ngọt" gần như không có Sử thi/Huyền thoại
  (đã đo trước khi chọn), nên chia luân phiên trong từng độ hiếm.
- **208 món** chứ không phải 160: món lễ hội, cửa hàng Hội và cửa hàng VIP cũng mang được nên cũng thuộc họ.
  Vì vậy huyền thoại là 19 món (không phải 9) và bộ tối đa dễ đạt hơn dự tính — vẫn bị trần chặn.
- **Hộp xác nhận khi tháo** (không có trong đề xuất): vì tháo khởi động khoá 30 phút nên lỡ tay rất đắt.

## 8. Câu hỏi cần chốt trước khi code (đã chốt: đồng ý cả 4)

1. Đồng ý **đảo ngược "cosmetic thuần"** (§26) không?
2. Bốn họ + bốn loại buff + trần (§3.1–3.2) ổn chưa, hay muốn đổi/bớt?
3. Khoá đổi **30 phút + mở bằng QC** (§3.4): giữ, đổi thời gian, hay bỏ khoá ở bản đầu?
4. Người chơi hiện đang trưng bày món sẽ **tự nhận buff** (§5): chấp nhận?
