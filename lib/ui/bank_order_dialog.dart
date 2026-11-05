/// Hộp chuyển khoản cho bản Android tải APK: mã QR VietQR + thông tin tài khoản + nội dung (mã đơn).
/// Tự đóng khi tiền về (service trao hàng qua `purchases`). Chỉ tiếng Việt: kênh này chỉ cho
/// người chơi có tài khoản ngân hàng Việt Nam.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../iap/bank_config.dart';
import '../iap/iap_service.dart';
import 'widgets/app_dialog.dart';

Future<void> showBankOrderDialog(BuildContext context, BankOrder order) =>
    showAppDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BankOrderDialog(order),
    );

class _BankOrderDialog extends ConsumerStatefulWidget {
  const _BankOrderDialog(this.order);
  final BankOrder order;

  @override
  ConsumerState<_BankOrderDialog> createState() => _BankOrderDialogState();
}

class _BankOrderDialogState extends ConsumerState<_BankOrderDialog> {
  Timer? _poll;
  StreamSubscription<dynamic>? _sub;

  @override
  void initState() {
    super.initState();
    final iap = ref.read(iapServiceProvider);
    // Hỏi server mỗi 5 giây; restore() trao hàng và phát `purchases` khi đơn đã 'paid'.
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => iap.restore());
    _sub = iap.purchases.listen((p) {
      if (p == widget.order.product && mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(text: '$label: '),
                TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ])),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () => Clipboard.setData(ClipboardData(text: value)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return AlertDialog(
      key: const Key('bank-order-dialog'),
      title: const Text('Chuyển khoản để nhận hàng'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              BankConfig.qrUrl(o.code, o.amount),
              width: 240,
              errorBuilder: (_, _, _) =>
                  const Text('Không tải được mã QR, hãy chuyển khoản thủ công.'),
            ),
            _row('Ngân hàng', BankConfig.bankId),
            _row('Số TK', BankConfig.account),
            _row('Chủ TK', BankConfig.accountName),
            _row('Số tiền', formatVnd(o.amount)),
            _row('Nội dung', o.code),
            const SizedBox(height: 8),
            const Text(
              'Phải ghi ĐÚNG nội dung, không sửa. Tiền về khoảng 1 phút là hàng tự vào; '
              'có thể đóng hộp này, lần mở game sau hàng vẫn được trao.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
