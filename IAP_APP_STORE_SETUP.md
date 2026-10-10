# Tạo 4 product IAP mới trên App Store Connect

Cập nhật 2026-10-10. Bốn product khớp `lib/iap/iap_products.dart` — **Product ID gõ sai một ký tự là app không thấy giá, và KHÔNG sửa được sau khi tạo**.

| Product ID | Loại (Type) | Giá gợi ý | Nội dung |
|---|---|---|---|
| `boba_gems_huge` | **Consumable** | $15.99 | 4000 💎 |
| `boba_gems_mega` | **Consumable** | $19.99 | 10000 💎 |
| `boba_cold_storage` | **Non-Consumable** | $2.99 (hoặc $1.99) | +8 giờ trần tiền offline, vĩnh viễn |
| `boba_combo_noads_x2` | **Non-Consumable** | ~80% tổng giá `boba_remove_ads` + `boba_double_income` | Gỡ QC + x2 thu nhập |

Combo: xem giá hai gói lẻ trên ASC, cộng lại, nhân ~0,8 rồi chọn mức giá hợp lệ gần nhất (phải RẺ HƠN tổng, nếu không không ai mua combo).

## 0. Điều kiện trước
- **Business → Agreements**: hợp đồng **Paid Applications** phải ở trạng thái *Active* (kèm thông tin ngân hàng + thuế). Đã bán gói 💎 cũ được thì mục này đã ổn.

## 1. Tạo từng product (lặp 4 lần)
1. App Store Connect → **Apps → Boba Empire → Monetization → In-App Purchases** (bản cũ: *Features → In-App Purchases*) → nút **+**.
2. Chọn **Type** theo bảng trên → *Create*.
3. **Reference Name**: tên nội bộ, tuỳ ý (vd. `Gems Huge 4000`). **Product ID**: gõ đúng bảng trên.
4. **Availability**: tất cả quốc gia/khu vực mà app đang bán.
5. **Price Schedule**: chọn *Base Country* = United States, đặt giá theo bảng. Apple tự quy đổi các nước; ở thị trường sức mua thấp (VN, ID, TH, BR) nên **hạ ~20–40%** như ghi ở `SETUP.md` mục "Giá theo vùng".
6. **App Store Localization** (bắt buộc ít nhất 1 ngôn ngữ; nên thêm đủ 7 như app): **Display Name** ≤ 30 ký tự, **Description** ≤ 45 ký tự — dùng bảng ở mục 3.
7. **Review Information**:
   - **Screenshot** (bắt buộc, ≥ 640×920): chụp màn Cửa hàng 💎 có hiện product (mở app → chạm chip 💎 trên màn chính → cuộn tới mục nạp tiền thật). Dùng chung một ảnh cho 4 product được.
   - **Review Notes** (dán): `Open the game, tap the 💎 chip on the home screen to open the Gem Shop, then scroll to the real-money section. The pack is listed there.`
8. Lưu. Trạng thái phải là **Ready to Submit** (nếu là *Missing Metadata* tức còn thiếu giá, bản địa hoá hoặc ảnh review).

## 2. Gắn vào bản phát hành (QUAN TRỌNG với IAP đầu tiên)
IAP mới **không tự có hiệu lực**, phải đi kèm một phiên bản app gửi duyệt:
1. Build mới (chứa code IAP mới) đã upload và chọn cho phiên bản.
2. Trang phiên bản (vd. 1.0.9) → mục **In-App Purchases and Subscriptions** → **+** → tick đủ 4 product → *Done*.
3. **Add for Review / Submit** — Apple duyệt app và IAP cùng lúc.

Build bản cũ không có code IAP mới nên người dùng bản cũ sẽ không thấy 4 gói này.

## 3. Nội dung bản địa hoá (copy/dán)
Display Name ≤ 30, Description ≤ 45 ký tự.

**`boba_gems_huge`**
| Ngôn ngữ | Display Name | Description |
|---|---|---|
| vi | 4.000 Kim Cương | Gói Kim Cương lớn cho Boba Empire |
| en | 4,000 Diamonds | Big diamond pack for Boba Empire |
| es | 4.000 Diamantes | Paquete grande de diamantes |
| id | 4.000 Berlian | Paket berlian besar |
| pt | 4.000 Diamantes | Pacote grande de diamantes |
| th | เพชร 4,000 เม็ด | แพ็กเพชรใหญ่สำหรับ Boba Empire |
| ko | 다이아몬드 4,000개 | Boba Empire 대용량 다이아 팩 |

**`boba_gems_mega`**
| Ngôn ngữ | Display Name | Description |
|---|---|---|
| vi | 10.000 Kim Cương | Gói Kim Cương siêu hời |
| en | 10,000 Diamonds | Best-value diamond pack |
| es | 10.000 Diamantes | Paquete de diamantes de mayor valor |
| id | 10.000 Berlian | Paket berlian paling hemat |
| pt | 10.000 Diamantes | Pacote de diamantes mais vantajoso |
| th | เพชร 10,000 เม็ด | แพ็กเพชรสุดคุ้ม |
| ko | 다이아몬드 10,000개 | 가장 알찬 다이아 팩 |

**`boba_cold_storage`**
| Ngôn ngữ | Display Name | Description |
|---|---|---|
| vi | Kho lạnh vĩnh viễn | Thêm 8 giờ trần tiền offline mãi mãi |
| en | Cold Storage (permanent) | +8 hours offline earnings cap, forever |
| es | Cámara fría (permanente) | +8 horas de límite sin conexión |
| id | Gudang dingin (permanen) | +8 jam batas pendapatan offline |
| pt | Câmara fria (permanente) | +8 horas de limite offline |
| th | ห้องเย็นถาวร | เพิ่มเพดานรายได้ออฟไลน์ 8 ชม. |
| ko | 냉장고 (영구) | 오프라인 수입 한도 영구 +8시간 |

**`boba_combo_noads_x2`**
| Ngôn ngữ | Display Name | Description |
|---|---|---|
| vi | Combo: Gỡ QC + x2 Thu nhập | Gỡ quảng cáo và x2 thu nhập vĩnh viễn |
| en | Combo: No Ads + x2 Income | Remove ads and double income forever |
| es | Combo: Sin anuncios + x2 | Sin anuncios y x2 ingresos para siempre |
| id | Kombo: Tanpa iklan + x2 | Tanpa iklan dan x2 pendapatan selamanya |
| pt | Combo: Sem anúncios + x2 | Sem anúncios e x2 de renda para sempre |
| th | คอมโบ: ไม่มีโฆษณา + x2 | ไม่มีโฆษณาและรายได้ x2 ถาวร |
| ko | 콤보: 광고 제거 + 수입 x2 | 광고 제거와 영구 수입 x2 |

## 4. Test trước khi gửi duyệt
1. **Users and Access → Sandbox → Testers**: tạo Sandbox Apple ID (email chưa dùng cho Apple ID thật).
2. Trên iPhone: *Settings → App Store → Sandbox Account* đăng nhập tài khoản đó, cài build TestFlight/dev.
3. Mua thử cả 4 gói: 💎 cộng đúng số; Kho lạnh làm trần offline tăng 8 giờ; Combo bật cả "gỡ QC" lẫn "x2" và biến mất khỏi danh sách; mua xong màn **Mốc nạp & VIP** (👑 ở đầu cửa hàng) có điểm.
4. Thử **Khôi phục mua hàng**: Kho lạnh/Combo khôi phục được, KHÔNG cộng thêm điểm nạp.

## 5. Lỗi hay gặp
- **App không hiện giá / nút mua trống**: Product ID sai, product chưa *Ready to Submit*, hoặc hợp đồng Paid Apps chưa Active. Product mới đôi khi cần vài giờ để Apple phân phối.
- **Combo không hiện**: cố ý — chỉ hiện khi người chơi chưa có gói Gỡ QC lẫn gói x2 (nếu có một trong hai thì ẩn).
- **Bị Apple từ chối vì tỉ lệ 💎**: hiếm khi; nếu bị, trả lời rằng gói gems là consumable bình thường, tỉ lệ có công bố trong game.
