/// Lời kể cho 36 chương cốt truyện + text sự kiện đối thủ.
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

  /// Chỉ có ở chương lựa chọn (Chương 6, 8, 13, 18, 23, 28).
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
  // --- Mở rộng thế giới (2026-09-12): sau "Đế chế toàn cầu", hồi truyện
  // IPO/tập đoàn đa ngành + đối thủ mới "Vy - Golden Orb". ---
  9: {
    'vi': StoryText(
      speaker: 'Cô Lan',
      title: 'Lên sàn',
      body: 'Cô Lan, chuyên viên ngân hàng đầu tư, đặt xấp hồ sơ IPO lên bàn. '
          '"Thị trường đang chờ cổ phiếu Nhà Bà Tư đấy." Con ký tên — từ hôm '
          'nay, mỗi tách trà đều có cổ đông dõi theo.',
    ),
    'en': StoryText(
      speaker: 'Lan',
      title: 'Going Public',
      body: 'Lan, an investment banker, sets the IPO papers on your desk. '
          '"The market\'s waiting for Grandma Tư\'s shares," she says. You '
          'sign — from today, every cup has shareholders watching.',
    ),
  },
  10: {
    'vi': StoryText(
      speaker: 'Bạn',
      title: 'Tập đoàn đa ngành',
      body: 'Vốn IPO đổ vào bất động sản, chuỗi cà phê, cả một hãng xe điện '
          'giao trà. Trà sữa giờ chỉ là viên gạch đầu tiên của một tòa tháp. '
          'Bà Tư nhìn biểu đồ cổ phiếu, lắc đầu cười: "Bà chỉ hiểu trà thôi, '
          'con à."',
    ),
    'en': StoryText(
      speaker: 'You',
      title: 'The Conglomerate',
      body: 'IPO capital flows into real estate, a coffee chain, even an '
          'electric delivery-bike startup. Boba is now just the first brick '
          'of a tower. Grandma Tư looks at the stock chart, laughing and '
          'shaking her head: "I only ever understood tea, child."',
    ),
  },
  11: {
    'vi': StoryText(
      speaker: 'Vy "Golden Orb"',
      title: 'Người mua tiềm năng',
      body: 'Một tập đoàn ngoại tên Golden Orb ngỏ ý mua cổ phần chi phối. '
          'Đại diện của họ, Vy, mỉm cười lịch thiệp: "Chúng tôi không muốn '
          'cạnh tranh. Chúng tôi muốn sở hữu." Cổ phiếu công ty con bắt đầu '
          'biến động lạ.',
    ),
    'en': StoryText(
      speaker: 'Vy "Golden Orb"',
      title: 'A Would-Be Buyer',
      body: 'A foreign conglomerate, Golden Orb, offers to buy a controlling '
          'stake. Their rep, Vy, smiles politely: "We don\'t want to '
          'compete. We want to own." Your stock starts moving strangely.',
    ),
  },
  12: {
    'vi': StoryText(
      speaker: 'Vy "Golden Orb"',
      title: 'Chiến tranh cổ phiếu',
      body: 'Golden Orb âm thầm gom cổ phiếu qua các quỹ bình phong. Một bài '
          'phân tích tài chính giấu tên nghi ngờ "dòng tiền bất thường" ở '
          'công ty con. Giá cổ phiếu rớt 12% trong một buổi sáng.',
    ),
    'en': StoryText(
      speaker: 'Vy "Golden Orb"',
      title: 'The Stock War',
      body: 'Golden Orb quietly buys shares through shell funds. An '
          'anonymous analyst report questions "unusual cash flow" at your '
          'company. The stock drops 12% in one morning.',
    ),
  },
  13: {
    'vi': StoryText(
      speaker: 'Bạn',
      title: 'Chống lại hay bắt tay',
      body: 'Golden Orb ra giá thâu tóm. Hội đồng quản trị chia phe. Con phải '
          'chọn: tự đứng vững một mình, hay bắt tay với chính đối thủ để lớn '
          'nhanh hơn.',
      optionA: 'Giữ độc lập',
      optionADesc: 'Mua lại cổ phiếu, giữ quyền kiểm soát trong tay gia đình. '
          '+8% giá trị mỗi lần chạm, vĩnh viễn.',
      optionB: 'Sáp nhập chiến lược',
      optionBDesc: 'Bắt tay với Golden Orb, đổi lấy vốn và quy mô toàn cầu. '
          '+8% thu nhập tự động, vĩnh viễn.',
    ),
    'en': StoryText(
      speaker: 'You',
      title: 'Fight or Shake Hands',
      body: 'Golden Orb makes a buyout offer. The board splits. You must '
          'choose: stand alone, or join hands with the very rival trying to '
          'take you over — to grow faster.',
      optionA: 'Stay Independent',
      optionADesc: 'Buy back shares, keep control in the family. +8% tap '
          'value, permanent.',
      optionB: 'Strategic Merger',
      optionBDesc: 'Join Golden Orb for capital and global reach. +8% idle '
          'income, permanent.',
    ),
  },
  14: {
    'vi': StoryText(
      speaker: 'Bà Tư',
      title: 'Về tận gốc',
      body: 'Dù chọn đường nào, con vẫn nhớ lời bà: "Trà ngon bắt đầu từ gốc '
          'trà." Công ty mua lại cả nông trại chè, xây chuỗi cung ứng riêng '
          '— không còn phụ thuộc ai.',
    ),
    'en': StoryText(
      speaker: 'Grandma Tư',
      title: 'Back to the Root',
      body: 'Whichever path you chose, Grandma Tư\'s words stick: "Good tea '
          'starts at the root." The company buys entire tea farms, building '
          'its own supply chain — dependent on no one.',
    ),
  },
  15: {
    'vi': StoryText(
      speaker: 'Bạn',
      title: 'Không còn biên giới',
      body: 'Nông trại ở năm quốc gia, nhà máy đóng gói tự động, tàu hàng '
          'riêng. Bản đồ thế giới trong phòng họp giờ đầy chấm đỏ — mỗi chấm '
          'là một vùng trồng chè thuộc về con.',
    ),
    'en': StoryText(
      speaker: 'You',
      title: 'No More Borders',
      body: 'Farms in five countries, automated packing plants, a private '
          'cargo fleet. The world map in the boardroom is full of red dots '
          'now — each one a tea region you own.',
    ),
  },
  16: {
    'vi': StoryText(
      speaker: 'Bạn',
      title: 'Trà sữa không cần người pha',
      body: 'Cánh tay robot rót đúng từng giọt syrup, AI dự đoán khách muốn '
          'gì trước cả khi họ gọi món. Nhanh hơn, đều hơn, rẻ hơn. Nhưng có '
          'gì đó ấm áp đã mất đi giữa dây chuyền sáng loáng.',
    ),
    'en': StoryText(
      speaker: 'You',
      title: 'Milk Tea Without Hands',
      body: 'Robot arms pour syrup to the exact drop; an AI predicts orders '
          'before customers speak. Faster, more consistent, cheaper. But '
          'something warm got lost somewhere in the gleaming machinery.',
    ),
  },
  17: {
    'vi': StoryText(
      speaker: 'Vy "Golden Orb"',
      title: 'Lời chào cuối',
      body: 'Golden Orb rút khỏi thị trường sau một quý thua lỗ. Vy gửi một '
          'tin nhắn ngắn: "Tôi thua, nhưng công nhận: bà pha trà giỏi hơn '
          'tôi buôn cổ phiếu." Không còn ai để cạnh tranh nữa.',
    ),
    'en': StoryText(
      speaker: 'Vy "Golden Orb"',
      title: 'A Final Word',
      body: 'Golden Orb exits the market after a losing quarter. Vy sends a '
          'short message: "I lost. But credit where it\'s due — you brew '
          'better than I trade." There\'s no one left to compete with.',
    ),
  },
  18: {
    'vi': StoryText(
      speaker: 'Bà Tư',
      title: 'Di sản',
      body: 'Bà Tư, giờ đã rất già, hỏi con một câu cuối: con muốn để lại '
          'điều gì? Một quán trà nhỏ ai cũng nhớ tên, hay một cái tên ai '
          'cũng biết dù không nhớ vị?',
      optionA: 'Giữ hồn quán nhỏ',
      optionADesc: 'Trà sữa mãi mãi được pha tay, dù ở quy mô nào. +8% giá '
          'trị mỗi lần chạm, vĩnh viễn.',
      optionB: 'Phủ khắp thế giới',
      optionBDesc: 'Một cái tên ở mọi ngã tư trên hành tinh. +8% thu nhập tự '
          'động, vĩnh viễn.',
    ),
    'en': StoryText(
      speaker: 'Grandma Tư',
      title: 'Legacy',
      body: 'Grandma Tư, very old now, asks you one last question: what do '
          'you want to leave behind? A small shop everyone remembers by '
          'name, or a name everyone knows, even if they forget the taste?',
      optionA: 'Keep the Shop\'s Soul',
      optionADesc: 'Every cup, at any scale, still made by hand. +8% tap '
          'value, permanent.',
      optionB: 'Cover the World',
      optionBDesc: 'A name on every corner of the planet. +8% idle income, '
          'permanent.',
    ),
  },
  19: {
    'vi': StoryText(
      speaker: 'Bà Tư',
      title: 'Mở học viện',
      body: 'Bà Tư gõ nhẹ cây muỗng lên thành ly: "Con đã đi xa hơn bà '
          'tưởng. Giờ đến lúc dạy lại cho người khác." Nhà máy cũ được '
          'cải tạo thành Học viện Trà Sữa — nơi ai cũng được học pha một '
          'ly cho ra hồn.',
    ),
    'en': StoryText(
      speaker: 'Grandma Tư',
      title: 'The Academy',
      body: 'Grandma Tư taps a spoon against a cup: "You\'ve gone further '
          'than I ever imagined. Now it\'s time to teach others." The old '
          'factory becomes the Milk Tea Academy — where anyone can learn '
          'to brew a cup worth remembering.',
    ),
  },
  20: {
    'vi': StoryText(
      speaker: 'Mộc',
      title: 'Học trò đầu tiên',
      body: 'Một cậu bé tên Mộc đứng chờ ở cổng từ sáng sớm, tay ôm cuốn sổ '
          'ghi chép chi chít. "Cô ơi, tại sao trà của cô lại ngon hơn của '
          'con dù con làm y hệt?" Bạn mỉm cười. Đó chính là câu hỏi hay '
          'nhất mà học viện từng nhận.',
    ),
    'en': StoryText(
      speaker: 'Mộc',
      title: 'The First Student',
      body: 'A boy named Mộc has been waiting at the gate since dawn, '
          'clutching a notebook crammed with notes. "Why is your tea '
          'better than mine when I do exactly the same thing?" You smile. '
          'It is the best question the Academy has ever been asked.',
    ),
  },
  21: {
    'vi': StoryText(
      speaker: 'Thị trưởng',
      title: 'Con đường mang tên quán',
      body: 'Học viện đông đến mức cả khu phố mọc lên quanh nó. Thị trưởng '
          'đích thân đến trao bảng tên: một con đường mới mang tên quán '
          'trà nhỏ ngày xưa. Bà Tư đứng nhìn tấm bảng rất lâu, không nói '
          'gì, chỉ chỉnh lại cho nó thẳng.',
    ),
    'en': StoryText(
      speaker: 'The Mayor',
      title: 'A Street Named After the Shop',
      body: 'The Academy grows so busy that a whole neighborhood sprouts '
          'around it. The Mayor personally hands over a sign: a new '
          'street named after the little tea shop of old. Grandma Tư '
          'stares at it for a long time, saying nothing, only '
          'straightening it.',
    ),
  },
  22: {
    'vi': StoryText(
      speaker: 'Bạn',
      title: 'Thành phố không ngủ',
      body: 'Thành phố lớn nhanh hơn dự tính. Đêm nào cũng có người xếp '
          'hàng, đèn đường ngả màu nâu trà. Có lúc bạn tự hỏi liệu có ai '
          'còn nhớ lý do mình bắt đầu. Rồi Mộc mang ra một ly, nhỏ thôi, '
          'pha tay: "Của cô đây, như ngày đầu."',
    ),
    'en': StoryText(
      speaker: 'You',
      title: 'The City That Never Sleeps',
      body: 'The city grows faster than planned. Every night there is a '
          'line, and the streetlights glow tea-brown. Sometimes you '
          'wonder if anyone remembers why you started. Then Mộc brings '
          'out one small, hand-brewed cup: "Yours, just like the first '
          'day."',
    ),
  },
  23: {
    'vi': StoryText(
      speaker: 'Bộ trưởng',
      title: 'Quốc bảo hay xuất khẩu',
      body: 'Chính phủ đề nghị công nhận trà sữa là di sản quốc gia. Đồng '
          'thời, các nước láng giềng ngỏ ý nhập khẩu hàng loạt. Cả hai '
          'không thể cùng lúc trọn vẹn: gìn giữ nguyên bản hay đưa đi '
          'khắp nơi?',
      optionA: 'Giữ làm di sản',
      optionADesc: 'Công thức được bảo hộ, mỗi ly là một tác phẩm. +8% giá trị mỗi '
          'lần chạm, vĩnh viễn.',
      optionB: 'Xuất khẩu khắp nơi',
      optionBDesc: 'Mở đường vận chuyển sang mọi quốc gia. +8% thu nhập tự động, '
          'vĩnh viễn.',
    ),
    'en': StoryText(
      speaker: 'The Minister',
      title: 'National Treasure or Export',
      body: 'The government offers to recognize milk tea as national '
          'heritage. At the same time, neighboring countries want to '
          'import it by the shipload. You cannot fully have both: '
          'preserve the original, or send it everywhere?',
      optionA: 'Keep it as Heritage',
      optionADesc: 'The recipe is protected; every cup is a craft. +8% tap value, '
          'permanent.',
      optionB: 'Export Everywhere',
      optionBDesc: 'Open shipping routes to every nation. +8% idle income, '
          'permanent.',
    ),
  },
  24: {
    'vi': StoryText(
      speaker: 'Đại sứ',
      title: 'Ngoại giao bằng trà',
      body: 'Các nước lập một liên minh, và trà sữa bất ngờ trở thành ngôn '
          'ngữ chung. Hai bên đang căng thẳng cũng chịu ngồi xuống cạnh '
          'nhau khi có một ly trong tay. Bà Tư chỉ nhún vai: "Bà đã bảo, '
          'ai uống trà xong cũng dễ nói chuyện hơn."',
    ),
    'en': StoryText(
      speaker: 'The Ambassador',
      title: 'Diplomacy by Tea',
      body: 'The nations form an alliance, and milk tea unexpectedly '
          'becomes the common language. Even sides in tense standoffs '
          'will sit beside each other with a cup in hand. Grandma Tư just '
          'shrugs: "I always said people talk better after tea."',
    ),
  },
  25: {
    'vi': StoryText(
      speaker: 'Vy "Golden Orb"',
      title: 'Lá thư mời',
      body: 'Một phong bì màu vàng đến tay bạn. Vy viết: "Tôi muốn mời bà '
          'và cô đến hội nghị thượng đỉnh. Lần này không phải để thâu tóm '
          '— mà để nhờ hai người dạy lại đội ngũ của tôi cách pha một ly '
          'trà thật sự." Đối thủ cũ, giờ là đồng minh.',
    ),
    'en': StoryText(
      speaker: 'Vy "Golden Orb"',
      title: 'An Invitation',
      body: 'A golden envelope arrives. Vy writes: "I\'d like to invite you '
          'both to the summit. Not to buy you out this time — but to ask '
          'you to teach my team how to brew a truly good cup." The old '
          'rival is now an ally.',
    ),
  },
  26: {
    'vi': StoryText(
      speaker: 'Bạn',
      title: 'Cả hành tinh một ly trà',
      body: 'Từ phố nhỏ đến cả hành tinh, đâu đâu cũng có người cầm một ly '
          'trà sữa. Nhìn bản đồ đầy chấm sáng, bạn chợt nhận ra: mình '
          'không còn cạnh tranh với ai nữa. Chỉ còn một câu hỏi, khó hơn '
          'bất kỳ đối thủ nào: tiếp theo là gì?',
    ),
    'en': StoryText(
      speaker: 'You',
      title: 'A Planet, One Cup',
      body: 'From a small street to the whole planet, someone everywhere '
          'holds a cup of milk tea. Looking at a map full of glowing '
          'dots, you realize you are no longer competing with anyone. '
          'Only one question remains, harder than any rival: what comes '
          'next?',
    ),
  },
  27: {
    'vi': StoryText(
      speaker: 'Bà Tư',
      title: 'Tờ công thức cuối',
      body: 'Bà Tư đưa cho bạn một tờ giấy đã ố vàng, nét chữ run run. "Đây '
          'là công thức gốc, bà chưa cho ai xem." Bạn mở ra. Trên giấy '
          'chỉ có ba dòng: trà thật, sữa thật, và một chỗ trống để bạn tự '
          'điền.',
    ),
    'en': StoryText(
      speaker: 'Grandma Tư',
      title: 'The Last Recipe',
      body: 'Grandma Tư hands you a yellowed sheet of paper in shaky '
          'handwriting. "This is the original recipe. I\'ve never shown '
          'anyone." You unfold it. There are only three lines: real tea, '
          'real milk, and a blank space for you to fill in.',
    ),
  },
  28: {
    'vi': StoryText(
      speaker: 'Bà Tư',
      title: 'Chân lý',
      body: 'Bà Tư mỉm cười: "Vậy là con đã hiểu. Công thức không nằm trên '
          'tờ giấy." Bây giờ chỉ còn một quyết định cuối: giữ nguyên bản '
          'công thức làm của riêng mình, hay trao nó cho mọi người để mỗi '
          'người tự viết thêm một dòng?',
      optionA: 'Giữ công thức gốc',
      optionADesc: 'Bản gốc còn nguyên, chỉ bạn giữ. +8% giá trị mỗi lần chạm, '
          'vĩnh viễn.',
      optionB: 'Trao cho mọi người',
      optionBDesc: 'Ai cũng được viết tiếp công thức. +8% thu nhập tự động, vĩnh '
          'viễn.',
    ),
    'en': StoryText(
      speaker: 'Grandma Tư',
      title: 'The Truth',
      body: 'Grandma Tư smiles: "So you understand now. The recipe was '
          'never on the paper." One last decision remains: keep the '
          'original recipe as your own, or hand it to everyone so each '
          'person can write one more line?',
      optionA: 'Keep the Original',
      optionADesc: 'The original stays intact, yours alone. +8% tap value, '
          'permanent.',
      optionB: 'Give It to Everyone',
      optionBDesc: 'Anyone may continue the recipe. +8% idle income, permanent.',
    ),
  },
  // --- Hồi 3 (29-34): "Vòng Lặp Vĩnh Cửu" — Kỷ Nguyên + Hành trình Trân Châu
  // Rơi làm bài luyện tay nghề, nhân vật mới "Thầy Cả". ---
  29: {
    'vi': StoryText(
      speaker: 'Thầy Cả',
      title: 'Người lạ giữa vòng lặp',
      body: 'Ngay sau lần Kỷ Nguyên đầu tiên — khi mọi thứ vừa trở về số '
          'không — một bóng người bước ra từ quầy trống. "Ta đã chờ con ở '
          'đây từ rất lâu," ông nói, "qua không biết bao nhiêu vòng lặp của '
          'những người trước con. Ta là Thầy Cả, giữ cửa cho những ai dám '
          'bắt đầu lại."',
    ),
    'en': StoryText(
      speaker: 'The Grand Teacher',
      title: 'A Stranger in the Loop',
      body: 'Right after the first Ascension — the moment everything reset '
          'to zero — a figure stepped out from the empty counter. "I have '
          'waited for you here a very long time," he said, "through more '
          'loops of those before you than I can count. I am the Grand '
          'Teacher, keeper of the gate for those who dare begin again."',
    ),
  },
  30: {
    'vi': StoryText(
      speaker: 'Thầy Cả',
      title: 'Bài luyện đầu tiên',
      body: 'Thầy Cả đặt trước mặt bạn một khay trân châu đang rơi không '
          'ngừng. "Kỷ Nguyên cho con sức mạnh, nhưng sức mạnh không dạy con '
          'đôi tay. Bắt đúng nhịp 10 mẻ, rồi quay lại đây." Không có phép '
          'màu nào rút ngắn được bài học này.',
    ),
    'en': StoryText(
      speaker: 'The Grand Teacher',
      title: 'The First Trial',
      body: 'The Grand Teacher sets down a tray of endlessly falling '
          'pearls. "Ascension gives you power, but power doesn\'t teach your '
          'hands. Catch the rhythm through 10 batches, then come back." No '
          'shortcut can skip this lesson.',
    ),
  },
  31: {
    'vi': StoryText(
      speaker: 'Thầy Cả',
      title: 'Bắt đầu lại, lần nữa',
      body: 'Lần Kỷ Nguyên thứ hai đến, và bạn thấy dễ chịu hơn lần đầu. '
          '"Đúng vậy," Thầy Cả gật đầu, "nỗi sợ mất đi chỉ lớn ở lần đầu '
          'tiên. Càng buông bỏ nhiều lần, con càng nhận ra: không gì con '
          'từng học bị mất cả — chỉ có Xu là về không."',
    ),
    'en': StoryText(
      speaker: 'The Grand Teacher',
      title: 'Beginning Again',
      body: 'The second Ascension comes, and it feels easier than the '
          'first. "Just so," the Grand Teacher nods. "The fear of losing '
          'everything is only ever biggest the first time. Let go enough '
          'times, and you realize: nothing you\'ve learned is ever lost — '
          'only the coins reset to zero."',
    ),
  },
  32: {
    'vi': StoryText(
      speaker: 'Thầy Cả',
      title: 'Bài luyện thứ hai',
      body: '"Tay con đã vững hơn," Thầy Cả nhận xét khi nhìn bạn ghép '
          'những dãy trân châu dài dần. "Nhưng vững chưa đủ — còn phải '
          'nhanh." Ông chỉ vào khay mới: 25 mẻ, nhịp nhanh hơn hẳn lần '
          'trước.',
    ),
    'en': StoryText(
      speaker: 'The Grand Teacher',
      title: 'The Second Trial',
      body: '"Your hands are steadier now," the Grand Teacher remarks, '
          'watching your chains of pearls grow longer. "But steady isn\'t '
          'enough — you must also be fast." He points to a new tray: 25 '
          'batches, a noticeably faster pace than before.',
    ),
  },
  33: {
    'vi': StoryText(
      speaker: 'Thầy Cả',
      title: 'Ba lần, không phải ngẫu nhiên',
      body: 'Lần Kỷ Nguyên thứ ba, Thầy Cả không nói gì thêm về việc buông '
          'bỏ nữa — ông chỉ lặng nhìn bạn một lúc lâu. "Ba lần không phải '
          'ngẫu nhiên," cuối cùng ông nói. "Đó là số lần tối thiểu để một '
          'người thật sự tin vào vòng lặp, chứ không chỉ chịu đựng nó."',
    ),
    'en': StoryText(
      speaker: 'The Grand Teacher',
      title: 'Three Times, Not by Chance',
      body: 'On the third Ascension, the Grand Teacher says nothing more '
          'about letting go — he only watches you for a long moment. '
          '"Three times is not by chance," he finally says. "That is the '
          'minimum for someone to truly believe in the loop, not merely '
          'endure it."',
    ),
  },
  34: {
    'vi': StoryText(
      speaker: 'Thầy Cả',
      title: 'Bài luyện thứ ba',
      body: 'Khay trân châu thứ ba không còn là bài luyện tay nữa — nó là '
          'một tấm gương. "Con sẽ thấy," Thầy Cả nói khẽ, "càng gần mốc 40 '
          'mẻ, thứ con đang luyện không phải đôi tay, mà là sự kiên nhẫn '
          'với chính mình."',
    ),
    'en': StoryText(
      speaker: 'The Grand Teacher',
      title: 'The Third Trial',
      body: 'The third tray of pearls is no longer a hand trial — it is a '
          'mirror. "You will see," the Grand Teacher says quietly, "as you '
          'near batch 40, what you are training is no longer your hands, '
          'but your patience with yourself."',
    ),
  },
  35: {
    'vi': StoryText(
      speaker: 'Thầy Cả',
      title: 'Gần hết con đường',
      body: 'Khay trân châu cuối cùng chỉ còn vài màn nữa là hết cả hành '
          'trình. "Tới đây," Thầy Cả nói, "phần lớn người bỏ cuộc không '
          'phải vì tay họ chậm, mà vì họ tưởng gần xong rồi nên lơ là." 55 '
          'mẻ — gần sát đáy khay.',
    ),
    'en': StoryText(
      speaker: 'The Grand Teacher',
      title: 'Near the End of the Road',
      body: 'The last tray of pearls has only a few levels left before the '
          'whole journey ends. "By this point," the Grand Teacher says, '
          '"most who quit don\'t do so because their hands are slow, but '
          'because they think they are nearly done and grow careless." 55 '
          'batches — close to the bottom of the tray.',
    ),
  },
  36: {
    'vi': StoryText(
      speaker: 'Thầy Cả',
      title: 'Vòng lặp vĩnh cửu',
      body: 'Kỷ Nguyên thứ tư khép lại. Thầy Cả bước lùi, nhường chỗ quầy '
          'trống cho bạn. "Đến lượt con giữ cửa. Nhưng trước khi ta đi, một '
          'câu hỏi cuối: con sẽ giữ Vòng Lặp này bí mật, chỉ mở cho ai thật '
          'sự xứng đáng — hay mở nó cho tất cả, để ai cũng có cơ hội bắt '
          'đầu lại?"',
      optionA: 'Giữ bí mật',
      optionADesc: 'Chỉ truyền cho người xứng đáng, gìn giữ tinh hoa. +8% giá trị '
          'mỗi lần chạm, vĩnh viễn.',
      optionB: 'Mở cho tất cả',
      optionBDesc: 'Ai cũng được thử bắt đầu lại. +8% thu nhập tự động, vĩnh viễn.',
    ),
    'en': StoryText(
      speaker: 'The Grand Teacher',
      title: 'The Eternal Loop',
      body: 'The fourth Ascension closes. The Grand Teacher steps back, '
          'leaving the empty counter to you. "It is your turn to keep the '
          'gate. But before I go, one last question: will you keep this '
          'Loop secret, opened only to those truly worthy — or open it to '
          'everyone, so anyone may have the chance to begin again?"',
      optionA: 'Keep It Secret',
      optionADesc: 'Pass it only to the worthy, preserving its essence. +8% tap '
          'value, permanent.',
      optionB: 'Open It to Everyone',
      optionBDesc: 'Anyone may try to begin again. +8% idle income, permanent.',
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
