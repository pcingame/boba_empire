/// Lời kể cho 8 chương cốt truyện + text sự kiện đối thủ.
///
/// KHÔNG dùng ARB: prose dài, và giữ ở đây cho dễ biên tập. `vi` + `en` viết đủ;
/// các locale khác (es/id/pt/th) tạm fallback sang `en` — dịch sau.
library;

import 'rival.dart';

class StoryText {
  const StoryText({
    required this.speaker,
    required this.title,
    required this.body,
    this.optionA,
    this.optionADesc,
    this.optionB,
    this.optionBDesc,
  });

  final String speaker;
  final String title;
  final String body;

  /// Chỉ có ở chương lựa chọn (Chương 6 & 8).
  final String? optionA;
  final String? optionADesc;
  final String? optionB;
  final String? optionBDesc;
}

/// Lời kể cho chương [id] theo [locale] (fallback `en`).
StoryText storyText(int id, String locale) =>
    _chapters[id]![locale] ?? _chapters[id]!['en']!;

const Map<int, Map<String, StoryText>> _chapters = {
  1: {
    'vi': StoryText(
      speaker: 'Bà Tư',
      title: 'Chiếc xe đẩy',
      body: 'Bà Tư đẩy chiếc xe trà cũ về phía con. "Tay nghề pha trà của bà, '
          'nay bà trao lại. Đừng làm nó mất tiếng." Con nắm lấy càng xe, mùi '
          'trà đen còn ấm.',
    ),
    'en': StoryText(
      speaker: 'Grandma Tư',
      title: 'The Cart',
      body: 'Grandma Tư pushes the old tea cart toward you. "My hands are '
          'tired, but the recipes are yours now. Don\'t let the name down." '
          'You take the handle; the black tea is still warm.',
    ),
  },
  2: {
    'vi': StoryText(
      speaker: 'Bạn',
      title: 'Cái kiosk đầu tiên',
      body: 'Đủ tiền thuê một góc kiosk có mái che. Không còn dầm mưa nữa. '
          'Con dán tấm bảng "Trà sữa Nhà Bà Tư" lên vách — nhỏ thôi, nhưng là '
          'của mình.',
    ),
    'en': StoryText(
      speaker: 'You',
      title: 'First Kiosk',
      body: 'Enough saved to rent a covered corner. No more standing in the '
          'rain. You tape up a sign — "Grandma Tư\'s Boba" — small, but yours.',
    ),
  },
  3: {
    'vi': StoryText(
      speaker: 'Hải "Trân Châu"',
      title: 'Người hàng xóm mới',
      body: 'Một chuỗi bóng loáng mở ngay đối diện. Ông chủ Hải cười xã giao: '
          '"Quán nhỏ dễ thương đấy. Ở khu này, dễ thương không sống lâu đâu." '
          'Rồi quay đi.',
    ),
    'en': StoryText(
      speaker: 'Hải "Boba"',
      title: 'The New Neighbor',
      body: 'A glossy chain opens right across the street. Its owner, Hải, '
          'smiles thinly: "Cute little shop. Around here, cute doesn\'t last." '
          'Then he walks off.',
    ),
  },
  4: {
    'vi': StoryText(
      speaker: 'Bà Tư',
      title: 'Nhượng quyền',
      body: '"Con muốn lớn thì phải buông bớt," bà nói qua điện thoại. "Dạy '
          'người khác công thức, chia cho họ cái bảng hiệu. Con mất chi nhánh '
          'này, nhưng được cả trăm chi nhánh khác." Con hít một hơi, ký tên.',
    ),
    'en': StoryText(
      speaker: 'Grandma Tư',
      title: 'Franchise',
      body: '"To grow, you have to let go," she says on the phone. "Teach the '
          'recipe, lend the name. You lose this branch, you gain a hundred." '
          'You breathe in, and sign.',
    ),
  },
  5: {
    'vi': StoryText(
      speaker: 'Hải "Trân Châu"',
      title: 'Ép giá',
      body: 'Hải hạ giá toàn chuỗi xuống dưới vốn, treo băng-rôn đỏ rực khắp '
          'phố. "Xem ai trụ được lâu hơn." Nhân viên con bắt đầu hỏi về lương.',
    ),
    'en': StoryText(
      speaker: 'Hải "Boba"',
      title: 'Price War',
      body: 'Hải drops every store below cost and hangs blood-red banners down '
          'the block. "Let\'s see who lasts." Your staff start asking about '
          'their pay.',
    ),
  },
  6: {
    'vi': StoryText(
      speaker: 'Bạn',
      title: 'Ngã ba đường',
      body: 'Không thể vừa rẻ vừa tinh. Con phải chọn một con đường — và đi tới '
          'cùng.',
      optionA: 'Giữ nghề thủ công',
      optionADesc: 'Mỗi ly pha tay, chất lượng là thương hiệu. '
          '+8% giá trị mỗi lần chạm, vĩnh viễn.',
      optionB: 'Mở rộng thần tốc',
      optionBDesc: 'Dây chuyền, nhượng quyền ồ ạt, phủ khắp nơi. '
          '+8% thu nhập tự động, vĩnh viễn.',
    ),
    'en': StoryText(
      speaker: 'You',
      title: 'A Fork in the Road',
      body: 'You can\'t be both the cheapest and the finest. Pick a path — and '
          'commit.',
      optionA: 'Stay Handcrafted',
      optionADesc: 'Every cup made by hand; quality is the brand. '
          '+8% tap value, permanent.',
      optionB: 'Scale Fast',
      optionBDesc: 'Assembly lines, aggressive franchising, everywhere at '
          'once. +8% idle income, permanent.',
    ),
  },
  7: {
    'vi': StoryText(
      speaker: 'Bà Tư',
      title: 'Đế chế',
      body: 'Bảng hiệu Nhà Bà Tư sáng đèn ở sân bay, ở quảng trường nước ngoài. '
          'Bà xem tin trên tivi, lặng lẽ. "Bà không ngờ tới đây được." Còn Hải '
          'thì đã im tiếng mấy tháng nay.',
    ),
    'en': StoryText(
      speaker: 'Grandma Tư',
      title: 'Empire',
      body: 'The Grandma Tư sign glows in airports, in foreign plazas. She '
          'watches the news, quiet. "I never imagined this far." And Hải has '
          'been silent for months.',
    ),
  },
  8: {
    'vi': StoryText(
      speaker: 'Hải "Trân Châu"',
      title: 'Lời đề nghị cuối',
      body: 'Hải ngồi đối diện, không còn cười. "Chuỗi của tôi hết trụ nổi. '
          'Anh thắng rồi." Ông đẩy tập hồ sơ qua bàn. Tùy con quyết.',
      optionA: 'Thâu tóm đối thủ',
      optionADesc: 'Nuốt luôn chuỗi của Hải, gộp vào đế chế. '
          '+8% thu nhập tự động, vĩnh viễn.',
      optionB: 'Giữ bản sắc',
      optionBDesc: 'Để Hải rút lui trong danh dự; con giữ cái hồn quán nhỏ. '
          '+8% giá trị mỗi lần chạm, vĩnh viễn.',
    ),
    'en': StoryText(
      speaker: 'Hải "Boba"',
      title: 'The Last Offer',
      body: 'Hải sits across from you, no smile left. "My chain can\'t hold on. '
          'You won." He slides a folder across the table. Your call.',
      optionA: 'Acquire the Rival',
      optionADesc: 'Swallow Hải\'s chain whole, fold it into the empire. '
          '+8% idle income, permanent.',
      optionB: 'Keep Your Soul',
      optionBDesc: 'Let Hải retire with dignity; you keep the small-shop '
          'spirit. +8% tap value, permanent.',
    ),
  },
};

// --- Sự kiện đối thủ ---

class RivalEventText {
  const RivalEventText({
    required this.title,
    required this.body,
    required this.optionA,
    required this.optionB,
  });

  final String title;
  final String body;

  /// Nhãn lựa chọn 0 ("chắc tay", trả Xu) và 1 ("phản công", trả 💎).
  final String optionA;
  final String optionB;
}

RivalEventText rivalEventText(RivalEventType type, String locale) =>
    _events[type]![locale] ?? _events[type]!['en']!;

const Map<RivalEventType, Map<String, RivalEventText>> _events = {
  RivalEventType.priceWar: {
    'vi': RivalEventText(
      title: 'Đối thủ hạ giá sốc',
      body: 'Hải treo bảng "Mua 1 tặng 1" cả tuần. Khách xếp hàng bên đó.',
      optionA: 'Hạ giá giữ khách',
      optionB: 'Tung khuyến mãi lớn hơn',
    ),
    'en': RivalEventText(
      title: 'Rival Slashes Prices',
      body: 'Hải runs "buy one, get one" all week. The queue forms over there.',
      optionA: 'Match the price cut',
      optionB: 'Out-promote them',
    ),
  },
  RivalEventType.poachStaff: {
    'vi': RivalEventText(
      title: 'Đối thủ giành người',
      body: 'Hải mời hai thợ pha giỏi nhất của con sang, lương gấp rưỡi.',
      optionA: 'Tăng lương giữ người',
      optionB: 'Thuê thợ đầu bếp ngôi sao',
    ),
    'en': RivalEventText(
      title: 'Rival Poaches Staff',
      body: 'Hải offers your two best baristas a 50% raise to jump ship.',
      optionA: 'Raise pay to keep them',
      optionB: 'Hire a star mixologist',
    ),
  },
  RivalEventType.smearCampaign: {
    'vi': RivalEventText(
      title: 'Tin đồn xấu',
      body: 'Bài viết ẩn danh nói trà của con "kém vệ sinh". Lan nhanh.',
      optionA: 'Cải chính công khai',
      optionB: 'Thuê KOL phản công',
    ),
    'en': RivalEventText(
      title: 'Smear Campaign',
      body: 'An anonymous post calls your tea "unhygienic." It spreads fast.',
      optionA: 'Issue a public rebuttal',
      optionB: 'Hire influencers to hit back',
    ),
  },
};
