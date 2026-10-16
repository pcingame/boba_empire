// Kịch bản tự chơi để QUAY VIDEO quảng bá (TikTok/Shorts/Facebook): chạm kiếm Xu, pha theo đơn, khách gọi món.
//
//   flutter drive --driver=test_driver/screenshots.dart --target=integration_test/promo_video_test.dart -d <udid>
//   (quay song song bằng `xcrun simctl io <udid> recordVideo out.mp4`)
//
// Mỗi cảnh in ra dòng `SCENE|<tên>|start|<epoch ms>` và `...|end|...` để script cắt clip từ file quay.
// Save giả (không đụng cloud), tắt QC, chặn popup — giống integration_test/screenshots_test.dart.
import 'dart:convert';
import 'dart:math';

import 'package:boba_empire/audio/audio_service.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/recipe_orders.dart';
import 'package:boba_empire/core/recipes.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/market/market_highlight.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/home_page.dart' as home;
import 'package:boba_empire/ui/recipe_order_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chờ THEO ĐỒNG HỒ THẬT [ms] mili-giây (máy ảo đang được quay) trong khi vẫn dựng khung hình.
Future<void> wait(WidgetTester t, int ms) async {
  var left = ms;
  while (left > 0) {
    final step = min(left, 50);
    await t.pump(Duration(milliseconds: step));
    left -= step;
  }
}

/// `--dart-define=PROMO_ONLY=A` chỉ quay cảnh A (chạm kiếm Xu).
const _only = String.fromEnvironment('PROMO_ONLY');

/// Nghe lén âm thanh game: in `EV|<sfx>|<epoch>` để ghép lại tiếng THẬT (assets/audio) vào video sau
/// (simulator không thu được tiếng).
class _LogAudio implements AudioService {
  @override
  void play(Sfx sfx) => ev(sfx.name);
}

void ev(String name) => debugPrint('EV|$name|${DateTime.now().millisecondsSinceEpoch}');

void mark(String name, String what) => debugPrint('SCENE|$name|$what|${DateTime.now().millisecondsSinceEpoch}');

GameState _save(int now) {
  final s = GameState.newGame(nowMillis: now)
    ..tutorialSeen = true
    ..starterPackClaimed = true
    ..m3HowToSeen = true
    ..stage = 6
    ..money = 3e8
    ..gems = 320
    ..tapValue = 2.6e6
    ..lifetimeEarnings = 4e13
    ..adsRemoved = true
    ..lastSeenMillis = now
    ..firstPlayedMillis = now;
  for (final g in const ['tra_den', 'tran_chau', 'thach', 'pudding', 'kem_nuong', 'matcha', 'duong_den', 'brulee']) {
    s.levels[g] = 45;
  }
  return s;
}

Future<void> _dismissBlocking(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    final close = find.text('Đóng');
    if (close.evaluate().isNotEmpty) {
      await t.tap(close.first, warnIfMissed: false);
    } else {
      final btn = find.descendant(of: find.byType(Dialog), matching: find.byType(ButtonStyleButton));
      if (btn.evaluate().isEmpty) return;
      await t.tap(btn.first, warnIfMissed: false);
    }
    await wait(t, 700);
  }
}

/// Rót một nguyên liệu như người chơi: chạm khay → chọn mức → "Rót".
Future<void> _pour(WidgetTester t, RecipeIngredient i) async {
  final chip = find.byKey(Key('order-tray-${i.name}'));
  await t.ensureVisible(chip);
  await wait(t, 150);
  await t.tap(chip);
  await wait(t, 350);
  final r = t.getRect(find.byKey(const Key('order-slider')));
  final n = amountSteps(i.unit).length;
  const pad = 24.0;
  await t.tapAt(Offset(r.left + pad + (r.width - 2 * pad) * nearestStep(i.unit, i.qty) / (n - 1), r.center.dy));
  await wait(t, 300);
  await t.tap(find.byKey(const Key('order-pour')));
  ev('buy'); // tiếng "rót" (game không có SFX riêng cho trò này)
  await wait(t, 400);
}

Future<void> _serveRecipe(WidgetTester t, Recipe r) async {
  await wait(t, 1200);
  await _dismissBlocking(t); // hướng dẫn lần đầu của Pha theo đơn
  await wait(t, 800);
  for (final i in r.ingredients) {
    await _pour(t, i);
  }
  await wait(t, 350);
  await t.tap(find.byKey(const Key('order-serve')));
  ev('reward');
  await wait(t, 2200);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('quay video quảng bá', (t) async {
    home.debugAutoShowTutorial = false;
    home.debugAutoShowDaily = false;
    home.debugAutoShowStory = false;
    try {
      await binding.convertFlutterSurfaceToImage();
    } catch (_) {}

    SharedPreferences.setMockInitialValues({'flutter.app_locale': 'vi', 'flutter.market_intro_seen': true});
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await GameStorage(prefs).save(_save(now), nowMillis: now);
    final catalog = RecipeCatalog.fromJson(jsonDecode(await rootBundle.loadString('assets/recipes/recipes.json')) as Map<String, dynamic>);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      marketHighlightProvider.overrideWith((ref) async => null),
      audioServiceProvider.overrideWithValue(_LogAudio()),
      appVersionProvider.overrideWithValue(() async => '1.0.5'),
    ]);
    addTearDown(c.dispose);

    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
    await wait(t, 1500);
    await _dismissBlocking(t);
    await wait(t, 1000);

    // ── A: chạm pha trà, Xu nhảy ──
    mark('A_tap', 'start');
    for (var i = 0; i < 70; i++) {
      await t.tap(find.byKey(const Key('tap-circle')), warnIfMissed: false);
      await wait(t, i % 15 == 14 ? 300 : 85);
    }
    await wait(t, 1000);
    mark('A_tap', 'end');

    if (_only == 'A') {
      await t.pumpWidget(const SizedBox());
      return;
    }

    // ── B: Pha theo đơn (một món cố định, kéo-thả rót từng nguyên liệu) ──
    final recipe = catalog.byId(1)!;
    mark('B_order', 'start');
    final ctx = t.element(find.byType(Scaffold).first);
    showRecipeOrderFor(ctx, recipe.id);
    await wait(t, 1500);
    await _serveRecipe(t, recipe);
    mark('B_order', 'end');
    await wait(t, 1500);
    await t.tap(find.byType(BackButton).first, warnIfMissed: false);
    await wait(t, 1000);

    // ── C: khách đi ngang gọi món (đợi bong bóng 🧋 hiện, tối đa 90 giây) ──
    mark('C_walker', 'start');
    final bubble = find.byKey(const Key('walker-order'));
    var waited = 0;
    while (bubble.evaluate().isEmpty && waited < 90000) {
      await wait(t, 250);
      waited += 250;
    }
    if (bubble.evaluate().isNotEmpty) {
      await wait(t, 800);
      mark('C_walker', 'bubble');
      await t.tap(bubble.first, warnIfMissed: false);
      await wait(t, 1500);
      final prompt = find.byKey(const Key('order-prompt'));
      final text = prompt.evaluate().isEmpty ? '' : (t.widget<Text>(prompt).data ?? '');
      Recipe? picked;
      for (final r in catalog.recipes) {
        if (text.contains(r.name) && (picked == null || r.name.length > picked.name.length)) picked = r;
      }
      debugPrint('SCENE|C_walker|recipe|${picked?.name}|prompt=$text');
      if (picked != null) await _serveRecipe(t, picked);
    } else {
      debugPrint('SCENE|C_walker|no-bubble');
    }
    mark('C_walker', 'end');
    await wait(t, 1500);

    await t.pumpWidget(const SizedBox());
  });
}
