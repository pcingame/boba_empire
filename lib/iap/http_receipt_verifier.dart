/// [ReceiptVerifier] gọi backend qua HTTP. Chỉ `main()` import file này để giữ
/// phụ thuộc package:http ở rìa (giống real_ad_service/real_iap_service).
///
/// Chính sách FAIL-OPEN: chỉ chặn trao thưởng khi server trả lời DỨT KHOÁT
/// {valid:false}. Mọi lỗi khác (không 200, timeout, ngoại lệ) → [unavailable] →
/// tầng gọi vẫn trao thưởng để không kẹt người mua thật khi mạng chập chờn.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'receipt_verifier.dart';

class HttpReceiptVerifier implements ReceiptVerifier {
  HttpReceiptVerifier(
    this.endpoint, {
    http.Client? client,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client();

  /// URL endpoint POST /verify của backend.
  final Uri endpoint;
  final Duration timeout;
  final http.Client _client;

  @override
  Future<VerifyResult> verify(PurchaseReceipt receipt) async {
    try {
      final resp = await _client
          .post(
            endpoint,
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'productId': receipt.productId,
              'source': receipt.source,
              'verificationData': receipt.verificationData,
            }),
          )
          .timeout(timeout);

      // Chỉ tin phán quyết khi server trả 200; còn lại coi như không có phán
      // quyết → fail-open.
      if (resp.statusCode != 200) return VerifyResult.unavailable;

      final body = jsonDecode(resp.body);
      final valid = body is Map && body['valid'] == true;
      return valid ? VerifyResult.valid : VerifyResult.invalid;
    } catch (_) {
      // Mạng lỗi/timeout/JSON hỏng → fail-open.
      return VerifyResult.unavailable;
    }
  }
}
