import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:upgrader/upgrader.dart';

import 'arena/arena_config.dart';
import 'firebase_options.dart';
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
import 'data/remote_balance.dart';
import 'state/game_providers.dart';
import 'ui/home_page.dart';
import 'ui/widgets/phone_width.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Crashlytics chỉ cấu hình cho Android/iOS (xem lib/firebase_options.dart) —
  // web/desktop giữ nguyên, không khởi tạo Firebase.
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Chỉ báo cáo crash ở bản release — bản debug không cần làm nhiễu console.
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(kReleaseMode);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    // Nút vặn cân bằng tải từ Remote Config — KHÔNG await (gọi mạng), giá trị
    // biên dịch sẵn dùng ngay, bản mới áp khi về tới.
    unawaited(RemoteBalance.init());
  }
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
    // KHÔNG await: init AdMob gồm form đồng ý UMP (hiện dialog, chờ người bấm)
    // và gọi mạng — await ở đây là màn hình trắng vài giây trước frame đầu.
    // Chạy song song, chỉ RealAdService chờ nó xong mới nạp quảng cáo.
    final adsReady = AdBootstrap.ready = AdBootstrap.initialize();
    overrides.add(
      adServiceProvider.overrideWithValue(RealAdService(ready: adsReady)),
    );
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
      // Kẹp bề ngang hộp thoại cho máy tablet bằng insetPadding của theme —
      // MỘT chỗ, phủ cả 19 file có showDialog (iPad Pro 13" trước khi sửa:
      // hộp Nhượng quyền rộng 952dp, Thành tựu 952x1328).
      //
      // KHÔNG bọc `child` bằng PhoneWidth ở đây, dù nhìn thì gọn hơn: `builder`
      // nằm NGOÀI Navigator nên lớp chặn (ModalBarrier) của hộp thoại cũng bị
      // kẹp theo — đo được 560dp trên màn 1032dp, tức bấm ra vùng trống hai
      // bên KHÔNG đóng được hộp thoại và lớp mờ chỉ phủ giữa màn. Các trang tự
      // kẹp lấy bằng PhoneWidth trong Scaffold của mình.
      builder: (context, child) => LayoutBuilder(
        // Lấy bề ngang từ RÀNG BUỘC THẬT, không phải MediaQuery: trong
        // flutter_test, `setSurfaceSize` đổi kích thước dựng hình nhưng
        // MediaQuery vẫn báo 800dp — đo được lúc gỡ bug này (lớp chặn 1032dp
        // mà MediaQuery 800dp trong cùng một cây). LayoutBuilder luôn khớp với
        // thứ thật sự được vẽ, và cũng đúng khi app bị co ở Split View.
        builder: (context, box) {
          final t = Theme.of(context);
          final pad = ((box.maxWidth - kPhoneMaxWidth) / 2)
              .clamp(40.0, double.infinity);
          return Theme(
            data: t.copyWith(
              dialogTheme: t.dialogTheme.copyWith(
                insetPadding:
                    EdgeInsets.symmetric(horizontal: pad, vertical: 24),
              ),
            ),
            child: ColoredBox(
              // Nền phủ hết màn, nếu không hai bên dải kẹp lòi nền trống.
              color: t.colorScheme.surface,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
      // Chỉ bản release: debug/test không gọi mạng hỏi store.
      home: kReleaseMode
          ? UpgradeAlert(child: const HomePage())
          : const HomePage(),
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
        // Giai đoạn 7-18 (mở rộng thế giới): hue đi tiếp vòng cung, giữ độ tươi
        // tương đương GĐ2-6 để không lệch tông.
        7 => const Color(0xFF3F7F9E), // sàn chứng khoán — xanh thép
        8 => const Color(0xFF6B6FBF), // tập đoàn đa ngành — xanh chàm
        9 => const Color(0xFF3E9E88), // quỹ đầu tư toàn cầu — xanh ngọc
        10 => const Color(0xFF7C9A2E), // nông trại — lục cỏ úa
        11 => const Color(0xFF3B8FD1), // đế chế AI — xanh điện
        12 => const Color(0xFFD1823B), // huyền thoại — cam hổ phách
        13 => const Color(0xFF8F5FB5), // học viện — tím thư viện
        14 => const Color(0xFF5B7FA8), // thành phố — xanh đêm phố
        15 => const Color(0xFFB5544F), // quốc gia — đỏ gạch
        16 => const Color(0xFF3FA37D), // liên minh — xanh hoà bình
        17 => const Color(0xFF4F6FC4), // hành tinh — xanh đại dương
        18 => const Color(0xFFD4A62A), // chân lý — vàng kim
        _ => const Color(0xFFA06A45), // trà sữa caramel (xe đẩy) — nâu dịu
      };

  // Chủ đề trà sữa, [seed] đổi theo giai đoạn. Font Baloo 2 cho bề mặt hiển thị
  // lớn (fallback Mitr cho tiếng Thái); body giữ font hệ thống để đủ mọi ngôn ngữ.
  static ThemeData _buildTheme(Brightness brightness, Color seed) {
    final raw = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    // Tông pastel (chỉ light mode): nền = primaryContainer của seed trộn nhiều
    // trắng, thẻ/surface nhạt hơn nền một chút, nút filled dùng primaryContainer
    // + chữ đậm cùng tông. `primary` GIỮ NGUYÊN (icon/chữ nhấn dùng nó trên nền
    // sáng, pastel hoá sẽ mờ). Dark mode không đổi.
    final light = brightness == Brightness.light;
    final pastelBg = Color.lerp(raw.primaryContainer, Colors.white, 0.55)!;
    final scheme = light
        ? raw.copyWith(
            surface: Color.lerp(raw.primaryContainer, Colors.white, 0.8)!)
        : raw;
    // Nút "chunky đất sét": bo tròn dày, chữ đậm, có độ nổi nhẹ; dialog bo tròn
    // to — phong cách casual game (claymorphism).
    final buttonShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    const buttonText = TextStyle(fontWeight: FontWeight.w700, fontSize: 15);
    const buttonPad = EdgeInsets.symmetric(horizontal: 18, vertical: 12);
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: light ? pastelBg : null,
      appBarTheme: light
          ? AppBarTheme(
              backgroundColor: pastelBg, surfaceTintColor: Colors.transparent)
          : null,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: light ? scheme.primaryContainer : null,
          foregroundColor: light ? scheme.onPrimaryContainer : null,
          // Nút khoá: pastel nhạt thay vì xám đục (xám lạc tông trên nền pastel).
          disabledBackgroundColor:
              light ? scheme.primaryContainer.withValues(alpha: 0.5) : null,
          disabledForegroundColor:
              light ? scheme.onPrimaryContainer.withValues(alpha: 0.45) : null,
          shape: buttonShape,
          padding: buttonPad,
          textStyle: buttonText,
          elevation: 2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: light ? scheme.primaryContainer : null,
          foregroundColor: light ? scheme.onPrimaryContainer : null,
          // Nút khoá: pastel nhạt thay vì xám đục (xám lạc tông trên nền pastel).
          disabledBackgroundColor:
              light ? scheme.primaryContainer.withValues(alpha: 0.5) : null,
          disabledForegroundColor:
              light ? scheme.onPrimaryContainer.withValues(alpha: 0.45) : null,
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
