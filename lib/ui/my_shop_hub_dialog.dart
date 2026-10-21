/// Quán của tôi: một điểm vào cho Nhân viên và Linh vật (hệ thống quán, không phải trò chơi).
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'pet_dialog.dart';
import 'staff_dialog.dart';
import 'widgets/app_dialog.dart';

Future<void> showMyShopHub(BuildContext context) =>
    showAppDialog<void>(context: context, builder: (_) => const _MyShopHubDialog());

class _MyShopHubDialog extends StatelessWidget {
  const _MyShopHubDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.myShopTitle),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          key: const Key('shop-staff'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.badge_rounded),
          title: Text(l10n.staffTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            final nav = Navigator.of(context)..pop();
            showStaff(nav.context);
          },
        ),
        ListTile(
          key: const Key('shop-pet'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.pets_rounded),
          title: Text(l10n.petTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            final nav = Navigator.of(context)..pop();
            showPet(nav.context);
          },
        ),
      ]),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close))],
    );
  }
}
