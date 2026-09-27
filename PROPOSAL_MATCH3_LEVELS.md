# PROPOSAL — Hành trình Ghép 3 (chế độ chơi đơn có màn) + banner

Ngày 2026-09-28. Trạng thái: **đã làm xong Phase 1** (§11 bước 1-4). Phần cố ý
hoãn ở §10 vẫn chưa làm. Tóm tắt vận hành đã đưa vào `GAME_DESIGN.md` §23.

Mục tiêu: tách dạng Ghép 3 (đang chỉ là 1 trong 2 dạng PK của Đấu Trường, xem
GAME_DESIGN §20) thành một **tab riêng có hệ thống màn chơi**, và đặt **banner
quảng cáo** trong lúc chơi dạng này.

---

## 0. Ràng buộc bắt buộc đọc trước

**`lib/arena/match3_rules.dart` phải khớp bit-for-bit với `arena_m3_replay`
trong `supabase/arena_schema.sql`** (server replay log để chống gian lận PvP).
Vì vậy phần này **KHÔNG được đổi**: kích thước bảng, số loại ô, cách dò dãy,
thứ tự rơi/bù, bảng điểm.

Được phép: *thêm* hàm/field mới mà không đổi kết quả của `trySwap`
(VD một factory xáo bàn, hay thêm thông tin thống kê vào `Match3Move`). Mọi
thay đổi khác kéo theo sửa SQL + vector vàng trong
`test/arena/match3_rules_test.dart` — đắt gấp đôi, tránh ở đợt này.

Giả định đang dùng (nói ngay nếu sai):
- Chơi đơn, **không có server**, không bảng xếp hạng ở Phase 1.
- Không đụng kinh tế idle: Ghép 3 là nguồn thưởng phụ, không thay vòng lặp chính.
- Dùng lại engine + widget bàn cờ hiện có, **không viết bàn cờ thứ hai**.

---

## 1. Lối vào — tab thứ 5

`_BottomBar` (`home_page.dart:385`) đang là `Row` 4 mục, mỗi mục mở dialog/trang.
Thêm mục thứ 5 **"Ghép 3"**, mở `Match3JourneyPage` bằng `MaterialPageRoute`
(đúng khuôn `showArenaPage` ở `arena_page.dart:19`).

⚠️ **Rủi ro đã biết**: thanh cao 62px chia 5 mục → mỗi mục ~20% bề ngang. Nhãn
dài (th/pt/es) rất dễ tràn — đúng lớp lỗi trong memory `shop-tile-overflow-pattern`.
Bắt buộc: nhãn bọc `FittedBox(scaleDown)` hoặc `maxLines: 1 + ellipsis`, và thêm
một test dựng `_BottomBar` ở bề ngang 320px cho cả 6 ngôn ngữ.

Phương án đã loại: nhét vào "Đấu Trường"/Compete hub — trộn chơi đơn với PK làm
loãng cả hai, và đề bài là tab riêng.

## 2. Dữ liệu màn chơi — sinh bằng công thức, không bảng tay

```dart
class Match3Level {
  const Match3Level(this.id);
  final int id;                       // 1..Balance.m3LevelCount

  int get moves  => Balance.m3Moves;  // cố định 20
  int get target => (Balance.m3TargetBase * pow(Balance.m3TargetGrowth, id - 1)).round();
  int get seed   => id * 7919;        // số nguyên tố → bàn cố định, ai cũng như ai
}
```

- `seq` (chuỗi 2000 số engine cần) sinh tại chỗ bằng `Random(seed)` — bàn màn n
  **tất định**, giống nhau trên mọi máy, chơi lại vẫn y hệt.
- Sao: **1★** đạt `target`, **2★** đạt `1.5×`, **3★** đạt `2×`.
- Số màn Phase 1: **60**. Thêm màn = đổi một hằng số, không viết thêm data.
- 4 hằng số (`m3Moves`, `m3TargetBase`, `m3TargetGrowth`, `m3LevelCount`) nên
  **khai báo luôn là nút vặn Remote Config** (`lib/data/remote_balance.dart`,
  vừa dựng ở P1) → tune độ khó mà không phải nộp bản mới lên store.

> Đánh đổi: mọi màn cùng một kiểu mục tiêu (đạt điểm trong 20 nước) nên dễ nhàm
> sau ~20 màn. Đây là lựa chọn có ý thức để Phase 1 nhỏ; cách chữa ở §10.

## 3. Vòng đời một lượt chơi

```
Danh sách màn (lưới nút, khoá dần)
  → vào bàn: 20 nước, hiện điểm/mục tiêu/số nước còn lại
  → hết nước HOẶC đạt 3★ → bảng kết quả (sao + thưởng) → về danh sách
```

**Hết nước đi hợp lệ giữa chừng (stuck)**: PvP hiện chỉ báo "Hết nước đi!" rồi
đứng im cho hết 60 giây (ROADMAP §P2 mục 9). Ở chơi đơn điều đó là **kẹt cứng**,
bắt buộc phải **tự xáo lại bàn**. Cách làm không đụng luật: lấy tiếp số từ `seq`
chưa dùng để dựng bàn mới (`Match3Board.reshuffle()`), lặp tới khi bàn có ít
nhất 1 nước. Hàm mới, `arena_m3_replay` không gọi → SQL không đổi.

⚠️ **SỬA LẠI khẳng định ban đầu của bản đề xuất này** (đã kiểm
`arena_m3_replay` trong `supabase/arena_schema.sql` trước khi code): Đấu Trường
**KHÔNG dùng được** hàm xáo này. Server replay cả trận **chỉ từ `seq` + log nước
đi**, hoàn toàn không biết có xáo bàn — client tự xáo giữa trận là bàn lệch
server, mọi nước sau bị chấm sai. Muốn Đấu Trường hết kẹt (ROADMAP §P2 mục 9)
thì phải viết xáo bàn ở CẢ `arena_m3_replay` + vector vàng — việc riêng, không
đi kèm đợt này. Chơi đơn không có server nên xáo thoải mái.

## 4. Lưu tiến độ

- Thêm `GameState.m3Stars: List<int>` (chỉ số = màn − 1, giá trị 0..3), JSON key
  `m3Stars`, mặc định `[]` để save cũ vẫn đọc được.
- **Không** reset khi Nhượng quyền / Kỷ Nguyên (cùng nhóm với thành tựu, cốt truyện).
- Nằm trong `GameState` nên **tự đi theo cloud save**, không cần code đồng bộ riêng.
- Mở khoá: màn n mở khi màn n−1 được ≥1★.

## 5. Thưởng — và vì sao phải chặn farm

Bàn cờ tất định ⇒ chơi lại được điểm y hệt. Nếu thưởng lặp lại thì đây là **máy
in Xu/💎**. Quy tắc: **chỉ thưởng lần ĐẦU đạt mỗi mốc sao** (lên từ 1★ lên 2★ thì
chỉ trả phần chênh).

- **Xu**: theo *ngưỡng tương đối* — `thu nhập/giây × 10 phút × số sao`. Cùng thủ
  thuật nhiệm vụ hằng ngày đang dùng (GAME_DESIGN §19), vì kinh tế trải từ 1e2
  tới 1e80, số cố định vô nghĩa chỉ sau vài giờ chơi.
- **💎**: chỉ khi đạt 3★, **3 💎/màn** → trọn đời 60 màn = 180 💎. Đối chiếu:
  nhiệm vụ ngày + điểm danh đang ~40 💎/ngày, nên mức này không gây lạm phát 💎.
- Không có "mua thêm nước bằng 💎" ở Phase 1 (xem §10).

## 6. Banner quảng cáo — chi tiết

**Chỗ đặt**: đáy màn danh sách màn + đáy màn chơi, trong `SafeArea`, cách nội
dung ≥ 8px, và **bàn cờ co lại theo chiều cao banner** (`LayoutBuilder`), tuyệt
đối không đè lên bàn. Chống chạm nhầm là **yêu cầu chính sách AdMob**, không phải
chuyện thẩm mỹ: banner sát vùng chạm liên tục là kiểu vi phạm dễ bị khoá tài khoản
nhất.

**Chỗ KHÔNG đặt**:
- Trong trận Đấu Trường PvP — trận tính giờ 60 giây, chạm nhầm banner là thua trận.
- Trên các dialog kết quả/thưởng, không đặt cạnh nút bấm.

**Bắt buộc tôn trọng `adFree`**: `GameSnapshot.adFree` đã có sẵn
(`= adsRemoved || đang VIP`). Người đã mua gói "Gỡ quảng cáo" mà vẫn thấy banner
là refund + đánh giá 1 sao.

**Kiến trúc** (giữ nguyên nguyên tắc "SDK ở rìa" của repo): thêm
`lib/ads/banner_ad_box.dart` chứa widget `BannerAdBox` — tự no-op (trả
`SizedBox.shrink()`) khi không phải Android/iOS hoặc khi `adFree`. UI chỉ cần
`const BannerAdBox()`. Không nhét `Widget` vào interface `AdService` (interface
đang thuần logic, đừng bẩn hoá nó).

**Vòng đời**: tạo khi vào trang, `dispose()` khi rời. **KHÔNG** tải lại sau mỗi
nước đi — AdMob tự refresh ~60s, tự làm thêm bị tính là invalid traffic.

**AdConfig**: thêm test id của Google (`ca-app-pub-3940256099942544/6300978111`
cho Android, `/2934735716` cho iOS) + 2 unit id thật phải tự tạo trên AdMob →
ghi vào `SETUP.md` §1 cạnh phần rewarded. Dùng **anchored adaptive banner**
(`AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize`), không dùng banner
320×50 cứng.

**Nói thẳng về doanh thu**: banner eCPM ở VN/SEA rất thấp. Với lượng người chơi
hiện tại (analytics mới có 2 device, gần như toàn máy dev) thì thu nhập thực tế
≈ 0, trong khi rủi ro tự bấm lúc test là có thật → **bắt buộc** thêm máy mình vào
`--dart-define=ADMOB_TEST_DEVICES=...` (cơ chế đã có). Banner đáng làm như hạ
tầng sẵn sàng cho lúc có người chơi, không phải như nguồn thu ngay.

**Đáng cân nhắc thêm (không thay banner)**: rewarded interstitial "xem QC để
thêm 5 nước / chơi lại màn" — eCPM cao hơn banner nhiều lần và hợp ngữ cảnh
match-3, dùng lại `AdService.showRewardedAd()` đã có. Nếu muốn thì đây là thứ
thực sự ra tiền, banner chỉ là nền.

## 7. Tái dùng widget bàn cờ (không viết cái thứ hai)

`ArenaMatch3Panel` đang nhận `ArenaInMatch`, nhưng chỉ đụng 5 thứ:
`boardCells`, `frames`, `moveId`, `stuck`, và `remaining <= 0` (khoá bàn).

→ Rút thành value class nhỏ:

```dart
class Match3View {
  final List<int> cells;
  final List<List<int>> frames;
  final int moveId;
  final bool stuck;
  final bool finished;   // thay cho remaining <= 0
}
```

Đấu Trường dựng `Match3View` từ `ArenaInMatch`; chơi đơn dựng từ controller mới.
Sửa cơ học ~20 dòng, 1 chỗ gọi.

## 8. Controller chơi đơn

`Match3LevelController` (Riverpod `autoDispose`), thuần cục bộ **không gọi mạng**
(khác hẳn `ArenaController`): giữ `board`, `movesLeft`, `score`, `frames`,
`moveId`, `stuck`. Kết thúc màn gọi `GameController.grantMatch3Reward(level, stars)`
— nơi duy nhất mutate `GameState` (giữ đúng quy ước `simulation.dart`).

## 9. Test khoá cái gì

| Test | Bắt lỗi gì |
|---|---|
| sao theo điểm, biên đúng bằng `target` | lệch mốc 1★/2★/3★ |
| mở khoá tuần tự | nhảy màn |
| **chơi lại màn đã 3★ → thưởng = 0** | lỗ hổng farm ở §5 |
| xáo khi hết nước → bàn mới có ≥1 nước | kẹt cứng màn chơi |
| cùng `id` → cùng bàn | seed không tất định |
| `_BottomBar` 5 mục ở 320px, cả 6 ngôn ngữ | tràn nhãn (§1) |

Không test được: banner (cần SDK thật) — kiểm bằng mắt trên máy thật với test id.

## 10. Cố ý HOÃN

- **Loại mục tiêu thứ 2** ("thu thập N ô 🍓"): cần thêm field `cleared` vào
  `Match3Move` — thêm field là an toàn (không đổi điểm ⇒ SQL không đổi). Đây là
  cách chữa cái nhàm ở §2, làm khi 60 màn một kiểu bắt đầu chán.
- **Kẹo đặc biệt (gộp 4/5 ô)**: đổi luật ⇒ phải sửa cả `arena_m3_replay` + vector
  vàng. Đắt gấp đôi, để sau.
- Mua thêm nước bằng 💎 (sink 💎 tốt, nhưng cân bằng riêng).
- Bảng xếp hạng điểm từng màn (bàn tất định nên so sánh được — nhưng lại cần
  chống gian lận server như Đấu Trường).
- Bản đồ/cây màn chơi có art; Phase 1 chỉ là lưới nút.

## 11. Thứ tự làm — mỗi bước chạy được và verify được

1. Rút `Match3View` + `Match3Board.reshuffle()` → **verify**: test Đấu Trường cũ
   xanh + test mới "hết nước thì xáo". (Đấu Trường VẪN kẹt như cũ — xem §3.)
2. `Match3Level` + controller + trang danh sách + trang chơi + tab thứ 5 →
   **verify**: chơi xong màn 1-3 trên máy ảo, test tràn nav bar.
3. Lưu `m3Stars` + thưởng chống farm → **verify**: test chơi lại không thưởng.
4. `BannerAdBox` + AdConfig + SETUP.md + tôn trọng `adFree` → **verify**: chạy
   máy thật với test id, banner không đè bàn cờ, bật VIP thì banner biến mất.

Ước lượng: bước 1-3 là phần lớn công việc; bước 4 nhỏ nhưng nhiều thao tác
console AdMob.
