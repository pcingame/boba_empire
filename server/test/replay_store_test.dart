import 'package:boba_receipt_server/replay_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryReplayStore', () {
    test('lần đầu true, lần 2 CÙNG (source, id) false', () async {
      final s = InMemoryReplayStore();
      expect(await s.reserve('app_store', 'tx-1'), isTrue);
      expect(await s.reserve('app_store', 'tx-1'), isFalse);
    });

    test('khác source, CÙNG id -> không đụng nhau (đều true)', () async {
      final s = InMemoryReplayStore();
      expect(await s.reserve('app_store', 'tx-1'), isTrue);
      expect(await s.reserve('google_play', 'tx-1'), isTrue);
    });
  });

  group('SupabaseReplayStore', () {
    test('HTTP 201 -> true, gửi đúng payload + service role key', () async {
      final client = MockClient((req) async {
        expect(req.url.toString(),
            'https://x.supabase.co/rest/v1/iap_redeemed_receipts');
        expect(req.headers['apikey'], 'sr-key');
        expect(req.headers['authorization'], 'Bearer sr-key');
        return http.Response('', 201);
      });
      final s = SupabaseReplayStore(
          supabaseUrl: 'https://x.supabase.co',
          serviceRoleKey: 'sr-key',
          client: client);
      expect(await s.reserve('app_store', 'tx-1'), isTrue);
    });

    test('HTTP 409 (vi phạm UNIQUE) -> false', () async {
      final client = MockClient((_) async => http.Response('conflict', 409));
      final s = SupabaseReplayStore(
          supabaseUrl: 'https://x.supabase.co',
          serviceRoleKey: 'sr-key',
          client: client);
      expect(await s.reserve('app_store', 'tx-1'), isFalse);
    });

    test('lỗi khác (500/mạng) -> ném lỗi, KHÔNG lặng lẽ coi là hợp lệ',
        () async {
      final client = MockClient((_) async => http.Response('boom', 500));
      final s = SupabaseReplayStore(
          supabaseUrl: 'https://x.supabase.co',
          serviceRoleKey: 'sr-key',
          client: client);
      expect(() => s.reserve('app_store', 'tx-1'), throwsStateError);
    });
  });
}
