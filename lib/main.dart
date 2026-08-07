import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio/audio_service.dart';
import 'audio/flame_audio_service.dart';
import 'state/game_providers.dart';
import 'ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final audio = FlameAudioService();
  unawaited(audio.preload());
  runApp(
    ProviderScope(
      overrides: [
        // Bơm SharedPreferences đã khởi tạo cho tầng state.
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Âm thanh thật (test giữ SilentAudioService mặc định).
        audioServiceProvider.overrideWithValue(audio),
      ],
      child: const BobaEmpireApp(),
    ),
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
