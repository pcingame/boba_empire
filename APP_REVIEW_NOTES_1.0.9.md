# App Review — Notes for Reviewer, bản 1.0.9 (23)

Dán vào **App Store Connect → phiên bản 1.0.9 → App Review Information → Notes** (tiếng Anh).
Giữ đoạn "GENERAL" của các lần trước; PHẦN THÊM là "WHAT'S NEW IN 1.0.9" bên dưới. Đoạn "Sign-in" đã
sửa lại vì bản này **mua bằng tiền thật cần liên kết email** — xem "Ghi chú nội bộ" (rủi ro bị hỏi).

---

```
GENERAL (updated)
Boba Empire is an idle/tycoon game: tap to brew, buy upgrades, earn coins even
while offline. The whole game can be played WITHOUT signing in. Rewarded ads are
always optional. In-app purchases are virtual items only (gems, ad removal,
income boosts, cosmetic storage). The lucky wheel is not sold for real money.

EMAIL LINK (new rule, only for real-money purchases)
Before a real-money purchase the player is asked once to link an email (Settings
> Cloud save, or the prompt shown when tapping a purchase). We send a 6-digit
code to that email (Supabase Auth, sent from our domain via Resend). This ties
purchases to an account so gems/VIP survive a device change or reinstall.
- Gameplay, leaderboards, the Market and Restore Purchases do NOT require it.
- The code email can land in the SPAM / Junk folder - please check there. It
  expires after a few minutes; "Resend code" is available after 60 seconds.
- If you cannot receive the email, please reply in App Store Connect and we will
  respond immediately, or use the redeem code below to evaluate IAP-related
  features without paying.
Redeem code (Settings > Redeem code): REVIEWER2026 (gems + ad removal + VIP).

WHAT'S NEW IN 1.0.9

1) VIP system (Gem shop > "Top-up rewards & VIP")
   VIP EXP is earned from purchases (about 100 EXP per USD) or bought with gems
   up to a lifetime cap (roughly VIP 6; higher levels need purchases). 10 VIP levels give virtual perks only: a small income bonus,
   daily/weekly/monthly gem gifts, a name tag/frame on leaderboards, a VIP
   leaderboard, and a "VIP Shop" that spends a virtual VIP currency on in-game items. Nothing
   has real-world value; no cash-out.
   First-purchase bonus: the first purchase of each gem pack gives 2x gems, once per pack.

2) New in-app purchases (4)
   boba_gems_huge (consumable, 14.99 USD) and boba_gems_mega (consumable, 19.99
   USD): fixed amounts of gems. boba_cold_storage (non-consumable, 2.99 USD): a
   permanent bigger offline storage. boba_combo_noads_x2 (non-consumable, 5.99
   USD): ad removal + permanent 2x income. There is no randomized paid item.
   Restore Purchases is in the Gem shop.

3) Guilds (Home > Compete hub > Guild)
   Join or create a guild (creation costs gems; some guilds require approval).
   Weekly guild Boss and gem gifts between members (virtual). Members can chat.
   User-generated text safeguards (guideline 1.2): a server-side banned-word
   filter on guild names/tags and chat, a rate limit (3 messages / 10 seconds),
   a Report button on every message and on guilds (a guild reported by 3+
   different players is hidden from the list), and owner/officers can delete
   messages and remove members. Chat is visible to guild members only.

4) Weekly quests, streak bonuses, "Today's Deal"
   Weekly quests (open the Quests dialog > "Weekly quests") with a reward chest; extra gems at
   daily-streak milestones; a daily discounted offer of in-game items paid with
   in-game currency.

5) Player profiles and web links
   Tapping a leaderboard row shows that player's ranks (nickname + numbers only).
   "View on web" and Settings > Website open bobaempiregame.com (information
   pages: guide and public leaderboards) in the browser. The website does not
   sell anything and does not link to any payment.

6) Invite friends (Home > "Earn more" gift dialog > Invite)
   A code that rewards both players with gems when a friend joins. No contacts
   access; shared through the standard iOS share sheet.

HOW TO SEE THE NEW FEATURES QUICKLY
- Settings > Redeem code > REVIEWER2026 (gives gems + VIP).
- Gem shop > "Top-up rewards & VIP": VIP levels, perks, VIP Shop.
- Quests dialog > "Weekly quests".
- Compete hub > any leaderboard: tap a row for the profile.

CONTACT: phuongtdoan2008@gmail.com
```

---

## Ghi chú nội bộ (không dán)

- **Rủi ro bị hỏi nhiều nhất:** mua tiền thật yêu cầu liên kết email (OTP). Apple 5.1.1(v) cấm bắt đăng
  nhập cho tính năng không gắn tài khoản; ta lập luận được vì mua hàng cần tài khoản để khôi phục, và
  game/Restore không bị chặn. Nhưng reviewer phải NHẬN được email OTP mới thử được IAP. Nếu bị
  "Information Needed", cách chắc nhất: cho reviewer một hộp thư thử (tạo Gmail riêng, điền vào ô
  Sign-in của App Review Information, tạm tắt 2FA) hoặc thêm đường vòng cho mã `REVIEWER2026` (hiện mã
  này chỉ tặng 💎/VIP, KHÔNG bỏ qua cổng email — `lib/ui/email_gate.dart`).
- Email OTP gửi qua Resend (xem memory `cloud-save-smtp-configured`); nhớ domain gửi còn hoạt động
  trước khi nộp.
- Chat hội/tên hội là UGC → đã có lọc từ cấm, báo cáo, xoá tin, ẩn hội ≥3 báo cáo (guild_schema.sql).
  Chưa có "chặn người dùng" riêng — nếu Apple đòi 1.2 đầy đủ thì phải thêm.
- Phải tạo đủ 4 IAP mới trên ASC và chọn chúng ở mục In-App Purchases của phiên bản 1.0.9.
- Thẻ force update giữ nguyên `[:mav: 1.0.6]` ở mọi ngôn ngữ mô tả.
