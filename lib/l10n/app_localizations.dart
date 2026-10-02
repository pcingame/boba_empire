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

  /// No description provided for @adNotReadySnack.
  ///
  /// In vi, this message translates to:
  /// **'Quảng cáo chưa sẵn sàng, thử lại sau nhé'**
  String get adNotReadySnack;

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

  /// No description provided for @globalBonusChip.
  ///
  /// In vi, this message translates to:
  /// **'🌐 +{percent}%'**
  String globalBonusChip(int percent);

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

  /// No description provided for @buyModeMax.
  ///
  /// In vi, this message translates to:
  /// **'MAX'**
  String get buyModeMax;

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

  /// No description provided for @gemInstantStageName.
  ///
  /// In vi, this message translates to:
  /// **'Mở giai đoạn tức thì'**
  String get gemInstantStageName;

  /// No description provided for @gemInstantStageDesc.
  ///
  /// In vi, this message translates to:
  /// **'Mở {stage} ngay, bỏ qua chi phí Xu'**
  String gemInstantStageDesc(String stage);

  /// No description provided for @gemStageUnlockedSnack.
  ///
  /// In vi, this message translates to:
  /// **'Đã mở {stage}!'**
  String gemStageUnlockedSnack(String stage);

  /// No description provided for @gemTimeSkipName.
  ///
  /// In vi, this message translates to:
  /// **'Tua nhanh'**
  String get gemTimeSkipName;

  /// No description provided for @gemTimeSkipDesc.
  ///
  /// In vi, this message translates to:
  /// **'Nhận ngay {hours} giờ sản xuất'**
  String gemTimeSkipDesc(int hours);

  /// No description provided for @gemTimeSkipRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn {remaining}/{max} lượt hôm nay'**
  String gemTimeSkipRemaining(int remaining, int max);

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
  String prestigeIntro(String percent);

  /// No description provided for @prestigeStarsNow.
  ///
  /// In vi, this message translates to:
  /// **'Sao hiện có'**
  String get prestigeStarsNow;

  /// No description provided for @prestigeStarsValue.
  ///
  /// In vi, this message translates to:
  /// **'{stars} ⭐  (+{percent}%)'**
  String prestigeStarsValue(String stars, String percent);

  /// No description provided for @prestigeNow.
  ///
  /// In vi, this message translates to:
  /// **'Nhượng quyền bây giờ'**
  String get prestigeNow;

  /// No description provided for @prestigeGain.
  ///
  /// In vi, this message translates to:
  /// **'+{stars} ⭐'**
  String prestigeGain(String stars);

  /// No description provided for @prestigeTotalBonus.
  ///
  /// In vi, this message translates to:
  /// **'Tổng bonus sau đó'**
  String get prestigeTotalBonus;

  /// No description provided for @prestigeTotalValue.
  ///
  /// In vi, this message translates to:
  /// **'+{percent}%'**
  String prestigeTotalValue(String percent);

  /// No description provided for @prestigeWarning.
  ///
  /// In vi, this message translates to:
  /// **'⚠️ Reset Xu, cấp nâng cấp và giai đoạn (perk kho Sao có thể giữ lại một phần).'**
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
  String prestigeConfirm(String stars);

  /// No description provided for @prestigeNotEnough.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đủ'**
  String get prestigeNotEnough;

  /// No description provided for @prestigeSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Nhượng quyền thành công! +{stars} ⭐'**
  String prestigeSuccess(String stars);

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

  /// No description provided for @htpNumberFormat.
  ///
  /// In vi, this message translates to:
  /// **'🔢 Số lớn viết tắt: K=nghìn, M=triệu, B=tỷ, T=nghìn tỷ, rồi tới aa, bb, cc... — mỗi bước gấp 1.000 lần bước trước.'**
  String get htpNumberFormat;

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
  String prestigeShopSpendable(String stars);

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

  /// No description provided for @prestigeOfflineName.
  ///
  /// In vi, this message translates to:
  /// **'Siêu offline'**
  String get prestigeOfflineName;

  /// No description provided for @prestigeOfflineDesc.
  ///
  /// In vi, this message translates to:
  /// **'+{percent}% thu nhập lúc vắng mỗi cấp'**
  String prestigeOfflineDesc(int percent);

  /// No description provided for @prestigeStartCashName.
  ///
  /// In vi, this message translates to:
  /// **'Vốn khởi nghiệp'**
  String get prestigeStartCashName;

  /// No description provided for @prestigeStartCashDesc.
  ///
  /// In vi, this message translates to:
  /// **'Nhận Xu ngay sau Nhượng quyền (tăng mỗi cấp)'**
  String get prestigeStartCashDesc;

  /// No description provided for @prestigeKeepStageName.
  ///
  /// In vi, this message translates to:
  /// **'Giữ giai đoạn'**
  String get prestigeKeepStageName;

  /// No description provided for @prestigeKeepStageDesc.
  ///
  /// In vi, this message translates to:
  /// **'Sau Nhượng quyền giữ thêm 1 giai đoạn mỗi cấp'**
  String get prestigeKeepStageDesc;

  /// No description provided for @prestigeDiscountName.
  ///
  /// In vi, this message translates to:
  /// **'Mua sỉ'**
  String get prestigeDiscountName;

  /// No description provided for @prestigeDiscountDesc.
  ///
  /// In vi, this message translates to:
  /// **'−{percent}% giá nâng cấp nguồn thu mỗi cấp'**
  String prestigeDiscountDesc(int percent);

  /// No description provided for @prestigeAutoBuyName.
  ///
  /// In vi, this message translates to:
  /// **'Tự động mua'**
  String get prestigeAutoBuyName;

  /// No description provided for @prestigeAutoBuyDesc.
  ///
  /// In vi, this message translates to:
  /// **'Mở khoá công tắc tự mua nguồn đáng mua nhất'**
  String get prestigeAutoBuyDesc;

  /// No description provided for @autoBuyLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tự động mua'**
  String get autoBuyLabel;

  /// No description provided for @prestigeStarCost.
  ///
  /// In vi, this message translates to:
  /// **'{cost} ⭐'**
  String prestigeStarCost(String cost);

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

  /// No description provided for @questRepeatEarn.
  ///
  /// In vi, this message translates to:
  /// **'Kiếm thêm {amount} Xu'**
  String questRepeatEarn(String amount);

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

  /// No description provided for @genDuongDen.
  ///
  /// In vi, this message translates to:
  /// **'Sữa tươi đường đen'**
  String get genDuongDen;

  /// No description provided for @genBrulee.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa nướng'**
  String get genBrulee;

  /// No description provided for @genCheeseFoam.
  ///
  /// In vi, this message translates to:
  /// **'Kem phô mai'**
  String get genCheeseFoam;

  /// No description provided for @genTraTraiCay.
  ///
  /// In vi, this message translates to:
  /// **'Trà trái cây'**
  String get genTraTraiCay;

  /// No description provided for @genBobaVang.
  ///
  /// In vi, this message translates to:
  /// **'Boba vàng'**
  String get genBobaVang;

  /// No description provided for @genGalaxy.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa ngân hà'**
  String get genGalaxy;

  /// No description provided for @genQuantumTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa lượng tử'**
  String get genQuantumTea;

  /// No description provided for @genAiTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa AI'**
  String get genAiTea;

  /// No description provided for @genParallelTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa vũ trụ song song'**
  String get genParallelTea;

  /// No description provided for @genNftTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa NFT'**
  String get genNftTea;

  /// No description provided for @genTimeTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa xuyên thời gian'**
  String get genTimeTea;

  /// No description provided for @genMultidimTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa đa chiều'**
  String get genMultidimTea;

  /// No description provided for @genBlackholeTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa hố đen'**
  String get genBlackholeTea;

  /// No description provided for @genLightTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa ánh sáng'**
  String get genLightTea;

  /// No description provided for @genRobotTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa robot'**
  String get genRobotTea;

  /// No description provided for @genHologramTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa hologram'**
  String get genHologramTea;

  /// No description provided for @genLegendTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa huyền thoại'**
  String get genLegendTea;

  /// No description provided for @genEternalTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa vĩnh cửu'**
  String get genEternalTea;

  /// No description provided for @stage4.
  ///
  /// In vi, this message translates to:
  /// **'Xưởng trà sữa nướng'**
  String get stage4;

  /// No description provided for @stage5.
  ///
  /// In vi, this message translates to:
  /// **'Nhà máy phô mai tươi'**
  String get stage5;

  /// No description provided for @stage6.
  ///
  /// In vi, this message translates to:
  /// **'Đế chế toàn cầu'**
  String get stage6;

  /// No description provided for @stage7.
  ///
  /// In vi, this message translates to:
  /// **'Niêm yết sàn chứng khoán'**
  String get stage7;

  /// No description provided for @stage8.
  ///
  /// In vi, this message translates to:
  /// **'Tập đoàn đa ngành'**
  String get stage8;

  /// No description provided for @stage9.
  ///
  /// In vi, this message translates to:
  /// **'Quỹ đầu tư toàn cầu'**
  String get stage9;

  /// No description provided for @stage10.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi cung ứng nông trại'**
  String get stage10;

  /// No description provided for @stage11.
  ///
  /// In vi, this message translates to:
  /// **'Đế chế công nghệ AI'**
  String get stage11;

  /// No description provided for @stage12.
  ///
  /// In vi, this message translates to:
  /// **'Huyền thoại trà sữa'**
  String get stage12;

  /// No description provided for @stage13.
  ///
  /// In vi, this message translates to:
  /// **'Học viện Trà Sữa'**
  String get stage13;

  /// No description provided for @stage14.
  ///
  /// In vi, this message translates to:
  /// **'Thành phố Trà Sữa'**
  String get stage14;

  /// No description provided for @stage15.
  ///
  /// In vi, this message translates to:
  /// **'Quốc gia Trà Sữa'**
  String get stage15;

  /// No description provided for @stage16.
  ///
  /// In vi, this message translates to:
  /// **'Liên minh thế giới'**
  String get stage16;

  /// No description provided for @stage17.
  ///
  /// In vi, this message translates to:
  /// **'Hành tinh Trà Sữa'**
  String get stage17;

  /// No description provided for @stage18.
  ///
  /// In vi, this message translates to:
  /// **'Chân lý Trà Sữa'**
  String get stage18;

  /// No description provided for @genAcademyTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa học viện'**
  String get genAcademyTea;

  /// No description provided for @genScholarTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa học giả'**
  String get genScholarTea;

  /// No description provided for @genCityTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa đô thị'**
  String get genCityTea;

  /// No description provided for @genMetroTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa siêu đô thị'**
  String get genMetroTea;

  /// No description provided for @genNationTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa quốc gia'**
  String get genNationTea;

  /// No description provided for @genTreatyTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa hiệp ước'**
  String get genTreatyTea;

  /// No description provided for @genUnionTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa liên minh'**
  String get genUnionTea;

  /// No description provided for @genWorldTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa hoà bình thế giới'**
  String get genWorldTea;

  /// No description provided for @genPlanetTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa hành tinh'**
  String get genPlanetTea;

  /// No description provided for @genTerraformTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa cải tạo hành tinh'**
  String get genTerraformTea;

  /// No description provided for @genTruthTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa chân lý'**
  String get genTruthTea;

  /// No description provided for @genUltimateTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa tối thượng'**
  String get genUltimateTea;

  /// No description provided for @settingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsTitle;

  /// No description provided for @settingsSound.
  ///
  /// In vi, this message translates to:
  /// **'Âm thanh'**
  String get settingsSound;

  /// No description provided for @settingsReset.
  ///
  /// In vi, this message translates to:
  /// **'Chơi lại từ đầu'**
  String get settingsReset;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xoá toàn bộ tiến trình và bắt đầu lại?'**
  String get settingsResetConfirm;

  /// No description provided for @navHome.
  ///
  /// In vi, this message translates to:
  /// **'Nhà'**
  String get navHome;

  /// No description provided for @navShop.
  ///
  /// In vi, this message translates to:
  /// **'Cửa hàng'**
  String get navShop;

  /// No description provided for @navPrestige.
  ///
  /// In vi, this message translates to:
  /// **'Nhượng quyền'**
  String get navPrestige;

  /// No description provided for @navAchievements.
  ///
  /// In vi, this message translates to:
  /// **'Thành tựu'**
  String get navAchievements;

  /// No description provided for @wheelName.
  ///
  /// In vi, this message translates to:
  /// **'Vòng quay may mắn 🎡'**
  String get wheelName;

  /// No description provided for @spinFree.
  ///
  /// In vi, this message translates to:
  /// **'Quay miễn phí'**
  String get spinFree;

  /// No description provided for @spinAd.
  ///
  /// In vi, this message translates to:
  /// **'Xem QC để quay'**
  String get spinAd;

  /// No description provided for @storyChapterLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chương {n}'**
  String storyChapterLabel(int n);

  /// No description provided for @storyContinue.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get storyContinue;

  /// No description provided for @storyChoosePrompt.
  ///
  /// In vi, this message translates to:
  /// **'Chọn hướng đi — không đổi lại được:'**
  String get storyChoosePrompt;

  /// No description provided for @storyLogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cốt truyện'**
  String get storyLogTitle;

  /// No description provided for @storyLogLocked.
  ///
  /// In vi, this message translates to:
  /// **'Chương chưa mở'**
  String get storyLogLocked;

  /// No description provided for @storyUnlockWhen.
  ///
  /// In vi, this message translates to:
  /// **'Mở khi: {cond}'**
  String storyUnlockWhen(String cond);

  /// No description provided for @storyUnlockAfter.
  ///
  /// In vi, this message translates to:
  /// **'Mở sau {chapter}'**
  String storyUnlockAfter(String chapter);

  /// No description provided for @storyCondFirst.
  ///
  /// In vi, this message translates to:
  /// **'{name} lần đầu'**
  String storyCondFirst(String name);

  /// No description provided for @storyCondRival.
  ///
  /// In vi, this message translates to:
  /// **'Đánh bại đối thủ'**
  String get storyCondRival;

  /// No description provided for @storyCondAscension.
  ///
  /// In vi, this message translates to:
  /// **'{name} lần {n}'**
  String storyCondAscension(int n, String name);

  /// No description provided for @storyCondM3.
  ///
  /// In vi, this message translates to:
  /// **'Qua màn {n} của {game}'**
  String storyCondM3(int n, String game);

  /// No description provided for @rivalEventTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đối thủ ra tay!'**
  String get rivalEventTitle;

  /// No description provided for @rivalEventIgnore.
  ///
  /// In vi, this message translates to:
  /// **'Phớt lờ'**
  String get rivalEventIgnore;

  /// No description provided for @rivalMeterAhead.
  ///
  /// In vi, this message translates to:
  /// **'Đang dẫn trước'**
  String get rivalMeterAhead;

  /// No description provided for @rivalMeterEven.
  ///
  /// In vi, this message translates to:
  /// **'Ngang sức'**
  String get rivalMeterEven;

  /// No description provided for @rivalMeterBehind.
  ///
  /// In vi, this message translates to:
  /// **'Đang bị lấn'**
  String get rivalMeterBehind;

  /// No description provided for @rivalResolvedSnack.
  ///
  /// In vi, this message translates to:
  /// **'Đã đối phó. Đối thủ chùn lại.'**
  String get rivalResolvedSnack;

  /// No description provided for @rivalIgnoredSnack.
  ///
  /// In vi, this message translates to:
  /// **'Bạn làm ngơ — đối thủ được đà lấn tới.'**
  String get rivalIgnoredSnack;

  /// No description provided for @navArena.
  ///
  /// In vi, this message translates to:
  /// **'Đấu Trường'**
  String get navArena;

  /// No description provided for @navCompete.
  ///
  /// In vi, this message translates to:
  /// **'Thi đấu'**
  String get navCompete;

  /// No description provided for @arenaTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đấu Trường'**
  String get arenaTitle;

  /// No description provided for @arenaIntro.
  ///
  /// In vi, this message translates to:
  /// **'Đấu 1v1 trong 60 giây — ai kiếm nhiều Xu hơn thắng!'**
  String get arenaIntro;

  /// No description provided for @arenaStartButton.
  ///
  /// In vi, this message translates to:
  /// **'Tìm đối thủ'**
  String get arenaStartButton;

  /// No description provided for @arenaModeTap.
  ///
  /// In vi, this message translates to:
  /// **'Đua chạm'**
  String get arenaModeTap;

  /// No description provided for @arenaModeMatch3.
  ///
  /// In vi, this message translates to:
  /// **'Trân Châu Rơi'**
  String get arenaModeMatch3;

  /// No description provided for @arenaMatch3Intro.
  ///
  /// In vi, this message translates to:
  /// **'Ghép 3 hình giống nhau trong 60 giây — ăn nhiều điểm hơn đối thủ thì thắng!'**
  String get arenaMatch3Intro;

  /// No description provided for @arenaMatch3Stuck.
  ///
  /// In vi, this message translates to:
  /// **'Hết nước đi!'**
  String get arenaMatch3Stuck;

  /// No description provided for @arenaQueueWaiting.
  ///
  /// In vi, this message translates to:
  /// **'Đang tìm đối thủ…'**
  String get arenaQueueWaiting;

  /// No description provided for @arenaCancelButton.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get arenaCancelButton;

  /// No description provided for @arenaTapButton.
  ///
  /// In vi, this message translates to:
  /// **'Chạm ly'**
  String get arenaTapButton;

  /// No description provided for @arenaResolving.
  ///
  /// In vi, this message translates to:
  /// **'Đang chốt trận…'**
  String get arenaResolving;

  /// No description provided for @arenaTierButton.
  ///
  /// In vi, this message translates to:
  /// **'Nâng ×2 ({cost} Xu)'**
  String arenaTierButton(String cost);

  /// No description provided for @arenaTimeLeft.
  ///
  /// In vi, this message translates to:
  /// **'Còn {seconds}s'**
  String arenaTimeLeft(int seconds);

  /// No description provided for @arenaOnlineCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} người đang online'**
  String arenaOnlineCount(int count);

  /// No description provided for @arenaYourScore.
  ///
  /// In vi, this message translates to:
  /// **'Điểm của bạn'**
  String get arenaYourScore;

  /// No description provided for @arenaOpponentScore.
  ///
  /// In vi, this message translates to:
  /// **'Đối thủ'**
  String get arenaOpponentScore;

  /// No description provided for @arenaResultWin.
  ///
  /// In vi, this message translates to:
  /// **'Bạn thắng! 🎉'**
  String get arenaResultWin;

  /// No description provided for @arenaResultLose.
  ///
  /// In vi, this message translates to:
  /// **'Bạn thua rồi'**
  String get arenaResultLose;

  /// No description provided for @arenaResultDraw.
  ///
  /// In vi, this message translates to:
  /// **'Hoà'**
  String get arenaResultDraw;

  /// No description provided for @arenaResultReward.
  ///
  /// In vi, this message translates to:
  /// **'+{gems} 💎'**
  String arenaResultReward(int gems);

  /// No description provided for @arenaCloseButton.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get arenaCloseButton;

  /// No description provided for @redeemTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã quà tặng'**
  String get redeemTitle;

  /// No description provided for @redeemHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã'**
  String get redeemHint;

  /// No description provided for @redeemButton.
  ///
  /// In vi, this message translates to:
  /// **'Nhận quà'**
  String get redeemButton;

  /// No description provided for @redeemSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Nhận thành công +{gems} 💎!'**
  String redeemSuccess(int gems);

  /// No description provided for @redeemAlreadyClaimed.
  ///
  /// In vi, this message translates to:
  /// **'Mã này bạn đã nhận rồi'**
  String get redeemAlreadyClaimed;

  /// No description provided for @redeemInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Mã không hợp lệ'**
  String get redeemInvalid;

  /// No description provided for @cloudSaveMenuTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sao lưu tiến trình'**
  String get cloudSaveMenuTitle;

  /// No description provided for @cloudSaveMenuLinked.
  ///
  /// In vi, this message translates to:
  /// **'Đã liên kết: {email}'**
  String cloudSaveMenuLinked(String email);

  /// No description provided for @cloudSaveMenuUnlinked.
  ///
  /// In vi, this message translates to:
  /// **'Chưa liên kết — có thể mất tiến trình nếu gỡ app'**
  String get cloudSaveMenuUnlinked;

  /// No description provided for @cloudSaveTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sao lưu tiến trình'**
  String get cloudSaveTitle;

  /// No description provided for @cloudSaveIntro.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết email để khôi phục được tiến trình nếu gỡ app hoặc đổi máy.'**
  String get cloudSaveIntro;

  /// No description provided for @cloudSaveEmailHint.
  ///
  /// In vi, this message translates to:
  /// **'Email của bạn'**
  String get cloudSaveEmailHint;

  /// No description provided for @cloudSaveSendCode.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã'**
  String get cloudSaveSendCode;

  /// No description provided for @cloudSaveCodeSentTo.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi mã xác nhận tới {email}'**
  String cloudSaveCodeSentTo(String email);

  /// No description provided for @cloudSaveCodeHint.
  ///
  /// In vi, this message translates to:
  /// **'Mã xác nhận'**
  String get cloudSaveCodeHint;

  /// No description provided for @cloudSaveVerify.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get cloudSaveVerify;

  /// No description provided for @cloudSaveChangeEmail.
  ///
  /// In vi, this message translates to:
  /// **'Đổi email khác'**
  String get cloudSaveChangeEmail;

  /// No description provided for @cloudSaveResend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã'**
  String get cloudSaveResend;

  /// No description provided for @cloudSaveResendIn.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã ({seconds}s)'**
  String cloudSaveResendIn(int seconds);

  /// No description provided for @cloudSaveConflictTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tìm thấy save khác trên cloud'**
  String get cloudSaveConflictTitle;

  /// No description provided for @cloudSaveConflictLocal.
  ///
  /// In vi, this message translates to:
  /// **'Máy này: {amount} Xu cả đời'**
  String cloudSaveConflictLocal(String amount);

  /// No description provided for @cloudSaveConflictCloud.
  ///
  /// In vi, this message translates to:
  /// **'Trên cloud: {amount} Xu cả đời'**
  String cloudSaveConflictCloud(String amount);

  /// No description provided for @cloudSaveRestoreButton.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục từ cloud'**
  String get cloudSaveRestoreButton;

  /// No description provided for @cloudSaveKeepLocalButton.
  ///
  /// In vi, this message translates to:
  /// **'Giữ máy này'**
  String get cloudSaveKeepLocalButton;

  /// No description provided for @cloudSaveLinkedStatus.
  ///
  /// In vi, this message translates to:
  /// **'Đã liên kết: {email}'**
  String cloudSaveLinkedStatus(String email);

  /// No description provided for @cloudSaveDisconnect.
  ///
  /// In vi, this message translates to:
  /// **'Ngắt kết nối'**
  String get cloudSaveDisconnect;

  /// No description provided for @cloudSaveRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get cloudSaveRetry;

  /// No description provided for @leaderboardMenuTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bảng xếp hạng'**
  String get leaderboardMenuTitle;

  /// No description provided for @leaderboardTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bảng xếp hạng'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardNicknameIntro.
  ///
  /// In vi, this message translates to:
  /// **'Đặt tên hiển thị trên bảng xếp hạng (đổi được sau):'**
  String get leaderboardNicknameIntro;

  /// No description provided for @leaderboardNicknameHint.
  ///
  /// In vi, this message translates to:
  /// **'Tên của bạn'**
  String get leaderboardNicknameHint;

  /// No description provided for @leaderboardSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get leaderboardSubmit;

  /// No description provided for @leaderboardYourRank.
  ///
  /// In vi, this message translates to:
  /// **'Hạng của bạn: #{rank}'**
  String leaderboardYourRank(int rank);

  /// No description provided for @leaderboardStars.
  ///
  /// In vi, this message translates to:
  /// **'{stars} ⭐'**
  String leaderboardStars(String stars);

  /// No description provided for @leaderboardEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ai trên bảng xếp hạng — là bạn đây!'**
  String get leaderboardEmpty;

  /// No description provided for @leaderboardRewardSnack.
  ///
  /// In vi, this message translates to:
  /// **'🎉 Bạn đang giữ hạng cao! +{gems} 💎'**
  String leaderboardRewardSnack(int gems);

  /// No description provided for @leaderboardRewardInfo.
  ///
  /// In vi, this message translates to:
  /// **'Top 1: {top1}💎 · Top 2-3: {top23}💎 · Top 4-10: {top410}💎 — mỗi 24 giờ nếu còn giữ hạng'**
  String leaderboardRewardInfo(int top1, int top23, int top410);

  /// No description provided for @leaderboardChangeName.
  ///
  /// In vi, this message translates to:
  /// **'Đổi tên'**
  String get leaderboardChangeName;

  /// No description provided for @leaderboardRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get leaderboardRetry;

  /// No description provided for @storySpeedrunMenuTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tốc độ hoàn thành'**
  String get storySpeedrunMenuTitle;

  /// No description provided for @storySpeedrunTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bảng xếp hạng tốc độ'**
  String get storySpeedrunTitle;

  /// No description provided for @storySpeedrunNotCompletedYet.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa hoàn thành cốt truyện — hoàn thành Chương 18 để được xếp hạng.'**
  String get storySpeedrunNotCompletedYet;

  /// No description provided for @storySpeedrunTabMain.
  ///
  /// In vi, this message translates to:
  /// **'Hồi 1'**
  String get storySpeedrunTabMain;

  /// No description provided for @storySpeedrunTabExt.
  ///
  /// In vi, this message translates to:
  /// **'Hồi 2'**
  String get storySpeedrunTabExt;

  /// No description provided for @storySpeedrunExtNotCompletedYet.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa hoàn thành Hồi 2 — hoàn thành Chương 28 để được xếp hạng.'**
  String get storySpeedrunExtNotCompletedYet;

  /// No description provided for @storySpeedrunTabExt2.
  ///
  /// In vi, this message translates to:
  /// **'Hồi 3'**
  String get storySpeedrunTabExt2;

  /// No description provided for @storySpeedrunExt2NotCompletedYet.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa hoàn thành Hồi 3 — hoàn thành Chương 36 để được xếp hạng.'**
  String get storySpeedrunExt2NotCompletedYet;

  /// No description provided for @accessoryMenuTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sưu tập'**
  String get accessoryMenuTitle;

  /// No description provided for @accessoryInventoryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kho phụ kiện'**
  String get accessoryInventoryTitle;

  /// No description provided for @accessoryInventoryOwned.
  ///
  /// In vi, this message translates to:
  /// **'Đã có {owned}/{total}'**
  String accessoryInventoryOwned(int owned, int total);

  /// No description provided for @accessoryRarityCommon.
  ///
  /// In vi, this message translates to:
  /// **'Thường'**
  String get accessoryRarityCommon;

  /// No description provided for @accessoryRarityRare.
  ///
  /// In vi, this message translates to:
  /// **'Hiếm'**
  String get accessoryRarityRare;

  /// No description provided for @accessoryRarityEpic.
  ///
  /// In vi, this message translates to:
  /// **'Sử thi'**
  String get accessoryRarityEpic;

  /// No description provided for @accessoryRarityLegendary.
  ///
  /// In vi, this message translates to:
  /// **'Huyền thoại'**
  String get accessoryRarityLegendary;

  /// No description provided for @accessoryLbTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bảng xếp hạng Sưu tập'**
  String get accessoryLbTitle;

  /// No description provided for @accessoryLbCount.
  ///
  /// In vi, this message translates to:
  /// **'{n} phụ kiện'**
  String accessoryLbCount(int n);

  /// No description provided for @accessoryLbTopTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhà Sưu Tầm'**
  String get accessoryLbTopTitle;

  /// No description provided for @accessoryLbTitleKing.
  ///
  /// In vi, this message translates to:
  /// **'Vua Phụ Kiện'**
  String get accessoryLbTitleKing;

  /// No description provided for @accessoryLbTitleMaster.
  ///
  /// In vi, this message translates to:
  /// **'Cao Thủ Sưu Tầm'**
  String get accessoryLbTitleMaster;

  /// No description provided for @accessoryLbEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa ai lên bảng. Sưu tập 1 món là có tên ngay!'**
  String get accessoryLbEmpty;

  /// No description provided for @accessoryLbNoOwned.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có phụ kiện nào — hoàn thành đủ 3 nhiệm vụ ngày để có cơ hội nhận.'**
  String get accessoryLbNoOwned;

  /// No description provided for @accessoryLbError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được bảng xếp hạng, thử lại sau nhé.'**
  String get accessoryLbError;

  /// No description provided for @accessoryMintLeaf.
  ///
  /// In vi, this message translates to:
  /// **'Lá bạc hà'**
  String get accessoryMintLeaf;

  /// No description provided for @accessoryCupcake.
  ///
  /// In vi, this message translates to:
  /// **'Bánh cupcake'**
  String get accessoryCupcake;

  /// No description provided for @accessoryCookie.
  ///
  /// In vi, this message translates to:
  /// **'Bánh quy'**
  String get accessoryCookie;

  /// No description provided for @accessoryPottedPlant.
  ///
  /// In vi, this message translates to:
  /// **'Chậu cây nhỏ'**
  String get accessoryPottedPlant;

  /// No description provided for @accessoryCandle.
  ///
  /// In vi, this message translates to:
  /// **'Nến thơm'**
  String get accessoryCandle;

  /// No description provided for @accessoryScarf.
  ///
  /// In vi, this message translates to:
  /// **'Khăn quàng'**
  String get accessoryScarf;

  /// No description provided for @accessoryKite.
  ///
  /// In vi, this message translates to:
  /// **'Diều giấy'**
  String get accessoryKite;

  /// No description provided for @accessoryCap.
  ///
  /// In vi, this message translates to:
  /// **'Mũ lưỡi trai'**
  String get accessoryCap;

  /// No description provided for @accessorySeashell.
  ///
  /// In vi, this message translates to:
  /// **'Vỏ sò'**
  String get accessorySeashell;

  /// No description provided for @accessoryMask.
  ///
  /// In vi, this message translates to:
  /// **'Mặt nạ'**
  String get accessoryMask;

  /// No description provided for @accessoryDrum.
  ///
  /// In vi, this message translates to:
  /// **'Trống nhỏ'**
  String get accessoryDrum;

  /// No description provided for @accessoryPalette.
  ///
  /// In vi, this message translates to:
  /// **'Bảng màu'**
  String get accessoryPalette;

  /// No description provided for @accessoryCrystalBall.
  ///
  /// In vi, this message translates to:
  /// **'Quả cầu pha lê'**
  String get accessoryCrystalBall;

  /// No description provided for @accessoryLantern.
  ///
  /// In vi, this message translates to:
  /// **'Đèn lồng cổ'**
  String get accessoryLantern;

  /// No description provided for @accessoryUnicorn.
  ///
  /// In vi, this message translates to:
  /// **'Kỳ lân nhỏ'**
  String get accessoryUnicorn;

  /// No description provided for @accessoryDragon.
  ///
  /// In vi, this message translates to:
  /// **'Rồng nhỏ'**
  String get accessoryDragon;

  /// No description provided for @accessoryBalloon.
  ///
  /// In vi, this message translates to:
  /// **'Bong bóng'**
  String get accessoryBalloon;

  /// No description provided for @accessoryBowtie.
  ///
  /// In vi, this message translates to:
  /// **'Nơ bướm'**
  String get accessoryBowtie;

  /// No description provided for @accessorySunglasses.
  ///
  /// In vi, this message translates to:
  /// **'Kính râm'**
  String get accessorySunglasses;

  /// No description provided for @accessoryUmbrella.
  ///
  /// In vi, this message translates to:
  /// **'Dù nhỏ'**
  String get accessoryUmbrella;

  /// No description provided for @accessoryTeapot.
  ///
  /// In vi, this message translates to:
  /// **'Ấm trà nhỏ'**
  String get accessoryTeapot;

  /// No description provided for @accessoryBell.
  ///
  /// In vi, this message translates to:
  /// **'Chuông nhỏ'**
  String get accessoryBell;

  /// No description provided for @accessoryRibbon.
  ///
  /// In vi, this message translates to:
  /// **'Ruy băng'**
  String get accessoryRibbon;

  /// No description provided for @accessoryBookmark.
  ///
  /// In vi, this message translates to:
  /// **'Bookmark xinh'**
  String get accessoryBookmark;

  /// No description provided for @accessoryWindChime.
  ///
  /// In vi, this message translates to:
  /// **'Chuông gió'**
  String get accessoryWindChime;

  /// No description provided for @accessoryClover.
  ///
  /// In vi, this message translates to:
  /// **'Cỏ bốn lá'**
  String get accessoryClover;

  /// No description provided for @accessoryBubble.
  ///
  /// In vi, this message translates to:
  /// **'Bong bóng xà phòng'**
  String get accessoryBubble;

  /// No description provided for @accessorySticker.
  ///
  /// In vi, this message translates to:
  /// **'Nhãn dán'**
  String get accessorySticker;

  /// No description provided for @accessoryYarn.
  ///
  /// In vi, this message translates to:
  /// **'Cuộn len'**
  String get accessoryYarn;

  /// No description provided for @accessoryFan.
  ///
  /// In vi, this message translates to:
  /// **'Quạt giấy'**
  String get accessoryFan;

  /// No description provided for @accessoryBasket.
  ///
  /// In vi, this message translates to:
  /// **'Giỏ mây'**
  String get accessoryBasket;

  /// No description provided for @accessoryBead.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi hạt'**
  String get accessoryBead;

  /// No description provided for @accessoryLadybug.
  ///
  /// In vi, this message translates to:
  /// **'Bọ rùa nhỏ'**
  String get accessoryLadybug;

  /// No description provided for @accessoryKey.
  ///
  /// In vi, this message translates to:
  /// **'Chìa khoá cổ'**
  String get accessoryKey;

  /// No description provided for @accessoryDiamondStone.
  ///
  /// In vi, this message translates to:
  /// **'Viên đá kim cương'**
  String get accessoryDiamondStone;

  /// No description provided for @accessoryMusicNote.
  ///
  /// In vi, this message translates to:
  /// **'Nốt nhạc nhỏ'**
  String get accessoryMusicNote;

  /// No description provided for @accessoryTelescope.
  ///
  /// In vi, this message translates to:
  /// **'Kính viễn vọng'**
  String get accessoryTelescope;

  /// No description provided for @accessoryAnchor.
  ///
  /// In vi, this message translates to:
  /// **'Mỏ neo'**
  String get accessoryAnchor;

  /// No description provided for @accessoryFeather.
  ///
  /// In vi, this message translates to:
  /// **'Lông vũ'**
  String get accessoryFeather;

  /// No description provided for @accessoryHourglass.
  ///
  /// In vi, this message translates to:
  /// **'Đồng hồ cát'**
  String get accessoryHourglass;

  /// No description provided for @accessoryMap.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ cổ'**
  String get accessoryMap;

  /// No description provided for @accessoryRing.
  ///
  /// In vi, this message translates to:
  /// **'Nhẫn nhỏ'**
  String get accessoryRing;

  /// No description provided for @accessoryMagicWand.
  ///
  /// In vi, this message translates to:
  /// **'Đũa phép'**
  String get accessoryMagicWand;

  /// No description provided for @accessoryTrident.
  ///
  /// In vi, this message translates to:
  /// **'Đinh ba biển cả'**
  String get accessoryTrident;

  /// No description provided for @accessoryPeacock.
  ///
  /// In vi, this message translates to:
  /// **'Công nhỏ'**
  String get accessoryPeacock;

  /// No description provided for @accessoryComet.
  ///
  /// In vi, this message translates to:
  /// **'Sao chổi'**
  String get accessoryComet;

  /// No description provided for @accessoryButterfly.
  ///
  /// In vi, this message translates to:
  /// **'Bướm pha lê'**
  String get accessoryButterfly;

  /// No description provided for @accessoryAngelWing.
  ///
  /// In vi, this message translates to:
  /// **'Cánh thiên thần'**
  String get accessoryAngelWing;

  /// No description provided for @accessoryPhoenix.
  ///
  /// In vi, this message translates to:
  /// **'Phượng hoàng lửa'**
  String get accessoryPhoenix;

  /// No description provided for @accessoryGalaxy.
  ///
  /// In vi, this message translates to:
  /// **'Dải ngân hà'**
  String get accessoryGalaxy;

  /// No description provided for @marketTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chợ Phụ kiện'**
  String get marketTitle;

  /// No description provided for @marketTabBrowse.
  ///
  /// In vi, this message translates to:
  /// **'Chợ'**
  String get marketTabBrowse;

  /// No description provided for @marketTabMine.
  ///
  /// In vi, this message translates to:
  /// **'Của tôi'**
  String get marketTabMine;

  /// No description provided for @marketRecentSalesHeader.
  ///
  /// In vi, this message translates to:
  /// **'Vừa bán'**
  String get marketRecentSalesHeader;

  /// No description provided for @marketMerchantTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thương gia tuần'**
  String get marketMerchantTitle;

  /// No description provided for @marketFilterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get marketFilterAll;

  /// No description provided for @marketFilterMissing.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có'**
  String get marketFilterMissing;

  /// No description provided for @marketSortPriceAsc.
  ///
  /// In vi, this message translates to:
  /// **'Giá thấp'**
  String get marketSortPriceAsc;

  /// No description provided for @marketBadgeNew.
  ///
  /// In vi, this message translates to:
  /// **'MỚI'**
  String get marketBadgeNew;

  /// No description provided for @marketNeedMore.
  ///
  /// In vi, this message translates to:
  /// **'Thiếu {n} Xu Chợ'**
  String marketNeedMore(int n);

  /// No description provided for @marketNoFilterResults.
  ///
  /// In vi, this message translates to:
  /// **'Không có món nào khớp bộ lọc.'**
  String get marketNoFilterResults;

  /// No description provided for @marketWallet.
  ///
  /// In vi, this message translates to:
  /// **'{n} Xu Chợ'**
  String marketWallet(int n);

  /// No description provided for @marketError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được Chợ, thử lại sau nhé.'**
  String get marketError;

  /// No description provided for @marketEmptyBrowse.
  ///
  /// In vi, this message translates to:
  /// **'Chợ chưa có ai đăng bán gì.'**
  String get marketEmptyBrowse;

  /// No description provided for @marketBuyButton.
  ///
  /// In vi, this message translates to:
  /// **'Mua'**
  String get marketBuyButton;

  /// No description provided for @marketBoughtToast.
  ///
  /// In vi, this message translates to:
  /// **'Đã mua!'**
  String get marketBoughtToast;

  /// No description provided for @marketConfirmBuy.
  ///
  /// In vi, this message translates to:
  /// **'Mua với giá {price} Xu Chợ?'**
  String marketConfirmBuy(int price);

  /// No description provided for @marketPriceTag.
  ///
  /// In vi, this message translates to:
  /// **'{price} Xu Chợ'**
  String marketPriceTag(int price);

  /// No description provided for @marketMyListingsHeader.
  ///
  /// In vi, this message translates to:
  /// **'Đang đăng bán'**
  String get marketMyListingsHeader;

  /// No description provided for @marketEmptyMine.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa đăng bán món nào.'**
  String get marketEmptyMine;

  /// No description provided for @marketCancelButton.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ đăng'**
  String get marketCancelButton;

  /// No description provided for @marketCancelledToast.
  ///
  /// In vi, this message translates to:
  /// **'Đã huỷ đăng.'**
  String get marketCancelledToast;

  /// No description provided for @marketSellableHeader.
  ///
  /// In vi, this message translates to:
  /// **'Phụ kiện có thể đăng bán'**
  String get marketSellableHeader;

  /// No description provided for @marketEmptySellable.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có phụ kiện nào để đăng bán.'**
  String get marketEmptySellable;

  /// No description provided for @marketListedToast.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng bán!'**
  String get marketListedToast;

  /// No description provided for @marketListButton.
  ///
  /// In vi, this message translates to:
  /// **'Đăng bán'**
  String get marketListButton;

  /// No description provided for @marketPriceLabel.
  ///
  /// In vi, this message translates to:
  /// **'Giá (Xu Chợ)'**
  String get marketPriceLabel;

  /// No description provided for @marketListFeeNote.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ nhận {proceeds} Xu Chợ sau khi trừ phí sàn 1% (−{fee})'**
  String marketListFeeNote(int proceeds, int fee);

  /// No description provided for @marketConvertButton.
  ///
  /// In vi, this message translates to:
  /// **'Đổi'**
  String get marketConvertButton;

  /// No description provided for @marketConvertTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đổi lấy Xu Chợ'**
  String get marketConvertTitle;

  /// No description provided for @marketConvertAmountLabel.
  ///
  /// In vi, this message translates to:
  /// **'Số Xu Chợ muốn đổi'**
  String get marketConvertAmountLabel;

  /// No description provided for @marketConvertCostGems.
  ///
  /// In vi, this message translates to:
  /// **'Tốn: {cost} 💎'**
  String marketConvertCostGems(String cost);

  /// No description provided for @marketConvertCostMoney.
  ///
  /// In vi, this message translates to:
  /// **'Tốn: {cost} 💰'**
  String marketConvertCostMoney(String cost);

  /// No description provided for @marketConvertSuccessToast.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi!'**
  String get marketConvertSuccessToast;

  /// No description provided for @marketConvertFailToast.
  ///
  /// In vi, this message translates to:
  /// **'Đổi thất bại — không đủ số dư hoặc lỗi mạng.'**
  String get marketConvertFailToast;

  /// No description provided for @storySpeedrunEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ai hoàn thành cốt truyện — là bạn đây!'**
  String get storySpeedrunEmpty;

  /// No description provided for @arenaLeaderboardMenuTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bảng xếp hạng PK'**
  String get arenaLeaderboardMenuTitle;

  /// No description provided for @arenaLeaderboardTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bảng xếp hạng PK'**
  String get arenaLeaderboardTitle;

  /// No description provided for @arenaLeaderboardNotPlayedYet.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa đấu trận nào — thắng 1 trận Đấu Trường để xuất hiện ở đây.'**
  String get arenaLeaderboardNotPlayedYet;

  /// No description provided for @arenaLeaderboardRecord.
  ///
  /// In vi, this message translates to:
  /// **'{wins} thắng - {losses} bại'**
  String arenaLeaderboardRecord(int wins, int losses);

  /// No description provided for @ascensionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kỷ Nguyên'**
  String get ascensionTitle;

  /// No description provided for @ascensionOpen.
  ///
  /// In vi, this message translates to:
  /// **'Kỷ Nguyên ⏳'**
  String get ascensionOpen;

  /// No description provided for @ascensionIntro.
  ///
  /// In vi, this message translates to:
  /// **'Đổi toàn bộ Sao và perk Kho Sao lấy ⏳ Điểm Kỷ Nguyên — perk vĩnh viễn mạnh hơn. Bạn sẽ chơi lại từ đầu.'**
  String get ascensionIntro;

  /// No description provided for @ascensionProgress.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ tới ngưỡng mở: {percent}%'**
  String ascensionProgress(int percent);

  /// No description provided for @ascensionPointsNow.
  ///
  /// In vi, this message translates to:
  /// **'Điểm đang có'**
  String get ascensionPointsNow;

  /// No description provided for @ascensionPointsGain.
  ///
  /// In vi, this message translates to:
  /// **'Nhận nếu Kỷ Nguyên hoá'**
  String get ascensionPointsGain;

  /// No description provided for @ascensionPointsValue.
  ///
  /// In vi, this message translates to:
  /// **'{points} ⏳'**
  String ascensionPointsValue(int points);

  /// No description provided for @ascensionWarning.
  ///
  /// In vi, this message translates to:
  /// **'⚠️ Reset Sao, mọi perk Kho Sao, Xu, cấp nâng cấp và giai đoạn. Giữ 💎, thành tựu, cốt truyện. Sao trên bảng xếp hạng về 0 (thứ hạng theo tổng thu nhập không đổi).'**
  String get ascensionWarning;

  /// No description provided for @ascensionConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Kỷ Nguyên hoá (+{points} ⏳)'**
  String ascensionConfirm(int points);

  /// No description provided for @ascensionNotEnough.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đủ điều kiện'**
  String get ascensionNotEnough;

  /// No description provided for @ascensionSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu Kỷ Nguyên mới! +{points} ⏳'**
  String ascensionSuccess(int points);

  /// No description provided for @ascensionShopTitle.
  ///
  /// In vi, this message translates to:
  /// **'Perk Kỷ Nguyên ⏳'**
  String get ascensionShopTitle;

  /// No description provided for @ascensionShopSpendable.
  ///
  /// In vi, this message translates to:
  /// **'Còn {points} ⏳ để tiêu'**
  String ascensionShopSpendable(int points);

  /// No description provided for @ascensionCost.
  ///
  /// In vi, this message translates to:
  /// **'{cost} ⏳'**
  String ascensionCost(int cost);

  /// No description provided for @ascensionMaxed.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa'**
  String get ascensionMaxed;

  /// No description provided for @ascensionIncomeName.
  ///
  /// In vi, this message translates to:
  /// **'Nguồn năng lượng'**
  String get ascensionIncomeName;

  /// No description provided for @ascensionIncomeDesc.
  ///
  /// In vi, this message translates to:
  /// **'+{percent}% thu nhập mỗi cấp'**
  String ascensionIncomeDesc(int percent);

  /// No description provided for @ascensionStarBonusName.
  ///
  /// In vi, this message translates to:
  /// **'Ngôi sao rực rỡ'**
  String get ascensionStarBonusName;

  /// No description provided for @ascensionStarBonusDesc.
  ///
  /// In vi, this message translates to:
  /// **'+{percent}% sức mạnh mỗi Sao, mỗi cấp'**
  String ascensionStarBonusDesc(int percent);

  /// No description provided for @ascensionStarGainName.
  ///
  /// In vi, this message translates to:
  /// **'Tinh tú dồi dào'**
  String get ascensionStarGainName;

  /// No description provided for @ascensionStarGainDesc.
  ///
  /// In vi, this message translates to:
  /// **'+{percent}% tốc độ tích Sao, mỗi cấp'**
  String ascensionStarGainDesc(int percent);

  /// No description provided for @achAscend.
  ///
  /// In vi, this message translates to:
  /// **'Kỷ Nguyên hoá lần đầu'**
  String get achAscend;

  /// No description provided for @dailyQuestsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhiệm vụ ngày'**
  String get dailyQuestsTitle;

  /// No description provided for @dailyQuestsChip.
  ///
  /// In vi, this message translates to:
  /// **'Nhiệm vụ'**
  String get dailyQuestsChip;

  /// No description provided for @dailyQuestsBonusLabel.
  ///
  /// In vi, this message translates to:
  /// **'Xong cả 3 nhiệm vụ'**
  String get dailyQuestsBonusLabel;

  /// No description provided for @dailyQuestsResetsIn.
  ///
  /// In vi, this message translates to:
  /// **'Đổi nhiệm vụ sau {time}'**
  String dailyQuestsResetsIn(Object time);

  /// No description provided for @dailyQuestClaimed.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận'**
  String get dailyQuestClaimed;

  /// No description provided for @dqTap.
  ///
  /// In vi, this message translates to:
  /// **'Chạm ly {n} lần'**
  String dqTap(int n);

  /// No description provided for @dqBuy.
  ///
  /// In vi, this message translates to:
  /// **'Nâng cấp {n} lần'**
  String dqBuy(int n);

  /// No description provided for @dqEarn.
  ///
  /// In vi, this message translates to:
  /// **'Kiếm {amount} Xu'**
  String dqEarn(Object amount);

  /// No description provided for @dqCat.
  ///
  /// In vi, this message translates to:
  /// **'Bắt mèo Mưa vàng'**
  String get dqCat;

  /// No description provided for @dqVip.
  ///
  /// In vi, this message translates to:
  /// **'Phục vụ khách VIP'**
  String get dqVip;

  /// No description provided for @dqSpin.
  ///
  /// In vi, this message translates to:
  /// **'Quay vòng quay may mắn'**
  String get dqSpin;

  /// No description provided for @notifyOfflineFullTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kho Xu đã đầy! 🧋'**
  String get notifyOfflineFullTitle;

  /// No description provided for @notifyOfflineFullBody.
  ///
  /// In vi, this message translates to:
  /// **'Quán ngừng tích Xu mất rồi — ghé nhận và mở ca mới nào.'**
  String get notifyOfflineFullBody;

  /// No description provided for @notifyDailyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ngày mới, việc mới 📋'**
  String get notifyDailyTitle;

  /// No description provided for @notifyDailyBody.
  ///
  /// In vi, this message translates to:
  /// **'Điểm danh, 1 lượt quay miễn phí và 3 nhiệm vụ hôm nay đang chờ bạn.'**
  String get notifyDailyBody;

  /// No description provided for @notifyD3Title.
  ///
  /// In vi, this message translates to:
  /// **'Quán vắng bạn 3 ngày rồi 🧋'**
  String get notifyD3Title;

  /// No description provided for @notifyD3Body.
  ///
  /// In vi, this message translates to:
  /// **'Kho Xu đã đầy từ lâu, đơn hàng vẫn đang chờ — ghé qua thu dọn nhé.'**
  String get notifyD3Body;

  /// No description provided for @notifyD7Title.
  ///
  /// In vi, this message translates to:
  /// **'Đã 1 tuần rồi đó! 🧋'**
  String get notifyD7Title;

  /// No description provided for @notifyD7Body.
  ///
  /// In vi, this message translates to:
  /// **'Kỷ Nguyên, Trân Châu Rơi và bao nhiêu thứ mới đang chờ bạn quay lại.'**
  String get notifyD7Body;

  /// No description provided for @eventBannerLabel.
  ///
  /// In vi, this message translates to:
  /// **'🎉 Sự kiện: ×{mult} thu nhập! Còn {timeLeft}'**
  String eventBannerLabel(String mult, String timeLeft);

  /// No description provided for @navMatch3.
  ///
  /// In vi, this message translates to:
  /// **'Trân châu'**
  String get navMatch3;

  /// No description provided for @m3Title.
  ///
  /// In vi, this message translates to:
  /// **'Trân Châu Rơi'**
  String get m3Title;

  /// No description provided for @m3Level.
  ///
  /// In vi, this message translates to:
  /// **'Màn {n}'**
  String m3Level(int n);

  /// No description provided for @m3Locked.
  ///
  /// In vi, this message translates to:
  /// **'Chưa mở'**
  String get m3Locked;

  /// No description provided for @m3MovesLeft.
  ///
  /// In vi, this message translates to:
  /// **'Còn {n} nước'**
  String m3MovesLeft(int n);

  /// No description provided for @m3Score.
  ///
  /// In vi, this message translates to:
  /// **'Điểm'**
  String get m3Score;

  /// No description provided for @m3Win.
  ///
  /// In vi, this message translates to:
  /// **'Qua màn!'**
  String get m3Win;

  /// No description provided for @m3Lose.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đạt mục tiêu'**
  String get m3Lose;

  /// No description provided for @m3Retry.
  ///
  /// In vi, this message translates to:
  /// **'Chơi lại'**
  String get m3Retry;

  /// No description provided for @m3Next.
  ///
  /// In vi, this message translates to:
  /// **'Màn sau'**
  String get m3Next;

  /// No description provided for @m3Back.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách màn'**
  String get m3Back;

  /// No description provided for @m3Reward.
  ///
  /// In vi, this message translates to:
  /// **'Thưởng'**
  String get m3Reward;

  /// No description provided for @m3NoReward.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận thưởng màn này rồi'**
  String get m3NoReward;

  /// No description provided for @m3AdMoves.
  ///
  /// In vi, this message translates to:
  /// **'Xem QC: +{n} nước'**
  String m3AdMoves(int n);

  /// No description provided for @m3KeepPlaying.
  ///
  /// In vi, this message translates to:
  /// **'Chơi nốt'**
  String get m3KeepPlaying;

  /// No description provided for @m3Pause.
  ///
  /// In vi, this message translates to:
  /// **'Tạm nghỉ'**
  String get m3Pause;

  /// No description provided for @m3GoalReached.
  ///
  /// In vi, this message translates to:
  /// **'Đạt mục tiêu!'**
  String get m3GoalReached;

  /// No description provided for @m3NeedScore.
  ///
  /// In vi, this message translates to:
  /// **'Còn thiếu {n} điểm nữa là {star}★'**
  String m3NeedScore(String n, int star);

  /// No description provided for @m3NeedCollect.
  ///
  /// In vi, this message translates to:
  /// **'Còn thiếu {n} ô {icon} nữa là {star}★'**
  String m3NeedCollect(int n, String icon, int star);

  /// No description provided for @m3HowToTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chơi Trân Châu Rơi'**
  String get m3HowToTitle;

  /// No description provided for @m3HtpSwap.
  ///
  /// In vi, this message translates to:
  /// **'🔄 Đổi hai ô KỀ NHAU (chạm ô này rồi chạm ô kia, hoặc vuốt) để xếp 3 ô cùng loại trở lên. Nước không tạo được dãy thì không tính.'**
  String get m3HtpSwap;

  /// No description provided for @m3HtpGoal.
  ///
  /// In vi, this message translates to:
  /// **'🎯 Mỗi màn có một mục tiêu: đạt đủ điểm, hoặc thu thập đủ số ô của một loại. Mục tiêu hiện ngay trên thanh đầu màn.'**
  String get m3HtpGoal;

  /// No description provided for @m3HtpMoves.
  ///
  /// In vi, this message translates to:
  /// **'👣 Số nước có hạn. Hết nước là kết thúc màn, nên ưu tiên nước ăn được nhiều ô.'**
  String get m3HtpMoves;

  /// No description provided for @m3HtpChain.
  ///
  /// In vi, this message translates to:
  /// **'⛓️ Ô bị xoá làm các ô trên rơi xuống; nếu chúng lại tạo dãy mới thì nổ dây chuyền — bước sau ăn điểm gấp bội.'**
  String get m3HtpChain;

  /// No description provided for @m3HtpSpecial.
  ///
  /// In vi, this message translates to:
  /// **'💥 Xếp 4 ô tạo BOM CHÉO (nổ cả hàng và cột). Xếp từ 5 ô tạo BOM MÀU 🌈 (nổ sạch mọi ô cùng loại). Ghép chúng như ô thường để kích nổ.'**
  String get m3HtpSpecial;

  /// No description provided for @m3HtpStars.
  ///
  /// In vi, this message translates to:
  /// **'⭐ Ba ngôi sao trên thanh là ba mốc. Chạm mốc đầu là qua màn; muốn thêm sao thì bấm \"Chơi nốt\" để dùng nốt số nước còn lại.'**
  String get m3HtpStars;

  /// No description provided for @m3HtpReward.
  ///
  /// In vi, this message translates to:
  /// **'🎁 Thưởng chỉ trả LẦN ĐẦU đạt mỗi mốc sao. Chơi lại màn cũ để luyện thì không nhận thêm.'**
  String get m3HtpReward;

  /// No description provided for @m3LbTitle.
  ///
  /// In vi, this message translates to:
  /// **'BXH Trân Châu Rơi'**
  String get m3LbTitle;

  /// No description provided for @m3LbStars.
  ///
  /// In vi, this message translates to:
  /// **'{n} ⭐'**
  String m3LbStars(int n);

  /// No description provided for @m3LbEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ai lên bảng. Chơi vài màn là bạn đứng đầu!'**
  String get m3LbEmpty;

  /// No description provided for @m3LbNoStars.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có sao nào — qua một màn là được lên bảng.'**
  String get m3LbNoStars;

  /// No description provided for @m3LbLevels.
  ///
  /// In vi, this message translates to:
  /// **'{n} màn'**
  String m3LbLevels(int n);

  /// No description provided for @m3LbError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được bảng xếp hạng, thử lại sau nhé.'**
  String get m3LbError;
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
