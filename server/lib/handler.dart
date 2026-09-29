/// Handler HTTP cho `POST /verify` — tách khỏi bin/server.dart để test được
/// (bin/ không import được từ test/ theo quy ước gói Dart).
library;

import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

import 'replay_store.dart';
import 'verifier.dart';

/// [verifierFor] tách thành tham số riêng (không đọc thẳng `Platform.
/// environment` bên trong) để test được nhánh chặn phát lại bằng verifier
/// giả, không cần dựng credential Play/App Store thật.
Future<Response> verifyHandler(
  Request request,
  ReplayStore replay,
  Verifier Function(String source) verifierFor,
) async {
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
    final verifier = verifierFor(req.source);
    final transactionId = await verifier.verify(req);
    var valid = transactionId != null;

    // Chặn phát lại CHỈ với consumable — non-consumable gửi lại đúng id cũ
    // là luồng "Khôi phục giao dịch mua" hợp lệ, không phải gian lận (xem
    // VerifyRequest.isConsumable).
    if (valid && req.isConsumable) {
      valid = await replay.reserve(req.source, transactionId);
    }

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

/// Dựng [ReplayStore] theo biến môi trường: có đủ SUPABASE_URL +
/// SUPABASE_SERVICE_ROLE_KEY thì dùng Supabase (bền qua restart/nhiều
/// instance), thiếu thì rơi về bộ nhớ tạm (chỉ đủ cho dev/test cục bộ) kèm
/// cảnh báo — KHÔNG lặng lẽ coi như replay-protection đang chạy đầy đủ.
ReplayStore replayStoreFor(Map<String, String> env) {
  final url = env['SUPABASE_URL'];
  final key = env['SUPABASE_SERVICE_ROLE_KEY'];
  if (url != null && key != null) {
    return SupabaseReplayStore(supabaseUrl: url, serviceRoleKey: key);
  }
  if (env['VERIFY_MODE'] == 'prod') {
    stderr.writeln('⚠️ VERIFY_MODE=prod nhưng thiếu SUPABASE_URL/'
        'SUPABASE_SERVICE_ROLE_KEY — chặn phát lại consumable KHÔNG bền '
        '(mất khi restart/không chia sẻ giữa nhiều instance). Đặt 2 biến '
        'này trước khi chạy thật.');
  }
  return InMemoryReplayStore();
}
