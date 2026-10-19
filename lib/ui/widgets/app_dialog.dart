import 'package:flutter/material.dart';

import 'motion.dart';

/// Thay `showDialog`: popup nảy vào (phóng 0.88 → 1 có nảy nhẹ + trượt lên 6% + mờ dần) thay vì chỉ mờ dần.
/// [celebrate] = tin vui (nảy mạnh hơn, lâu hơn). Giảm chuyển động / test → chỉ mờ dần 150ms như `showDialog` cũ.
/// Cùng chữ ký các tham số hay dùng của `showDialog` nên thay thẳng được.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor = Colors.black54,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  bool celebrate = false,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  final reduce = reduceMotion;
  return navigator.push(
    RawDialogRoute<T>(
      pageBuilder: (ctx, _, _) {
        Widget child = Builder(builder: builder);
        if (useSafeArea) child = SafeArea(child: child);
        return Semantics(
          scopesRoute: true,
          explicitChildNodes: true,
          child: DisplayFeatureSubScreen(anchorPoint: anchorPoint, child: themes.wrap(child)),
        );
      },
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel ?? MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: Duration(milliseconds: reduce ? 150 : (celebrate ? 420 : 280)),
      settings: routeSettings,
      transitionBuilder: (ctx, anim, _, child) {
        if (reduce) return FadeTransition(opacity: anim, child: child);
        final pop = CurvedAnimation(
          parent: anim,
          curve: celebrate ? Curves.easeOutBack : Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: celebrate ? 0.6 : 0.88, end: 1).animate(pop),
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(pop),
              child: child,
            ),
          ),
        );
      },
    ),
  );
}
