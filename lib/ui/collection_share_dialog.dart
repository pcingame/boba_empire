/// Thẻ khoe bộ sưu tập: xem trước tấm thẻ rồi chia sẻ dạng ẢNH (share sheet hệ
/// thống) hoặc sao chép dạng chữ. Ảnh chụp từ chính widget [CollectionCard]
/// bằng RepaintBoundary — không cần dựng riêng một bản vẽ thứ hai.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core/accessories.dart';
import '../core/collection_milestones.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';
import 'widgets/accessory_rarity.dart';

/// Chia sẻ ảnh PNG [png] kèm chữ [text]; [origin] là vùng nút bấm (bắt buộc cho
/// iPad). Công khai để test ghi đè (không mở share sheet thật).
final shareImageProvider =
    Provider<Future<void> Function(Uint8List png, String text, Rect? origin)>(
      (ref) => (png, text, origin) async {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile.fromData(png, mimeType: 'image/png')],
            fileNameOverrides: const ['boba_collection.png'],
            text: text,
            sharePositionOrigin: origin,
          ),
        );
      },
    );

Future<void> showCollectionShare(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _CollectionShareDialog(),
);

/// Câu chia sẻ dạng chữ (cũng dùng làm chú thích cho ảnh).
String collectionShareText(AppLocalizations l10n, Set<String> owned) =>
    l10n.collectionShareText(
      owned.length,
      accessories.length,
      accessories.where((a) => owned.contains(a.id)).map((a) => a.emoji).join(),
    );

/// Tấm thẻ: rộng cố định để ảnh xuất ra giống nhau trên mọi máy.
class CollectionCard extends StatelessWidget {
  const CollectionCard({super.key, required this.owned, this.title});
  final Set<String> owned;
  final String? title;

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
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.tertiaryContainer,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🧋 Boba Empire',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.accessoryInventoryOwned(owned.length, accessories.length),
            key: const Key('card-count'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (title != null) Text(title!, style: theme.textTheme.labelLarge),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final a in accessories)
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: Colors.white.withValues(alpha: 0.5),
                    border: Border.all(
                      color: rarityColor(
                        a.rarity,
                      ).withValues(alpha: owned.contains(a.id) ? 1 : 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    owned.contains(a.id) ? a.emoji : '·',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionShareDialog extends ConsumerStatefulWidget {
  const _CollectionShareDialog();

  @override
  ConsumerState<_CollectionShareDialog> createState() =>
      _CollectionShareDialogState();
}

class _CollectionShareDialogState
    extends ConsumerState<_CollectionShareDialog> {
  final _cardKey = GlobalKey();
  final _shareButtonKey = GlobalKey();
  bool _busy = false;

  Set<String> get _owned =>
      ref.read(gameControllerProvider).ownedAccessories.toSet();

  Future<Uint8List> _capture() async {
    final boundary =
        _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  Future<void> _shareImage() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final share = ref.read(shareImageProvider);
    final box =
        _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final text = collectionShareText(l10n, _owned);
    setState(() => _busy = true);
    try {
      await share(await _capture(), text, origin);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.collectionShareFailed)),
      );
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _copyText() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
      ClipboardData(text: collectionShareText(l10n, _owned)),
    );
    messenger.showSnackBar(SnackBar(content: Text(l10n.collectionShareCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Danh hiệu cao nhất đã nhận (xem collection_milestones.dart).
    final claimed = ref.watch(
      gameControllerProvider.select(
        (s) => s.collectionMilestonesClaimed.join(','),
      ),
    );
    final claimedSet = claimed.isEmpty
        ? <int>{}
        : claimed.split(',').map(int.parse).toSet();
    final highest = collectionMilestones
        .where((m) => claimedSet.contains(m.count))
        .fold<CollectionMilestone?>(null, (_, m) => m);
    final owned =
        ref
            .watch(
              gameControllerProvider.select(
                (s) => s.ownedAccessories.join(','),
              ),
            )
            .split(',')
            .toSet()
          ..remove('');
    return AlertDialog(
      title: Text(l10n.collectionCardTitle),
      content: SingleChildScrollView(
        child: Center(
          child: RepaintBoundary(
            key: _cardKey,
            child: CollectionCard(
              owned: owned,
              title: highest == null
                  ? null
                  : collectionTitle(l10n, highest.count),
            ),
          ),
        ),
      ),
      actionsOverflowButtonSpacing: 4,
      actions: [
        TextButton(
          key: const Key('card-copy'),
          onPressed: _copyText,
          child: Text(l10n.collectionShareCopy),
        ),
        FilledButton.icon(
          key: _shareButtonKey,
          onPressed: _busy ? null : _shareImage,
          icon: const Icon(Icons.ios_share),
          label: Text(l10n.collectionShareImage),
        ),
      ],
    );
  }
}
