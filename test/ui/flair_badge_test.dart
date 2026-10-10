/// Huy hiệu bảng xếp hạng: id lạ bị bỏ qua, cache có sẵn thì hiện emoji.
library;

import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/flair.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Seeded extends FlairCache {
  @override
  Map<String, String> build() => {'a': '🐉', 'b': '', 'v': '', 'w': '🐉'};
}

class _Vips extends VipLevels {
  @override
  Map<String, int> build() => {'v': 3, 'w': 5, 'x': 4, 'y': 10};
}

class _Online extends VipOnline {
  @override
  Map<String, bool> build() => {'w': true, 'v': false};
}

void main() {
  test('flairEmoji: id lạ / không phải String -> null, không ném', () {
    expect(flairEmoji('dragon'), '🐉');
    expect(flairEmoji('item_from_future'), isNull);
    expect(flairEmoji(42), isNull);
    expect(flairEmoji(null), isNull);
  });

  testWidgets('FlairBadge hiện emoji khi có, không chiếm chỗ khi rỗng',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [flairCacheProvider.overrideWith(_Seeded.new)],
      child: const MaterialApp(
        home: Column(children: [
          FlairBadge(userId: 'a'),
          FlairBadge(userId: 'b'),
        ]),
      ),
    ));
    expect(find.text('🐉'), findsOneWidget);
    expect(find.byKey(const Key('flair-badge')), findsOneWidget);
  });

  testWidgets('FlairBadge hiện nhãn VIP (một mình hoặc cùng emoji)', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        flairCacheProvider.overrideWith(_Seeded.new),
        vipLevelProvider.overrideWith(_Vips.new),
      ],
      child: const MaterialApp(
        home: Column(children: [
          FlairBadge(userId: 'v'), // chỉ VIP
          FlairBadge(userId: 'w'), // VIP + emoji
          FlairBadge(userId: 'b'), // không gì cả
        ]),
      ),
    ));
    expect(find.text('VIP 3'), findsOneWidget);
    expect(find.text('VIP 5'), findsOneWidget);
    expect(find.byKey(const Key('flair-badge')), findsOneWidget); // chỉ 'w'
  });

  testWidgets('dòng danh hiệu chỉ từ VIP 5 trở lên; chấm xanh chỉ khi online',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        flairCacheProvider.overrideWith(_Seeded.new),
        vipLevelProvider.overrideWith(_Vips.new),
        vipOnlineProvider.overrideWith(_Online.new),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Column(children: [
          VipNameBlock(userId: 'w', child: Text('w')), // VIP 5, online
          VipNameBlock(userId: 'x', child: Text('x')), // VIP 4: không có dòng
          VipNameBlock(userId: 'y', child: Text('y')), // VIP 10
          VipNameBlock(userId: 'nobody', child: Text('n')),
          FlairBadge(userId: 'w'),
          FlairBadge(userId: 'v'), // VIP 3 nhưng offline
        ]),
      ),
    ));
    expect(find.text('👑 Shop Owner'), findsOneWidget);
    expect(find.text('👑 Boba Emperor'), findsOneWidget);
    expect(find.byKey(const Key('vip-title-line')), findsNWidgets(2));
    expect(find.byKey(const Key('vip-online-dot')), findsOneWidget); // chỉ 'w'
  });
}
