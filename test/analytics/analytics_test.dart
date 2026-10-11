import 'package:boba_empire/analytics/analytics.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/ui/invite_dialog.dart' show shareTextProvider;
import 'package:boba_empire/ui/web_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<(String, Map<String, Object>?)> events;

  Future<void> pump(WidgetTester tester, Widget body) async {
    events = [];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWithValue((n, [p]) => events.add((n, p))),
          urlOpenerProvider.overrideWithValue((_) async => true),
          shareTextProvider.overrideWithValue((_, _) async {}),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(appBar: AppBar(actions: [body])),
        ),
      ),
    );
  }

  testWidgets('mặc định không làm gì và không ném lỗi', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: Builder(
          builder: (c) {
            trackEvent(c, 'x', {'a': 1});
            return const SizedBox();
          },
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('trackEvent từ BuildContext gửi đúng tên + tham số', (
    tester,
  ) async {
    events = [];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWithValue((n, [p]) => events.add((n, p))),
        ],
        child: Builder(
          builder: (c) {
            trackEvent(c, 'market_open');
            return const SizedBox();
          },
        ),
      ),
    );
    expect(events.single.$1, 'market_open');
  });

  testWidgets('mở / chia sẻ BXH web ghi sự kiện không kèm dữ liệu cá nhân', (
    tester,
  ) async {
    await pump(tester, const WebBoardActions(WebBoard.vip));
    await tester.tap(find.byKey(const Key('web-board-open')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('web-board-share')));
    await tester.pump();
    expect(events.map((e) => e.$1), ['web_open', 'web_share']);
    expect(events[0].$2, {'page': '/?board=vip'});
    expect(events[1].$2, {'board': 'vip'});
  });
}
