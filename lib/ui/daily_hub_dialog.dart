/// "Nhiệm vụ & Quà": một hộp thoại có 4 tab gom nhiệm vụ ngày (+ thử thách), nhiệm vụ tuần, "Kiếm thêm" (quảng cáo,
/// vòng quay, mời bạn) và Thành tựu — trước đây là 3 hộp riêng với 2 chip trên màn chính, nhiệm vụ tuần còn lồng trong nhiệm vụ ngày.
/// Nội dung mỗi tab là chính các hộp cũ ở chế độ `embedded`.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'achievements_dialog.dart';
import 'daily_quests_dialog.dart';
import 'rewards_dialog.dart';
import 'weekly_quests_dialog.dart';
import 'widgets/phone_width.dart';
import 'widgets/app_dialog.dart';

enum DailyHubTab { daily, weekly, rewards, achievements }

Future<void> showDailyHub(BuildContext context, [DailyHubTab tab = DailyHubTab.daily]) => showAppDialog<void>(
      context: context,
      builder: (_) => DailyHubDialog(initialTab: tab),
    );

class DailyHubDialog extends StatelessWidget {
  const DailyHubDialog({super.key, this.initialTab = DailyHubTab.daily});
  final DailyHubTab initialTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Cao ~65% màn hình (tối đa 560) để mỗi tab cuộn trong khung cố định, đổi tab không nhảy kích thước hộp.
    final height = (MediaQuery.sizeOf(context).height * 0.65).clamp(320.0, 560.0);
    return DefaultTabController(
      length: DailyHubTab.values.length,
      initialIndex: initialTab.index,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: Text(l10n.dailyHubTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kPhoneMaxWidth - 48),
          child: SizedBox(
            width: double.maxFinite,
            height: height,
            child: Column(
              children: [
                TabBar(
                  // 4 tab trên hộp hẹp: bớt đệm hai bên để "Thành tựu" không bị cắt.
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  tabs: [
                    Tab(key: const Key('hub-tab-daily'), text: l10n.dailyHubTabDaily),
                    Tab(key: const Key('hub-tab-weekly'), text: l10n.dailyHubTabWeekly),
                    Tab(key: const Key('hub-tab-rewards'), text: l10n.dailyHubTabRewards),
                    Tab(key: const Key('hub-tab-achievements'), text: l10n.achievementsTitle),
                  ],
                ),
                const SizedBox(height: 8),
                const Expanded(
                  child: TabBarView(children: [
                    DailyQuestsPanel(embedded: true),
                    WeeklyQuestsPanel(embedded: true),
                    RewardsPanel(embedded: true),
                    AchievementsPanel(),
                  ]),
                ),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close))],
      ),
    );
  }
}
