/// HTTP server xác thực biên nhận IAP. Endpoint POST /verify nhận JSON
/// {productId, source, verificationData, kind} và trả {valid: bool} — khớp
/// HttpReceiptVerifier phía app (lib/iap/http_receipt_verifier.dart).
///
/// Chạy: `dart run bin/server.dart` (mặc định VERIFY_MODE=dev, cổng 8080).
/// Logic thật nằm ở lib/handler.dart (bin/ không import được từ test/).
library;

import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'package:boba_receipt_server/handler.dart';
import 'package:boba_receipt_server/verifier.dart';

void main() async {
  final replay = replayStoreFor(Platform.environment);

  final router = Router()
    ..get('/health', (Request _) => Response.ok('ok'))
    ..post(
        '/verify',
        (Request req) => verifyHandler(
            req, replay, (source) => verifierFor(source, Platform.environment)));

  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Receipt server chạy tại http://${server.address.host}:${server.port}'
      ' (VERIFY_MODE=${Platform.environment['VERIFY_MODE'] ?? 'dev'}, '
      'replay=${replay.runtimeType})');
}
