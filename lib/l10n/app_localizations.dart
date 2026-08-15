import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_id.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_th.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('id'),
    Locale('pt'),
    Locale('th'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đế Chế Trà Sữa'**
  String get appTitle;

  /// No description provided for @tapBrew.
  ///
  /// In vi, this message translates to:
  /// **'Chạm pha trà'**
  String get tapBrew;

  /// No description provided for @coinsSuffix.
  ///
  /// In vi, this message translates to:
  /// **' Xu'**
  String get coinsSuffix;

  /// No description provided for @incomePerSecond.
  ///
  /// In vi, this message translates to:
  /// **'+{amount} / giây'**
  String incomePerSecond(String amount);

  /// No description provided for @instantCashButton.
  ///
  /// In vi, this message translates to:
  /// **'Tiền tức thì'**
  String get instantCashButton;

  /// No description provided for @instantCashSnack.
  ///
  /// In vi, this message translates to:
  /// **'Tiền tức thì! +{amount} Xu'**
  String instantCashSnack(String amount);

  /// No description provided for @stageHeader.
  ///
  /// In vi, this message translates to:
  /// **'🏪 {name}'**
  String stageHeader(String name);

  /// No description provided for @unlockStageButton.
  ///
  /// In vi, this message translates to:
  /// **'Mở khóa {cost} Xu'**
  String unlockStageButton(String cost);

  /// No description provided for @generatorSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'+{amount} Xu/giây mỗi cấp'**
  String generatorSubtitle(String amount);

  /// No description provided for @buyButton.
  ///
  /// In vi, this message translates to:
  /// **'{cost} Xu'**
  String buyButton(String cost);

  /// No description provided for @boostChip.
  ///
  /// In vi, this message translates to:
  /// **'🔥 x3 · {seconds}s'**
  String boostChip(int seconds);

  /// No description provided for @vipSnack.
  ///
  /// In vi, this message translates to:
  /// **'Khách VIP! +{cash} Xu, +{gems} 💎'**
  String vipSnack(String cash, int gems);

  /// No description provided for @iapGemsSnack.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận +{amount} 💎'**
  String iapGemsSnack(String amount);

  /// No description provided for @iapRemoveAdsSnack.
  ///
  /// In vi, this message translates to:
  /// **'Đã gỡ quảng cáo. Cảm ơn bạn!'**
  String get iapRemoveAdsSnack;

  /// No description provided for @iapStarterSnack.
  ///
  /// In vi, this message translates to:
  /// **'Gói khởi động: +{amount} 💎'**
  String iapStarterSnack(String amount);

  /// No description provided for @genTraDen.
  ///
  /// In vi, this message translates to:
  /// **'Trà đen'**
  String get genTraDen;

  /// No description provided for @genTranChau.
  ///
  /// In vi, this message translates to:
  /// **'Trân châu'**
  String get genTranChau;

  /// No description provided for @genThach.
  ///
  /// In vi, this message translates to:
  /// **'Thạch'**
  String get genThach;

  /// No description provided for @genPudding.
  ///
  /// In vi, this message translates to:
  /// **'Pudding'**
  String get genPudding;

  /// No description provided for @genKemNuong.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa kem nướng'**
  String get genKemNuong;

  /// No description provided for @genMatcha.
  ///
  /// In vi, this message translates to:
  /// **'Matcha xô'**
  String get genMatcha;

  /// No description provided for @stage1.
  ///
  /// In vi, this message translates to:
  /// **'Xe đẩy vỉa hè'**
  String get stage1;

  /// No description provided for @stage2.
  ///
  /// In vi, this message translates to:
  /// **'Kiosk cửa hàng nhỏ'**
  String get stage2;

  /// No description provided for @stage3.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi cafe sang trọng'**
  String get stage3;

  /// No description provided for @gemShopTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cửa Hàng 💎 (có {gems})'**
  String gemShopTitle(String gems);

  /// No description provided for @gemBoostName.
  ///
  /// In vi, this message translates to:
  /// **'Tăng thu nhập'**
  String get gemBoostName;

  /// No description provided for @gemBoostDesc.
  ///
  /// In vi, this message translates to:
  /// **'+{percent}% thu nhập vĩnh viễn mỗi cấp'**
  String gemBoostDesc(int percent);

  /// No description provided for @offlineCapName.
  ///
  /// In vi, this message translates to:
  /// **'Kho lạnh offline'**
  String get offlineCapName;

  /// No description provided for @offlineCapDesc.
  ///
  /// In vi, this message translates to:
  /// **'+{hours} giờ trần tiền offline mỗi cấp'**
  String offlineCapDesc(int hours);

  /// No description provided for @gemItemLevel.
  ///
  /// In vi, this message translates to:
  /// **'{name}  Lv.{level}'**
  String gemItemLevel(String name, int level);

  /// No description provided for @gemCost.
  ///
  /// In vi, this message translates to:
  /// **'{cost} 💎'**
  String gemCost(int cost);

  /// No description provided for @iapSectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nạp bằng tiền thật'**
  String get iapSectionTitle;

  /// No description provided for @restorePurchases.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục giao dịch'**
  String get restorePurchases;

  /// No description provided for @close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get close;

  /// No description provided for @iapGemsDesc.
  ///
  /// In vi, this message translates to:
  /// **'Nạp thêm Kim Cương để mua vật phẩm trong Cửa hàng.'**
  String get iapGemsDesc;

  /// No description provided for @iapRemoveAdsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gỡ quảng cáo'**
  String get iapRemoveAdsTitle;

  /// No description provided for @iapRemoveAdsDesc.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua mọi quảng cáo — vẫn nhận đủ thưởng, không cần xem.'**
  String get iapRemoveAdsDesc;

  /// No description provided for @iapStarterTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gói khởi động'**
  String get iapStarterTitle;

  /// No description provided for @iapStarterDesc.
  ///
  /// In vi, this message translates to:
  /// **'Một lần: nhận ngay một túi Kim Cương lớn.'**
  String get iapStarterDesc;

  /// No description provided for @prestigeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhượng Quyền 🏪'**
  String get prestigeTitle;

  /// No description provided for @prestigeIntro.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi ⭐ Sao cho +{percent}% thu nhập vĩnh viễn.'**
  String prestigeIntro(int percent);

  /// No description provided for @prestigeStarsNow.
  ///
  /// In vi, this message translates to:
  /// **'Sao hiện có'**
  String get prestigeStarsNow;

  /// No description provided for @prestigeStarsValue.
  ///
  /// In vi, this message translates to:
  /// **'{stars} ⭐  (+{percent}%)'**
  String prestigeStarsValue(int stars, int percent);

  /// No description provided for @prestigeNow.
  ///
  /// In vi, this message translates to:
  /// **'Nhượng quyền bây giờ'**
  String get prestigeNow;

  /// No description provided for @prestigeGain.
  ///
  /// In vi, this message translates to:
  /// **'+{stars} ⭐'**
  String prestigeGain(int stars);

  /// No description provided for @prestigeTotalBonus.
  ///
  /// In vi, this message translates to:
  /// **'Tổng bonus sau đó'**
  String get prestigeTotalBonus;

  /// No description provided for @prestigeTotalValue.
  ///
  /// In vi, this message translates to:
  /// **'+{percent}%'**
  String prestigeTotalValue(int percent);

  /// No description provided for @prestigeWarning.
  ///
  /// In vi, this message translates to:
  /// **'⚠️ Sẽ reset toàn bộ Xu và cấp nâng cấp hiện tại.'**
  String get prestigeWarning;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get cancel;

  /// No description provided for @prestigeConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Nhượng quyền (+{stars} ⭐)'**
  String prestigeConfirm(int stars);

  /// No description provided for @prestigeNotEnough.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đủ'**
  String get prestigeNotEnough;

  /// No description provided for @prestigeSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Nhượng quyền thành công! +{stars} ⭐'**
  String prestigeSuccess(int stars);

  /// No description provided for @offlineTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng trở lại! 🧋'**
  String get offlineTitle;

  /// No description provided for @offlineBody.
  ///
  /// In vi, this message translates to:
  /// **'Quán vẫn bán trong lúc bạn vắng mặt.\nBạn kiếm được {amount} Xu.'**
  String offlineBody(String amount);

  /// No description provided for @offlineClaim.
  ///
  /// In vi, this message translates to:
  /// **'Nhận'**
  String get offlineClaim;

  /// No description provided for @offlineDoubleButton.
  ///
  /// In vi, this message translates to:
  /// **'Xem QC ×2'**
  String get offlineDoubleButton;

  /// No description provided for @offlineDoubleSnack.
  ///
  /// In vi, this message translates to:
  /// **'Nhân đôi! +{amount} Xu'**
  String offlineDoubleSnack(String amount);

  /// No description provided for @howToPlayTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cách chơi'**
  String get howToPlayTitle;

  /// No description provided for @htpTap.
  ///
  /// In vi, this message translates to:
  /// **'🧋 Chạm ly để pha trà và kiếm Xu.'**
  String get htpTap;

  /// No description provided for @htpBuy.
  ///
  /// In vi, this message translates to:
  /// **'🛒 Mua nâng cấp để có thu nhập tự động mỗi giây.'**
  String get htpBuy;

  /// No description provided for @htpStage.
  ///
  /// In vi, this message translates to:
  /// **'🏪 Đủ Xu thì mở khóa giai đoạn mới, bán món cao cấp hơn.'**
  String get htpStage;

  /// No description provided for @htpCat.
  ///
  /// In vi, this message translates to:
  /// **'🐱 Chạm mèo may mắn để nhận Mưa vàng ×3 trong chốc lát.'**
  String get htpCat;

  /// No description provided for @htpVip.
  ///
  /// In vi, this message translates to:
  /// **'🚗 Đón khách VIP đi ô tô để nhận Kim Cương 💎.'**
  String get htpVip;

  /// No description provided for @htpGems.
  ///
  /// In vi, this message translates to:
  /// **'💎 Dùng Kim Cương trong Cửa hàng mua nâng cấp vĩnh viễn.'**
  String get htpGems;

  /// No description provided for @htpPrestige.
  ///
  /// In vi, this message translates to:
  /// **'⭐ Nhượng quyền để chơi lại và nhận Sao — bonus thu nhập vĩnh viễn.'**
  String get htpPrestige;

  /// No description provided for @htpOffline.
  ///
  /// In vi, this message translates to:
  /// **'😴 Quán vẫn bán khi bạn thoát — quay lại nhận tiền offline.'**
  String get htpOffline;

  /// No description provided for @language.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In vi, this message translates to:
  /// **'Theo hệ thống'**
  String get languageSystem;

  /// No description provided for @dailyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Điểm danh hằng ngày'**
  String get dailyTitle;

  /// No description provided for @dailyPrompt.
  ///
  /// In vi, this message translates to:
  /// **'Nhận quà đăng nhập hôm nay!'**
  String get dailyPrompt;

  /// No description provided for @dailyClaim.
  ///
  /// In vi, this message translates to:
  /// **'Nhận quà'**
  String get dailyClaim;

  /// No description provided for @dailyReward.
  ///
  /// In vi, this message translates to:
  /// **'+{gems} 💎'**
  String dailyReward(String gems);

  /// No description provided for @dailyStreak.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi {days} ngày 🔥'**
  String dailyStreak(int days);

  /// No description provided for @achievementsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thành tựu'**
  String get achievementsTitle;

  /// No description provided for @achEarn.
  ///
  /// In vi, this message translates to:
  /// **'Kiếm tổng {amount} Xu'**
  String achEarn(String amount);

  /// No description provided for @achStage.
  ///
  /// In vi, this message translates to:
  /// **'Đạt giai đoạn {n}'**
  String achStage(int n);

  /// No description provided for @achLevels.
  ///
  /// In vi, this message translates to:
  /// **'Sở hữu tổng {n} cấp nâng cấp'**
  String achLevels(int n);

  /// No description provided for @achPrestige.
  ///
  /// In vi, this message translates to:
  /// **'Nhượng quyền ({n}★ trở lên)'**
  String achPrestige(int n);

  /// No description provided for @achUnlocked.
  ///
  /// In vi, this message translates to:
  /// **'🏆 Mở khoá thành tựu! +{gems} 💎'**
  String achUnlocked(String gems);

  /// No description provided for @prestigeShopTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kho Sao ⭐'**
  String get prestigeShopTitle;

  /// No description provided for @prestigeShopSpendable.
  ///
  /// In vi, this message translates to:
  /// **'Còn {stars} ⭐ để tiêu'**
  String prestigeShopSpendable(int stars);

  /// No description provided for @prestigeIncomeName.
  ///
  /// In vi, this message translates to:
  /// **'Siêu thu nhập'**
  String get prestigeIncomeName;

  /// No description provided for @prestigeIncomeDesc.
  ///
  /// In vi, this message translates to:
  /// **'+{percent}% thu nhập vĩnh viễn mỗi cấp'**
  String prestigeIncomeDesc(int percent);

  /// No description provided for @prestigeTapName.
  ///
  /// In vi, this message translates to:
  /// **'Siêu chạm'**
  String get prestigeTapName;

  /// No description provided for @prestigeTapDesc.
  ///
  /// In vi, this message translates to:
  /// **'+{percent}% giá trị chạm mỗi cấp'**
  String prestigeTapDesc(int percent);

  /// No description provided for @prestigeStarCost.
  ///
  /// In vi, this message translates to:
  /// **'{cost} ⭐'**
  String prestigeStarCost(int cost);

  /// No description provided for @questTap.
  ///
  /// In vi, this message translates to:
  /// **'Chạm pha trà {n} lần'**
  String questTap(int n);

  /// No description provided for @questBuy.
  ///
  /// In vi, this message translates to:
  /// **'Mua {n} nâng cấp'**
  String questBuy(int n);

  /// No description provided for @questClaim.
  ///
  /// In vi, this message translates to:
  /// **'Nhận'**
  String get questClaim;

  /// No description provided for @iapDoubleTitle.
  ///
  /// In vi, this message translates to:
  /// **'x2 Thu nhập (vĩnh viễn)'**
  String get iapDoubleTitle;

  /// No description provided for @iapDoubleDesc.
  ///
  /// In vi, this message translates to:
  /// **'Gấp đôi mọi thu nhập tự động, mãi mãi'**
  String get iapDoubleDesc;

  /// No description provided for @iapDoubleSnack.
  ///
  /// In vi, this message translates to:
  /// **'Đã bật x2 thu nhập vĩnh viễn!'**
  String get iapDoubleSnack;

  /// No description provided for @rewardsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kiếm thêm 🎁'**
  String get rewardsTitle;

  /// No description provided for @rewardX2Name.
  ///
  /// In vi, this message translates to:
  /// **'x2 thu nhập 24 giờ'**
  String get rewardX2Name;

  /// No description provided for @rewardX2Active.
  ///
  /// In vi, this message translates to:
  /// **'Đang bật · còn {hours}h'**
  String rewardX2Active(int hours);

  /// No description provided for @rewardX2Snack.
  ///
  /// In vi, this message translates to:
  /// **'Đã bật x2 thu nhập 24 giờ!'**
  String get rewardX2Snack;

  /// No description provided for @rewardGemsName.
  ///
  /// In vi, this message translates to:
  /// **'Nhận {gems} 💎'**
  String rewardGemsName(int gems);

  /// No description provided for @rewardTimeSkip.
  ///
  /// In vi, this message translates to:
  /// **'Tua nhanh {hours} giờ'**
  String rewardTimeSkip(int hours);

  /// No description provided for @watchAd.
  ///
  /// In vi, this message translates to:
  /// **'Xem QC'**
  String get watchAd;

  /// No description provided for @piggyName.
  ///
  /// In vi, this message translates to:
  /// **'Heo đất'**
  String get piggyName;

  /// No description provided for @piggyBreak.
  ///
  /// In vi, this message translates to:
  /// **'Đập'**
  String get piggyBreak;

  /// No description provided for @piggySnack.
  ///
  /// In vi, this message translates to:
  /// **'Đập heo: +{gems} 💎'**
  String piggySnack(String gems);

  /// No description provided for @iapVipTitle.
  ///
  /// In vi, this message translates to:
  /// **'VIP Pass 30 ngày 👑'**
  String get iapVipTitle;

  /// No description provided for @iapVipDesc.
  ///
  /// In vi, this message translates to:
  /// **'Gỡ QC + x2 thu nhập + 50💎/ngày + trần offline+'**
  String get iapVipDesc;

  /// No description provided for @iapVipSnack.
  ///
  /// In vi, this message translates to:
  /// **'Đã kích hoạt VIP 30 ngày! 👑'**
  String get iapVipSnack;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'es',
    'id',
    'pt',
    'th',
    'vi',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'id':
      return AppLocalizationsId();
    case 'pt':
      return AppLocalizationsPt();
    case 'th':
      return AppLocalizationsTh();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
