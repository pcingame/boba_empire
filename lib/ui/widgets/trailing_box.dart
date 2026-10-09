import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Phần tử CUỐI một hàng "chữ bên trái + nút/số bên phải" (đi cùng một `Expanded`).
///
/// KHÔNG dùng `Flexible` cho việc này: `Flexible` + `Expanded` chia đôi chỗ trống nên
/// chữ bên cạnh chỉ còn ~50% bề ngang dù nút rất nhỏ — tên bị cắt "Trà Sữa B…", tiêu
/// đề xuống dòng sớm, và ở cấp cao còn tràn RenderFlex (thanh mốc ô nâng cấp, đo được
/// 146dp trên màn 360dp). Ở đây phần tử lấy chiều rộng TỰ NHIÊN rồi để `Expanded` ăn
/// hết phần còn lại; chỉ chặn trần [maxFraction] bề ngang màn hình (nên đặt một
/// `FittedBox(scaleDown)` bên trong để chữ co lại khi vượt) và sàn [minWidth] (để các
/// nút trong một danh sách thẳng cột).
class TrailingBox extends StatelessWidget {
  const TrailingBox({
    super.key,
    required this.child,
    this.maxFraction = 0.36,
    this.minWidth = 0,
  });

  final Widget child;
  final double maxFraction;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth,
        maxWidth: math.max(minWidth, w * maxFraction),
      ),
      child: child,
    );
  }
}
