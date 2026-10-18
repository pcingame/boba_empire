# App Review — Notes for Reviewer, bản 1.0.11 (25)

Dán vào **App Store Connect → phiên bản 1.0.11 → App Review Information → Notes** (tiếng Anh).
Giữ nguyên phần GENERAL / EMAIL LINK của `APP_REVIEW_NOTES_1.0.10.md`, thêm đoạn dưới. Đổi lớn: **ảnh đại diện do người chơi tải lên** (nội dung người dùng tạo) — nêu rõ cơ chế báo cáo/ẩn. Không có IAP mới.

---

```
WHAT'S NEW IN 1.0.11 (in addition to the notes of 1.0.10)

1) Season Pass: a 28-day pass with 30 tiers, filled by playing (daily XP cap).
   A premium track can be unlocked with in-game gems. No real-money purchase.
   "Daily Item": one accessory per day, bought with gems. Top players of the
   season leaderboard receive virtual gems once (only accounts with a linked
   email). Gems cannot be cashed out.

2) Guild Dungeon (weekly, 3 stages) and an animated Guild Boss; accessory loadouts
   and refining. All use in-game currency/items only.

3) Arena: new Recipe PK mode, "ghost" matches (the player plays a recorded
   match, not counted on leaderboards) and a weekly tournament with gem rewards.

4) USER-GENERATED CONTENT - profile photo (new)
   Settings > My profile > "Upload photo" lets a signed-in (email-linked) player
   choose a profile photo from their gallery (stored in Supabase Storage, one
   small image per player, size-limited, overwritten on re-upload). The photo is
   shown on the public profile and in guild/leaderboard lists.
   Moderation: any other player can tap "Report photo" on a profile. Three
   reports from different accounts hide the photo automatically (a default
   avatar is shown) until we review it; we remove abusive photos and can ban the
   account. A player can delete/replace their own photo at any time. Photos are
   never required - the default avatar is used otherwise.

5) UI simplification: Daily quests, Weekly quests and "Earn more" are merged into
   one tabbed screen; the leaderboards are merged into one screen. Social links
   (Facebook / TikTok / YouTube) were added to Settings.
```
