import 'package:flutter/widgets.dart';

/// Giữ [controllers] sống đúng bằng đời của [child] và huỷ chúng khi cây widget bị gỡ.
///
/// Dùng cho hộp thoại tự tạo TextEditingController: huỷ ngay lúc `pop` sẽ làm TextField
/// còn đang chạy animation thoát dùng controller đã huỷ; huỷ ở `State.dispose` thì an
/// toàn (xảy ra SAU animation thoát). Đọc `controller.text` ngay sau `await showDialog`
/// vẫn hợp lệ vì lúc đó cây chưa bị gỡ.
class DisposeWithWidget extends StatefulWidget {
  const DisposeWithWidget({super.key, required this.controllers, required this.child});

  final List<ChangeNotifier> controllers;
  final Widget child;

  @override
  State<DisposeWithWidget> createState() => _DisposeWithWidgetState();
}

class _DisposeWithWidgetState extends State<DisposeWithWidget> {
  @override
  void dispose() {
    for (final c in widget.controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
