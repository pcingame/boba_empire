// Đẩy FCM "món của bạn đã bán được" cho người bán khi có hàng mới trong
// accessory_market_trades. Gọi bởi Database Webhook (INSERT trên bảng đó).
//
// Deploy (một lần):
//   1. Firebase Console → Project settings → Service accounts → Generate new
//      private key (JSON). Cloud Messaging → APNs: upload APNs auth key (.p8).
//   2. supabase secrets set FCM_SERVICE_ACCOUNT="$(cat service-account.json)" \
//        WEBHOOK_SECRET=<chuỗi ngẫu nhiên dài>
//   3. supabase functions deploy notify-market-sale --no-verify-jwt
//   4. Dashboard → Database → Webhooks → Create: table accessory_market_trades,
//      event INSERT, type HTTP Request (POST) tới URL function, thêm header
//      x-webhook-secret = đúng WEBHOOK_SECRET ở trên.
// SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY do Supabase tự cấp cho function.

import { createClient } from "jsr:@supabase/supabase-js@2";

const TEXT: Record<string, { title: string; body: (n: number) => string }> = {
  vi: { title: "Chợ Phụ kiện", body: (n) => `Món của bạn vừa bán được! +${n} Xu Chợ` },
  en: { title: "Accessory Market", body: (n) => `Your item just sold! +${n} Market Coins` },
  es: { title: "Mercado de accesorios", body: (n) => `¡Tu artículo se vendió! +${n} Monedas de Mercado` },
  id: { title: "Pasar Aksesori", body: (n) => `Barangmu terjual! +${n} Koin Pasar` },
  pt: { title: "Mercado de Acessórios", body: (n) => `Seu item foi vendido! +${n} Moedas de Mercado` },
  th: { title: "ตลาดของสะสม", body: (n) => `ของของคุณขายได้แล้ว! +${n} เหรียญตลาด` },
};

function b64url(data: ArrayBuffer | string): string {
  const bytes = typeof data === "string"
    ? new TextEncoder().encode(data)
    : new Uint8Array(data);
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function fcmAccessToken(sa: { client_email: string; private_key: string }) {
  const now = Math.floor(Date.now() / 1000);
  const unsigned = `${b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }))}.${
    b64url(JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }))
  }`;
  const der = Uint8Array.from(
    atob(sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s/g, "")),
    (c) => c.charCodeAt(0),
  );
  const key = await crypto.subtle.importKey(
    "pkcs8", der, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned),
  );
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${b64url(sig)}`,
    }),
  });
  if (!res.ok) throw new Error(`oauth ${res.status}`);
  return (await res.json()).access_token as string;
}

Deno.serve(async (req) => {
  const secret = Deno.env.get("WEBHOOK_SECRET");
  if (!secret || req.headers.get("x-webhook-secret") !== secret) {
    return new Response("forbidden", { status: 403 });
  }
  const { type, record } = await req.json();
  if (type !== "INSERT" || !record?.seller_id) return new Response("ignored");

  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: tokens } = await db
    .from("push_tokens").select("token, locale").eq("user_id", record.seller_id);
  if (!tokens?.length) return new Response("no tokens");

  // Cùng công thức phí với buy_listing(): 1%, làm tròn lên, tối thiểu 1.
  const price = Number(record.price);
  const net = price - Math.max(1, Math.ceil(price / 100));

  const sa = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT")!);
  const access = await fcmAccessToken(sa);
  for (const t of tokens) {
    const text = TEXT[t.locale] ?? TEXT.en;
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
      {
        method: "POST",
        headers: { authorization: `Bearer ${access}`, "content-type": "application/json" },
        body: JSON.stringify({
          message: {
            token: t.token,
            notification: { title: text.title, body: text.body(net) },
            apns: { payload: { aps: { sound: "default" } } },
            android: { priority: "high" },
          },
        }),
      },
    );
    // Token chết (gỡ app / đổi máy) → dọn để lần sau khỏi gửi vô ích.
    if (res.status === 404) await db.from("push_tokens").delete().eq("token", t.token);
  }
  return new Response("ok");
});
