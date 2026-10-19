// Mọi điểm vào tính năng online đều phải qua cổng liên kết email (ensureOnlineLinked) và app không
// còn tạo tài khoản ẩn danh. Test quét mã nguồn để điểm vào MỚI thêm sau này không lọt cổng.
import 'dart:io';

import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/ui/compete_hub_dialog.dart';
import 'package:boba_empire/ui/guild_page.dart';
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

Future<void> _openHub(WidgetTester tester, {required bool linked}) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(ProviderScope(
    overrides: [cloudSaveControllerProvider.overrideWith(() => _Cloud(linked))],
    child: MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          key: const Key('open-hub'),
          onPressed: () => showCompeteHub(context),
          child: const Text('hub'),
        ),
      ),
    ),
  ));
  await tester.tap(find.byKey(const Key('open-hub')));
  await tester.pumpAndSettle();
}

void main() {
  test('app không còn đăng nhập ẩn danh ở bất kỳ đâu', () {
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.contains('/l10n/')) continue;
      if (f.readAsStringSync().contains('signInAnonymously')) hits.add(f.path);
    }
    expect(hits, isEmpty, reason: 'signInAnonymously còn ở: $hits');
  });

  test('mọi lời gọi mở trang online đều đứng sau ensureOnlineLinked', () {
    const entries = [
      'showArenaPage', 'showGuildPage', 'showLeaderboardPage', 'showStorySpeedrunPage',
      'showArenaLeaderboardPage', 'showVipLeaderboard', 'showEventLeaderboard',
      'showM3Leaderboard', 'showAccessoryMarket', 'showAccessoryLeaderboard', 'showRecipeLeaderboard',
    ];
    final bad = <String>[];
    var found = 0;
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.contains('/l10n/')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final name in entries) {
          final line = lines[i];
          if (!line.contains('$name(context')) continue;
          if (line.contains('Future<void> $name')) continue; // định nghĩa hàm
          found++;
          // Trang gom mọi bảng: cổng nằm ở hàm dựng dòng `tile` dùng chung (cả file phải có cổng), không cạnh từng lời gọi.
          final window = f.path.endsWith('leaderboards_hub_page.dart')
              ? lines.join('\n')
              : lines.sublist(i < 6 ? 0 : i - 6, i + 1).join('\n');
          if (!window.contains('ensureOnlineLinked')) bad.add('${f.path}:${i + 1} $name');
        }
      }
    }
    expect(found, greaterThanOrEqualTo(entries.length), reason: 'quét không thấy đủ điểm vào');
    expect(bad, isEmpty, reason: 'điểm vào lọt cổng: $bad');
  });

  test('MỌI hàm mở bảng xếp hạng (tự dò) đều được gọi sau cổng email, trừ bảng Hội (đã nằm trong trang Hội)', () {
    final defs = RegExp(r'^(?:Future<void>|void) (show\w*(?:Leaderboard|Speedrun)\w*)\(', multiLine: true);
    const exempt = {'showGuildLeaderboard'};
    final names = <String>{};
    final files = [
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart') && !f.path.contains('/l10n/')) f,
    ];
    for (final f in files) {
      for (final m in defs.allMatches(f.readAsStringSync())) {
        names.add(m.group(1)!);
      }
    }
    names.removeAll(exempt);
    expect(names.length, greaterThanOrEqualTo(8), reason: 'dò không thấy đủ hàm bảng xếp hạng: $names');
    final bad = <String>[];
    for (final name in names) {
      var calls = 0;
      for (final f in files) {
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (!lines[i].contains('$name(context') || RegExp('Future<void> $name').hasMatch(lines[i])) continue;
          calls++;
          // Trang gom mọi bảng: cổng nằm ở hàm dựng dòng `tile` dùng chung (cả file phải có cổng), không cạnh từng lời gọi.
          final window = f.path.endsWith('leaderboards_hub_page.dart')
              ? lines.join('\n')
              : lines.sublist(i < 6 ? 0 : i - 6, i + 1).join('\n');
          if (!window.contains('ensureOnlineLinked')) bad.add('${f.path}:${i + 1} $name');
        }
      }
      expect(calls, greaterThan(0), reason: '$name không có nơi gọi nào');
    }
    expect(bad, isEmpty, reason: 'bảng xếp hạng lọt cổng email: $bad');
  });

  testWidgets('hub Thi đấu: chưa liên kết → bấm Hội bị chặn, không mở trang', (tester) async {
    await _openHub(tester, linked: false);
    await tester.tap(find.byKey(const Key('compete-guild')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('online-gate-dialog')), findsOneWidget);
    expect(find.byType(GuildPage), findsNothing);
  });

  testWidgets('hub Thi đấu: cả 5 mục đều bị chặn khi chưa liên kết', (tester) async {
    await _openHub(tester, linked: false);
    final tiles = find.descendant(of: find.byType(AlertDialog), matching: find.byType(ListTile));
    final n = tester.widgetList(tiles).length;
    expect(n, 5);
    for (var i = 0; i < n; i++) {
      await tester.tap(tiles.at(i));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('online-gate-dialog')), findsOneWidget, reason: 'mục $i');
      await tester.tap(find.byKey(const Key('online-gate-cancel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('online-gate-dialog')), findsNothing);
    }
  });

  testWidgets('hub Thi đấu: đã liên kết → mở trang Hội bình thường (không hiện cổng)', (tester) async {
    await _openHub(tester, linked: true);
    await tester.tap(find.byKey(const Key('compete-guild')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('online-gate-dialog')), findsNothing);
    expect(find.byType(GuildPage), findsOneWidget);
  });
}
