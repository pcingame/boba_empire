/// Huy hiệu bảng xếp hạng: id lạ bị bỏ qua, cache có sẵn thì hiện emoji.
library;

import 'package:boba_empire/leaderboard/flair.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Seeded extends FlairCache {
  @override
  Map<String, String> build() => {'a': '🐉', 'b': '', 'v': '', 'w': '🐉'};
}

class _Vips extends VipLevels {
  @override
  Map<String, int> build() => {'v': 3, 'w': 5};
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
}
