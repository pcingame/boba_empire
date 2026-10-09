/// Xu Hội: ví cá nhân kiếm bằng nạp 💎 hoặc nhiệm vụ hội hàng tuần, đổi lấy phụ kiện
/// độc quyền của hội + buff thu nhập cả hội. Server là nơi giữ ví và quyết định
/// (supabase/guild_schema.sql) — các hằng số dưới đây PHẢI khớp (test
/// test/guild/guild_sql_test.dart so khớp).
library;

import 'accessories.dart';

/// 1 💎 nạp = [guildCoinsPerGem] Xu Hội, tối đa [guildDonateDailyCap] 💎/ngày/người.
const int guildCoinsPerGem = 1;
const int guildDonateDailyCap = 1000;

/// Số 💎 gợi ý trên các nút nạp nhanh.
const List<int> guildDonateChoices = [10, 50, 100, 500];

class GuildQuest {
  const GuildQuest(this.need, this.reward);

  /// Điểm đóng góp CÁ NHÂN trong tuần cần đạt.
  final int need;
  final int reward;
}

/// Chỉ số 0-based = `p_tier - 1` ở server.
const List<GuildQuest> guildQuests = [
  GuildQuest(1000, 100),
  GuildQuest(5000, 200),
  GuildQuest(20000, 400),
];

class GuildShopItem {
  const GuildShopItem(this.accessory, this.price);
  final Accessory accessory;
  final int price;
  String get id => accessory.id;
}

/// Phụ kiện độc quyền của hội: cosmetic thuần, lưu ở [GameState.ownedLimited] (như
/// phụ kiện lễ hội) — không vào bộ sưu tập chính/Chợ/BXH. Id có tiền tố `guild_`.
const List<GuildShopItem> guildShopItems = [
  GuildShopItem(Accessory('guild_flag', AccessoryRarity.rare, '🚩'), 500),
  GuildShopItem(Accessory('guild_castle', AccessoryRarity.epic, '🏯'), 1500),
  GuildShopItem(Accessory('guild_wolf', AccessoryRarity.epic, '🐺'), 1500),
  GuildShopItem(Accessory('guild_dragon', AccessoryRarity.legendary, '🐲'), 4000),
  GuildShopItem(Accessory('guild_fox', AccessoryRarity.rare, '🦊'), 800),
  GuildShopItem(Accessory('guild_tiger', AccessoryRarity.rare, '🐯'), 1000),
  GuildShopItem(Accessory('guild_shark', AccessoryRarity.epic, '🦈'), 2500),
  GuildShopItem(Accessory('guild_trex', AccessoryRarity.legendary, '🦖'), 6000),
  GuildShopItem(Accessory('guild_boar', AccessoryRarity.rare, '🐗'), 600),
  GuildShopItem(Accessory('guild_bear', AccessoryRarity.rare, '🐻'), 1200),
  GuildShopItem(Accessory('guild_scorpion', AccessoryRarity.epic, '🦂'), 2000),
  GuildShopItem(Accessory('guild_moai', AccessoryRarity.epic, '🗿'), 3000),
];

List<Accessory> get guildAccessories => [
      for (final i in guildShopItems) i.accessory,
    ];

/// Buff thu nhập cả hội (hệ số ở [Balance.guildBuffMult]).
const int guildBuffPrice = 800;
const int guildBuffHours = 24;
const int guildBuffMaxHours = 48;
