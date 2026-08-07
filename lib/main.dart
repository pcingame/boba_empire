import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads/ad_bootstrap.dart';
import 'ads/ad_service.dart';
import 'ads/real_ad_service.dart';
import 'audio/audio_service.dart';
import 'audio/flame_audio_service.dart';
import 'iap/iap_service.dart';
import 'iap/real_iap_service.dart';
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
    overrides.add(iapServiceProvider.overrideWithValue(RealIapService()));
  }

  runApp(
    ProviderScope(overrides: overrides, child: const BobaEmpireApp()),
  );
}

class BobaEmpireApp extends StatelessWidget {
  const BobaEmpireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đế Chế Trà Sữa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8D5524)),
      ),
      home: const HomePage(),
    );
  }
}
