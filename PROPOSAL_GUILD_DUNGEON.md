# PROPOSAL — Phó bản Hội: đồng đội theo vai trò (không PvP)

> Trạng thái: **ĐÃ LÀM 2026-10-17 (chưa commit/playtest)** theo khuyến nghị cả 4 câu (đủ 3 thanh, chọn vai ×1.5, 3 ải/tuần, có rương) — `GAME_DESIGN.md` §42; SQL `guild_dungeon_schema.sql` PHẢI chạy (sau guild_schema.sql), test bằng `scripts/test_dungeon_sql.sh`. Lệch: ngưỡng tính theo SỐ THÀNH VIÊN (min 3), không theo "thành viên đang đóng góp"; chưa có nút nhắc chat/chấm đỏ menu. Mọi số là ước lượng chưa playtest, sẽ nằm trong `Balance` + hàm SQL
> `guild_dungeon_*` (khớp nhau bằng test như `guild_sql_test.dart`). Ngày: 2026-10-17.

## 1. Vấn đề hiện có
Boss Hội = tổng điểm tuần của cả hội (`guild_week_total`), điểm = chạm + 50×(mèo+VIP). Mọi thành viên làm
**cùng một việc** (chạm) và chỉ cộng dồn — không ai cần ai, người ít chạm bị coi là "vô dụng", và 3 hệ thống
khác (chơi offline, Công thức/Pha theo đơn, Ghép 3) không đóng góp gì cho hội.

## 2. Thiết kế

**Phó bản tuần** (đặt lại thứ Hai UTC, cùng chu kỳ Boss): 3 ải liên tiếp. Mỗi ải có **ba thanh tiến độ**:

| Thanh | Vai trò | Tính từ | Ví dụ ngưỡng ải 1 (hội 20 người) |
|---|---|---|---|
| ⚔️ Công phá | Thợ chạm | số lần chạm ly (`tap`) | 20 000 |
| 🌙 Gác đêm | Người gác | giờ offline được tính (kẹp ≤ trần offline/ngày) | 80 giờ |
| 📜 Công thức | Đầu bếp | câu đúng ở Công thức + đơn 3★ Pha theo đơn + sao Ghép 3 | 400 điểm |

- **Ải chỉ qua khi CẢ BA thanh đầy.** Dư ở thanh này **không** bù thanh kia → hội phải có người làm đủ
  ba loại việc; đó là phần "phối hợp". Ngưỡng = đơn giá/người × số thành viên (tối thiểu có sàn), như HP Boss.
- **Chọn vai trò**: mỗi người chọn 1 vai/tuần (đổi được 1 lần/tuần). Đóng góp đúng vai nhân **×1.5**; đóng
  góp ngoài vai vẫn tính ×1. Màn Phó bản cho thấy "thanh nào đang thiếu, ai đang đứng vai nào" để chủ hội
  điều phối bằng chat sẵn có.
- **Phần thưởng**: mỗi ải qua → cả hội nhận Xu Hội (người đã đóng góp ≥ mức tối thiểu ở BẤT KỲ thanh nào mới
  nhận, chống ăn theo); ải 3 → thêm 💎 và 1 rương phụ kiện. Bậc Phó bản tăng theo chuỗi tuần giống Boss.
- **Không pay-to-win**: không có 💎 mua tiến độ; đầu vào đều là hoạt động chơi thật (không tính mua nâng cấp,
  cùng lý do `eventScore`).
- **Tương tác**: bảng "đóng góp theo vai" (huy hiệu MVP mỗi thanh), nút "Nhắc trong chat" (dùng @tag sẵn có)
  cho người còn thiếu — không thêm kênh chat mới.

## 3. Phạm vi kỹ thuật
1. **SQL** `supabase/guild_dungeon_schema.sql` (file riêng, chạy SAU guild_schema.sql): bảng
   `guild_dungeon_members (user_id, week, role, tap, offline_s, recipe)`; RPC `guild_dungeon_submit(tap, offline_s,
   recipe)` nhận **tổng luỹ kế** (giống `guild_submit_score`: chỉ cộng phần tăng, kẹp trần theo giờ trong tuần
   cho từng thanh, từ chối giảm); `guild_dungeon_set_role`; `guild_dungeon_state` (trả ngưỡng, thanh, ải, vai
   từng người, đã nhận chưa); `guild_dungeon_claim(stage)` (hai pha: server đánh dấu rồi client cộng, như
   `guild_claim_boss`). Mọi ghi qua RPC `security definer`, RLS không policy; `revoke` hàm nội bộ.
2. **Dart**: `lib/core/guild_dungeon.dart` (hằng số + công thức ngưỡng, thuần), `GameState` giữ 3 bộ đếm luỹ kế
   tuần (`dungeonWeek`, `dungeonTap`, `dungeonOfflineSeconds`, `dungeonRecipe`; reset khi sang tuần; `?? 0` tương
   thích save cũ), điểm nối vào: chạm (`tapGain` caller), `applyOfflineEarnings`, `answerRecipe`/`grantOrderEssence`
   /`grantMatch3Result`. Repository + controller trong `lib/guild/`, màn `lib/ui/guild_dungeon_page.dart` +
   thẻ trên màn Hội. 7 ngôn ngữ.
3. **Test**: công thức ngưỡng khớp SQL; không qua ải khi thiếu 1 thanh; vai ×1.5; kẹp trần; luỹ kế không giảm;
   claim 1 lần/ải; `scripts/test_guild_sql.sh` kiểm trên Postgres thật; UI 320px×1.5×7 ngôn ngữ.

## 4. Rủi ro
| Rủi ro | Biện pháp |
|---|---|
| Số liệu do client báo → gian lận | Luỹ kế + trần theo giờ mỗi thanh (như điểm Hội); thưởng chỉ Xu Hội/💎 nhỏ; chưa có xác thực server thật, **chấp nhận mức bảo vệ như Boss hiện tại** |
| Hội nhỏ/ít hoạt động không qua nổi ải | Ngưỡng theo số thành viên **đang đóng góp** (≥1 thanh trong tuần), sàn thấp; thang bậc, ải 1 dễ |
| Thanh Công thức bị "bỏ rơi" vì ít người chơi | Nguồn rộng (3 trò) + tính ×1.5 theo vai; đo sau 2 tuần rồi chỉnh |
| Người mới vào hội muộn không có phần | Chỉ cần ≥ mức tối thiểu nhỏ để nhận thưởng ải; tính từ ngày vào |
| Quá tải màn Hội | Chỉ 1 thẻ gọn trên màn Hội, chi tiết ở màn riêng |

## 5. Câu hỏi cần chốt
1. **"Cả ba thanh phải đầy" mới qua ải** (khuyến nghị, ép phối hợp) hay chỉ cần tổng điểm 3 thanh?
2. **Chọn vai ×1.5** (khuyến nghị) hay tự động theo việc người chơi làm (đơn giản hơn, ít điều phối)?
3. **Số ải & chu kỳ**: 3 ải/tuần (khuyến nghị) hay 1 ải/ngày trong 7 ngày?
4. Phần thưởng cuối có **1 rương phụ kiện** như mốc cuối mục tiêu tuần, hay chỉ Xu Hội + 💎?
