# Kế hoạch: animation + nhân vật động, tối ưu theo từng dòng máy

Ghi ngày 2026-10-13. Chưa làm gì trong code. Mục tiêu: game "có hồn" hơn mà không làm giật/nóng máy yếu.

## Hiện trạng (đã khảo sát)
- Có `lottie` (`assets/anim`: bubbletea, cat, car, coins, confetti, fireworks, celebration — 952K). Thiếu file thì tự về emoji.
- Có sẵn: `lib/ui/widgets/idle_mascot.dart` (Lottie + nhún, 30Hz bằng Timer), `motion.dart` (`reduceMotion`, `PulseOnIncrease`), `one_shot_lottie.dart`, `animated_count.dart`, `accessory_reveal.dart`.
- Màn chính = 18 ảnh tĩnh `assets/scene/stage1..18.png` (440K). Truyện 36 chương, nhân vật chỉ là emoji + chữ.
- CHƯA có cơ chế phân loại máy. Impeller đang TẮT trên Android (emoji trống trên Xiaomi A15) — lớp vẽ mới phải chạy tốt khi Impeller tắt và khi bật lại.
- Bài học cũ: vòng lặp vô hạn ở 60Hz ăn ~50% GPU → mọi thứ mới phải dừng khi không hiển thị, tôn trọng `reduceMotion`, 0 ticker khi đứng yên.

## Công nghệ
Giữ Lottie. Cảnh nền = animation viết bằng code (`CustomPainter`, hạt). KHÔNG thêm Rive/Flame trừ khi sau này cần nhân vật nhiều trạng thái.

## Nguyên tắc: `EffectsQuality` điều khiển mọi hiệu ứng
| Mức | Hạt nền | Tốc độ vẽ | Nhân vật | Nổ (confetti/pháo hoa) |
|---|---|---|---|---|
| Tắt | 0 | 0 khung khi đứng yên | emoji tĩnh | không |
| Thấp | ≤ 6 | 15Hz | 1–2 nhân vật | nhẹ, ngắn |
| Vừa | ≤ 14 | 30Hz | đầy đủ | vừa |
| Cao | ≤ 24 | 30Hz (60Hz cho tương tác ngắn) | đầy đủ + parallax | đầy đủ |

Cài đặt: Tự động / Cao / Vừa / Thấp / Tắt.

### Chọn mức tự động
1. Lúc khởi động: Android = RAM, số nhân, cờ low-RAM, phiên bản Android; iOS = model máy → mức khởi điểm.
2. Khi chạy: theo dõi `FrameTiming` vài giây đầu (BỎ QUA giai đoạn nạp tài nguyên); >15% khung chậm → hạ 1 mức. Chỉ hạ, không tự nâng (tránh dao động).
3. Tiết kiệm pin của OS, pin <20%, máy nóng → hạ thêm.
4. Lưu mức đã chốt theo máy; gửi sự kiện analytics (bảng sẵn có, KHÔNG Firebase) để biết tỷ lệ mỗi mức.
- Cần thêm 1 gói đọc thông tin máy (vd `device_info_plus`) + đọc trạng thái pin — phụ thuộc mới duy nhất. (Chờ user đồng ý.)

## Quy tắc bắt buộc cho hiệu ứng mới
- Một `AmbientTicker` chung (30Hz, 15Hz ở Thấp); dừng khi trang bị che / app xuống nền / mức Tắt.
- `RepaintBoundary` quanh phần động.
- Nạp ảnh/Lottie theo nhu cầu, giải phóng khi rời màn; trần bộ nhớ ảnh giải mã.
- Luôn có phương án dự phòng (thiếu file / mức Tắt → emoji hoặc ảnh tĩnh).
- Ngân sách: màn chính mức Vừa ≤ 8ms GPU/khung trên máy tầm trung; mức Thấp gần bằng hiện tại. Dung lượng asset thêm < 3MB.

## Giai đoạn
| GĐ | Nội dung |
|---|---|
| 0 | Phân loại máy: `EffectsQuality`, chọn tự động, tự hiệu chỉnh, tùy chọn Cài đặt, analytics. `IdleMascot`/`PulseOnIncrease`/`OneShotLottie` đọc mức này |
| 1 | `AmbientTicker` chung theo mức + vòng đời trang |
| 2 | Cảnh nền sống: hạt/ánh sáng theo giai đoạn, số lượng theo mức |
| 3 | Phản hồi hành động: Xu bay, tia sáng khi mua, confetti ở mốc |
| 4 | Nhân vật khách + nhân viên (Thấp chỉ giữ 1–2) — cần art |
| 5 | Vi tương tác UI (nút nảy, popup trượt, chuyển tab, mở hộp quà) |
| 6 | Truyện: chân dung 2–3 biểu cảm (kể cả 🌀 Thầy Cả), chuyển cảnh — nhiều art nhất |

Thứ tự đề xuất: 0 → 1 → 2 → 3 → 5 → 4 → 6 (ba bước đầu không cần art mới).

## Kiểm thử
- Máy mốc: Xiaomi A15, Android RAM ≤ 3GB (nếu có), iPhone đời cũ. Không có máy thật → giả lập giới hạn tốc độ vẽ, ghi rõ chỉ là ước lượng.
- Đo mỗi GĐ trước/sau: thời gian dựng/vẽ khung, số khung chậm, nhiệt + hao pin sau 10 phút.
- Test tự động: chọn mức theo mô tả máy giả; tự hạ khi khung chậm; ticker dừng khi ẩn; mức Tắt = 0 ticker; không tràn 320px (7 ngôn ngữ).
- Khi cờ Impeller bị gỡ: kiểm lại mọi lớp vẽ mới.

## Rủi ro
- Đo FPS sai lúc khởi động → hạ mức oan (phải bỏ qua giai đoạn nạp).
- Hai máy cùng đời có thể ra mức khác nhau → cho chỉnh tay và hiện rõ trong Cài đặt.

## Việc cần user quyết định (chưa trả lời)
1. Nguồn art nhân vật: Lottie miễn phí (nhanh, lệch phong cách, kiểm giấy phép) / thuê hoặc tự vẽ bộ thống nhất / tôi vẽ đơn giản bằng code? (quyết định GĐ4, GĐ6)
2. Đồng ý thêm gói đọc thông tin máy (`device_info_plus`)? Nếu không: chỉ dựa đo FPS lúc chạy.
3. Phát hành: gom GĐ0–3 một bản đầu hay chia nhỏ hơn?

Mặc định nếu không có ý kiến: bắt đầu GĐ0 + GĐ1.

## Tiến độ
- 2026-10-14: GĐ0 + GĐ1 xong, chưa commit/chưa thử trên máy thật. Code: `lib/ui/widgets/effects_quality.dart` (mức, `FrameTuner`, `EffectsController`), `ambient_ticker.dart`; `IdleMascot` chạy qua ticker chung; `reduceMotion`/`Mascot` tôn trọng mức Tắt; mục "Hiệu ứng động" ở Cài đặt; analytics `fx_auto_drop` + `fx` trong `session_start`. Test: `test/ui/effects_quality_test.dart`, `idle_mascot_test.dart`.
- KHÔNG thêm `device_info_plus` (chưa được đồng ý): điểm xuất phát iOS=Cao, Android=Vừa, chỉ tự hạ theo đo khung hình. Chưa có: phân loại theo RAM/model, hạ theo pin/nhiệt.
- Đã nhận 8 file Lottie (`animation_1.zip`) vào assets/anim, đã khai báo `AnimAssets`, chưa nối vào màn nào. Còn thiếu giấy phép → `assets/anim/CREDITS.md`.
