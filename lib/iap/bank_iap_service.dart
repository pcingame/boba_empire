/// IapService cho bản Android tải APK: mua bằng chuyển khoản ngân hàng thay vì Google Play Billing.
/// Xem supabase/bank_orders_schema.sql. Chỉ main.dart import file này.
///
/// `buy` tạo đơn rồi phát [bankOrders] để UI hiện mã QR; tiền về thì server đổi đơn sang 'paid' và
/// [restore] (HomePage gọi lúc mở app, hộp QR gọi mỗi vài giây) trao hàng qua [purchases] rồi báo ack.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'bank_config.dart';
import 'iap_products.dart';
import 'iap_service.dart';

class BankIapService implements IapService {
  BankIapService({SupabaseClient Function()? client})
      : _client = client ?? (() => Supabase.instance.client);

  final SupabaseClient Function() _client;
  final StreamController<IapProduct> _delivered =
      StreamController<IapProduct>.broadcast();
  final StreamController<IapProduct> _failed =
      StreamController<IapProduct>.broadcast();
  final StreamController<BankOrder> _orders =
      StreamController<BankOrder>.broadcast();
  bool _checking = false;

  @override
  Stream<IapProduct> get purchases => _delivered.stream;

  @override
  Stream<IapProduct> get purchaseFailed => _failed.stream;

  Stream<BankOrder> get bankOrders => _orders.stream;

  @override
  Future<Map<IapProduct, String>> loadPrices() async {
    if (!BankConfig.configured) return const {};
    return {
      for (final p in IapProduct.values)
        if (bankPriceVnd[p.id] != null) p: formatVnd(bankPriceVnd[p.id]!),
    };
  }

  @override
  void buy(IapProduct product) => unawaited(_createOrder(product));

  Future<void> _createOrder(IapProduct product) async {
    try {
      final r = await _client().rpc('bank_create_order',
          params: {'p_product': product.id}) as Map;
      _orders.add(BankOrder(product, r['code'] as String, r['amount'] as int));
    } catch (e) {
      developer.log('bank_create_order failed: $e', name: 'IapService');
      _failed.add(product);
    }
  }

  /// Trao các đơn đã thanh toán. Ack SAU khi phát: crash giữa chừng thì lần mở sau trao lại
  /// (nghiêng về phía người mua) thay vì mất hàng đã trả tiền.
  @override
  Future<void> restore() async {
    if (_checking || _client().auth.currentUser == null) return;
    _checking = true;
    try {
      final rows = await _client().rpc('bank_my_paid') as List;
      final codes = <String>[];
      for (final row in rows) {
        final product = IapProduct.byId(row['product_id'] as String);
        if (product == null) continue;
        _delivered.add(product);
        codes.add(row['code'] as String);
      }
      if (codes.isNotEmpty) {
        await _client().rpc('bank_ack', params: {'p_codes': codes});
      }
    } catch (e) {
      developer.log('bank restore failed: $e', name: 'IapService');
    } finally {
      _checking = false;
    }
  }
}
