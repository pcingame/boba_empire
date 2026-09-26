import 'package:boba_empire/ads/ad_service.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InstantAds implements AdService {
  const _InstantAds(this.outcome);
  final RewardOutcome outcome;
  @override
  Future<RewardOutcome> showRewardedAd() async => outcome;
}

Future<void> _pump(WidgetTester tester, GameState seed, AdService ads) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
        adServiceProvider.overrideWithValue(ads),
      ],
      child: const BobaEmpireApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('chưa có thu nhập: nút Tiền tức thì ẩn', (tester) async {
    await _pump(
      tester,
      GameState.newGame(nowMillis: 0),
      const _InstantAds(RewardOutcome.earned),
    );
    expect(find.byKey(const Key('instant-cash')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('có thu nhập: xem QC nhận 15 phút sản xuất', (tester) async {
    // tra_den cấp 2 = 1 Xu/s → 15 phút = 900 giây = 900 Xu.
    await _pump(
      tester,
      GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2,
      const _InstantAds(RewardOutcome.earned),
    );

    expect(find.text('0 Xu'), findsOneWidget);
    await tester.tap(find.byKey(const Key('instant-cash')));
    await tester.pumpAndSettle();

    expect(find.text('900 Xu'), findsOneWidget);
    expect(find.textContaining('Tiền tức thì'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('đóng QC sớm: không nhận tiền', (tester) async {
    await _pump(
      tester,
      GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2,
      const _InstantAds(RewardOutcome.dismissed),
    );

    await tester.tap(find.byKey(const Key('instant-cash')));
    await tester.pumpAndSettle();
    expect(find.text('0 Xu'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'HỒI QUY: nhãn "Tiền tức thì" hiện đủ, không bị cắt thành "Tiền tứ…"',
      (tester) async {
    // Bản sửa tràn RenderFlex trước đây bọc nút bằng Flexible chia đều chỗ trống
    // với dòng thu nhập → nút bị cắt dù màn còn dư chỗ. Với thu nhập vừa phải
    // (chỗ dư rất nhiều) nhãn phải ở kích thước gốc, KHÔNG bị thu nhỏ/cắt.
    await _pump(
      tester,
      GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2,
      const _InstantAds(RewardOutcome.earned),
    );
    final fitted = find.descendant(
      of: find.byKey(const Key('instant-cash')),
      matching: find.byType(FittedBox),
    );
    expect(fitted, findsOneWidget);
    final box = tester.renderObject<RenderFittedBox>(fitted);
    expect(box.child!.size.width, lessThanOrEqualTo(box.size.width + 0.01),
        reason: 'nhãn bị thu nhỏ dù còn dư chỗ');
    await tester.pumpWidget(const SizedBox());
  });
}
