/// Chặn phát lại (replay) một giao dịch CONSUMABLE đã trao thưởng rồi.
///
/// CHỈ áp cho consumable — phát lại nghĩa là cộng 💎 hai lần, mất tiền thật.
/// Non-consumable KHÔNG được chặn ở đây (gọi trước khi tới lớp này qua
/// [VerifyRequest.kind]): gửi lại ĐÚNG transaction id cũ chính là luồng
/// "Khôi phục giao dịch mua" hợp lệ khi người chơi đổi máy — trao lại quyền
/// (ví dụ `adsRemoved = true`) là đúng và vô hại vì đó chỉ là 1 cờ boolean.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

abstract interface class ReplayStore {
  /// true nếu ĐÂY LÀ LẦN ĐẦU thấy cặp (source, transactionId) — đã ghi nhận,
  /// gọi lại lần 2 sẽ trả false. false nghĩa là giao dịch này ĐÃ được trao
  /// thưởng rồi, không trao thêm lần nữa.
  Future<bool> reserve(String source, String transactionId);
}

/// Chỉ dùng khi CHƯA cấu hình Supabase (dev/test cục bộ) — mất hết khi restart
/// tiến trình. KHÔNG dùng ở production (nhiều instance server sẽ không thấy
/// nhau, mất tác dụng chặn phát lại).
class InMemoryReplayStore implements ReplayStore {
  final _seen = <String>{};

  @override
  Future<bool> reserve(String source, String transactionId) async =>
      _seen.add('$source:$transactionId');
}

/// Ghi vào bảng `iap_redeemed_receipts` (supabase/iap_replay_schema.sql) qua
/// REST API bằng SERVICE ROLE KEY — bảng không có policy nào cho anon/
/// authenticated, chỉ server (key này) ghi/đọc được, bỏ qua RLS hoàn toàn.
///
/// Cơ chế chặn phát lại là RÀNG BUỘC UNIQUE của chính Postgres trên
/// (source, transaction_id) — atomic ở tầng DB, không phải "kiểm tra rồi ghi"
/// hai bước riêng (dính race condition nếu 2 request trùng giờ tới cùng lúc).
class SupabaseReplayStore implements ReplayStore {
  SupabaseReplayStore({
    required this.supabaseUrl,
    required this.serviceRoleKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String supabaseUrl;
  final String serviceRoleKey;
  final http.Client _client;

  @override
  Future<bool> reserve(String source, String transactionId) async {
    final resp = await _client.post(
      Uri.parse('$supabaseUrl/rest/v1/iap_redeemed_receipts'),
      headers: {
        'apikey': serviceRoleKey,
        'authorization': 'Bearer $serviceRoleKey',
        'content-type': 'application/json',
        'prefer': 'return=minimal',
      },
      body: jsonEncode({'source': source, 'transaction_id': transactionId}),
    );
    if (resp.statusCode == 201) return true;
    // 409 = vi phạm UNIQUE (primary key trùng) -> đã ghi nhận từ trước.
    if (resp.statusCode == 409) return false;
    // Lỗi khác (mạng/cấu hình sai) không nên NGẦM cho qua chặn phát lại —
    // ném lỗi để tầng gọi coi là "không xác thực được" (fail-closed đúng
    // hướng NGƯỢC với ReceiptVerifier: ở đây thà chặn oan còn hơn phát lại
    // lọt, vì hậu quả là mất tiền thật trực tiếp).
    throw StateError(
        'SupabaseReplayStore: HTTP ${resp.statusCode} — ${resp.body}');
  }
}
