import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'arena/arena_config.dart';
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
  // Đấu Trường (Arena PvP) — xem PROPOSAL_ARENA_PVP.md. Khởi tạo sớm, trước
  // cả `runApp`, để `ArenaRepository`/`ArenaController` luôn có sẵn
  // `Supabase.instance.client` khi người chơi mở màn Đấu Trường.
  await Supabase.initialize(
    url: ArenaConfig.supabaseUrl,
    publishableKey: ArenaConfig.supabasePublishableKey,
  );
  final prefs = await SharedPreferences.getInstance();
  audioMuted = !(prefs.getBool('sound_on') ?? true); // khôi phục cài đặt tắt tiếng
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

  // Seed màu theo giai đoạn: caramel → matcha → taro → đường đen → dâu phô mai →
  // vàng đế chế. Cân bằng lại để độ tươi/độ sáng đồng đều, hue đi vòng cung
  // (ấm → lục → tím → cam → hồng → vàng) và KHÔNG tụt lùi ở GĐ4 (trước là nâu
  // tối gần trùng GĐ1). GĐ1 nhạt & dịu (khởi đầu khiêm tốn), các GĐ sau tươi
  // và rực dần (cảm giác lên đời).
  static Color _seedForStage(int stage) => switch (stage) {
        2 => const Color(0xFF5B9137), // matcha (kiosk) — lục ngả vàng
        3 => const Color(0xFF7B4FBB), // taro (chuỗi cafe) — tím lavender
        4 => const Color(0xFFB87029), // đường đen nướng — hổ phách rực
        5 => const Color(0xFFC85A7B), // dâu / phô mai — hồng rose
        6 => const Color(0xFFC0982F), // vàng gold đế chế — vàng ấm sâu
        _ => const Color(0xFFA06A45), // trà sữa caramel (xe đẩy) — nâu dịu
      };

  // Chủ đề trà sữa, [seed] đổi theo giai đoạn. Font Baloo 2 cho bề mặt hiển thị
  // lớn (fallback Mitr cho tiếng Thái); body giữ font hệ thống để đủ mọi ngôn ngữ.
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

    const fallback = ['Mitr', 'Roboto'];
    final display = base.textTheme
        .apply(fontFamily: 'Baloo 2', fontFamilyFallback: fallback);
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
