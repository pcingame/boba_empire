// Phát hiện save cloud "khác": phải xét cả 💎, không chỉ tiền kiếm được. Lỗi
// gốc: sửa `gems` trên cloud (quà tặng thủ công) không đổi lifetimeEarnings →
// máy lặng lẽ ghi nhận version mới rồi ĐÈ mất quà ở lần lưu kế tiếp.
import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/data/cloud_save_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

bool _diff({
  double cl = 1e6,
  double ll = 1e6,
  double cg = 100,
  double lg = 100,
}) =>
    cloudSaveLooksDifferent(
        cloudLifetime: cl, localLifetime: ll, cloudGems: cg, localGems: lg);

class _FakeRepo implements CloudSaveRepository {
  _FakeRepo(this.cloud);
  CloudSaveResult? cloud;
  int pushes = 0;

  @override
  bool get isLinked => true;
  @override
  String? get linkedEmail => 'a@b.c';
  @override
  Future<CloudSaveResult?> pull() async => cloud;
  @override
  Future<int> push(Map<String, dynamic> saveJson) async => ++pushes;
  @override
  Future<void> verifyCode(String email, String code) async {}
  @override
  Future<void> sendCode(String email) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<int?> pushIfCurrent(Map<String, dynamic> saveJson, int expectedVersion) async =>
      expectedVersion + 1;
}

CloudSaveResult _cloud({double lifetime = 1e6, double gems = 100, int v = 207}) =>
    CloudSaveResult(
        data: {'lifetimeEarnings': lifetime, 'gems': gems},
        updatedAt: DateTime(2026, 10, 8),
        version: v);

ProviderContainer _container(_FakeRepo repo,
    {double lifetime = 1e6, double gems = 100, void Function(int)? onVersion}) {
  final c = ProviderContainer();
  final n = c.read(cloudSaveControllerProvider.notifier);
  n.repository = repo;
  n.getLocalLifetimeEarnings = () => lifetime;
  n.getLocalGems = () => gems;
  n.getLocalSave = () => {'gems': gems, 'lifetimeEarnings': lifetime};
  n.onSyncVersionKnown = onVersion ?? (_) {};
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('cloudSaveLooksDifferent', () {
    test('LỖI GỐC: tiền kiếm được giống hệt nhưng cloud được cộng 100.000 💎 → khác',
        () {
      expect(_diff(cg: 100199, lg: 99), isTrue);
    });

    test('giống hệt → không khác', () {
      expect(_diff(), isFalse);
    });

    test('cả hai bên 0 (lifetime lẫn 💎) → không khác, không chia cho 0', () {
      expect(_diff(cl: 0, ll: 0, cg: 0, lg: 0), isFalse);
    });

    test('💎 lệch nhỏ (< 10) không làm phiền dù tỉ lệ lớn', () {
      expect(_diff(cg: 9, lg: 0), isFalse);
      expect(_diff(cg: 5, lg: 1), isFalse);
    });

    test('💎 lệch ≥ 10 và > 1% → khác (cả hai chiều)', () {
      expect(_diff(cg: 10, lg: 0), isTrue);
      expect(_diff(cg: 143, lg: 43), isTrue);
      expect(_diff(cg: 43, lg: 143), isTrue, reason: 'máy giữ nhiều hơn cloud');
    });

    test('💎 lệch ≥ 10 nhưng ≤ 1% của số lớn → không khác', () {
      expect(_diff(cg: 100500, lg: 100000), isFalse); // 0,5%
      expect(_diff(cg: 102000, lg: 100000), isTrue); // ~2%
    });

    test('tiền kiếm được lệch > 1% vẫn khác như trước, bất kể 💎', () {
      expect(_diff(cl: 1.05e6, ll: 1e6), isTrue);
      expect(_diff(cl: 1.005e6, ll: 1e6), isFalse);
      expect(_diff(cl: 3.4e80, ll: 3.4e80 * 1.05), isTrue);
    });

    test('một bên lifetime 0, bên kia có → khác (máy mới liên kết)', () {
      expect(_diff(cl: 5e5, ll: 0), isTrue);
    });
  });

  group('luồng thật qua CloudSaveController', () {
    test('recheckConflict: chỉ 💎 khác → hiện hộp thoại xung đột (KHÔNG lặng lẽ bỏ qua)',
        () async {
      var syncedVersion = -1;
      final repo = _FakeRepo(_cloud(gems: 100199));
      final c = _container(repo, gems: 99, onVersion: (v) => syncedVersion = v);
      await c.read(cloudSaveControllerProvider.notifier).recheckConflict();
      final s = c.read(cloudSaveControllerProvider);
      expect(s, isA<CloudSaveConflict>());
      expect((s as CloudSaveConflict).localGems, 99);
      expect(s.cloud.data['gems'], 100199);
      expect(syncedVersion, -1, reason: 'chưa được ghi nhận version khi chưa chọn');
    });

    test('recheckConflict: không khác gì → lặng lẽ đồng bộ version, trạng thái Linked',
        () async {
      var synced = -1;
      final repo = _FakeRepo(_cloud(gems: 100));
      final c = _container(repo, gems: 100, onVersion: (v) => synced = v);
      await c.read(cloudSaveControllerProvider.notifier).recheckConflict();
      expect(c.read(cloudSaveControllerProvider), isA<CloudSaveLinked>());
      expect(synced, 207);
    });

    test('chọn "Khôi phục từ cloud" → máy nhận save cloud (có 💎 quà)', () async {
      Map<String, dynamic>? restored;
      int? restoredVersion;
      final repo = _FakeRepo(_cloud(gems: 100199));
      final c = _container(repo, gems: 99);
      final n = c.read(cloudSaveControllerProvider.notifier);
      n.onRestore = (json, v) {
        restored = json;
        restoredVersion = v;
      };
      await n.recheckConflict();
      n.restoreFromCloud();
      expect(restored!['gems'], 100199);
      expect(restoredVersion, 207);
      expect(c.read(cloudSaveControllerProvider), isA<CloudSaveLinked>());
    });

    test('liên kết lần đầu (verifyCode): cloud chỉ khác 💎 cũng hỏi, không đẩy đè lên cloud',
        () async {
      final repo = _FakeRepo(_cloud(gems: 100199));
      final c = _container(repo, gems: 99);
      await c.read(cloudSaveControllerProvider.notifier).verifyCode('a@b.c', '123456');
      expect(c.read(cloudSaveControllerProvider), isA<CloudSaveConflict>());
      expect(repo.pushes, 0, reason: 'không được ghi đè cloud khi chưa hỏi');
    });

    test('liên kết lần đầu: hai bên giống nhau → đẩy save máy lên như cũ', () async {
      final repo = _FakeRepo(_cloud(gems: 100));
      final c = _container(repo, gems: 100);
      await c.read(cloudSaveControllerProvider.notifier).verifyCode('a@b.c', '123456');
      expect(c.read(cloudSaveControllerProvider), isA<CloudSaveLinked>());
      expect(repo.pushes, 1);
    });

    test('chọn "Giữ máy này" vẫn ghi đè cloud (hành vi cũ không đổi)', () async {
      final repo = _FakeRepo(_cloud(gems: 100199));
      final c = _container(repo, gems: 99);
      final n = c.read(cloudSaveControllerProvider.notifier);
      await n.recheckConflict();
      await n.keepLocal();
      expect(repo.pushes, 1);
      expect(c.read(cloudSaveControllerProvider), isA<CloudSaveLinked>());
    });

    test('chưa gán getLocalGems (test/UI cũ) → coi là 0, không ném lỗi', () async {
      final repo = _FakeRepo(_cloud(gems: 5));
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(cloudSaveControllerProvider.notifier);
      n.repository = repo;
      n.getLocalLifetimeEarnings = () => 1e6;
      n.onSyncVersionKnown = (_) {};
      await n.recheckConflict();
      expect(c.read(cloudSaveControllerProvider), isA<CloudSaveLinked>());
    });
  });
}
