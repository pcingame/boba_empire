/// Khoe ly vừa pha hoàn hảo: xem trước tấm thẻ (ly đậy nắp + tên món) rồi chia sẻ dạng ảnh. Cùng khuôn
/// [showCollectionShare]: chụp chính widget [CupCard] bằng RepaintBoundary, đẩy qua [shareImageProvider].
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'collection_share_dialog.dart' show shareImageProvider;
import 'web_links.dart';
import 'widgets/order_visuals.dart';

Future<void> showCupShare(BuildContext context, {required String recipeName, required List<CupLayer> layers}) =>
    showDialog<void>(context: context, builder: (_) => _CupShareDialog(recipeName: recipeName, layers: layers));

/// Tấm thẻ: rộng cố định để ảnh xuất ra giống nhau trên mọi máy.
class CupCard extends StatelessWidget {
  const CupCard({super.key, required this.recipeName, required this.layers});
  final String recipeName;
  final List<CupLayer> layers;

  static const width = 320.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
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
        const SizedBox(height: 12),
        OrderCup(layers: layers, lidded: true, width: 120, height: 160),
        const SizedBox(height: 12),
        Text(recipeName,
            key: const Key('cup-card-name'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 3; i++) Icon(Icons.star_rounded, size: 24, color: Colors.amber.shade600),
        ]),
        Text(l10n.cupSharePerfect, style: theme.textTheme.labelLarge),
      ]),
    );
  }
}

class _CupShareDialog extends ConsumerStatefulWidget {
  const _CupShareDialog({required this.recipeName, required this.layers});
  final String recipeName;
  final List<CupLayer> layers;

  @override
  ConsumerState<_CupShareDialog> createState() => _CupShareDialogState();
}

class _CupShareDialogState extends ConsumerState<_CupShareDialog> {
  final _cardKey = GlobalKey();
  final _shareButtonKey = GlobalKey();
  bool _busy = false;

  Future<ui.Image> _capture() =>
      (_cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio: 3);

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final share = ref.read(shareImageProvider);
    final box = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    final text = '${l10n.cupShareText(widget.recipeName)}\n$webHomeUrl';
    setState(() => _busy = true);
    try {
      final image = await _capture();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await share(data!.buffer.asUint8List(), text, origin, 'boba_cup.png');
    } catch (_) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l10n.collectionShareFailed)));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.cupShareTitle),
      content: SingleChildScrollView(
        child: Center(
          child: RepaintBoundary(
            key: _cardKey,
            child: CupCard(recipeName: widget.recipeName, layers: widget.layers),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close)),
        FilledButton.icon(
          key: _shareButtonKey,
          onPressed: _busy ? null : _share,
          icon: const Icon(Icons.ios_share),
          label: Text(l10n.collectionShareImage),
        ),
      ],
    );
  }
}
