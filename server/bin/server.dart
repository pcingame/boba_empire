/// HTTP server xác thực biên nhận IAP. Endpoint POST /verify nhận JSON
/// {productId, source, verificationData} và trả {valid: bool} — khớp
/// HttpReceiptVerifier phía app (lib/iap/http_receipt_verifier.dart).
///
/// Chạy: `dart run bin/server.dart` (mặc định VERIFY_MODE=dev, cổng 8080).
library;

import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'package:boba_receipt_server/verifier.dart';

Future<Response> _verify(Request request) async {
  final Map<String, dynamic> json;
  try {
    json = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  } catch (_) {
    return Response.badRequest(body: jsonEncode({'error': 'invalid json'}));
  }

  final req = VerifyRequest.fromJson(json);
  if (req.productId.isEmpty || req.verificationData.isEmpty) {
    return Response.badRequest(body: jsonEncode({'error': 'missing fields'}));
  }

  try {
    final verifier = verifierFor(req.source, Platform.environment);
    final valid = await verifier.verify(req);
    return Response.ok(
      jsonEncode({'valid': valid}),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    // Lỗi cấu hình/API → 500. Client fail-open sẽ vẫn trao thưởng; sửa server
    // rồi giao dịch sau được xác thực đúng.
    stderr.writeln('verify error: $e');
    return Response.internalServerError(
      body: jsonEncode({'error': 'verify failed'}),
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() async {
  final router = Router()
    ..get('/health', (Request _) => Response.ok('ok'))
    ..post('/verify', _verify);

  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Receipt server chạy tại http://${server.address.host}:${server.port}'
      ' (VERIFY_MODE=${Platform.environment['VERIFY_MODE'] ?? 'dev'})');
}
