import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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

  /// No description provided for @iapGemsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Túi Kim Cương'**
  String get iapGemsTitle;

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
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
