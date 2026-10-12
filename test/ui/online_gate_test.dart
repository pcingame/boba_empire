// Cổng "liên kết email để chơi online": chưa liên kết thì chặn và giải thích; đã liên kết thì qua ngay.
import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/ui/email_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Cloud extends CloudSaveController {
  _Cloud(this._linked);
  final bool _linked;
  @override
  CloudSaveViewState build() =>
      _linked ? const CloudSaveLinked('a@b.c') : const CloudSaveUnlinked();
}

Future<List<bool>> _pump(WidgetTester tester, {required bool linked, String locale = 'vi'}) async {
  final results = <bool>[];
  await tester.pumpWidget(ProviderScope(
    overrides: [cloudSaveControllerProvider.overrideWith(() => _Cloud(linked))],
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const Key('go'),
              onPressed: () async => results.add(await ensureOnlineLinked(context)),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ),
  ));
  return results;
}

void main() {
  testWidgets('đã liên kết: qua ngay, không hiện hộp thoại', (tester) async {
    final r = await _pump(tester, linked: true);
    await tester.tap(find.byKey(const Key('go')));
    await tester.pumpAndSettle();
    expect(r, [true]);
    expect(find.byKey(const Key('online-gate-dialog')), findsNothing);
  });

  testWidgets('chưa liên kết: hiện giải thích; "Huỷ" → bị chặn', (tester) async {
    final r = await _pump(tester, linked: false);
    await tester.tap(find.byKey(const Key('go')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('online-gate-dialog')), findsOneWidget);
    expect(find.text('Liên kết email để chơi online'), findsOneWidget);
    await tester.tap(find.byKey(const Key('online-gate-cancel')));
    await tester.pumpAndSettle();
    expect(r, [false]);
  });

  for (final l in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
    testWidgets('[$l] hộp thoại cổng 320px không tràn', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pump(tester, linked: false, locale: l);
      await tester.tap(find.byKey(const Key('go')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('online-gate-dialog')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
