// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Đế Chế Trà Sữa';

  @override
  String get tapBrew => 'Chạm pha trà';

  @override
  String get coinsSuffix => ' Xu';

  @override
  String incomePerSecond(String amount) {
    return '+$amount / giây';
  }

  @override
  String get instantCashButton => 'Tiền tức thì';

  @override
  String instantCashSnack(String amount) {
    return 'Tiền tức thì! +$amount Xu';
  }

  @override
  String stageHeader(String name) {
    return '🏪 $name';
  }

  @override
  String unlockStageButton(String cost) {
    return 'Mở khóa $cost Xu';
  }

  @override
  String generatorSubtitle(String amount) {
    return '+$amount Xu/giây mỗi cấp';
  }

  @override
  String buyButton(String cost) {
    return '$cost Xu';
  }

  @override
  String boostChip(int seconds) {
    return '🔥 x3 · ${seconds}s';
  }

  @override
  String vipSnack(String cash, int gems) {
    return 'Khách VIP! +$cash Xu, +$gems 💎';
  }

  @override
  String iapGemsSnack(String amount) {
    return 'Đã nhận +$amount 💎';
  }

  @override
  String get iapRemoveAdsSnack => 'Đã gỡ quảng cáo. Cảm ơn bạn!';

  @override
  String iapStarterSnack(String amount) {
    return 'Gói khởi động: +$amount 💎';
  }

  @override
  String get genTraDen => 'Trà đen';

  @override
  String get genTranChau => 'Trân châu';

  @override
  String get genThach => 'Thạch';

  @override
  String get genPudding => 'Pudding';

  @override
  String get genKemNuong => 'Trà sữa kem nướng';

  @override
  String get genMatcha => 'Matcha xô';

  @override
  String get stage1 => 'Xe đẩy vỉa hè';

  @override
  String get stage2 => 'Kiosk cửa hàng nhỏ';

  @override
  String get stage3 => 'Chuỗi cafe sang trọng';

  @override
  String gemShopTitle(String gems) {
    return 'Cửa Hàng 💎 (có $gems)';
  }

  @override
  String get gemBoostName => 'Tăng thu nhập';

  @override
  String gemBoostDesc(int percent) {
    return '+$percent% thu nhập vĩnh viễn mỗi cấp';
  }

  @override
  String get offlineCapName => 'Kho lạnh offline';

  @override
  String offlineCapDesc(int hours) {
    return '+$hours giờ trần tiền offline mỗi cấp';
  }

  @override
  String gemItemLevel(String name, int level) {
    return '$name  Lv.$level';
  }

  @override
  String gemCost(int cost) {
    return '$cost 💎';
  }

  @override
  String get iapSectionTitle => 'Nạp bằng tiền thật';

  @override
  String get restorePurchases => 'Khôi phục giao dịch';

  @override
  String get close => 'Đóng';

  @override
  String get iapGemsTitle => 'Túi Kim Cương';

  @override
  String get iapGemsDesc =>
      'Nạp thêm Kim Cương để mua vật phẩm trong Cửa hàng.';

  @override
  String get iapRemoveAdsTitle => 'Gỡ quảng cáo';

  @override
  String get iapRemoveAdsDesc =>
      'Bỏ qua mọi quảng cáo — vẫn nhận đủ thưởng, không cần xem.';

  @override
  String get iapStarterTitle => 'Gói khởi động';

  @override
  String get iapStarterDesc => 'Một lần: nhận ngay một túi Kim Cương lớn.';

  @override
  String get prestigeTitle => 'Nhượng Quyền 🏪';

  @override
  String prestigeIntro(int percent) {
    return 'Mỗi ⭐ Sao cho +$percent% thu nhập vĩnh viễn.';
  }

  @override
  String get prestigeStarsNow => 'Sao hiện có';

  @override
  String prestigeStarsValue(int stars, int percent) {
    return '$stars ⭐  (+$percent%)';
  }

  @override
  String get prestigeNow => 'Nhượng quyền bây giờ';

  @override
  String prestigeGain(int stars) {
    return '+$stars ⭐';
  }

  @override
  String get prestigeTotalBonus => 'Tổng bonus sau đó';

  @override
  String prestigeTotalValue(int percent) {
    return '+$percent%';
  }

  @override
  String get prestigeWarning =>
      '⚠️ Sẽ reset toàn bộ Xu và cấp nâng cấp hiện tại.';

  @override
  String get cancel => 'Huỷ';

  @override
  String prestigeConfirm(int stars) {
    return 'Nhượng quyền (+$stars ⭐)';
  }

  @override
  String get prestigeNotEnough => 'Chưa đủ';

  @override
  String prestigeSuccess(int stars) {
    return 'Nhượng quyền thành công! +$stars ⭐';
  }

  @override
  String get offlineTitle => 'Chào mừng trở lại! 🧋';

  @override
  String offlineBody(String amount) {
    return 'Quán vẫn bán trong lúc bạn vắng mặt.\nBạn kiếm được $amount Xu.';
  }

  @override
  String get offlineClaim => 'Nhận';

  @override
  String get offlineDoubleButton => 'Xem QC ×2';

  @override
  String offlineDoubleSnack(String amount) {
    return 'Nhân đôi! +$amount Xu';
  }

  @override
  String get howToPlayTitle => 'Cách chơi';

  @override
  String get htpTap => '🧋 Chạm ly để pha trà và kiếm Xu.';

  @override
  String get htpBuy => '🛒 Mua nâng cấp để có thu nhập tự động mỗi giây.';

  @override
  String get htpStage =>
      '🏪 Đủ Xu thì mở khóa giai đoạn mới, bán món cao cấp hơn.';

  @override
  String get htpCat =>
      '🐱 Chạm mèo may mắn để nhận Mưa vàng ×3 trong chốc lát.';

  @override
  String get htpVip => '🚗 Đón khách VIP đi ô tô để nhận Kim Cương 💎.';

  @override
  String get htpGems =>
      '💎 Dùng Kim Cương trong Cửa hàng mua nâng cấp vĩnh viễn.';

  @override
  String get htpPrestige =>
      '⭐ Nhượng quyền để chơi lại và nhận Sao — bonus thu nhập vĩnh viễn.';

  @override
  String get htpOffline =>
      '😴 Quán vẫn bán khi bạn thoát — quay lại nhận tiền offline.';
}
