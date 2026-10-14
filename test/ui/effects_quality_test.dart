// Mức chất lượng hiệu ứng: bộ đánh giá khung hình, lưu/đọc lựa chọn, tự hạ, và nhịp chung
// (không timer khi Tắt / không người nghe / ra nền).
import 'dart:ui' as ui;

import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/ui/settings_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boba_empire/ui/widgets/ambient_ticker.dart';
import 'package:boba_empire/ui/widgets/device_tier.dart';
import 'package:boba_empire/ui/widgets/effects_quality.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefs([Map<String, Object> v = const {}]) async {
  SharedPreferences.setMockInitialValues(v);
  return SharedPreferences.getInstance();
}

class _FakeCloud extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveUnlinked();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fx = EffectsController.instance;
  setUp(fx.debugReset);
  tearDown(fx.debugReset);

  group('FrameTuner', () {
    test('bỏ khởi động; máy mượt không bao giờ báo hạ', () {
      final t = FrameTuner();
      expect([for (var i = 0; i < 2000; i++) t.add(8)].any((x) => x), isFalse);
    });

    test('quá 15% khung chậm trong một cửa sổ → báo hạ; khởi động chậm không tính', () {
      final t = FrameTuner(warmup: 10, window: 20);
      for (var i = 0; i < 10; i++) {
        expect(t.add(90), isFalse); // đang khởi động
      }
      final drops = [for (var i = 0; i < 20; i++) t.add(i < 4 ? 40 : 8)]; // 20% chậm
      expect(drops.last, isTrue);
      expect(drops.take(19).any((x) => x), isFalse);
    });

    test('đúng ngưỡng 15% thì chưa hạ; khung treo dài (quay lại từ nền) bị bỏ qua', () {
      final t = FrameTuner(warmup: 0, window: 20);
      expect([for (var i = 0; i < 20; i++) t.add(i < 3 ? 40 : 8)].last, isFalse);
      expect([for (var i = 0; i < 200; i++) t.add(900)].any((x) => x), isFalse);
    });
  });

  group('EffectsController', () {
    test('mặc định theo điểm xuất phát; lựa chọn người chơi được lưu và áp ngay', () async {
      final p = await _prefs();
      fx.init(p, platformStart: EffectsQuality.high, listenFrames: false);
      expect(fx.quality.value, EffectsQuality.high);
      await fx.setPref(EffectsPref.low);
      expect(fx.quality.value, EffectsQuality.low);
      expect(p.getInt(EffectsController.prefKey), EffectsPref.low.index);

      fx.debugReset();
      fx.init(p, platformStart: EffectsQuality.high, listenFrames: false);
      expect(fx.pref, EffectsPref.low); // nhớ qua lần mở sau
      expect(fx.quality.value, EffectsQuality.low);
    });

    test('tự hạ từng bậc, lưu lại, báo analytics, KHÔNG xuống Tắt và không tự nâng', () async {
      final p = await _prefs();
      fx.init(p, platformStart: EffectsQuality.high, listenFrames: false);
      final drops = <String>[];
      fx.onAutoDrop = (a, b) => drops.add('${a.name}>${b.name}');
      fx.dropAuto();
      fx.dropAuto();
      fx.dropAuto(); // đã ở Thấp: dừng
      expect(fx.quality.value, EffectsQuality.low);
      expect(drops, ['high>medium', 'medium>low']);
      expect(p.getInt(EffectsController.autoKey), EffectsQuality.low.index);
      fx.debugReset();
      fx.init(p, platformStart: EffectsQuality.high, listenFrames: false);
      expect(fx.quality.value, EffectsQuality.low); // lần sau không bắt đo lại
    });

    test('người chơi chọn mức cố định thì tự hạ không đổi mức hiệu lực', () async {
      fx.init(await _prefs(), platformStart: EffectsQuality.high, listenFrames: false);
      await fx.setPref(EffectsPref.high);
      fx.dropAuto();
      expect(fx.quality.value, EffectsQuality.high);
      await fx.setPref(EffectsPref.auto);
      expect(fx.quality.value, EffectsQuality.medium); // mức tự đo đã hạ
    });

    test('giá trị lưu hỏng → về mặc định, không ném', () async {
      fx.init(await _prefs({'fx_pref': 99, 'fx_auto': -3}),
          platformStart: EffectsQuality.medium, listenFrames: false);
      expect(fx.pref, EffectsPref.auto);
      expect(fx.quality.value, EffectsQuality.medium);
    });

    test('ngân sách hạt và chu kỳ tăng dần theo mức; Tắt = 0', () {
      expect(EffectsQuality.off.particleBudget, 0);
      expect(EffectsQuality.off.tickMs, 0);
      final b = [for (final q in EffectsQuality.values) q.particleBudget];
      expect(b, [...b]..sort());
      expect(EffectsQuality.low.tickMs, greaterThan(EffectsQuality.medium.tickMs));
    });
  });

  group('AmbientTicker', () {
    test('không người nghe → không timer; có người nghe → chạy; huỷ → dừng', () {
      final t = AmbientTicker.instance;
      expect(t.running, isFalse);
      final cancel = t.subscribe((_) {});
      expect(t.running, isTrue);
      cancel();
      expect(t.running, isFalse);
    });

    test('mức Tắt: không có timer nào; bật lại thì chạy tiếp', () async {
      final t = AmbientTicker.instance;
      final cancel = t.subscribe((_) {});
      addTearDown(cancel);
      fx.init(await _prefs(), platformStart: EffectsQuality.medium, listenFrames: false);
      await fx.setPref(EffectsPref.off);
      expect(t.running, isFalse);
      await fx.setPref(EffectsPref.high);
      expect(t.running, isTrue);
    });

    test('tick theo chu kỳ của mức: Thấp thưa hơn Cao; dt hợp lý', () async {
      final t = AmbientTicker.instance;
      fx.init(await _prefs(), platformStart: EffectsQuality.medium, listenFrames: false);
      var n = 0;
      var maxDt = 0.0;
      final cancel = t.subscribe((dt) {
        n++;
        if (dt > maxDt) maxDt = dt;
      });
      addTearDown(cancel);
      await fx.setPref(EffectsPref.high);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final high = n;
      n = 0;
      await fx.setPref(EffectsPref.low);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(high, greaterThan(n));
      expect(n, greaterThan(0));
      expect(maxDt, closeTo(0.066, 0.034)); // 33ms (cao) hoặc 66ms (thấp)
    });

    test('app ra nền → dừng hẳn; quay lại → chạy', () {
      final t = AmbientTicker.instance;
      final cancel = t.subscribe((_) {});
      addTearDown(cancel);
      t.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(t.running, isFalse);
      t.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(t.running, isTrue);
    });
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('Cài đặt: chọn mức hiệu ứng được lưu, không tràn ở 320px ($lang)', (tester) async {
      final p = await _prefs();
      fx.init(p, platformStart: EffectsQuality.medium, listenFrames: false);
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(p),
        cloudSaveControllerProvider.overrideWith(_FakeCloud.new),
      ]);
      addTearDown(c.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          locale: ui.Locale(lang),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (ctx) =>
                  TextButton(onPressed: () => showSettings(ctx), child: const Text('open')),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('settings-effects')));
      await tester.tap(find.byKey(const Key('settings-effects')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('settings-effects-low')));
      await tester.pumpAndSettle();
      expect(fx.pref, EffectsPref.low);
      expect(p.getInt(EffectsController.prefKey), EffectsPref.low.index);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  group('phân loại máy', () {
    test('Android: low-RAM / RAM thấp / Android cũ → Thấp; tầm trung → Vừa; máy mạnh → Cao', () {
      EffectsQuality a(bool low, int ram, int sdk) =>
          classifyAndroid(isLowRam: low, ramMb: ram, sdkInt: sdk);
      expect(a(true, 8000, 34), EffectsQuality.low);
      expect(a(false, 2048, 33), EffectsQuality.low);
      expect(a(false, 4000, 25), EffectsQuality.low);
      expect(a(false, 4096, 33), EffectsQuality.medium);
      expect(a(false, 8000, 27), EffectsQuality.medium);
      expect(a(false, 8000, 34), EffectsQuality.high);
      expect(a(false, 6000, 29), EffectsQuality.high); // đúng ngưỡng
    });

    test('iOS: iPhone cũ (≤ A11) Thấp, XS/XR Vừa, A13+ Cao; iPad / mã lạ Cao', () {
      expect(classifyIos('iPhone8,1'), EffectsQuality.low);
      expect(classifyIos('iPhone9,3'), EffectsQuality.low);
      expect(classifyIos('iPhone10,6'), EffectsQuality.medium);
      expect(classifyIos('iPhone11,8'), EffectsQuality.medium);
      expect(classifyIos('iPhone12,1'), EffectsQuality.high);
      expect(classifyIos('iPhone17,1'), EffectsQuality.high);
      expect(classifyIos('iPad13,4'), EffectsQuality.high);
      expect(classifyIos('x86_64'), EffectsQuality.high);
    });

    test('mức đã tự hạ được giữ; cấu hình máy chỉ kéo xuống thêm, không nâng lên', () async {
      final p = await _prefs({'fx_auto': EffectsQuality.low.index});
      fx.init(p, platformStart: EffectsQuality.high, listenFrames: false);
      expect(fx.quality.value, EffectsQuality.low);
      fx.debugReset();
      final p2 = await _prefs({'fx_auto': EffectsQuality.high.index});
      fx.init(p2, platformStart: EffectsQuality.low, listenFrames: false);
      expect(fx.quality.value, EffectsQuality.low);
    });
  });
}
