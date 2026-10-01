# ĐỀ XUẤT — Chợ Phụ kiện (Accessory Market, giai đoạn 2)

> Trạng thái: **đã code xong, chờ deploy SQL + test**. Tóm tắt vận hành đã
> đưa vào `GAME_DESIGN.md` §27. Nối tiếp "Kho phụ kiện" (giai đoạn 1, đã ship
> — xem [`GAME_DESIGN.md`](GAME_DESIGN.md) §26). File này chỉ mô tả **module
> cộng thêm**; không đụng `GameState`/`economy.dart`/`simulation.dart` hiện
> có, cùng nguyên tắc đã dùng ở [`PROPOSAL_ARENA_PVP.md`](PROPOSAL_ARENA_PVP.md).
>
> ⚠️ Khác bản phác thảo §4 ban đầu: lúc code mới phát hiện thiếu RPC
> `register_accessory_drop` (server không có cách nào verify quyền sở hữu nếu
> thiếu nó — xem ghi chú đầu `supabase/accessory_market_schema.sql`). Đã vá
> trước khi deploy, không phải vá sau.

## 0. Nguyên tắc thu hẹp

Lý do phải thu hẹp — **giống hệt bài học ở Arena PvP, nhưng nặng hơn**: nền
kinh tế chính (Xu, 💎) là **client-authoritative hoàn toàn**, sống trong save
JSON local, không có "ví" nào ở server cả. Arena PvP né được vấn đề này vì
phần thưởng chỉ chảy 1 chiều (server → `grantGems` sau trận, không có ai
"gửi tiền" cho ai). Chợ thì khác: **2 người chơi trao đổi giá trị thật qua
lại** — nếu để họ đổi thẳng bằng Xu/💎 thật, một người có thể tự mở 2 tài
khoản rồi bán/mua qua lại để rửa tiền ảo (bơm Xu/💎 vào 1 tài khoản mà không
tốn công chơi thật) — đúng lớp lỗ hổng đã né được ở Arena bằng cách không
port kinh tế thật lên server.

**Giải pháp thu hẹp — không dùng Xu/💎 thật để giao dịch:**

- Chợ chạy bằng 1 đơn vị MỚI, tách biệt: **Xu Chợ** (market credit).
- Xu Chợ **chỉ kiếm được bằng cách BÁN** phụ kiện trên chợ, và **chỉ tiêu
  được bằng cách MUA** phụ kiện trên chợ — **KHÔNG đổi ngược ra Xu/💎 thật
  được theo bất kỳ hướng nào**.
- Vì vậy tự bán-mua qua lại giữa 2 tài khoản chỉ luân chuyển một thứ **vô
  giá trị ngoài chợ** — triệt tiêu động cơ rửa tiền ngay từ thiết kế, không
  cần dò từng kiểu gian lận như Arena phải làm (rate-limit tap, v.v.).
- Đánh đổi: chợ trở thành 1 nền kinh tế "đóng", không liên thông với ván
  chính — nhưng đó chính xác là điều cần để KHÔNG phải port `economy.dart`
  lên server (giống lý do Arena PvP không dùng `tapValue`/cấp thật).

**Rủi ro khác, riêng của tính năng này (Arena không có):** `ownedAccessories`
hiện là 1 field trong save local, đồng bộ qua Cloud Save kiểu **one-way, còn
hạn chế đã ghi nhận** (xem `cloud-save-one-way-sync-limitation` trong known
issues). Nếu máy A bán 1 món (server đã trừ khỏi máy A) nhưng máy B (cùng
tài khoản, chưa đồng bộ) vẫn còn bản cũ có món đó trong save local — lần
đồng bộ cloud tiếp theo từ máy B có thể "hồi sinh" món đã bán. Phải xử lý ở
§5.

## 1. Phạm vi

**Trong phạm vi (bản đầu):**
- Đăng bán 1 phụ kiện ĐANG SỞ HỮU với giá Xu Chợ tự đặt (trong khung giá cho
  phép — chặn giá 0/âm/vô lý).
- Mua phụ kiện người khác đăng — người mua trả Xu Chợ, món chuyển chủ.
- Huỷ đăng bán (lấy lại món, không hoàn/mất gì).
- Lịch sử giao dịch của chính mình (đã bán/đã mua) — chỉ để xem, không cần
  màn hình đẹp ở bản đầu.
- Kiếm Xu Chợ khởi điểm bằng cách BÁN món dư (trùng) thay vì quy đổi 💎 như
  hiện tại — GĐ1 vẫn giữ nguyên đường quy đổi 💎 cho món trùng **song song**,
  người chơi tự chọn bán chợ hay quy đổi thẳng lúc rớt trùng (2 lối ra, xem
  §6 cách đổi tối thiểu ở `claimDailyBonus`).

**Ngoài phạm vi (không làm ở bản đầu):**
- KHÔNG mua bằng Xu/💎 thật — xem §0. Đây là ranh giới cứng, không thương
  lượng ở bản đầu (đổi sau thì phải thiết kế lại toàn bộ phần chống gian lận).
- Không đấu giá (auction)/trả giá (counter-offer) — chỉ mua đứt bán đoạn theo
  giá người bán đặt.
- Không tìm kiếm/lọc nâng cao (theo độ hiếm là đủ ở bản đầu).
- Không giới hạn số lượng mỗi món trên chợ (1 món chỉ có 1 bản mỗi người sở
  hữu — xem GĐ1 — nên tự nhiên không có chuyện "bán 100 cái cùng lúc").
- Không thông báo đẩy ("món bạn đăng vừa bán") — người chơi tự vào chợ kiểm
  tra, cùng triết lý "không tự bật popup" đã dùng ở GĐ1.

## 2. Cơ chế Xu Chợ & giao dịch (đề xuất cụ thể)

- **Số dư Xu Chợ**: đọc trực tiếp từ Supabase mỗi lần mở màn Chợ (KHÔNG cache
  vào `GameState`/save local — tránh đúng lớp rủi ro "hồi sinh" ở §0). Giống
  cách bảng xếp hạng luôn tải trực tiếp, không lưu local.
- **Đăng bán** (`list_accessory` RPC): kiểm `auth.uid()` thật sự sở hữu món
  (server-side, không tin client) → xoá khỏi bảng sở hữu server, tạo hàng
  `accessory_listings` (status = active). Client sau đó tự xoá món khỏi
  `GameState.ownedAccessories` local + đẩy save (xem §6).
  ⚠️ Vì vậy **số đếm nộp lên bảng xếp hạng Sưu tập không được lấy thẳng
  `ownedAccessories.length` như GĐ1 nữa** — phải cộng thêm số listing
  `active` của chính mình (đọc từ `accessory_listings`), đúng theo quyết
  định §9.3: món đang rao bán vẫn tính là "của mình" tới khi thật sự có
  người mua.
- **Mua** (`buy_listing` RPC, 1 transaction): khoá hàng listing (`for update`)
  → kiểm còn `active` + người mua đủ Xu Chợ + người mua ≠ người bán (chặn tự
  mua chính mình, dù không có lợi gì về mặt kinh tế nhờ §0 nhưng vẫn chặn
  cho sạch) → trừ Xu Chợ người mua, cộng người bán, đổi `status = sold`,
  ghi `accessory_market_trades`. Người mua client sau đó tự thêm món vào
  `GameState.ownedAccessories` local + đẩy save.
- **Huỷ đăng** (`cancel_listing` RPC): kiểm đúng chủ + còn `active` → đổi
  `status = cancelled`. Client tự thêm lại món vào local.
- **"Đồng bộ lệch"**: nếu app bị tắt giữa lúc đăng bán/mua/huỷ TRƯỚC khi kịp
  cập nhật `GameState` local (mất mạng, crash) — mở lại Chợ thì màn "Của
  tôi" phải đối chiếu server (nguồn sự thật) và tự sửa local cho khớp, giống
  cách Cloud Save xử lý xung đột (`CloudSaveConflict`) — không bắt người chơi
  tự nhớ.

## 3. Kiến trúc

```
Flutter app (module mới: lib/market/…)
        │  Supabase Dart client
        ▼
┌─────────────────────────────────────────────┐
│                  Supabase                    │
│  ┌───────────┐  ┌────────────────────────┐   │
│  │   Auth    │  │       Postgres          │   │
│  │(cùng phiên│  │ accessory_listings      │   │
│  │ cloud save│  │ accessory_wallets       │   │
│  │ hiện có)  │  │ accessory_market_trades │   │
│  └───────────┘  └────────────────────────┘   │
│         │                  │                  │
│         └──► RPC: list_accessory /            │
│                   buy_listing /                │
│                   cancel_listing  ◄─── CHỈ     │
│              đường ghi duy nhất (RLS chặn      │
│              insert/update thẳng từ client)    │
└─────────────────────────────────────────────┘
```

- Dùng lại session Supabase hiện có (cloud save đã đăng nhập thật hoặc Đấu
  Trường đã đăng nhập ẩn danh) — không cần luồng đăng nhập riêng.
- Không cần Realtime (khác Arena) — chợ không cần "trực tiếp", tải lại khi
  mở màn là đủ (cùng khuôn bảng xếp hạng).

## 4. Data model (Postgres, phác thảo — chốt kỹ lúc triển khai)

```sql
-- Số dư Xu Chợ, KHÔNG liên thông Xu/💎 thật (xem §0).
create table accessory_wallets (
  user_id  uuid primary key references auth.users(id) on delete cascade,
  balance  bigint not null default 0 check (balance >= 0)
);

-- Ai đang sở hữu món nào — nguồn sự thật SERVER-SIDE khi món đang/từng lên
-- chợ (khác GĐ1: GameState.ownedAccessories local chỉ là bản cache).
create table accessory_server_ownership (
  user_id       uuid not null references auth.users(id) on delete cascade,
  accessory_id  text not null,
  primary key (user_id, accessory_id)
);

create table accessory_listings (
  id            uuid primary key default gen_random_uuid(),
  seller_id     uuid not null references auth.users(id),
  accessory_id  text not null,
  -- Giá tự do, chỉ chặn biên rộng (xem §9.1) — không khung theo độ hiếm.
  price         bigint not null check (price between 1 and 100000),
  status        text not null default 'active', -- active|sold|cancelled
  created_at    timestamptz not null default now(),
  resolved_at   timestamptz
);

create table accessory_market_trades (
  id            bigint generated always as identity primary key,
  listing_id    uuid not null references accessory_listings(id),
  buyer_id      uuid not null references auth.users(id),
  seller_id     uuid not null references auth.users(id),
  accessory_id  text not null,
  price         bigint not null,
  traded_at     timestamptz not null default now()
);
```

- RLS: `accessory_wallets`/`accessory_server_ownership` — `select` chỉ hàng
  của chính mình; KHÔNG có policy `insert`/`update` nào cho client (mọi thay
  đổi đi qua RPC `security definer`).
- `accessory_listings` — `select` công khai (ai cũng xem được chợ đang bán
  gì), `insert`/`update` chỉ qua RPC.

## 5. Chống gian lận & đồng bộ

- **Rửa tiền qua lại**: triệt tiêu bằng thiết kế (Xu Chợ không đổi ra được
  Xu/💎 thật) — xem §0. Không cần thêm cơ chế phát hiện phức tạp.
- **Double-spend/race**: `buy_listing` PHẢI `select ... for update` khoá hàng
  `accessory_listings` trong transaction trước khi đổi `status`, chặn 2
  người mua cùng lúc 1 listing (bài học từ `pushIfCurrent`/optimistic
  concurrency đã dùng ở Cloud Save).
- **Tự mua chính mình**: chặn ở RPC dù không có lợi kinh tế thật (§0), tránh
  làm nhiễu `accessory_market_trades` (vd để thao túng cảm giác "món hot").
- **Đồng bộ ngược với Cloud Save (rủi ro riêng đã nêu ở §0)**: BẮT BUỘC —
  ngay sau `list_accessory`/`buy_listing` thành công, client phải xoá/thêm
  món trong `GameState.ownedAccessories` VÀ gọi `saveNow()` (đẩy cloud save
  ngay, không đợi tick nền) để giảm cửa sổ máy khác "hồi sinh" món đã bán.
  Không triệt tiêu hoàn toàn được (vẫn có thể mất mạng đúng lúc đó) — nên
  thêm bước đối chiếu khi mở app (xem §2, "đồng bộ lệch") làm lưới an toàn
  cuối, không dựa 100% vào việc đẩy save kịp thời.
- **Spam đăng bán**: giới hạn số listing active/người chơi (VD tối đa = tổng
  số món họ từng sở hữu, tự nhiên bị chặn vì mỗi món chỉ đăng được 1 lần) —
  không cần thêm rate-limit riêng vì tổng phụ kiện có trần 50 (GĐ1, nâng từ
  16 lên 50 lúc chốt kế hoạch này — xem GAME_DESIGN.md §26).

## 6. Điểm nối vào code hiện tại

- Module mới, tách biệt: `lib/market/` (repository + controller, cùng khuôn
  `cloud_save_repository.dart`/`cloud_save_controller.dart`) + UI riêng
  trong `lib/ui/accessory_market_page.dart`, vào từ nút mới trên AppBar của
  `accessory_inventory_page.dart` (cạnh nút 🏆 xếp hạng đã có).
- **Đổi tối thiểu ở code GĐ1 đã ship**: `grantAccessory` (accessories.dart)
  khi rớt TRÙNG — hiện quy đổi thẳng 💎. Thêm 1 lựa chọn ở UI rớt trùng: quy
  đổi 💎 (như cũ) HOẶC "đăng bán chợ" (gọi RPC `list_accessory` ngay lúc đó
  cho món vừa rớt trùng đang dư thừa). Không đổi chữ ký `grantAccessory`.
- `GameState.ownedAccessories` — thêm/bớt qua `list_accessory`/`buy_listing`
  client-side sau khi RPC thành công (xem §5), tương tự cách `cloud_save_
  controller.dart` mutate `GameState` sau khi Supabase xác nhận.
- `pubspec.yaml`: không cần thêm dependency (đã có `supabase_flutter`).

## 7. Việc CHƯA làm ở bản đầu (ghi lại để khỏi quên, không phải từ chối)

- Không đấu giá/trả giá — chỉ mua đứt bán đoạn (xem §1).
- Không cho đổi Xu Chợ ra Xu/💎 thật theo bất kỳ tỷ giá nào — đây là ranh
  giới thiết kế cốt lõi, đổi sau phải thiết kế lại toàn bộ §0/§5.
- Không xử lý hoàn chỉnh trường hợp mất mạng ĐÚNG lúc giao dịch (RPC server
  đã chạy xong nhưng client crash trước khi kịp cập nhật local) — bản đầu
  chưa hỗ trợ (xem §6 — cần `saveNow()` ngay sau giao dịch + bước đối chiếu
  khi mở app).
- Không có giới hạn/thuế giao dịch (phí sàn) — cân nhắc thêm nếu thấy lạm
  phát Xu Chợ (không có cơ chế "rút" Xu Chợ khỏi hệ thống trừ lúc mua, nên
  về lý thuyết tổng Xu Chợ luôn bảo toàn — ít rủi ro lạm phát hơn Xu/💎 thật).
- Không có kiểm duyệt/báo cáo (report listing) — chợ chỉ đổi cosmetic, rủi ro
  thấp hơn chợ đổi tiền thật nên tạm bỏ qua ở bản đầu.

## 8. Lộ trình đề xuất

| Giai đoạn | Việc | Ước lượng |
|---|---|---|
| 0 | Schema + RLS + RPC (`list_accessory`, `buy_listing`, `cancel_listing`) | 1–1.5 ngày |
| 1 | `lib/market/` repository + controller (đọc listing, đọc ví, gọi 3 RPC) | 1 ngày |
| 2 | UI: màn Chợ (danh sách đang bán, lọc theo độ hiếm) + màn "Của tôi" (đăng bán/huỷ/lịch sử) | 2 ngày |
| 3 | Nối GĐ1: nút "đăng bán" ở màn rớt trùng phụ kiện | 0.5 ngày |
| 4 | Đối chiếu lúc mở app (lưới an toàn đồng bộ, xem §5) + test tích hợp race-condition mua trùng | 1–1.5 ngày |
| 5 | QA chống gian lận (tự mua, double-spend, đồng bộ lệch nhiều máy) | 1 ngày |

**Tổng ước lượng: ~6.5–8 ngày công** cho bản MVP.

## 9. Quyết định (đã chốt 2026-10-01)

1. **Tỉ giá quy đổi lúc bán**: giá Xu Chợ **tự do, không có khung theo độ
   hiếm** — chỉ chặn biên rất rộng (đề xuất 1–100,000) để UI không vỡ vì số
   0/âm/khổng lồ. Vì Xu Chợ không quy đổi được ra giá trị thật (§0), giá đặt
   vô lý nhiều nhất chỉ làm món đó ế, không gây thiệt hại kinh tế — không
   đáng thêm logic khung giá theo độ hiếm.
2. **Khởi điểm Xu Chợ**: **0, không "mồi" nhân tạo**. Người chơi tự nhiên có
   Xu Chợ qua đường bán món trùng (đã rớt đều từ nhiệm vụ ngày, xem GĐ1) —
   không cần cấp sẵn. Đánh đổi chấp nhận được: chợ có thể "nguội" vài ngày
   đầu lúc chưa ai bán gì, nhưng đây là tính năng không gấp.
3. **Món đang đăng bán VẪN tính vào bảng xếp hạng Sưu tập** — chỉ trừ khi
   giao dịch THẬT SỰ hoàn tất (có người mua). Lý do: nếu đăng bán làm tụt
   hạng ngay lập tức, người chơi sẽ ngại bán → chợ không có hàng → market
   chết yểu. Kéo theo thay đổi kỹ thuật ở §2 (số đếm nộp lên bảng xếp hạng
   phải cộng thêm listing `active` của chính mình, không chỉ đếm
   `ownedAccessories.length` cục bộ như GĐ1).
4. **Không thêm giới hạn giao dịch/ngày riêng** — tổng danh mục 50 món/người
   (GAME_DESIGN.md §26) đã tự nhiên chặn số lượng đăng bán tối đa ở mức thấp
   (mỗi món chỉ đăng được 1 lần), không cần thêm rate-limit cho một rủi ro
   vốn đã bị cấu trúc dữ liệu giới hạn sẵn.

Coi như đóng băng phạm vi ở mức này cho bản MVP — đổi luật sau khi đã có
bản chạy được, tránh vừa code vừa đổi yêu cầu (cùng cách Arena PvP đã làm
ở §10 của file đó).
