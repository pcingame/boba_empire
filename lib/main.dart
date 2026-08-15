import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'l10n/locale_provider.dart';

import 'ads/ad_bootstrap.dart';
import 'ads/ad_service.dart';
import 'ads/real_ad_service.dart';
import 'audio/audio_service.dart';
import 'audio/flame_audio_service.dart';
import 'iap/http_receipt_verifier.dart';
import 'iap/iap_config.dart';
import 'iap/iap_service.dart';
import 'iap/real_iap_service.dart';
import 'iap/receipt_verifier.dart';
import 'state/game_providers.dart';
import 'ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final audio = FlameAudioService();
  unawaited(audio.preload());

  // AdMob và IAP là plugin mobile-only; chỉ bật trên Android/iOS, các nền khác
  // giữ StubAdService mặc định để không crash.
  final overrides = [
    sharedPreferencesProvider.overrideWithValue(prefs),
    audioServiceProvider.overrideWithValue(audio),
  ];
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await AdBootstrap.initialize();
    overrides.add(adServiceProvider.overrideWithValue(RealAdService()));
    // Có cấu hình endpoint (qua --dart-define IAP_VERIFY_ENDPOINT) thì xác thực
    // biên nhận phía server trước khi trao; rỗng thì giữ client-only.
    final ReceiptVerifier verifier = IapConfig.receiptVerifyEndpoint.isEmpty
        ? const NoopReceiptVerifier()
        : HttpReceiptVerifier(Uri.parse(IapConfig.receiptVerifyEndpoint));
    overrides.add(
      iapServiceProvider.overrideWithValue(RealIapService(verifier: verifier)),
    );
  }

  runApp(
    ProviderScope(overrides: overrides, child: const BobaEmpireApp()),
  );
}

class BobaEmpireApp extends ConsumerWidget {
  const BobaEmpireApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Đổi tông màu theo giai đoạn (xe đẩy → kiosk → cafe). `select` để chỉ đổi
    // theme khi stage đổi, không rebuild theo từng tick tiền.
    final stage =
        ref.watch(gameControllerProvider.select((s) => s.stage));
    final seed = _seedForStage(stage);
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      locale: ref.watch(localeProvider),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: ThemeMode.system,
      theme: _buildTheme(Brightness.light, seed),
      darkTheme: _buildTheme(Brightness.dark, seed),
      home: const HomePage(),
    );
  }

  // Seed màu theo giai đoạn: nâu trà sữa → matcha → taro (cao cấp dần).
  static Color _seedForStage(int stage) => switch (stage) {
        2 => const Color(0xFF3E7C68), // matcha (kiosk)
        3 => const Color(0xFF7A4FA3), // taro (chuỗi cafe)
        _ => const Color(0xFF8D5524), // nâu trà sữa (xe đẩy)
      };

  // Chủ đề trà sữa, [seed] đổi theo giai đoạn. Font Fredoka cho bề mặt hiển thị
  // lớn; body giữ font hệ thống (fallback) để đủ glyph mọi ngôn ngữ.
  static ThemeData _buildTheme(Brightness brightness, Color seed) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    // Nút "chunky đất sét": bo tròn dày, chữ đậm, có độ nổi nhẹ; dialog bo tròn
    // to — phong cách casual game (claymorphism).
    final buttonShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    const buttonText = TextStyle(fontWeight: FontWeight.w700, fontSize: 15);
    const buttonPad = EdgeInsets.symmetric(horizontal: 18, vertical: 12);
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: buttonShape,
          padding: buttonPad,
          textStyle: buttonText,
          elevation: 2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: buttonShape,
          padding: buttonPad,
          textStyle: buttonText,
          elevation: 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: buttonText),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );

    const fallback = ['Roboto'];
    final display = base.textTheme
        .apply(fontFamily: 'Fredoka', fontFamilyFallback: fallback);
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: display.displayLarge,
        displayMedium: display.displayMedium,
        displaySmall: display.displaySmall,
        headlineLarge: display.headlineLarge,
        headlineMedium: display.headlineMedium,
        headlineSmall: display.headlineSmall,
        titleLarge: display.titleLarge,
      ),
    );
  }
}
