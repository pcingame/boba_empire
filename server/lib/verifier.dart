/// Xác thực biên nhận IAP với store (Google Play / App Store).
///
/// [DevVerifier] chạy được ngay (chấp nhận mọi biên nhận) để test wiring
/// client↔server. [PlayVerifier]/[AppStoreVerifier] gọi API thật — điền
/// credential rồi bật `VERIFY_MODE=prod` (xem README.md).
library;

import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Yêu cầu xác thực client gửi lên (khớp HttpReceiptVerifier phía app).
class VerifyRequest {
  const VerifyRequest({
    required this.productId,
    required this.source,
    required this.verificationData,
    required this.isConsumable,
  });

  factory VerifyRequest.fromJson(Map<String, dynamic> json) => VerifyRequest(
        productId: json['productId'] as String? ?? '',
        source: json['source'] as String? ?? '',
        verificationData: json['verificationData'] as String? ?? '',
        // Thiếu/không nhận ra field 'kind' -> coi là consumable. An toàn hơn
        // về tiền: quá tay chặn nhầm 1 lần khôi phục non-consumable (hiếm,
        // người chơi thử lại là được) còn hơn lọt 1 lần phát lại consumable
        // (mất tiền thật ngay lập tức). Xem PurchaseReceipt.isConsumable
        // (lib/iap/receipt_verifier.dart) — client bản mới luôn gửi field
        // này, đường này chỉ để đỡ cho client cũ/thiếu field.
        isConsumable: json['kind'] != 'non_consumable',
      );

  final String productId;

  /// 'google_play' hoặc 'app_store'.
  final String source;

  /// Play: purchase token. App Store: JWS (jwsRepresentation từ StoreKit 2 —
  /// KHÔNG phải base64 receipt kiểu StoreKit 1 cũ, xem AppStoreVerifier).
  final String verificationData;

  /// true = consumable (💎, đập heo, VIP Pass) — chặn phát lại + Play cần
  /// `consume`. false = non-consumable (gỡ QC, x2 thu nhập, starter pack) —
  /// CHO PHÉP phát lại (đó là luồng khôi phục giao dịch hợp lệ) + Play cần
  /// `acknowledge` thay vì `consume`.
  final bool isConsumable;
}

/// Kết quả xác thực: `null` = không hợp lệ. Khác `null` = id giao dịch
/// (Play: orderId. App Store: transactionId) — tầng gọi dùng id này để chặn
/// phát lại qua [ReplayStore] (chỉ với consumable, xem replay_store.dart).
abstract interface class Verifier {
  Future<String?> verify(VerifyRequest req);
}

/// Chấp nhận mọi biên nhận — CHỈ để test wiring cục bộ, KHÔNG dùng ở production.
class DevVerifier implements Verifier {
  @override
  Future<String?> verify(VerifyRequest req) async {
    print('[DevVerifier] ⚠️ chấp nhận không kiểm chứng: ${req.productId}');
    // Giả một id duy nhất mỗi lần gọi để logic chặn phát lại phía trên vẫn
    // chạy được khi test cục bộ (không phải hằng số cố định — sẽ luôn bị
    // ReplayStore coi là "đã dùng" từ lần gọi thứ 2).
    return 'dev-${req.productId}-${DateTime.now().microsecondsSinceEpoch}';
  }
}

/// Endpoint Play cần gọi SAU KHI verify thành công (`:consume` / `:acknowledge`
/// / không gọi gì nếu đã làm rồi) — tách thành hàm thuần để test không cần
/// dựng cả OAuth service-account flow thật.
///
///   consumptionState:     0 = chưa consume,     1 = đã consume.
///   acknowledgementState: 0 = chưa acknowledge, 1 = đã acknowledge.
String? playPostPurchaseAction({
  required bool isConsumable,
  required int? consumptionState,
  required int? acknowledgementState,
}) {
  if (isConsumable) {
    return consumptionState == 1 ? null : 'consume';
  }
  return acknowledgementState == 1 ? null : 'acknowledge';
}

/// Xác thực với Google Play Developer API (androidpublisher).
///
/// Cần một service account có quyền "View financial data" và bundle id của app.
class PlayVerifier implements Verifier {
  PlayVerifier({
    required this.serviceAccountJson,
    required this.packageName,
    http.Client Function()? httpClientFactory,
  }) : _httpClientFactory = httpClientFactory ?? http.Client.new;

  /// Nội dung file JSON của service account (không phải đường dẫn).
  final String serviceAccountJson;
  final String packageName;
  final http.Client Function() _httpClientFactory;

  static const _scope = 'https://www.googleapis.com/auth/androidpublisher';

  @override
  Future<String?> verify(VerifyRequest req) async {
    final creds = ServiceAccountCredentials.fromJson(serviceAccountJson);
    final client =
        await clientViaServiceAccount(creds, const [_scope], baseClient: _httpClientFactory());
    try {
      final base = Uri.https('androidpublisher.googleapis.com',
          '/androidpublisher/v3/applications/$packageName/purchases/products/'
          '${req.productId}/tokens/${req.verificationData}');
      final resp = await client.get(base);
      if (resp.statusCode != 200) return null;
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      // purchaseState: 0 = Purchased, 1 = Canceled, 2 = Pending.
      if (body['purchaseState'] != 0) return null;

      // Play tự HOÀN TIỀN sau ~3 ngày nếu giao dịch không được
      // acknowledge/consume — bắt buộc, không phải tuỳ chọn.
      final action = playPostPurchaseAction(
        isConsumable: req.isConsumable,
        consumptionState: body['consumptionState'] as int?,
        acknowledgementState: body['acknowledgementState'] as int?,
      );
      if (action != null) {
        await client.post(
            Uri.https('androidpublisher.googleapis.com', '${base.path}:$action'));
      }

      // orderId vắng mặt cực hiếm (giao dịch thử nghiệm nội bộ) — dùng luôn
      // purchase token làm id thay thế, vẫn duy nhất mỗi giao dịch.
      return (body['orderId'] as String?) ?? req.verificationData;
    } finally {
      client.close();
    }
  }
}

/// Xác thực với App Store Server API (StoreKit 2).
///
/// KHÔNG dùng endpoint `verifyReceipt` (StoreKit 1) cũ — `in_app_purchase_
/// storekit` bản đang dùng (>=0.3, xem pubspec.lock) gửi lên
/// `serverVerificationData` là JWS (jwsRepresentation) ký bởi StoreKit 2,
/// KHÔNG PHẢI base64 receipt mà verifyReceipt hiểu — endpoint cũ sẽ luôn trả
/// lỗi định dạng cho MỌI giao dịch thật.
///
/// Cách xác thực: đọc `transactionId` từ JWS client gửi (không cần kiểm chữ
/// ký ở bước này — chỉ dùng để biết gọi API với id nào), rồi GỌI App Store
/// Server API bằng JWT tự ký (khoá riêng của app) — bước gọi có xác thực
/// hai chiều (TLS + JWT) này mới là xác thực thật. Đọc payload trong JWS mà
/// Apple trả về cũng KHÔNG tự kiểm chữ ký cục bộ (bỏ qua chuỗi x5c +
/// CRL/OCSP) — kênh gọi Apple đã xác thực rồi, tự dựng lại việc Apple đã làm
/// là thừa.
///
/// ponytail: bỏ qua kiểm chữ ký x5c cục bộ — chỉ cần nâng cấp nếu sau này
/// cần xác thực OFFLINE (không gọi mạng tới Apple mỗi lần).
class AppStoreVerifier implements Verifier {
  AppStoreVerifier({
    required this.keyId,
    required this.issuerId,
    required this.bundleId,
    required this.privateKeyPem,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// App Store Connect → Users and Access → Integrations → khoá "In-App
  /// Purchase" hoặc "App Store Server API" — 3 thứ đi cùng nhau (key id,
  /// issuer id, và nội dung file .p8).
  final String keyId;
  final String issuerId;
  final String bundleId;

  /// Nội dung file .p8 (PEM) — dán cả khối `-----BEGIN PRIVATE KEY-----...`.
  final String privateKeyPem;
  final http.Client _client;

  static final _prod = Uri.parse('https://api.storekit.itunes.apple.com');
  static final _sandbox =
      Uri.parse('https://api.storekit-sandbox.itunes.apple.com');

  @override
  Future<String?> verify(VerifyRequest req) async {
    final transactionId = _readTransactionId(req.verificationData);
    if (transactionId == null) return null;

    final authToken = _signAuthToken();
    // Apple không có cách nào để biết trước giao dịch là sandbox hay prod —
    // thử prod trước (đa số giao dịch thật), 404 thì thử sandbox (cùng cách
    // verifyReceipt cũ thử prod-rồi-sandbox qua status 21007).
    var info = await _fetchTransaction(_prod, transactionId, authToken);
    info ??= await _fetchTransaction(_sandbox, transactionId, authToken);
    if (info == null) return null;

    if (info['bundleId'] != bundleId) return null;
    if (info['productId'] != req.productId) return null;
    if (info['revocationDate'] != null) return null; // đã hoàn tiền/thu hồi.

    return transactionId;
  }

  String? _readTransactionId(String jws) {
    try {
      final payload = JWT.decode(jws).payload;
      if (payload is! Map) return null;
      final id = payload['transactionId'];
      return id is String && id.isNotEmpty ? id : null;
    } catch (_) {
      return null; // JWS hỏng hình dạng.
    }
  }

  String _signAuthToken() {
    final jwt = JWT(
      <String, dynamic>{'bid': bundleId},
      issuer: issuerId,
      audience: Audience.one('appstoreconnect-v1'),
      header: {'kid': keyId},
    );
    // Apple giới hạn tối đa 60 phút; 5 phút là đủ cho một lần gọi và giảm rủi
    // ro nếu token bị lộ ra ngoài.
    return jwt.sign(ECPrivateKey(privateKeyPem),
        algorithm: JWTAlgorithm.ES256, expiresIn: const Duration(minutes: 5));
  }

  Future<Map<String, dynamic>?> _fetchTransaction(
      Uri base, String transactionId, String authToken) async {
    final url = base.replace(path: '/inApps/v1/transactions/$transactionId');
    final resp = await _client
        .get(url, headers: {'authorization': 'Bearer $authToken'});
    if (resp.statusCode != 200) return null;
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final signed = body['signedTransactionInfo'] as String?;
    if (signed == null) return null;
    try {
      final payload = JWT.decode(signed).payload;
      return payload is Map<String, dynamic> ? payload : null;
    } catch (_) {
      return null;
    }
  }
}

/// Chọn verifier theo biến môi trường và [source] của request.
///
/// `VERIFY_MODE=dev` (mặc định) → luôn [DevVerifier]. `VERIFY_MODE=prod` →
/// Play/App Store thật theo source; thiếu credential thì ném lỗi để lộ cấu
/// hình sai (fail-closed phía server).
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
      final keyId = env['APPSTORE_KEY_ID'];
      final issuerId = env['APPSTORE_ISSUER_ID'];
      final bundleId = env['APPSTORE_BUNDLE_ID'];
      final privateKey = env['APPSTORE_PRIVATE_KEY'];
      if (keyId == null ||
          issuerId == null ||
          bundleId == null ||
          privateKey == null) {
        throw StateError('Thiếu APPSTORE_KEY_ID/APPSTORE_ISSUER_ID/'
            'APPSTORE_BUNDLE_ID/APPSTORE_PRIVATE_KEY');
      }
      return AppStoreVerifier(
        keyId: keyId,
        issuerId: issuerId,
        bundleId: bundleId,
        privateKeyPem: privateKey,
      );
    default:
      throw ArgumentError('source không hỗ trợ: $source');
  }
}
