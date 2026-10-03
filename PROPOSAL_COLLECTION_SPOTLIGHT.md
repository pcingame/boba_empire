# Làm nổi bật Chợ Phụ kiện + Sưu tập (2026-10-03)

Bổ sung cho [`PROPOSAL_ACCESSORY_MARKET.md`](PROPOSAL_ACCESSORY_MARKET.md) và GAME_DESIGN §26–27.

## 0. Vấn đề
Hai tính năng đã code xong nhưng "chết": ẩn sâu, ít hàng, rớt đồ chậm, sưu tập không có hồi đáp.

| # | Vấn đề | Bằng chứng |
|---|---|---|
| 1 | Lối vào quá sâu | Màn chính → Thi đấu → Sưu tập → icon cửa hàng → Chợ (4 chạm) |
| 2 | Nhận phụ kiện không có "khoảnh khắc" | Cố ý không popup (§26), phải tự mở Kho |
| 3 | Sưu tập không có hồi đáp | Món chỉ nằm trong lưới Kho, không hiện ở đâu khác |
| 4 | Nguồn cung quá chậm | 1 lần rớt/ngày. Mô phỏng 2000 lượt: 10 món ≈ 11 ngày · 25 ≈ 35 · 40 ≈ 83 · **đủ 50 ≈ 270 ngày** (p90 387) |
| 5 | Chợ khởi đầu lạnh | Ít hàng, người mua mới 0 Xu Chợ, không có giá tham khảo |

## 1. Quyết định đã chốt (2026-10-03)
1. **Phụ kiện THUẦN TRANG TRÍ** — không buff thu nhập/chạm. Giá trị chuyển từ "hữu dụng"
   sang "khoe khoang". Lý do: tránh Pay-to-Win và để Xu Chợ không gián tiếp thành sức mạnh.
2. **Thêm nguồn rớt, KHÔNG gắn vào chạm/tick** (vòng lặp lõi):
   - Vòng quay may mắn: ô rương phụ kiện 5–8% (kích thích xem quảng cáo kiếm lượt quay).
   - Mốc Kỷ Nguyên: tặng món Sử thi/Huyền thoại.
   - Trân Châu Rơi: thưởng ở các mốc vượt màn (vd 10, 30, 60).
3. **Không tặng Xu Chợ — tặng hàng**: gói tân thủ = 1 phụ kiện Thường + 1 bản dư, bán được 10 Xu Chợ
   (NPC mua sau ~5 phút) để người chơi có khoảnh khắc "mình vừa bán được hàng".
4. **Trưng bày bắt buộc làm**: tối đa 3 phụ kiện lơ lửng quanh ly trà sữa trên màn chính, và 1 phụ
   kiện làm huy hiệu cạnh tên trên bảng xếp hạng. Dạng emoji nhẹ, không tốn chi phí vẽ.

### ⚠️ Điều chỉnh đề xuất cho quyết định 3 (cần chốt)
Cách "tặng hàng qua bot" vẫn bị cày như tặng tiền: mỗi danh tính mới (xoá dữ liệu app / đăng nhập
ẩn danh mới) nhận 10 Xu Chợ rồi dồn về nick chính qua việc mua đồ giá cao. Chống gian lận nằm ở
**điều kiện nhận**, không ở hình thức tặng:
- Chỉ mở gói tân thủ khi **đã có tiến độ thật** (vd đã nhận thưởng nhiệm vụ ngày lần đầu, hoặc
  đạt giai đoạn 3), không phải ngay lần mở Chợ đầu.
- **Một lần duy nhất mỗi tài khoản**, ghi cố định trên server (bảng `accessory_starter`).
- **Không cần tài khoản bot**: RPC `claim_starter_pack` tặng món, tạo listing 10 Xu Chợ, và hoàn tất
  "bán" sau 5 phút khi client gọi lại; không cần cron, không có tài khoản giả trong bảng giao dịch.
- Nếu vẫn lo cày hàng loạt: giới hạn thêm theo liên kết sao lưu, hoặc rate limit đăng nhập ẩn danh.

## 1b. Đã làm (2026-10-03, commit cục bộ, chưa push)
- Vòng quay 9 ô (rương 6%), khoảnh khắc nhận nội tuyến, trưng bày ≤3 món quanh cốc.
- Huy hiệu bảng xếp hạng: bảng `accessory_flair` + RPC `set_accessory_flair`/`accessory_flairs`
  (giữ lâu món trong Kho để đặt). Thay cho "cột badge" — 1 bảng thay vì sửa 6 bảng xếp hạng.
- Gói Khởi Nghiệp Chợ: RPC `claim_starter_pack`, điều kiện giai đoạn ≥3 + ≥1 nhiệm vụ ngày;
  1 lần/tài khoản + trần 500/ngày toàn server. Tiến độ do client khai nên làm giả được.
- Nguồn rớt có bảo đảm độ hiếm: Kỷ Nguyên (Sử thi, 15% Huyền thoại), mốc Ghép 3 lần đầu qua
  màn 10/30/60 (Hiếm/Sử thi/Huyền thoại).
- SQL phải chạy lại `supabase/accessory_market_schema.sql` trong Supabase.
- Đã làm thêm: ô Chợ ở hộp Thi đấu + chấm đỏ, hướng dẫn lần đầu, analytics, mốc sưu tập 10/25/40/50,
  giá tham khảo, danh sách muốn có (push), GĐ4: xem bộ sưu tập người khác (bấm hàng ở BXH Sưu tập,
  RPC `accessory_collection_of`), thẻ chia sẻ dạng chữ (chép clipboard, nút ở Kho), sự kiện cuối tuần
  (phí Chợ 0% thứ 7/CN UTC — `market_fee_free()` + `lib/core/market_fee.dart` + Edge Function).
- Chưa làm: thẻ chia sẻ dạng ẢNH (cần share_plus), tăng tỉ lệ rớt cuối tuần.

## 2. Kế hoạch

**GĐ1 — Dễ thấy hơn (1–2 ngày, rủi ro thấp)**
- Hộp Thi đấu: tách "Chợ" thành ô riêng (2 chạm), ô Sưu tập + Chợ có huy hiệu số (món mới nhận,
  listing mới).
- Khoảnh khắc nhận phụ kiện **nội tuyến trong hộp thoại nhiệm vụ ngày** (hàng "🎁 Nhận được 🐉 …"
  + hiệu ứng ánh độ hiếm, huyền thoại có pháo giấy) — không thêm popup mới.
- Hướng dẫn 3 bước lần đầu vào Chợ (Xu Chợ, phí 1%, bán bản dư).
- Sự kiện phân tích: `market_open`, `listing_created`, `trade_done`, `accessory_dropped`,
  `collection_milestone`.

**GĐ2 — Có lý do để sưu tập (3–4 ngày)**
- Trưng bày: chọn ≤3 phụ kiện lơ lửng quanh vòng cốc (`equippedAccessories`, lưu trong save, đồng
  bộ đám mây). Đặt quanh vòng cốc — KHÔNG gắn vào tranh cảnh (18 bản nghệ thuật khác nhau).
- Huy hiệu bảng xếp hạng: cột `badge` trong `accessory_leaderboard_entries`, kiểm tra id hợp lệ ở
  server; app bỏ qua id lạ (bài học lỗi `accessoryById` ném `StateError`).
- Mốc sưu tập 10/25/40/50 món + vòng tiến độ trong Kho; thưởng là **Xu Chợ + danh hiệu**
  (không đụng 💎/Xu thật).
- Gói tân thủ (RPC `claim_starter_pack`, xem mục 1).

**GĐ3 — Chợ sôi động (3–5 ngày)**
- Nguồn rớt mới: ô rương vòng quay (cân lại trọng số các ô hiện có), thưởng Kỷ Nguyên, mốc
  Trân Châu Rơi (cờ "đã nhận mốc" lưu trong save, chống nhận lặp).
- Giá tham khảo "bán gần đây / thấp nhất" theo món (RPC thống kê, ẩn danh) trong hộp đăng bán/mua.
- Danh sách muốn có (wishlist) + push khi có người đăng bán (tái dùng hạ tầng push).

**GĐ4 — Lan truyền (tuỳ chọn)**: thẻ chia sẻ, xem bộ sưu tập người khác từ bảng xếp hạng, sự kiện
cuối tuần (tỉ lệ rớt cao hơn / phí Chợ 0%).

## 3. Rủi ro
- Xu Chợ khởi đầu bị cày (xem điều chỉnh ở mục 1).
- Lạm phát Xu Chợ do thưởng mốc/gói tân thủ — giữ ràng buộc MỘT CHIỀU (không đổi ra Xu/💎 thật).
- Hiệu năng: phần trưng bày dùng emoji `Text`, không Lottie/ảnh; đo lại bằng
  `integration_test/perf_test.dart` trước/sau.
- Mỗi chuỗi mới cần 6 ngôn ngữ; SQL mới phải chạy trên Supabase (idempotent).
- Nguyên tắc "không popup": mọi phản hồi làm nội tuyến hoặc huy hiệu.

## 4. Đo hiệu quả
% người chơi hoạt động mở Chợ mỗi ngày · listing/giao dịch mỗi ngày · thời gian trung bình để bán
được · phân bố số món sưu tập · D7 của người có ≥1 giao dịch so với người không có.
