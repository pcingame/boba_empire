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
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const HomePage(),
    );
  }

  // Chủ đề nâu-kem trà sữa, dùng chung cho sáng/tối để đồng nhất thương hiệu.
  static ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8D5524), // nâu trà sữa
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
