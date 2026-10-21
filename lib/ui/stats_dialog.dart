/// Thống kê của tôi: tấm thẻ số liệu cá nhân + chia sẻ dạng ảnh/chữ (cùng khuôn collection_share_dialog.dart).
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/stats.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import 'collection_share_dialog.dart' show shareImageProvider;
import 'web_links.dart';
import 'widgets/app_dialog.dart';

Future<void> showStats(BuildContext context) =>
    showAppDialog<void>(context: context, builder: (_) => const _StatsDialog());

/// Câu chia sẻ dạng chữ (cũng là chú thích cho ảnh).
String statsShareText(AppLocalizations l10n, PlayerStats s) =>
    '${l10n.statsShareText(s.daysPlayed, formatNumber(s.lifetime))}\n$webHomeUrl';

/// Tấm thẻ: rộng cố định để ảnh xuất ra giống nhau trên mọi máy.
class StatsCard extends StatelessWidget {
  const StatsCard({super.key, required this.stats});
  final PlayerStats stats;

  static const width = 320.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rows = <(String, String)>[
      (l10n.statsDays, '${stats.daysPlayed}'),
      (l10n.statsLifetime, formatNumber(stats.lifetime)),
      (l10n.statsTaps, formatNumber(stats.taps.toDouble())),
      (l10n.statsBuys, formatNumber(stats.buys.toDouble())),
      (l10n.statsAscensions, '${stats.ascensions}'),
      (l10n.statsChapter, '${stats.chapter}'),
      (l10n.statsItems, '${stats.items}'),
      (l10n.statsVip, '${stats.vipLevel}'),
      (l10n.statsBestStreak, '${stats.bestRecipeStreak}'),
    ];
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primaryContainer, theme.colorScheme.tertiaryContainer],
        ),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('🧋 Boba Empire', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _StatsDialog extends ConsumerStatefulWidget {
  const _StatsDialog();

  @override
  ConsumerState<_StatsDialog> createState() => _StatsDialogState();
}

class _StatsDialogState extends ConsumerState<_StatsDialog> {
  final _cardKey = GlobalKey();
  final _shareKey = GlobalKey();
  bool _busy = false;
  late final PlayerStats _stats = ref.read(gameControllerProvider.notifier).playerStats();

  Future<Uint8List> _capture() async {
    final boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  Future<void> _shareImage() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final share = ref.read(shareImageProvider);
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _busy = true);
    try {
      await share(await _capture(), statsShareText(l10n, _stats), origin, 'boba_stats.png');
    } catch (_) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l10n.collectionShareFailed)));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _copyText() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: statsShareText(l10n, _stats)));
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l10n.collectionShareCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.statsTitle),
      content: SingleChildScrollView(
        child: Center(child: RepaintBoundary(key: _cardKey, child: StatsCard(stats: _stats))),
      ),
      actionsOverflowButtonSpacing: 4,
      actions: [
        TextButton(key: const Key('stats-copy'), onPressed: _copyText, child: Text(l10n.collectionShareCopy)),
        FilledButton.icon(
          key: _shareKey,
          onPressed: _busy ? null : _shareImage,
          icon: const Icon(Icons.ios_share),
          label: Text(l10n.collectionShareImage),
        ),
      ],
    );
  }
}
