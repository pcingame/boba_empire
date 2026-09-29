// Nhánh chặn phát lại (replay) là chỗ quan trọng nhất trong toàn bộ server
// này — sai một trong hai hướng đều tốn tiền thật:
//   - Chặn quá tay non-consumable: chặn nhầm "Khôi phục giao dịch mua" hợp
//     lệ (người chơi đổi máy).
//   - Chặn quá lỏng consumable: cho phát lại 1 giao dịch để cộng 💎 nhiều
//     lần — mất tiền thật trực tiếp.
// Test bằng Verifier GIẢ (không cần credential Play/App Store thật) — đúng
// lý do verifyHandler nhận `verifierFor` qua tham số thay vì tự đọc
// Platform.environment.
import 'dart:convert';

import 'package:boba_receipt_server/handler.dart';
import 'package:boba_receipt_server/replay_store.dart';
import 'package:boba_receipt_server/verifier.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class _FixedVerifier implements Verifier {
  _FixedVerifier(this.id);
  final String? id;
  @override
  Future<String?> verify(VerifyRequest req) async => id;
}

Request _req(Map<String, dynamic> body) => Request(
      'POST',
      Uri.parse('http://x/verify'),
      body: jsonEncode(body),
    );

Future<bool> _valid(Response resp) async {
  final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
  return body['valid'] as bool;
}

void main() {
  group('phát lại consumable', () {
    test('lần đầu hợp lệ, lần 2 với ĐÚNG transaction id bị chặn', () async {
      final replay = InMemoryReplayStore();
      Verifier verifierFor(String s) => _FixedVerifier('tx-1');
      final body = {
        'productId': 'boba_gems_small',
        'source': 'app_store',
        'verificationData': 'jws-abc',
        'kind': 'consumable',
      };

      final r1 = await verifyHandler(_req(body), replay, verifierFor);
      expect(await _valid(r1), isTrue);

      final r2 = await verifyHandler(_req(body), replay, verifierFor);
      expect(await _valid(r2), isFalse, reason: 'phát lại consumable phải bị chặn');
    });

    test('hai giao dịch KHÁC transaction id đều hợp lệ (không phải replay)',
        () async {
      final replay = InMemoryReplayStore();
      var call = 0;
      Verifier verifierFor(String s) =>
          _FixedVerifier('tx-${++call}'); // id khác nhau mỗi lần.
      final body = {
        'productId': 'boba_gems_small',
        'source': 'app_store',
        'verificationData': 'jws-abc',
        'kind': 'consumable',
      };

      expect(await _valid(await verifyHandler(_req(body), replay, verifierFor)),
          isTrue);
      expect(await _valid(await verifyHandler(_req(body), replay, verifierFor)),
          isTrue);
    });
  });

  test('non-consumable: gửi lại ĐÚNG transaction id cũ vẫn hợp lệ (khôi phục)',
      () async {
    final replay = InMemoryReplayStore();
    Verifier verifierFor(String s) => _FixedVerifier('tx-1');
    final body = {
      'productId': 'boba_remove_ads',
      'source': 'app_store',
      'verificationData': 'jws-abc',
      'kind': 'non_consumable',
    };

    final r1 = await verifyHandler(_req(body), replay, verifierFor);
    expect(await _valid(r1), isTrue);

    // Gửi lại y hệt (đúng luồng "Khôi phục giao dịch mua") — PHẢI vẫn hợp lệ.
    final r2 = await verifyHandler(_req(body), replay, verifierFor);
    expect(await _valid(r2), isTrue,
        reason: 'khôi phục non-consumable không được coi là replay');
  });

  test('verifier trả null (biên nhận giả) -> invalid, không đụng replay store',
      () async {
    final replay = InMemoryReplayStore();
    Verifier verifierFor(String s) => _FixedVerifier(null);
    final body = {
      'productId': 'boba_gems_small',
      'source': 'app_store',
      'verificationData': 'jws-hỏng',
      'kind': 'consumable',
    };
    final resp = await verifyHandler(_req(body), replay, verifierFor);
    expect(await _valid(resp), isFalse);
  });

  test('thiếu productId/verificationData -> 400, không gọi verifier', () async {
    var called = false;
    Verifier verifierFor(String s) {
      called = true;
      return _FixedVerifier('tx-1');
    }

    final resp = await verifyHandler(
      _req({'productId': '', 'source': 'app_store', 'verificationData': ''}),
      InMemoryReplayStore(),
      verifierFor,
    );
    expect(resp.statusCode, 400);
    expect(called, isFalse);
  });

  test('verifier ném lỗi -> 500 (client fail-open ở tầng gọi, không phải ở đây)',
      () async {
    Verifier verifierFor(String s) => _ThrowingVerifier();
    final resp = await verifyHandler(
      _req({
        'productId': 'boba_gems_small',
        'source': 'app_store',
        'verificationData': 'x',
      }),
      InMemoryReplayStore(),
      verifierFor,
    );
    expect(resp.statusCode, 500);
  });
}

class _ThrowingVerifier implements Verifier {
  @override
  Future<String?> verify(VerifyRequest req) => throw StateError('boom');
}
