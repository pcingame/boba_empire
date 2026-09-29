/// Giới hạn bề ngang nội dung trên máy màn rộng (iPad, máy gập, cửa sổ
/// desktop) rồi canh giữa.
///
/// Toàn bộ giao diện game được thiết kế ở bề ngang điện thoại (~400dp). Thả
/// nguyên lên iPad Pro 13" (1032dp dọc) thì không có gì "vỡ" theo nghĩa tràn
/// RenderFlex — nó tệ theo kiểu khác: cảnh quán và danh sách shop bị kéo giãn
/// hết chiều ngang, 5 mục thanh dưới cách nhau cả gang tay, còn giữa màn hình
/// là một dải trống. Đo trên máy ảo iPad Pro 13" trước khi sửa.
///
/// Đây là cách xử lý tiêu chuẩn của game điện thoại chạy trên tablet: giữ
/// nguyên bố cục dọc, khoá bề ngang, canh giữa — KHÔNG làm lại bố cục 2 cột
/// cho tablet (tốn gấp nhiều lần mà người chơi tablet là thiểu số).
library;

import 'package:flutter/material.dart';

/// Bề ngang tối đa của nội dung. ~560 là rộng hơn mọi điện thoại hiện hành
/// (iPhone Pro Max ~440dp) nên trên điện thoại widget này KHÔNG đổi gì cả —
/// chỉ tablet mới thấy khác.
const double kPhoneMaxWidth = 560;

class PhoneWidth extends StatelessWidget {
  const PhoneWidth({
    super.key,
    required this.child,
    this.maxWidth = kPhoneMaxWidth,
    this.fillHeight = true,
  });

  final Widget child;
  final double maxWidth;

  /// `Center` giãn theo CẢ HAI chiều. Với thân trang thì đúng (bên trong có
  /// `Expanded` cần chiều cao có biên), nhưng với `bottomNavigationBar` thì
  /// nó nuốt trọn chiều cao màn hình — Scaffold hết chỗ cho SnackBar và ném
  /// "Floating SnackBar presented off screen" (6 test đỏ lúc mới thêm).
  /// `fillHeight: false` cho nó ôm sát chiều cao con.
  final bool fillHeight;

  @override
  Widget build(BuildContext context) => Center(
        heightFactor: fillHeight ? null : 1.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}
