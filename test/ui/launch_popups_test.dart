// Mở app chỉ hiện TỐI ĐA MỘT popup, theo ưu tiên:
// điểm danh > cốt truyện > tiền offline (vắng ≥ 2 phút) > "Có gì mới" > nhắc liên kết email.
// Popup không được hiện thì giữ nguyên trạng thái để lần mở sau còn thấy.
import 'package:boba_empire/core/cloud_remind.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/whats_new.dart';
import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCloud extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveUnlinked();
}

const _day = 24 * 60 * 60 * 1000;
const _today = 20003;
const _now = _today * _day + 5 * 60 * 1000;

const _daily = Key('daily-claim');
const _story = Key('story-choice-0');
const _offline = Key('offline-double');
const _whatsNew = Key('whats-new');
const _remind = Key('cloud-remind-link');

/// [awayMs] = vắng bao lâu; [dailyDone] = đã nhận điểm danh hôm nay; [story] = đang
/// chờ cutscene; [whatsNewDue] = vừa cập nhật; [remindDue] = đủ lượt nhắc email.
Future<ProviderContainer> _launch(
  WidgetTester tester, {
  int awayMs = 200000,
  bool dailyDone = false,
  bool story = false,
  bool whatsNewDue = false,
  bool remindDue = false,
  bool tutorialSeen = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({
    if (whatsNewDue) whatsNewSeenKey: '0.0.1' else whatsNewSeenKey: whatsNewVersion,
    if (remindDue) cloudRemindOpensKey: 2,
  });
  final prefs = await SharedPreferences.getInstance();
  final seed = GameState.newGame(nowMillis: 0)
    ..levels['tra_den'] = 2
    ..tutorialSeen = tutorialSeen
    ..lastDailyDay = dailyDone ? _today : 0
    // Ván mới mặc định đang chờ chương 1: cho qua chương 1 để cốt truyện chỉ hiện
    // khi ca test chủ động yêu cầu.
    ..storyChapter = 1;
  if (story) {
    seed
      ..storyChapter = 5
      ..stage = 5;
  }
  await GameStorage(prefs).save(seed, nowMillis: _now - awayMs);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => _now),
    appVersionProvider.overrideWithValue(() async => whatsNewVersion),
    cloudLinkedProvider.overrideWithValue(false),
    cloudSaveControllerProvider.overrideWith(_FakeCloud.new),
  ]);
  await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
  await tester.pumpAndSettle();
  return c;
}

int _shown(WidgetTester tester) => [_daily, _story, _offline, _whatsNew, _remind]
    .where((k) => find.byKey(k).evaluate().isNotEmpty)
    .length;

Future<void> _end(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  setUp(() {
    debugAutoShowDaily = true;
    debugAutoShowStory = true;
  });
  tearDown(() {
    debugAutoShowDaily = false;
    debugAutoShowStory = false;
    debugAutoShowTutorial = false;
  });

  testWidgets('mọi thứ cùng đến hạn: CHỈ điểm danh; các popup khác giữ nguyên trạng thái',
      (tester) async {
    final c = await _launch(tester,
        story: true, whatsNewDue: true, remindDue: true);
    expect(find.byKey(_daily), findsOneWidget);
    expect(_shown(tester), 1);
    // Đóng điểm danh xong cũng KHÔNG có popup nào nối tiếp.
    await tester.tap(find.byKey(_daily));
    await tester.pumpAndSettle();
    expect(_shown(tester), 0);
    final prefs = c.read(sharedPreferencesProvider);
    expect(prefs.getString(whatsNewSeenKey), '0.0.1', reason: 'chưa hiện → chưa ghi nhớ');
    expect(prefs.getInt(cloudRemindCountKey) ?? 0, 0, reason: 'chưa nhắc → không tốn lượt');
    await _end(tester, c);
  });

  testWidgets('đã nhận điểm danh: cốt truyện đến trước tiền offline', (tester) async {
    final c = await _launch(tester, dailyDone: true, story: true, whatsNewDue: true);
    expect(find.byKey(_story), findsOneWidget);
    expect(_shown(tester), 1);
    await _end(tester, c);
  });

  testWidgets('chỉ còn tiền offline (vắng đủ lâu): hiện nó, không kèm "Có gì mới"/nhắc email',
      (tester) async {
    final c = await _launch(tester,
        dailyDone: true, whatsNewDue: true, remindDue: true);
    expect(find.byKey(_offline), findsOneWidget);
    expect(_shown(tester), 1);
    final prefs = c.read(sharedPreferencesProvider);
    expect(prefs.getString(whatsNewSeenKey), '0.0.1');
    expect(prefs.getInt(cloudRemindCountKey) ?? 0, 0);
    await _end(tester, c);
  });

  testWidgets('vắng NGẮN: không có popup offline → "Có gì mới" được hiện', (tester) async {
    final c = await _launch(tester,
        dailyDone: true, awayMs: 60000, whatsNewDue: true, remindDue: true);
    expect(find.byKey(_offline), findsNothing);
    expect(find.byKey(_whatsNew), findsOneWidget);
    expect(_shown(tester), 1, reason: 'nhắc email nhường "Có gì mới"');
    await _end(tester, c);
  });

  testWidgets('yên ắng hoàn toàn (vắng ngắn, không gì đến hạn): không popup nào',
      (tester) async {
    final c = await _launch(tester, dailyDone: true, awayMs: 30000);
    expect(_shown(tester), 0);
    await _end(tester, c);
  });

  testWidgets('chỉ nhắc email đến hạn → hiện và tính lượt', (tester) async {
    final c = await _launch(tester,
        dailyDone: true, awayMs: 30000, remindDue: true);
    expect(find.byKey(_remind), findsOneWidget);
    expect(_shown(tester), 1);
    expect(c.read(sharedPreferencesProvider).getInt(cloudRemindCountKey), 1);
    await _end(tester, c);
  });

  testWidgets('hướng dẫn lần đầu chưa xong: điểm danh/offline/"Có gì mới"/nhắc email đều chờ',
      (tester) async {
    debugAutoShowTutorial = true;
    final c = await _launch(tester,
        tutorialSeen: false, whatsNewDue: true, remindDue: true);
    expect(find.byKey(const Key('ftue-bubble')), findsOneWidget);
    expect(_shown(tester), 0);
    await _end(tester, c);
  });

  testWidgets('hướng dẫn lần đầu chưa xong: cutscene mở đầu vẫn được hiện', (tester) async {
    debugAutoShowTutorial = true;
    final c = await _launch(tester, tutorialSeen: false, story: true);
    expect(find.byKey(_story), findsOneWidget);
    expect(find.byKey(const Key('ftue-bubble')), findsOneWidget);
    expect(find.byKey(_daily), findsNothing);
    await _end(tester, c);
  });
}
