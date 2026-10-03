# Cách xử lý UI hay gặp (text, dialog, widget, hiệu năng, test)

Ghi lại các lỗi đã gặp và cách sửa đã dùng trong dự án. Mỗi mục có chỗ tham chiếu trong code.
Đọc trước khi thêm màn/hộp thoại/chuỗi mới.

## 1. Text

### 1.1 Chữ tràn (RenderFlex overflow)
Số lớn (tỷ Sao, Xu rất lớn) và chữ dịch dài (pt/id/es) là nguồn tràn chính.

| Tình huống | Cách xử lý | Ví dụ |
|---|---|---|
| Con của `Row` không bọc | Bọc `Expanded`/`Flexible` | `leaderboard_page.dart` |
| Số phải đọc đủ, không được "…" | `Flexible` + `FittedBox(fit: BoxFit.scaleDown)` | cột Sao/Xu ở bảng xếp hạng |
| Tên có thể dài, cắt được | `maxLines: 1` + `overflow: TextOverflow.ellipsis` | cột tên bảng xếp hạng |
| Ô lưới hẹp, cả cụm (emoji + tên + chip) | `FittedBox(scaleDown)` bọc cả `Column` | `_AccessoryCell` ở Kho |
| Chữ **phải đọc hết mà khung chật** (banner) | **Marquee** — mục 1.2 | banner Chợ ở màn chính |
| `Badge`/chip không giới hạn bề rộng nhãn | Bọc `ConstrainedBox`/`Flexible` | xem memory "shop tile overflow pattern" |

Kiểm tra: test máy hẹp + chữ to (`physicalSize 320x640`, `textScaleFactorTestValue 1.3`, đủ 6 ngôn ngữ),
mẫu ở `test/ui/accessory_inventory_page_test.dart` và `accessory_market_page_test.dart`.

### 1.2 Marquee (chữ chạy ngang)
`lib/ui/widgets/marquee_text.dart` — `MarqueeText(text, style: …)`.
- Vừa khung: hiện `Text` thường. Dài quá: trượt sang trái để lộ đuôi, đứng ~20% ở hai đầu, rồi quay lại
  (ping-pong, ~35 px/giây).
- **Dừng hẳn** khi bị hộp thoại/trang khác phủ lên (`ModalRoute.isCurrent`) hoặc khi hệ thống tắt
  animation (khi đó rơi về "…"). Không để animation chạy dưới lớp phủ.
- Bẫy đã dính: `OverflowBox` mặc định phình theo ràng buộc cha → trong `Column` (cao không giới hạn)
  báo "infinite size". Phải bọc `SizedBox(height: chiều cao 1 dòng)`.
- Bẫy test: đoạn đứng yên đầu dài cỡ 20% chu kỳ; chu kỳ phụ thuộc bề rộng chữ (font test Ahem rất
  rộng) → pump đủ lâu (≥ 12 s) mới thấy dịch chuyển.
- Bẫy test: marquee là animation vô hạn → màn có banner đang chạy chữ thì `pumpAndSettle` luôn hết giờ; dùng
  vài lần `pump(Duration)` thay thế.
- Chỉ áp dụng khi chữ **quan trọng và một dòng**. `SnackBar` và đoạn mô tả thì cho xuống dòng.

### 1.3 Chuỗi đa ngôn ngữ (l10n)
- Mỗi chuỗi mới phải có đủ **6 ngôn ngữ**: vi, en, es, id, pt, th (`lib/l10n/app_*.arb`), rồi `flutter gen-l10n`.
- **Chèn văn bản vào .arb**, đừng `json.dump` lại cả file — nó đổi định dạng hàng trăm dòng và làm diff vô nghĩa.
- Placeholder khai báo trong `@key` (`"placeholders": {"n": {"type": "int"}}`).
- Tên đồ vật qua `accessoryName(l10n, id)`, câu nhận đồ qua `accessoryRevealMessage` (`l10n_ext.dart`).
- Server (Edge Function) không có danh mục tên → thông báo đẩy dùng câu chung, không nêu tên món.

### 1.4 Id từ nơi khác (server/save/bản app mới hơn)
- **Không** gọi `accessoryById(id)` với id không tin cậy: nó ném `StateError`. Dùng
  `flairEmoji(id)` hoặc lọc `accessories.any(...)` trước (xem `market_highlight.dart`, `flair.dart`).
- JSON save: trường phụ sai kiểu phải **bị bỏ qua**, không ném. `GameStorage.load()` nuốt lỗi thành "ván mới" →
  một trường sai kiểu = mất cả save. Dùng `json['x'] == true`, `is List`, lọc phần tử (`models.dart`).

## 2. Hộp thoại, trang, thông báo

- **Sau mọi `await`**: `if (!mounted) return;` (State) hoặc `if (!context.mounted) return;`
  trước khi dùng `setState`/`context`/`ref`. Đã gây crash "dùng ref trên element đã dispose"
  (rewarded ad, nhận thưởng, huy hiệu). Mẫu: `_StarterPackCard._claim`, `_MilestoneStrip._claim`.
- `Future.microtask`/`addPostFrameCallback` gọi `ref.read` phải kiểm `context.mounted`/`mounted` ngay trong callback
  (`FlairBadge`).
- Lấy `ScaffoldMessenger.of(context)`/`AppLocalizations.of(context)` **trước** `await` rồi dùng biến đó.
- Nhận thưởng cần server: **server trước, cấp cục bộ sau**; lỗi mạng thì không cấp, vẫn bấm lại được;
  `already_claimed` thì đánh dấu cục bộ để ẩn nút. Khoá bấm đúp bằng `_busy` + kiểm trùng ở controller
  (`claimMarketStarter`, `claimCollectionMilestone`).
- Hộp thoại chỉ hiện một lần: cờ SharedPreferences (`marketIntroSeenKey`), đặt cờ **trước** khi `showDialog`.
  Test cũ phải seed cờ `true`, nếu không hộp chặn mọi thao tác chạm.
- Phản hồi nhận đồ làm **nội tuyến** (hàng trong hộp nhiệm vụ, dòng trong kết quả vòng quay), không thêm popup.
- Banner/chấm đỏ dùng chung một nguồn (`marketHighlightProvider`); mở trang tương ứng thì ghi `marketSeenKey`
  và `ref.invalidate`.

## 3. Widget & bố cục

- **`Stack` nới lỏng ràng buộc** → con co lại theo nội dung (ô Kho hẹp, lệch trái). Thêm
  `fit: StackFit.expand` khi con phải lấp đầy ô. Khi test: đo con (`Opacity`), không đo `Stack`
  (nó vẫn bằng ô lưới nên test không bắt được lỗi).
- **Trang có phần đầu + lưới**: dùng `CustomScrollView` (`SliverToBoxAdapter` + `SliverGrid`) để cả trang cuộn
  chung. `Column` + `Expanded(GridView)` tràn dọc khi máy nhỏ/chữ to hoặc khi thêm hàng vào phần đầu.
- Lưới: tắt `overscroll` (`ScrollConfiguration … copyWith(overscroll: false)`) — hiệu ứng kéo giãn của
  Android làm méo ô vuông.
- Huy hiệu/ghim chồng lên ô: `Positioned` trong `Stack`, thêm `ExcludeSemantics` cho emoji trang trí.
- Thêm nút vào hàng `trailing` của tile (ngôi sao ⭐ cạnh "Mua"): dùng `Row(mainAxisSize: min)` và chạy lại
  test màn hẹp + chữ 1.3x.
- Vòng đời `ref`: `ConsumerWidget` chỉ `watch` đúng thứ cần (`select`). Với danh sách, select **chuỗi/record**
  (`list.join(',')`) để so sánh theo giá trị — select thẳng `List` thì rebuild mỗi giây vì snapshot tạo list mới;
  ngược lại chia sẻ cùng instance `List` thì `select` không rebuild (xem memory "snapshot list aliasing").

## 4. Hiệu năng (Impeller)

- Tránh `Opacity` trên vùng lớn/trong danh sách (saveLayer). Dùng màu có alpha. Ô Kho khoá vẫn còn `Opacity(0.45)` —
  việc tối ưu còn dở.
- Tránh bóng mờ lớn, Lottie nhiều layer vector, `ClipRRect` trên từng hàng.
- Animation nền (`IdleMascot`, `MarqueeText`) phải dừng khi route không còn là route hiện tại
  (`ModalRoute.of(context).isCurrent`) và khi app ra nền.
- Đo bằng `integration_test/perf_test.dart` (xem ghi chú đầu file): dùng raster avg/p99, **không** tin số khung
  hình trong harness (nó làm phồng số khung với animation theo Timer).

## 5. Test

- `ProviderScope`/`ProviderContainer` override `sharedPreferencesProvider`, `clockProvider`. `GameController` có
  Timer 1 giây → **`container.dispose()` ngay trong thân test** (tearDown chạy sau khi flutter_test đã kiểm timer treo).
- `SupabaseClient(...)` mở timer định kỳ: tạo trong `setUpAll` (ngoài FakeAsync), không tạo trong `testWidgets`
  (xem `test/ui/realtime_collection_test.dart`). Controller dùng `debugMarketRepo = FakeRepo()` để giả server.
- Mở Cài đặt cần `cloudSaveControllerProvider` giả. `debugDisableMascotAnimation = true` trong test.
- Gỡ widget giữa chừng (`await tester.pumpWidget(const SizedBox())`) rồi `pump` tiếp để bắt crash "dùng sau dispose".
- Test dùng ngẫu nhiên (vòng quay 6% ô rương) phải chấp nhận **mọi** nhánh kết quả, không thì chập chờn.
- Test lỗi UI nên chứng minh được là **bắt được lỗi**: tạm đảo lại bản sửa và xem test hỏng.
- `flutter test` toàn bộ + `flutter analyze` trước khi commit. **Không** chạy `dart format` lên file cũ chưa
  được format (đổi hàng trăm dòng); chỉ format file mới.

## 6. Cài lên máy thật

- iPhone: `flutter run --release -d <id> --no-resident`.
- Android: dùng `adb install -r <apk>`. **Đừng** chạy `flutter run` lặp lại khi máy (Xiaomi) từ chối cài: Flutter có thể
  gỡ app rồi cài lại → **mất dữ liệu cục bộ** của máy thử. Máy Xiaomi hiện hộp xác nhận cài qua USB; phải bấm Cài đặt.
- Xem UI thoáng qua: quay màn hình/chụp nhiều khung liên tiếp rồi so sánh (memory "verify UI bugs with video"),
  đừng kết luận từ một ảnh chụp.
- Xem thử dữ liệu giả: dùng `--dart-define=FLAG=true` cho bản build tạm, **không commit** cờ đó.
