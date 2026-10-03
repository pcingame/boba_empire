# App Review — Notes for Reviewer, bản 1.0.6 (13)

Dán vào **App Store Connect → phiên bản 1.0.6 → App Review Information → Notes**
(tiếng Anh, vì reviewer đọc tiếng Anh). Giữ nguyên đoạn "General" đã dùng ở các lần
nộp trước (Apple đã yêu cầu lưu ở Notes cho các lần sau — xem IOS_APP_STORE_CHECKLIST.md);
phần "What's new in 1.0.6" dưới đây là PHẦN THÊM.

---

```
GENERAL (unchanged from previous versions)
Boba Empire is an idle/tycoon game: tap to brew, buy upgrades, earn coins even
while offline. No sign-in is required. Rewarded ads are always optional (the
player chooses to watch). In-app purchases are virtual items only; the lucky wheel
is not sold for real money.

WHAT'S NEW IN 1.0.6

1) Accessory Collection (home screen > "Collection" button)
   50 cosmetic accessories (emoji items) that are collected through gameplay only:
   daily-quest bonus, lucky-wheel chest slot, Ascension, and Falling Pearls
   (match-3) milestones. They are purely decorative: they can be shown around the
   tea cup and as a badge next to the player's name on leaderboards. They give no
   gameplay advantage. There is no paid randomized purchase of accessories.

2) Accessory Market (Collection > shop icon in the top bar)
   Players can trade spare accessories with each other using "Market Coins", a
   virtual in-game currency. Market Coins can only be obtained by converting
   in-game coins or gems; they cannot be bought directly with real money, cannot
   be converted back, and cannot be withdrawn or exchanged for real money or goods.
   There is no real-money trading. Prices are numbers only (no free-text input, no
   chat or messaging between players), so there is no user-generated text content.
   A 1% market fee applies (0% on weekends).

3) Anonymous account
   The market and leaderboards use an anonymous server session created
   automatically (Supabase anonymous auth). No personal information, email or
   phone is collected for this. Nothing needs to be entered by the reviewer.

4) Optional push notifications
   The permission prompt only appears when the player lists an item for sale or
   adds an item to their wishlist ("your item sold" / "a wishlist item was
   listed"). It can be declined; the game works the same.

5) Sharing
   The collection card can be shared as an image through the standard iOS share
   sheet, or copied as text.

6) Other
   Story Act 3 (8 new chapters), refreshed pastel visual style, a one-time
   "What's new" dialog after updating, and a weekend event (0% market fee, higher
   chance of rare accessory drops).

HOW TO SEE THE NEW FEATURES QUICKLY
- Home > "Collection": the 50-slot grid, milestone rewards (10/25/40/50 items).
- Collection > shop icon: the Market. Browsing and buying need an internet
  connection. To obtain a few Market Coins: Market > the "+" next to the balance
  converts in-game gems to Market Coins.
- Accessories drop from: Quests > complete all three daily quests > claim the
  bonus; or the lucky wheel (6% chest slot).

UPDATE PROMPT
The app already shows an update prompt (the "upgrader" library) based on the App
Store listing. The marker line "[:mav: 1.0.6]" at the end of the App Store
description is a technical tag read by that library, to ask users on very old
versions to update. It does not change app behavior for reviewers.

CONTACT: phuongtdoan2008@gmail.com
```

---

## Ghi chú nội bộ (không dán)

- **Thẻ force update** `[:mav: 1.0.6]` phải nằm ở MỌI ngôn ngữ mô tả — xem `RELEASE_NOTES.md`.
- **Loot box / tỉ lệ rớt:** Apple (guideline 3.1.1) buộc công bố tỉ lệ cho vật phẩm ngẫu nhiên
  **mua bằng tiền thật**. Phụ kiện KHÔNG bán bằng tiền thật, nên ghi chú trên khẳng định rõ điều
  đó. Nhưng 💎 mua bằng tiền thật CÓ thể đổi sang Xu Chợ để mua phụ kiện từ người chơi khác —
  ghi chú đã nêu Xu Chợ chỉ có từ việc quy đổi, một chiều, không rút ra. Nếu Apple hỏi thêm, trả lời
  theo hướng "mua đồ cố định đã niêm yết từ người chơi khác, không phải hộp ngẫu nhiên".
  Không có hiển thị tỉ lệ rớt trong app (chưa có nhu cầu bắt buộc, nhưng có thể thêm nếu bị yêu cầu).
- **Mã reviewer:** `REVIEWER2026` (xem `lib/core/redeem.dart`) tặng 💎 + gỡ QC + VIP — không cần cho Apple,
  chỉ nhắc nếu reviewer muốn thử IAP.
- Các cảnh báo cũ cần giữ: "Information Needed" luôn kèm video quay thiết bị thật nếu Apple yêu cầu lại.
