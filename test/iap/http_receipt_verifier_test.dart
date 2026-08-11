import 'dart:convert';

import 'package:boba_empire/iap/http_receipt_verifier.dart';
import 'package:boba_empire/iap/receipt_verifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _receipt = PurchaseReceipt(
  productId: 'boba_gems_small',
  source: 'google_play',
  verificationData: 'token-123',
);

HttpReceiptVerifier _verifierReturning(http.Response Function() respond) {
  final client = MockClient((req) async {
    // Gửi đúng payload lên endpoint.
    final body = jsonDecode(req.body) as Map<String, dynamic>;
    expect(body['productId'], 'boba_gems_small');
    expect(body['source'], 'google_play');
    expect(body['verificationData'], 'token-123');
    return respond();
  });
  return HttpReceiptVerifier(Uri.parse('https://x/verify'), client: client);
}

void main() {
  test('200 {valid:true} → valid', () async {
    final v = _verifierReturning(() => http.Response('{"valid":true}', 200));
    expect(await v.verify(_receipt), VerifyResult.valid);
  });

  test('200 {valid:false} → invalid (chặn trao thưởng)', () async {
    final v = _verifierReturning(() => http.Response('{"valid":false}', 200));
    expect(await v.verify(_receipt), VerifyResult.invalid);
  });

  test('không 200 → unavailable (fail-open)', () async {
    final v = _verifierReturning(() => http.Response('nope', 500));
    expect(await v.verify(_receipt), VerifyResult.unavailable);
  });

  test('ngoại lệ mạng → unavailable (fail-open)', () async {
    final client = MockClient((_) async => throw Exception('down'));
    final v = HttpReceiptVerifier(Uri.parse('https://x/verify'), client: client);
    expect(await v.verify(_receipt), VerifyResult.unavailable);
  });
}
