/// Xác thực biên nhận IAP với store (Google Play / App Store).
///
/// SKELETON: [DevVerifier] chạy được ngay (chấp nhận mọi biên nhận) để test
/// wiring client↔server. [PlayVerifier] và [AppStoreVerifier] chứa khung gọi
/// API thật kèm TODO — điền credential rồi bật `VERIFY_MODE=prod`.
library;

import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Yêu cầu xác thực client gửi lên (khớp HttpReceiptVerifier phía app).
class VerifyRequest {
  const VerifyRequest({
    required this.productId,
    required this.source,
    required this.verificationData,
  });

  factory VerifyRequest.fromJson(Map<String, dynamic> json) => VerifyRequest(
        productId: json['productId'] as String? ?? '',
        source: json['source'] as String? ?? '',
        verificationData: json['verificationData'] as String? ?? '',
      );

  final String productId;

  /// 'google_play' hoặc 'app_store'.
  final String source;

  /// Play: purchase token. App Store: base64 receipt (StoreKit 1) hoặc JWS.
  final String verificationData;
}

abstract interface class Verifier {
  /// true nếu biên nhận hợp lệ và giao dịch có thật.
  Future<bool> verify(VerifyRequest req);
}

/// Chấp nhận mọi biên nhận — CHỈ để test wiring cục bộ, KHÔNG dùng ở production.
class DevVerifier implements Verifier {
  @override
  Future<bool> verify(VerifyRequest req) async {
    print('[DevVerifier] ⚠️ chấp nhận không kiểm chứng: ${req.productId}');
    return true;
  }
}

/// Xác thực với Google Play Developer API (androidpublisher).
///
/// Cần một service account có quyền "View financial data" và bundle id của app.
class PlayVerifier implements Verifier {
  PlayVerifier({required this.serviceAccountJson, required this.packageName});

  /// Nội dung file JSON của service account (không phải đường dẫn).
  final String serviceAccountJson;
  final String packageName;

  static const _scope =
      'https://www.googleapis.com/auth/androidpublisher';

  @override
  Future<bool> verify(VerifyRequest req) async {
    final creds = ServiceAccountCredentials.fromJson(serviceAccountJson);
    final client = await clientViaServiceAccount(creds, const [_scope]);
    try {
      // products.get: GET .../purchases/products/{productId}/tokens/{token}
      final url = Uri.https('androidpublisher.googleapis.com',
          '/androidpublisher/v3/applications/$packageName/purchases/products/'
          '${req.productId}/tokens/${req.verificationData}');
      final resp = await client.get(url);
      if (resp.statusCode != 200) return false;
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      // purchaseState: 0 = Purchased, 1 = Canceled, 2 = Pending.
      // TODO(prod): với consumable còn nên kiểm consumptionState / acknowledge
      // và chống replay bằng cách lưu orderId đã trao vào DB.
      return body['purchaseState'] == 0;
    } finally {
      client.close();
    }
  }
}

/// Xác thực với App Store (StoreKit 1 verifyReceipt endpoint).
class AppStoreVerifier implements Verifier {
  AppStoreVerifier({required this.sharedSecret, http.Client? client})
      : _client = client ?? http.Client();

  /// App-specific shared secret (App Store Connect → App → App Information).
  final String sharedSecret;
  final http.Client _client;

  static final _prod = Uri.parse('https://buy.itunes.apple.com/verifyReceipt');
  static final _sandbox =
      Uri.parse('https://sandbox.itunes.apple.com/verifyReceipt');

  @override
  Future<bool> verify(VerifyRequest req) async {
    // Apple khuyến nghị gọi prod trước; nếu status 21007 thì thử sandbox.
    var status = await _post(_prod, req.verificationData);
    if (status == 21007) status = await _post(_sandbox, req.verificationData);
    // TODO(prod): parse latest_receipt_info, đối chiếu product_id/bundle_id,
    // chống replay bằng transaction_id đã trao. StoreKit 2 (JWS) nên dùng
    // App Store Server API thay verifyReceipt (đã deprecated dần).
    return status == 0;
  }

  Future<int> _post(Uri url, String receipt) async {
    final resp = await _client.post(url,
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'receipt-data': receipt,
          'password': sharedSecret,
        }));
    if (resp.statusCode != 200) return -1;
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return body['status'] as int? ?? -1;
  }
}

/// Chọn verifier theo biến môi trường và [source] của request.
///
/// `VERIFY_MODE=dev` (mặc định) → luôn [DevVerifier]. `VERIFY_MODE=prod` →
/// Play/App Store thật theo source; thiếu credential thì ném lỗi để lộ cấu hình
/// sai (fail-closed phía server).
Verifier verifierFor(String source, Map<String, String> env) {
  final mode = env['VERIFY_MODE'] ?? 'dev';
  if (mode != 'prod') return DevVerifier();

  switch (source) {
    case 'google_play':
      final sa = env['PLAY_SERVICE_ACCOUNT_JSON'];
      final pkg = env['ANDROID_PACKAGE_NAME'];
      if (sa == null || pkg == null) {
        throw StateError('Thiếu PLAY_SERVICE_ACCOUNT_JSON/ANDROID_PACKAGE_NAME');
      }
      return PlayVerifier(serviceAccountJson: sa, packageName: pkg);
    case 'app_store':
      final secret = env['APPSTORE_SHARED_SECRET'];
      if (secret == null) {
        throw StateError('Thiếu APPSTORE_SHARED_SECRET');
      }
      return AppStoreVerifier(sharedSecret: secret);
    default:
      throw ArgumentError('source không hỗ trợ: $source');
  }
}
