// RarityGlint: chỉ Sử thi/Huyền thoại, chỉ ở mức Vừa/Cao, đứng yên khi giảm chuyển động; huỷ → 0 timer.
import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/ui/widgets/ambient_ticker.dart';
import 'package:boba_empire/ui/widgets/effects_quality.dart';
import 'package:boba_empire/ui/widgets/mascot.dart' as mascot;
import 'package:boba_empire/ui/widgets/rarity_glint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(AccessoryRarity r) => MaterialApp(
      home: Scaffold(body: Center(child: RarityGlint(rarity: r, child: const Text('🦄')))),
    );

Finder get _glow => find.descendant(of: find.byType(RarityGlint), matching: find.byType(DecoratedBox));

double _alpha(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(_glow).decoration as BoxDecoration;
  return box.boxShadow!.first.color.a;
}

void main() {
  late EffectsQuality saved;
  setUp(() {
    mascot.debugDisableMascotAnimation = false;
    saved = EffectsController.instance.quality.value;
  });
  tearDown(() {
    mascot.debugDisableMascotAnimation = true;
    EffectsController.instance.quality.value = saved;
  });

  testWidgets('Vừa: Sử thi/Huyền thoại có quầng sáng nhấp nháy; Thường/Hiếm thì không', (tester) async {
    EffectsController.instance.quality.value = EffectsQuality.medium;
    await tester.pumpWidget(_host(AccessoryRarity.epic));
    expect(_glow, findsOneWidget);
    final a0 = _alpha(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(_alpha(tester), isNot(a0), reason: 'quầng sáng đổi theo thời gian');
    await tester.pumpWidget(_host(AccessoryRarity.legendary));
    expect(find.byType(Transform), findsWidgets);
    for (final r in [AccessoryRarity.common, AccessoryRarity.rare]) {
      await tester.pumpWidget(_host(r));
      expect(_glow, findsNothing);
    }
    await tester.pumpWidget(const SizedBox());
    expect(AmbientTicker.instance.running, isFalse, reason: 'gỡ hết ô → 0 timer');
  });

  testWidgets('Thấp/Tắt hoặc giảm chuyển động: đứng yên, không timer nào', (tester) async {
    for (final q in [EffectsQuality.low, EffectsQuality.off]) {
      EffectsController.instance.quality.value = q;
      await tester.pumpWidget(_host(AccessoryRarity.legendary));
      expect(_glow, findsNothing);
      expect(AmbientTicker.instance.running, isFalse);
    }
    EffectsController.instance.quality.value = EffectsQuality.high;
    mascot.debugDisableMascotAnimation = true;
    await tester.pumpWidget(_host(AccessoryRarity.legendary));
    expect(_glow, findsNothing);
    expect(AmbientTicker.instance.running, isFalse);
  });
}
