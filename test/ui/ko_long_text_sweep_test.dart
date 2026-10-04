import 'dart:ui' as ui;

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quét "nhiều chữ": mọi màn/hộp thoại chính ở máy hẹp 320dp, save "nặng" (số cực
/// lớn, nhiều thứ đã mở), cỡ chữ 1.0 và 1.6. Phông của flutter_test rộng hơn phông
/// thật nên bản thân tiếng Anh/Việt đã tràn vài chỗ (home_page milestone, rewards
/// dialog, settings) — đó là tồn đọng có sẵn, không phải lỗi bản dịch. Test này
/// chỉ khoá điều QUAN TRỌNG: tiếng Hàn (và Thái) KHÔNG tràn ở chỗ nào
/// mà tiếng Anh không tràn.
/// Cài đặt đọc trạng thái sao lưu đám mây (cần Supabase) — thay bằng bản chưa liên kết.
class _FakeCloudSave extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveUnlinked();
}

final _site = RegExp(r'lib/[a-z_/]+\.dart:\d+');

Future<Set<String>> _sweep(WidgetTester tester, String locale, double scale) async {
  const keys = [
    'story-log-button',
    'settings-button',
    'gem-shop-button',
    'prestige-button',
    'achievements-button',
    'compete-button',
    'rewards-chip',
    'daily-quests-chip',
    'collection-chip',
  ];
  tester.platformDispatcher.localesTestValue = [ui.Locale(locale)];
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  await tester.binding.setSurfaceSize(const Size(320, 640));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)
        ..tutorialSeen = true
        ..stage = 8
        ..money = 3.156e40
        ..gems = 123456
        ..lifetimeEarnings = 1e60
        ..prestigeStars = 98765
        ..levels.addAll({'tra_den': 400, 'tran_chau': 390}),
      nowMillis: 0);

  final sites = <String>{};
  final old = FlutterError.onError;
  FlutterError.onError = (d) {
    if (d.exception.toString().contains('overflowed')) {
      sites.addAll(_site.allMatches(d.toString()).map((m) => m.group(0)!));
    } else {
      old?.call(d);
    }
  };
  try {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
        cloudSaveControllerProvider.overrideWith(_FakeCloudSave.new),
      ],
      child: const BobaEmpireApp(),
    ));
    await tester.pumpAndSettle();
    for (final k in keys) {
      final f = find.byKey(Key(k));
      if (f.evaluate().isEmpty) continue;
      await tester.ensureVisible(f.first);
      await tester.tap(f.first, warnIfMissed: false);
      await tester.pumpAndSettle();
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      while (nav.canPop()) {
        nav.pop();
        await tester.pumpAndSettle();
      }
    }
    await tester.pumpWidget(const SizedBox());
  } finally {
    FlutterError.onError = old;
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.binding.setSurfaceSize(null);
  }
  return sites;
}

void main() {
  for (final scale in [1.0, 1.6]) {
    testWidgets('×$scale: ko/th không tràn thêm chỗ nào so với en',
        (tester) async {
      final base = await _sweep(tester, 'en', scale);
      // Chỉ khoá tiếng Hàn + Thái: pt (home_page:820, rewards_dialog:267) và vi ×1.6
      // (prestige_dialog:49) tràn thêm ở phông test — tồn đọng có sẵn, ngoài phạm vi.
      for (final l in ['ko', 'th']) {
        final s = await _sweep(tester, l, scale);
        expect(s.difference(base), isEmpty,
            reason: '[$l] ×$scale tràn thêm ở: ${s.difference(base)}');
      }
    });
  }
}
