// Nhận webhook SePay khi có tiền vào tài khoản ngân hàng, đối chiếu MÃ ĐƠN (BExxxxxxxx) trong nội dung
// chuyển khoản rồi đánh dấu đơn đã thanh toán (xem supabase/bank_orders_schema.sql).
//
// Deploy (một lần):
//   1. supabase secrets set SEPAY_API_KEY=<chuỗi ngẫu nhiên dài>
//   2. supabase functions deploy sepay-webhook --no-verify-jwt
//   3. SePay → Tích hợp Webhooks → Thêm: URL = https://<ref>.supabase.co/functions/v1/sepay-webhook,
//      kiểu chứng thực "API Key" với đúng SEPAY_API_KEY ở trên (SePay gửi header "Authorization: Apikey <key>"),
//      chỉ bắn khi "có tiền vào".
// SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY do Supabase tự cấp cho function.

import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  // Thiếu secret thì chuỗi so sánh thành "Apikey undefined" — ai gửi đúng chuỗi đó cũng qua. Chặn hẳn.
  const key = Deno.env.get("SEPAY_API_KEY");
  if (!key) return new Response("not configured", { status: 500 });
  if (req.headers.get("authorization") !== `Apikey ${key}`) {
    return new Response("unauthorized", { status: 401 });
  }
  const body = await req.json();
  if (body.transferType !== "in") return Response.json({ success: true });

  // Ngân hàng có thể chèn/đổi chữ hoa-thường quanh mã; lấy mã đầu tiên khớp.
  const match = /BE[0-9A-F]{8}/i.exec(`${body.content ?? ""} ${body.code ?? ""}`);
  if (!match) return Response.json({ success: true, result: "no_code" });

  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data, error } = await db.rpc("bank_mark_paid", {
    p_code: match[0],
    p_amount: Math.floor(Number(body.transferAmount)),
    p_tx: String(body.id),
  });
  // Lỗi → 500 để SePay thử lại; các kết quả khác (đã trả, thiếu tiền...) là 200 để khỏi lặp vô ích.
  if (error) return new Response(error.message, { status: 500 });
  return Response.json({ success: true, result: data });
});
