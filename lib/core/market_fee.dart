/// Phí sàn Chợ: 1% (làm tròn lên, tối thiểu 1 Xu Chợ), MIỄN PHÍ vào thứ 7 và
/// Chủ nhật theo UTC. PHẢI khớp `market_fee_free()` / `buy_listing()` trong
/// supabase/accessory_market_schema.sql và Edge Function notify-market-sale
/// (server mới là bên quyết định lúc mua — đây chỉ để hiển thị trước).
library;

bool marketFeeFree(DateTime nowUtc) =>
    nowUtc.weekday == DateTime.saturday || nowUtc.weekday == DateTime.sunday;

/// Phí người bán phải trả khi bán giá [price].
int marketFee(int price, DateTime nowUtc) =>
    marketFeeFree(nowUtc) ? 0 : ((price + 99) ~/ 100).clamp(1, price);
