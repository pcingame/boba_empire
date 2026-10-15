# App Review — Notes for Reviewer, bản 1.0.10 (24)

Dán vào **App Store Connect → phiên bản 1.0.10 → App Review Information → Notes** (tiếng Anh).
Đổi lớn so với 1.0.9: **tính năng online (bảng xếp hạng, Chợ, Hội, Đấu Trường) giờ đòi liên kết email** —
phần "EMAIL LINK" bên dưới đã viết lại. Không có IAP mới.

---

```
GENERAL (updated)
Boba Empire is an idle/tycoon game: tap to brew, buy upgrades, earn coins even
while offline, and play several mini-games. The whole single-player game can be
played WITHOUT signing in. Rewarded ads are always optional. In-app purchases
are virtual items only (gems, ad removal, income boosts, cosmetic storage). The
lucky wheel is not sold for real money.

EMAIL LINK (updated rule)
An email-linked account is needed for (a) real-money purchases and (b) the
online/social features: leaderboards, the player Market, Guilds and the Arena.
Everything else - the idle game, story, all mini-games, offline earnings, daily
rewards - works without any account. When a player opens an online feature or
tries to buy, we ask once to link an email (Settings > Cloud save, or the prompt
shown at that point). We send a 6-digit code to that email (Supabase Auth, sent
from our domain via Resend). Reasons: purchases and social data survive a device
change/reinstall, and leaderboards/Market/Guilds are protected from fake or
throw-away accounts (cheating, spam, user-generated content moderation).
- Restore Purchases does NOT require it.
- The code email can land in the SPAM / Junk folder - please check there. It
  expires after a few minutes; "Resend code" is available after 60 seconds.
- If you cannot receive the email, please reply in App Store Connect and we will
  respond immediately, or use the redeem code below to evaluate IAP-related
  features without paying.
Redeem code (Settings > Redeem code): REVIEWER2026 (gems + ad removal + VIP).

WHAT'S NEW IN 1.0.10

1) New mini-games (Home > bottom bar "Games")
   - Recipe game: learn 100 drink recipes with spaced review (short quizzes).
   - Brew by Order: drag/tap ingredients into a cup for a customer's order,
     choose amounts, serve and get graded. Optional "Rush Hour" timer. During a
     holiday an extra festival order appears.
   - Daily Challenge: three fixed orders per day, one attempt per day.
   - Each mini-game has a "How to play" guide (the ? button; shown once at first
     use). Rewards are in-game currency only. There is no gambling and nothing
     is sold for real money in these modes. Optional rewarded ads give a hint or
     double the in-game reward.

2) Story Act 4 (Chapters 37-46): each chapter unlocks after reaching a milestone
   in the mini-games. Story-only content, no purchase involved.

3) Weekly leaderboard rewards: the top players of each leaderboard receive
   virtual gems once a week (only accounts with a linked email). Gems cannot be
   cashed out.

4) Auto-tap (optional): watch a rewarded ad for 10 minutes of automatic taps
   (permanent perk for higher VIP levels). Market: players can swap accessories
   (virtual cosmetic items) with each other; no real money changes hands.

5) Guild quests and other quality improvements (layout fixes for large text).

HOW TO SEE THE NEW FEATURES QUICKLY
- Settings > Redeem code > REVIEWER2026 (gives gems + VIP).
- Home > "Games" > Brew by Order / Recipe game / Daily Challenge (tap ? for the
  guide).
- Compete hub > any leaderboard (asks to link an email once).

CONTACT: phuongtdoan2008@gmail.com
```

---

## Ghi chú nội bộ (không dán)

- **Rủi ro lớn nhất 1.0.10:** tính năng online đòi email (Apple 5.1.1(v)). Lập luận: game đơn chơi đủ không cần
  tài khoản; chỉ các tính năng THỰC SỰ gắn tài khoản (xếp hạng, Chợ, Hội, Đấu Trường) cần email, và có lý do
  (chống gian lận/UGC). Nếu reviewer không nhận được OTP thì không vào được các mục này — cho một hộp thư thử
  (Gmail riêng, điền vào ô Sign-in của App Review Information) là cách chắc nhất.
- Chat hội/tên hội là UGC → có lọc từ cấm, báo cáo, xoá tin, ẩn hội ≥3 báo cáo. Chưa có "chặn người dùng".
- Chưa có IAP mới ở bản này: không cần chọn gì ở mục In-App Purchases.
- Thẻ force update giữ nguyên `[:mav: 1.0.6]` ở mọi ngôn ngữ mô tả.
- Đối chiếu danh sách nội dung với bản 1.0.9 thực tế (xem RELEASE_NOTES.md) trước khi dán.
