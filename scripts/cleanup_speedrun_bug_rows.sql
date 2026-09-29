-- Dọn dữ liệu bị hỏng bởi bug firstPlayedMillis-mặc-định (xem commit sửa
-- gốc rễ: game_controller.dart _stampStoryFinales + GameState.firstPlayedIsEstimate).
--
-- KHÔNG PHẢI GIAN LẬN của người chơi — xem giải thích trong hội thoại. Đây là
-- save cũ (tạo trước 2026-09-12, khi trường firstPlayedMillis chưa tồn tại)
-- được nạp lần đầu dưới code MỚI đúng lúc họ vừa/sắp hoàn thành cốt truyện —
-- mốc "bắt đầu" bị đoán thành một điểm rất gần "bây giờ" nên thời gian hoàn
-- thành tính ra chỉ còn vài chục/vài trăm giây, dù họ đã chơi thật hàng giờ.
--
-- Cách chạy: xem lại SELECT trước, ưng thì bỏ comment 2 dòng DELETE bên dưới.
-- Không có cột nào khác bị ảnh hưởng (Xu/💎/Sao của người chơi không đụng tới
-- — bảng này chỉ là vanity leaderboard, tách biệt hoàn toàn kinh tế chính).

-- ─── Hồi 1 (Chương 18, cần GĐ12) ───────────────────────────────────────────
-- 10 dòng dưới 300s, tất cả nộp trong đúng khung 2026-09-24 → 2026-09-26 —
-- đúng cửa sổ save-cũ-nạp-lần-đầu-dưới-code-mới, không phải rải rác ngẫu
-- nhiên. Đối chiếu: lên GĐ12 từ save mới cần hàng giờ chơi thật.
select nickname, complete_seconds, completed_at
from story_speedrun_entries
where complete_seconds < 300
order by complete_seconds asc;

-- delete from story_speedrun_entries where complete_seconds < 300;

-- ─── Hồi 2 (Chương 28, cần GĐ18 — còn đòi hỏi nhiều hơn Hồi 1) ─────────────
-- Chỉ 1 dòng nghi vấn (NTN, 508s = 8 phút 28s) — tự xem có đáng xoá không,
-- không tự động gộp vào ngưỡng trên vì mốc nộp (2026-09-29) không khớp đúng
-- khung ngày như nhóm trên.
select nickname, complete_seconds, completed_at
from story_speedrun2_entries
where complete_seconds < 600
order by complete_seconds asc;

-- delete from story_speedrun2_entries where user_id = '<dán user_id của NTN nếu quyết định xoá>';
