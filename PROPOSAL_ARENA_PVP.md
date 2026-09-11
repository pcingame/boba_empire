# ĐỀ XUẤT — Chế độ "Đấu Trường" (Arena PvP, dùng Supabase)

> Trạng thái: **đề xuất, chưa code**. Đây là bản thu hẹp phạm vi từ ý tưởng
> "multiplayer" ban đầu — không đụng tới engine kinh tế single-player hiện có
> (`lib/core/economy.dart`, `simulation.dart`, `game_controller.dart`).
> Đối chiếu với [`GAME_DESIGN.md`](GAME_DESIGN.md) — tài liệu đó vẫn là nguồn
> sự thật cho chế độ chơi chính; file này chỉ mô tả một **module cộng thêm**.

## 0. Nguyên tắc thu hẹp

Lý do phải thu hẹp (xem lại phần trao đổi trước): nền kinh tế chính hiện là
**client-authoritative hoàn toàn** (không server, save là JSON local, ai cũng
sửa tay được — xem thêm vụ lỗi tràn số vừa sửa). Biến *toàn bộ* game thành
multiplayer nghĩa là phải port lại 12 nguồn thu + mốc nhân bội + prestige +
perk sang chạy trên server — gần như viết lại app. Nên:

- **KHÔNG** đụng tới `GameState`, `economy.dart`, `simulation.dart` hiện có.
- **KHÔNG** làm tiền/cấp trong Đấu Trường ảnh hưởng ngược lại ván chính, trừ
  phần thưởng (Kim Cương) nhận SAU trận — cộng qua `grantGems` như IAP/quest
  hiện tại, không đổi engine.
- Đấu Trường là **luật riêng, tự chứa, đơn giản hơn hẳn** ván chính — để phần
  cần server xác thực (authoritative) nhỏ tới mức không cần port công thức
  kinh tế phức tạp.

## 1. Phạm vi

**Trong phạm vi:**
- 1v1, trận ngắn (60–90 giây), ghép ngẫu nhiên (matchmaking đơn giản, không
  cần MMR phức tạp ở bản đầu).
- Server (Supabase) xác thực kết quả để chống gian lận cơ bản.
- Đồng bộ điểm 2 người trong lúc đấu (real-time, đúng nghĩa "cùng chơi").
- Phần thưởng thắng/thua đổ ngược về ví Kim Cương của ván chính.

**Ngoài phạm vi (không làm ở bản đầu):**
- Không dùng `tapValue`/cấp nguồn thu/prestige thật của người chơi làm input
  trận đấu (tránh chênh lệch pay-to-win cực đoan giữa người chơi lâu năm và
  người mới — và tránh phải port công thức).
- Không chat, không bạn bè/guild, không rank mùa giải (để sau, xem §7).
- Không cần tài khoản đầy đủ — dùng **Supabase Anonymous Auth**, nâng cấp
  lên tài khoản thật là việc của bản sau.

## 2. Luật chơi Đấu Trường (đề xuất cụ thể — có thể đổi)

**"Đua pha trà 60 giây"**: cả 2 người chơi vào trận với **cùng một bộ số
liệu khởi điểm cố định** do server phát (không liên quan save thật):
- `tapValue = 1`, có 1 nút "Chạm ly" y hệt màn hình chính hiện tại.
- Trong 60 giây, thấy **3 mốc nâng cấp giá cố định** xuất hiện lần lượt
  (ví dụ: 20 Xu → ×2 giá trị chạm, 80 Xu → ..., 200 Xu → ...) — y hệt tinh
  thần "nguồn thu" nhưng chỉ 3 mốc, số cố định, KHÔNG dùng công thức
  `costGrowth^level` của ván chính.
- Ai đạt tổng Xu cao hơn khi hết giờ → thắng.

Vì luật này không có tăng trưởng luỹ thừa/mốc nhân bội/prestige, phần server
cần xác thực chỉ là: *số lần chạm hợp lệ trong 60s* (chặn bot/spam) + *các
mốc nâng cấp đã mua có đúng thứ tự/đúng giá không* — nhỏ và rõ ràng, không
phải re-implement `economy.dart`.

## 3. Kiến trúc

```
Flutter app (module mới: lib/arena/…)
        │
        │  Supabase JS/Dart client
        ▼
┌───────────────────────────────────────────┐
│                Supabase                    │
│  ┌───────────┐  ┌────────────┐  ┌────────┐ │
│  │   Auth    │  │  Postgres   │  │Realtime│ │
│  │(anonymous)│  │ + RLS       │  │Broadcast│ │
│  └───────────┘  └────────────┘  └────────┘ │
│         │              │             │      │
│         └──────► Edge Function (RPC) ◄──────┘
│              "submit_tap" / "resolve_match"  │
└───────────────────────────────────────────┘
```

- **Client KHÔNG được ghi trực tiếp** vào bảng điểm/trận đấu — mọi thay đổi
  đi qua RPC (Postgres function hoặc Edge Function). RLS chặn `UPDATE`/
  `INSERT` thẳng từ client trên các bảng trạng thái trận.
- **Realtime Broadcast** (kênh theo `match_id`) để 2 client thấy điểm của
  nhau gần như tức thời — đây là phần "trực tiếp" thật sự của multiplayer,
  và nó KHÔNG cần server tính hộ, chỉ cần server xác nhận số cuối trận.
- Client vẫn tự tính điểm cục bộ để hiển thị mượt (giống tap hiện tại), rồi
  gửi hành động lên RPC để server ghi nhận — mô hình **optimistic update +
  server xác nhận sau**, không chặn UX.

## 4. Data model (Postgres)

```sql
create table arena_matches (
  id           uuid primary key default gen_random_uuid(),
  player_a     uuid not null references auth.users(id),
  player_b     uuid references auth.users(id), -- null khi đang chờ ghép
  status       text not null default 'waiting', -- waiting|active|finished
  started_at   timestamptz,
  ends_at      timestamptz,
  score_a      numeric not null default 0,
  score_b      numeric not null default 0,
  winner       uuid,
  created_at   timestamptz not null default now()
);

create table arena_actions (
  id         bigint generated always as identity primary key,
  match_id   uuid not null references arena_matches(id),
  player     uuid not null references auth.users(id),
  kind       text not null,       -- 'tap' | 'buy_tier_1' | 'buy_tier_2' | 'buy_tier_3'
  at         timestamptz not null default now()
);
```

- `arena_actions` là **nhật ký thô** (append-only) — server tính lại
  `score_a`/`score_b` từ đây khi chốt trận, không tin số điểm client tự báo.
- RLS: `player_a`/`player_b` chỉ được `select` trận của chính họ; `insert`
  vào `arena_actions` chỉ qua RPC `submit_action(match_id, kind)` (kiểm tra
  `auth.uid()` khớp người trong trận + trận đang `active` + chưa hết giờ +
  đúng thứ tự mốc nâng cấp).

## 5. Chống gian lận (mức tối thiểu, không phải để giải Olympic bảo mật)

- Rate-limit trong `submit_action`: chặn > N tap/giây (idle game không cần
  chống cheat cấp esports, chỉ cần chặn bot thô).
  Ưu tiên áp ngay từ MVP để tránh phải vá lại
  sau khi có người chơi lợi dụng.
- `resolve_match` (chạy tự động khi `now() >= ends_at`, qua Supabase Cron/
  `pg_cron`) tính lại điểm từ `arena_actions`, không tin số client gửi kèm.
- Vì luật chơi không có state phức tạp (không cấp/không tăng trưởng luỹ
  thừa), việc "tính lại từ log" ở đây rẻ — khác hẳn nếu dùng thẳng luật ván
  chính.

## 6. Điểm nối vào code Flutter hiện tại

- Module mới, tách biệt: `lib/arena/` (client Supabase, models trận đấu,
  UI riêng) + 1 mục nav mới (không sửa `_BottomBar` 4 mục hiện có, thêm mục
  thứ 5 hoặc icon riêng ở màn hình chính).
- Duy nhất 1 điểm chạm vào `GameController` hiện có: khi trận kết thúc và
  thắng, gọi `grantGems(state, reward)` y như đường quest/IAP/ads hiện tại —
  không thêm field mới vào `GameState`/JSON save (giữ nguyên schema).
- `pubspec.yaml` thêm `supabase_flutter`.

## 7. Việc CHƯA làm ở bản đầu (ghi lại để khỏi quên, không phải từ chối)

- Không có ranked/mùa giải, không có bảng xếp hạng toàn cầu (đó là hướng "1.
  Leaderboard" đã bàn — có thể làm song song, rẻ hơn nhiều, cùng hạ tầng
  Supabase này).
- Không dùng số liệu thật của người chơi (tapValue/level) — nếu sau này
  muốn "đấu bằng chính đế chế của mình", đó là bước 2 và **sẽ** cần port một
  phần `economy.dart`, chi phí cao hơn hẳn — cân nhắc riêng, đừng gộp vào
  bản đầu.
- Không xử lý reconnect/mất mạng giữa trận ở mức hoàn chỉnh (bản đầu: mất
  mạng → xử thua, đơn giản).

## 8. Lộ trình đề xuất

| Giai đoạn | Việc | Ước lượng |
|---|---|---|
| 0 | Tạo project Supabase, bật Anonymous Auth, viết schema + RLS ở trên | 0.5–1 ngày |
| 1 | RPC `submit_action`, `resolve_match`, `pg_cron` chốt trận | 1–2 ngày |
| 2 | Matchmaking đơn giản (join hàng đợi, ghép 2 người, tạo `arena_matches`) | 1 ngày |
| 3 | UI Flutter: màn hình chờ ghép → màn trận (đồng hồ 60s, nút chạm, 3 mốc nâng cấp) → màn kết quả | 2–3 ngày |
| 4 | Nối Realtime Broadcast hiển thị điểm đối thủ trực tiếp | 1 ngày |
| 5 | Nối phần thưởng về `grantGems`, QA chống gian lận cơ bản, rate-limit | 1 ngày |

**Tổng ước lượng: ~7–10 ngày công** cho 1 bản MVP khả dụng — khác hẳn con số
"tính bằng tháng" nếu làm PvP trên chính nền kinh tế đầy đủ.

## 9. Chi phí Supabase (tham khảo, cần chốt lại lúc triển khai)

Free tier Supabase đủ cho giai đoạn thử nghiệm (giới hạn Realtime concurrent
connections + DB size) — chỉ cần nâng cấp trả phí khi lượng người chơi thật
vượt ngưỡng free tier.

## 10. Quyết định (đã chốt 2026-09-11)

1. **Luật**: dùng đúng như §2 — đua 60s + 3 mốc nâng cấp giá cố định.
2. **Matchmaking**: ghép ngẫu nhiên bất kỳ lúc nào có đủ 2 người trong hàng
   đợi (không làm "mời bạn qua mã phòng" ở bản đầu).
3. **Điều kiện vào**: mở cho mọi người chơi từ đầu, không khoá theo `stage`.

Coi như đóng băng phạm vi ở mức này cho bản MVP — đổi luật/matchmaking sau
khi đã có bản chạy được, tránh vừa code vừa đổi yêu cầu.
