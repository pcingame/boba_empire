// Luồng đầy đủ: bị cổng chặn → nhập email → nhập mã → vào được; nâng cấp tài khoản ẩn danh GIỮ user_id;
// email đã có tài khoản → đăng nhập tài khoản đó; mã sai/huỷ → vẫn bị chặn.
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/data/cloud_save_repository.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/email_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User mkUser({required bool anon, required String id, String? email}) => User(
      id: id,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-10-12T00:00:00Z',
      email: email,
      isAnonymous: anon,
    );

class _Auth extends GoTrueClient {
  _Auth(this._user)
      : super(url: 'http://localhost', headers: const {}, autoRefreshToken: false);
  User? _user;
  final calls = <String>[];
  AuthException? updateError;
  bool badCode = false;

  /// user_id sau khi xác nhận: nâng cấp → giữ nguyên; đăng nhập tài khoản có sẵn → id khác.
  String idAfterVerify = 'u-legacy';
  String? pendingEmail;

  @override
  User? get currentUser => _user;

  @override
  Future<UserResponse> updateUser(UserAttributes attributes, {String? emailRedirectTo}) async {
    calls.add('updateUser:${attributes.email}');
    if (updateError != null) throw updateError!;
    pendingEmail = attributes.email;
    return UserResponse.fromJson(<String, dynamic>{
      'id': _user!.id,
      'aud': 'authenticated',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-10-12T00:00:00Z',
    });
  }

  @override
  Future<void> signInWithOtp({
    String? email, String? phone, String? emailRedirectTo, bool? shouldCreateUser,
    Map<String, dynamic>? data, String? captchaToken, OtpChannel channel = OtpChannel.sms,
  }) async {
    calls.add('signInWithOtp:$email');
    pendingEmail = email;
  }

  @override
  Future<AuthResponse> verifyOTP({
    String? email, String? phone, String? token, required OtpType type,
    String? redirectTo, String? captchaToken, String? tokenHash,
  }) async {
    calls.add('verifyOTP:${type.name}');
    if (badCode) throw AuthException('Token has expired or is invalid', statusCode: '403', code: 'otp_expired');
    _user = mkUser(anon: false, id: idAfterVerify, email: email);
    return AuthResponse();
  }
}

class _Repo extends CloudSaveRepository {
  _Repo(_Auth auth)
      : super(
          SupabaseClient('http://localhost', 'anon',
              authOptions: const AuthClientOptions(autoRefreshToken: false)),
          auth: auth,
        );
  int pushes = 0;
  @override
  Future<CloudSaveResult?> pull() async => null;
  @override
  Future<int> push(Map<String, dynamic> saveJson) async => ++pushes;
}

Future<(ProviderContainer, List<bool>, _Auth, _Repo)> _pump(
  WidgetTester tester, {
  User? start,
  String idAfterVerify = 'u-legacy',
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: 0), nowMillis: 0);
  final auth = _Auth(start)..idAfterVerify = idAfterVerify;
  final repo = _Repo(auth);
  final results = <bool>[];
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
    cloudSaveControllerProvider.overrideWith(() => CloudSaveController()..repository = repo),
  ]);
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('vi'),
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
  return (container, results, auth, repo);
}

Future<void> _end(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

Future<void> _linkThroughDialogs(WidgetTester tester, {String email = 'a@b.c', String code = '123456'}) async {
  await tester.tap(find.byKey(const Key('go')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('online-gate-link')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), email);
  await tester.tap(find.byType(FilledButton));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), code);
  await tester.tap(find.byType(FilledButton).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('người chơi cũ (phiên ẩn danh): nâng cấp tại chỗ, GIỮ user_id, rồi vào được', (tester) async {
    final (c, results, auth, repo) = await _pump(tester, start: mkUser(anon: true, id: 'u-legacy'));
    await _linkThroughDialogs(tester);
    expect(auth.calls, ['updateUser:a@b.c', 'verifyOTP:emailChange']);
    expect(auth.currentUser!.id, 'u-legacy', reason: 'user_id không đổi → không mất Hội/ví Chợ/BXH');
    expect(auth.currentUser!.isAnonymous, isFalse);
    expect(repo.pushes, 1, reason: 'save máy này được đẩy lên cloud lần đầu');
    await tester.tap(find.byType(TextButton).last); // Đóng hộp thoại liên kết
    await tester.pumpAndSettle();
    expect(results, [true]);
    // Lần sau qua cổng ngay, không hỏi lại.
    await tester.tap(find.byKey(const Key('go')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('online-gate-dialog')), findsNothing);
    expect(results, [true, true]);
    await _end(tester, c);
  });

  testWidgets('người mới (chưa có phiên): đăng nhập thường, không updateUser', (tester) async {
    final (c, results, auth, _) = await _pump(tester, idAfterVerify: 'u-new');
    await _linkThroughDialogs(tester);
    expect(auth.calls, ['signInWithOtp:a@b.c', 'verifyOTP:email']);
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    expect(results, [true]);
    await _end(tester, c);
  });

  testWidgets('email đã có tài khoản: rơi về đăng nhập thường vào tài khoản đó', (tester) async {
    final (c, results, auth, _) =
        await _pump(tester, start: mkUser(anon: true, id: 'u-legacy'), idAfterVerify: 'u-existing');
    auth.updateError =
        AuthException('A user with this email address has already been registered', statusCode: '422', code: 'email_exists');
    await _linkThroughDialogs(tester);
    expect(auth.calls, ['updateUser:a@b.c', 'signInWithOtp:a@b.c', 'verifyOTP:email']);
    expect(auth.currentUser!.id, 'u-existing');
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    expect(results, [true]);
    await _end(tester, c);
  });

  testWidgets('mã sai: không liên kết, vẫn bị chặn sau khi đóng', (tester) async {
    final (c, results, auth, _) = await _pump(tester, start: mkUser(anon: true, id: 'u-legacy'));
    auth.badCode = true;
    await _linkThroughDialogs(tester, code: '000000');
    expect(auth.currentUser!.isAnonymous, isTrue);
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    expect(results, [false]);
    await _end(tester, c);
  });

  testWidgets('đóng hộp thoại liên kết giữa chừng: vẫn bị chặn', (tester) async {
    final (c, results, _, _) = await _pump(tester, start: mkUser(anon: true, id: 'u-legacy'));
    await tester.tap(find.byKey(const Key('go')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('online-gate-link')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    expect(results, [false]);
    await _end(tester, c);
  });
}
