// Tính năng online chỉ cho tài khoản đã liên kết email; nâng cấp tài khoản ẩn danh phải GIỮ user_id.
import 'package:boba_empire/data/cloud_save_repository.dart';
import 'package:boba_empire/data/linked_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User _user({required bool anon, String id = 'u1', String? email}) => User(
      id: id,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-10-12T00:00:00Z',
      email: email,
      isAnonymous: anon,
    );

/// GoTrue giả: ghi lại lệnh gọi, không đụng mạng.
class _FakeAuth extends GoTrueClient {
  _FakeAuth(this._user) : super(url: 'http://localhost', headers: const {});
  final User? _user;
  final calls = <String>[];
  AuthException? updateError;

  @override
  User? get currentUser => _user;

  @override
  Future<UserResponse> updateUser(UserAttributes attributes, {String? emailRedirectTo}) async {
    calls.add('updateUser:${attributes.email}');
    if (updateError != null) throw updateError!;
    return UserResponse.fromJson(<String, dynamic>{
      'id': 'u1',
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
  }

  @override
  Future<AuthResponse> verifyOTP({
    String? email, String? phone, String? token, required OtpType type,
    String? redirectTo, String? captchaToken, String? tokenHash,
  }) async {
    calls.add('verifyOTP:${type.name}:$token');
    return AuthResponse();
  }
}

void main() {
  group('requireLinkedId', () {
    test('chưa đăng nhập hoặc còn ẩn danh → NotLinkedException', () {
      expect(() => requireLinkedId(null), throwsA(isA<NotLinkedException>()));
      expect(() => requireLinkedId(_user(anon: true)), throwsA(isA<NotLinkedException>()));
    });
    test('đã liên kết email → trả user_id', () {
      expect(requireLinkedId(_user(anon: false, id: 'abc', email: 'a@b.c')), 'abc');
    });
  });

  group('liên kết email: nâng cấp tại chỗ', () {
    test('phiên ẩn danh → updateUser(email) rồi xác nhận bằng email_change (giữ user_id)', () async {
      final auth = _FakeAuth(_user(anon: true));
      final repo = CloudSaveRepository(SupabaseClient('http://localhost', 'anon'), auth: auth);
      await repo.sendCode('a@b.c');
      await repo.verifyCode('a@b.c', '123456');
      expect(auth.calls, ['updateUser:a@b.c', 'verifyOTP:emailChange:123456']);
    });

    test('email đã thuộc tài khoản khác → rơi về đăng nhập thường (signInWithOtp + loại email)', () async {
      final auth = _FakeAuth(_user(anon: true))
        ..updateError = AuthException('A user with this email address has already been registered',
            statusCode: '422', code: 'email_exists');
      final repo = CloudSaveRepository(SupabaseClient('http://localhost', 'anon'), auth: auth);
      await repo.sendCode('old@b.c');
      await repo.verifyCode('old@b.c', '654321');
      expect(auth.calls, ['updateUser:old@b.c', 'signInWithOtp:old@b.c', 'verifyOTP:email:654321']);
    });

    test('lỗi khác của updateUser (vd gửi quá nhanh) thì ném lên, không đổi sang đăng nhập thường', () async {
      final auth = _FakeAuth(_user(anon: true))
        ..updateError = AuthException('rate limit', statusCode: '429', code: 'over_email_send_rate_limit');
      final repo = CloudSaveRepository(SupabaseClient('http://localhost', 'anon'), auth: auth);
      await expectLater(repo.sendCode('a@b.c'), throwsA(isA<AuthException>()));
      expect(auth.calls, ['updateUser:a@b.c']);
    });

    test('chưa có phiên nào (người mới) → đăng nhập thường, không updateUser', () async {
      final auth = _FakeAuth(null);
      final repo = CloudSaveRepository(SupabaseClient('http://localhost', 'anon'), auth: auth);
      await repo.sendCode('new@b.c');
      await repo.verifyCode('new@b.c', '111111');
      expect(auth.calls, ['signInWithOtp:new@b.c', 'verifyOTP:email:111111']);
    });

    test('isLinked chỉ đúng với tài khoản không ẩn danh', () {
      final c = SupabaseClient('http://localhost', 'anon');
      expect(CloudSaveRepository(c, auth: _FakeAuth(_user(anon: true))).isLinked, isFalse);
      expect(CloudSaveRepository(c, auth: _FakeAuth(null)).isLinked, isFalse);
      final linked = CloudSaveRepository(c, auth: _FakeAuth(_user(anon: false, email: 'a@b.c')));
      expect(linked.isLinked, isTrue);
      expect(linked.linkedEmail, 'a@b.c');
    });
  });
}
