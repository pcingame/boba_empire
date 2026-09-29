import 'dart:io';

import 'package:boba_receipt_server/verifier.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

// Khoá test (KHÔNG phải khoá thật của Apple) — xem fixtures/README.md.
final _testKey =
    ECPrivateKey(File('test/fixtures/test_ec_private.pem').readAsStringSync());

/// Dựng một JWS trông giống StoreKit 2 gửi lên (chỉ cần payload có
/// transactionId — AppStoreVerifier chỉ đọc field này từ JWS của CLIENT,
/// không kiểm chữ ký của nó).
String _fakeClientJws(String transactionId) => JWT(
      <String, dynamic>{'transactionId': transactionId},
    ).sign(_testKey, algorithm: JWTAlgorithm.ES256);

/// Dựng JWS trông giống `signedTransactionInfo` Apple trả về.
String _fakeAppleTransactionJws({
  required String transactionId,
  required String bundleId,
  required String productId,
  String? revocationDate,
}) =>
    JWT(<String, dynamic>{
      'transactionId': transactionId,
      'bundleId': bundleId,
      'productId': productId,
      if (revocationDate != null) 'revocationDate': revocationDate,
    }).sign(_testKey, algorithm: JWTAlgorithm.ES256);

void main() {
  group('VerifyRequest.fromJson — parse kind', () {
    test('kind: "non_consumable" -> isConsumable false', () {
      final r = VerifyRequest.fromJson({
        'productId': 'boba_remove_ads',
        'source': 'app_store',
        'verificationData': 'x',
        'kind': 'non_consumable',
      });
      expect(r.isConsumable, isFalse);
    });

    test('kind: "consumable" -> isConsumable true', () {
      final r = VerifyRequest.fromJson({
        'productId': 'boba_gems_small',
        'source': 'app_store',
        'verificationData': 'x',
        'kind': 'consumable',
      });
      expect(r.isConsumable, isTrue);
    });

    test('thiếu field kind (client cũ) -> mặc định coi là consumable (an toàn'
        ' hơn về tiền, xem chú thích trong verifier.dart)', () {
      final r = VerifyRequest.fromJson({
        'productId': 'boba_remove_ads',
        'source': 'app_store',
        'verificationData': 'x',
      });
      expect(r.isConsumable, isTrue);
    });
  });

  group('playPostPurchaseAction', () {
    test('consumable, CHƯA consume -> "consume"', () {
      expect(
          playPostPurchaseAction(
              isConsumable: true, consumptionState: 0, acknowledgementState: null),
          'consume');
    });
    test('consumable, ĐÃ consume -> null (không gọi lại)', () {
      expect(
          playPostPurchaseAction(
              isConsumable: true, consumptionState: 1, acknowledgementState: null),
          isNull);
    });
    test('non-consumable, CHƯA acknowledge -> "acknowledge"', () {
      expect(
          playPostPurchaseAction(
              isConsumable: false, consumptionState: null, acknowledgementState: 0),
          'acknowledge');
    });
    test('non-consumable, ĐÃ acknowledge -> null', () {
      expect(
          playPostPurchaseAction(
              isConsumable: false, consumptionState: null, acknowledgementState: 1),
          isNull);
    });
    test('non-consumable, thiếu field (null) -> vẫn "acknowledge" (an toàn hơn'
        ' gọi thừa còn hơn quên, Play tự bỏ qua nếu đã acknowledge rồi)', () {
      expect(
          playPostPurchaseAction(
              isConsumable: false, consumptionState: null, acknowledgementState: null),
          'acknowledge');
    });
  });

  group('DevVerifier', () {
    test('trả id KHÁC nhau mỗi lần gọi (không phải hằng số cố định)',
        () async {
      final v = DevVerifier();
      final req = VerifyRequest(
          productId: 'p', source: 's', verificationData: 'v', isConsumable: true);
      final id1 = await v.verify(req);
      final id2 = await v.verify(req);
      expect(id1, isNotNull);
      expect(id1, isNot(equals(id2)));
    });
  });

  group('AppStoreVerifier', () {
    const bundleId = 'com.pcingame.bobaempire';
    const productId = 'boba_gems_small';

    test('giao dịch hợp lệ (prod) -> trả về đúng transactionId', () async {
      final client = MockClient((req) async {
        expect(req.url.host, 'api.storekit.itunes.apple.com');
        expect(req.url.path, '/inApps/v1/transactions/tx-42');
        expect(req.headers['authorization'], startsWith('Bearer '));
        return http.Response(
          '{"signedTransactionInfo": "${_fakeAppleTransactionJws(
            transactionId: 'tx-42',
            bundleId: bundleId,
            productId: productId,
          )}"}',
          200,
        );
      });
      final v = AppStoreVerifier(
        keyId: 'kid',
        issuerId: 'iss',
        bundleId: bundleId,
        privateKeyPem: File('test/fixtures/test_ec_private.pem').readAsStringSync(),
        client: client,
      );
      final req = VerifyRequest(
          productId: productId,
          source: 'app_store',
          verificationData: _fakeClientJws('tx-42'),
          isConsumable: true);
      expect(await v.verify(req), 'tx-42');
    });

    test('404 ở prod -> tự thử sandbox', () async {
      var calls = <String>[];
      final client = MockClient((req) async {
        calls.add(req.url.host);
        if (req.url.host == 'api.storekit.itunes.apple.com') {
          return http.Response('not found', 404);
        }
        expect(req.url.host, 'api.storekit-sandbox.itunes.apple.com');
        return http.Response(
          '{"signedTransactionInfo": "${_fakeAppleTransactionJws(
            transactionId: 'tx-1',
            bundleId: bundleId,
            productId: productId,
          )}"}',
          200,
        );
      });
      final v = AppStoreVerifier(
        keyId: 'kid',
        issuerId: 'iss',
        bundleId: bundleId,
        privateKeyPem: File('test/fixtures/test_ec_private.pem').readAsStringSync(),
        client: client,
      );
      final req = VerifyRequest(
          productId: productId,
          source: 'app_store',
          verificationData: _fakeClientJws('tx-1'),
          isConsumable: true);
      expect(await v.verify(req), 'tx-1');
      expect(calls, [
        'api.storekit.itunes.apple.com',
        'api.storekit-sandbox.itunes.apple.com'
      ]);
    });

    test('bundleId trả về KHÔNG khớp -> null (chặn giả mạo)', () async {
      final client = MockClient((_) async => http.Response(
            '{"signedTransactionInfo": "${_fakeAppleTransactionJws(
              transactionId: 'tx-1',
              bundleId: 'com.ke.gia.mao',
              productId: productId,
            )}"}',
            200,
          ));
      final v = AppStoreVerifier(
        keyId: 'kid',
        issuerId: 'iss',
        bundleId: bundleId,
        privateKeyPem: File('test/fixtures/test_ec_private.pem').readAsStringSync(),
        client: client,
      );
      final req = VerifyRequest(
          productId: productId,
          source: 'app_store',
          verificationData: _fakeClientJws('tx-1'),
          isConsumable: true);
      expect(await v.verify(req), isNull);
    });

    test('productId trả về KHÔNG khớp product đang mua -> null', () async {
      final client = MockClient((_) async => http.Response(
            '{"signedTransactionInfo": "${_fakeAppleTransactionJws(
              transactionId: 'tx-1',
              bundleId: bundleId,
              productId: 'boba_vip30', // khác product client báo đang mua.
            )}"}',
            200,
          ));
      final v = AppStoreVerifier(
        keyId: 'kid',
        issuerId: 'iss',
        bundleId: bundleId,
        privateKeyPem: File('test/fixtures/test_ec_private.pem').readAsStringSync(),
        client: client,
      );
      final req = VerifyRequest(
          productId: productId, // client báo đang mua gems_small
          source: 'app_store',
          verificationData: _fakeClientJws('tx-1'),
          isConsumable: true);
      expect(await v.verify(req), isNull);
    });

    test('revocationDate khác null (đã hoàn tiền) -> null', () async {
      final client = MockClient((_) async => http.Response(
            '{"signedTransactionInfo": "${_fakeAppleTransactionJws(
              transactionId: 'tx-1',
              bundleId: bundleId,
              productId: productId,
              revocationDate: '1700000000000',
            )}"}',
            200,
          ));
      final v = AppStoreVerifier(
        keyId: 'kid',
        issuerId: 'iss',
        bundleId: bundleId,
        privateKeyPem: File('test/fixtures/test_ec_private.pem').readAsStringSync(),
        client: client,
      );
      final req = VerifyRequest(
          productId: productId,
          source: 'app_store',
          verificationData: _fakeClientJws('tx-1'),
          isConsumable: true);
      expect(await v.verify(req), isNull);
    });

    test('verificationData không phải JWS hợp lệ -> null, không gọi mạng',
        () async {
      var called = false;
      final client = MockClient((_) async {
        called = true;
        return http.Response('', 200);
      });
      final v = AppStoreVerifier(
        keyId: 'kid',
        issuerId: 'iss',
        bundleId: bundleId,
        privateKeyPem: File('test/fixtures/test_ec_private.pem').readAsStringSync(),
        client: client,
      );
      final req = VerifyRequest(
          productId: productId,
          source: 'app_store',
          verificationData: 'không-phải-jws',
          isConsumable: true);
      expect(await v.verify(req), isNull);
      expect(called, isFalse);
    });
  });

  group('verifierFor', () {
    test('VERIFY_MODE mặc định (không đặt) -> DevVerifier', () {
      expect(verifierFor('app_store', const {}), isA<DevVerifier>());
    });

    test('prod + thiếu credential App Store -> ném lỗi rõ ràng (fail-closed)',
        () {
      expect(
        () => verifierFor('app_store', const {'VERIFY_MODE': 'prod'}),
        throwsA(isA<StateError>()),
      );
    });

    test('prod + thiếu credential Play -> ném lỗi rõ ràng', () {
      expect(
        () => verifierFor('google_play', const {'VERIFY_MODE': 'prod'}),
        throwsA(isA<StateError>()),
      );
    });

    test('source lạ -> ném lỗi', () {
      expect(
        () => verifierFor('unknown_store', const {'VERIFY_MODE': 'prod'}),
        throwsArgumentError,
      );
    });
  });
}
