# WEBSITE — landing page bobaempiregame.com

Ghi lại cách trang web hoạt động để sửa/mở rộng mà không phải đọc lại từ đầu.
Cập nhật lần cuối: 2026-10-04 (thêm hiệu ứng + tối ưu).

## Hạ tầng
- Host: **GitHub Pages**, nguồn là thư mục `docs/` của nhánh `main`. Push là tự cập nhật
  (thường vài phút). Domain trỏ qua `docs/CNAME` (`bobaempiregame.com`); chi tiết DNS/HTTPS ở
  `DOMAIN_TODO.md`, tự kiểm bằng `bash scripts/check_domain.sh`.
- **Không có bước build**: `docs/index.html` (CSS inline, không framework) + `docs/assets/site.js`
  (logic, `defer`) + `docs/assets/i18n/<lang>.js` (mỗi ngôn ngữ một file, chỉ tải ngôn ngữ đang dùng)
  + ảnh. Mở thẳng file trong trình duyệt là chạy được.
- Trang kèm: `docs/privacy-policy.html` (chính sách quyền riêng tư, có link quay lại trang chủ).
- ⚠️ Mọi file trong `docs/` đều **công khai**: đừng đặt ghi chú nội bộ/`.md` ở đây (file này
  nằm ở gốc repo vì lý do đó).

## Tính năng của trang
| Tính năng | Ở đâu | Ghi chú |
|---|---|---|
| Nút tải **App Store** (chính) + **Google Play "sắp có"** | hero và mục CTA | App Store id `6808940339`. Khi Android lên Play: đổi `<span class="btn soon">` thành `<a class="btn primary" href="…play.google.com/store/apps/details?id=com.pcingame.bobaempire">`, sửa câu FAQ `q4/a4` và `ctaLead` trong `i18n/<lang>.js` |
| **7 ngôn ngữ** vi / en / es / id / pt / th / ko | `docs/assets/i18n/<lang>.js` + `site.js` | Chọn bằng ô thả xuống; tự đoán theo `navigator.language`, nhớ trong `localStorage`; ép bằng `?lang=ko`. Đổi cả `<title>`/meta description. Thêm khoá mới = thêm vào CẢ 7 ngôn ngữ |
| Khung điện thoại + **ảnh chụp theo ngôn ngữ** | hero, mục "Xem game" | Ảnh ở `docs/assets/<lang>/*.webp`; `ko` dùng bộ `en` (chưa có ảnh store tiếng Hàn) |
| **12 thẻ tính năng**, dải số liệu (18 giai đoạn / 36 chương / 80+ phụ kiện / 7 ngôn ngữ) | `index.html` + `i18n/<lang>.js` (`f1t…f12d`, `st*`) | Số liệu phải khớp game — cập nhật khi đổi |
| **Bảng xếp hạng trực tiếp** (4 tab, top 20) | mục `#board` | Xem mục "Bảng xếp hạng" dưới đây |
| **Lịch sự kiện lễ** (7 dịp) tự gắn nhãn ĐANG DIỄN RA / SẮP TỚI theo ngày | mục `#events`, mảng `EVENTS` trong script | PHẢI khớp `festivals` trong `lib/core/accessories.dart` (đổi một nơi thì đổi cả hai) |
| FAQ 5 câu | `q1…q5`/`a1…a5` | |
| Sáng/tối tự động (`prefers-color-scheme`), responsive | CSS biến `:root` | Điểm vỡ 860px (hero) và 640px (lưới) |
| **Hiệu ứng** (đều tắt khi `prefers-reduced-motion`) | CSS ở cuối `<style>` + `site.js` | Hiện dần khi cuộn (`.reveal` → `.in`, IntersectionObserver); hero: tiêu đề vào lần lượt, 2 điện thoại bồng bềnh, trân châu bay; số liệu đếm lên; nút App Store sáng/lướt bóng; thẻ nhấc lên khi rê chuột; thanh trượt có mũi tên (desktop); bảng xếp hạng: khung chờ lấp lánh (skeleton) + dòng vào lần lượt; nav đổ bóng khi cuộn |
| **Tối ưu hiệu năng** | `<head>` + CSS | Script `defer` ngoài file (được cache); script head chọn ngôn ngữ sớm và tải từ điển + preload 2 ảnh hero song song; chỉ tải từ điển của ngôn ngữ cần; ảnh `webp` có `width/height` (không xô lệch), `loading=lazy` (trừ 2 ảnh hero có `fetchpriority=high`); `content-visibility:auto` cho các mục dưới màn hình đầu; API xếp hạng chỉ gọi khi cuộn gần tới; `dns-prefetch` Supabase |
| SEO / chia sẻ | `<head>` | `canonical`, Open Graph + Twitter card (`assets/og.jpg` 1200×630), **Smart App Banner** Safari (`apple-itunes-app`), JSON-LD `MobileApplication` |

## Bảng xếp hạng
Gọi trực tiếp REST của Supabase từ trình duyệt (CORS mở `*`), **chỉ khi người dùng cuộn tới
mục** (IntersectionObserver), cache 60 giây mỗi tab, hiển thị bằng `textContent` (tên người
chơi KHÔNG bao giờ được chèn dưới dạng HTML).

| Tab | Endpoint | Cột dùng |
|---|---|---|
| Thu nhập | `GET /rest/v1/leaderboard_entries?select=nickname,lifetime_earnings,stage&order=lifetime_earnings.desc&limit=20` | `lifetime_earnings`, `stage` |
| Trân Châu Rơi | `POST /rest/v1/rpc/m3_leaderboard_top` `{p_limit:20}` | `stars`, `levels_cleared` |
| Sưu tập | `rpc/accessory_leaderboard_top` | `owned_count` |
| Phá đảo (Hồi 1) | `rpc/story_speedrun_top` | `complete_seconds` |

- URL project + `sb_publishable_…` key được nhúng trong script. Đây là khoá **công khai theo
  thiết kế** (cũng nằm trong `lib/arena/arena_config.dart` và mọi bản app); bảng chỉ cho đọc
  qua RLS/RPC công khai. **Không bao giờ** đưa `service_role` key vào trang.
- Số lớn dùng đúng quy ước `lib/core/format.dart` (K, M, B, T, aa … zz); hàm `big()` trong
  script là bản JS của nó — đổi bảng hậu tố ở game thì đổi cả ở đây.
- Chưa có: Hồi 2/Hồi 3 (`story_speedrun2_top`, `story_speedrun3_top`) và bảng PK Đấu Trường.
- 🔒 **Quyền riêng tư:** biệt danh (do người chơi tự đặt) hiển thị công khai trên web, kể cả với
  người chưa cài game. Trong app chúng vốn đã công khai; nếu muốn, ghi thêm vào
  `privacy-policy.html`.

## Việc thường làm
- **Đổi chữ**: sửa `docs/assets/i18n/<lang>.js` (đủ 7 ngôn ngữ — khoá phải giống hệt nhau; kiểm
  nhanh bằng `node` đọc 7 file và so tập khoá). Chữ tiếng Việt trong `index.html` là bản tĩnh
  cho SEO/không JS, cũng phải sửa theo.
- **Thêm dịp lễ mới**: thêm vào `festivals` (Dart) + `EVENTS` (script) + tên trong `ev` của cả
  7 ngôn ngữ.
- **Thêm hiệu ứng mới**: thêm class `reveal` vào phần tử (kèm `style="--d:.1s"` để trễ). Chỉ dùng `transform`/`opacity`/`translate` để không gây reflow.
- **Làm mới ảnh** sau khi có ảnh store mới: `python3 scripts/make_web_assets.py` (cần Pillow;
  đọc `assets/store/screenshots_ios/6.9in`). Muốn ảnh tiếng Hàn: chụp bộ `ko`, thêm `ko` vào
  `LANGS` của script rồi bỏ dòng `lang === 'ko' ? 'en' : lang` trong `apply()`.
- **Thêm ngôn ngữ**: tạo `docs/assets/i18n/<lang>.js` (đủ khoá), thêm mã vào `NAMES` (site.js) và mảng `L` trong script ở `<head>`, thêm thư mục ảnh (hoặc ánh xạ về `en`).
- **Cập nhật số liệu game** (số giai đoạn/chương/phụ kiện): `i18n/<lang>.js` (`f*`, `st*`, `s2d`,
  `metaDesc`) **và** `JSON-LD`/`<meta>` tĩnh trong `index.html` (đang bản tiếng Việt).

## Kiểm thử cục bộ
- Mở thẳng `docs/index.html` (hoặc `python3 -m http.server -d docs`).
- Chụp thử bằng Chrome headless: cửa sổ nhỏ hơn ~500px bị Chrome ép rộng hơn nên bố cục mobile
  trông như "tràn". Để xem mobile đúng, nhúng trang vào `<iframe width="390">` rồi chụp.
- Chỉ ảnh `?lang=…` và bảng xếp hạng cần mạng; phần còn lại chạy offline.

## Chưa làm / ý tưởng
- Trang tiếng Hàn trên store (mô tả/ảnh) và ảnh store tiếng Hàn để dùng cho web.
- Bảng xếp hạng Hồi 2/3 và PK; chia sẻ link trực tiếp tới một tab (`#board?tab=…`).
- Nút Google Play thật khi bản Android lên store.
