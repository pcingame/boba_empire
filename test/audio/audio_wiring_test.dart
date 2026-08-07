import 'package:boba_empire/audio/audio_service.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ghi lại các SFX được yêu cầu phát để kiểm chứng UI có gọi đúng.
class _RecordingAudio implements AudioService {
  final List<Sfx> played = [];
  @override
  void play(Sfx sfx) => played.add(sfx);
}

Future<void> _pump(WidgetTester tester, _RecordingAudio audio) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  // Seed đủ tiền để mua được nâng cấp đầu.
  await GameStorage(prefs).save(
    GameState.newGame(nowMillis: 0)..money = 1000,
    nowMillis: 0,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
        audioServiceProvider.overrideWithValue(audio),
      ],
      child: const BobaEmpireApp(),
    ),
  );
}

void main() {
  testWidgets('chạm ly → phát Sfx.tap', (tester) async {
    final audio = _RecordingAudio();
    await _pump(tester, audio);

    await tester.tap(find.text('Chạm pha trà'));
    await tester.pump();

    expect(audio.played, contains(Sfx.tap));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mua nâng cấp → phát Sfx.buy', (tester) async {
    final audio = _RecordingAudio();
    await _pump(tester, audio);

    // Nút mua của dòng shop đầu tiên (Trà đen).
    await tester.tap(find.widgetWithText(FilledButton, '15 Xu'));
    await tester.pump();

    expect(audio.played, contains(Sfx.buy));

    await tester.pumpWidget(const SizedBox());
  });
}
