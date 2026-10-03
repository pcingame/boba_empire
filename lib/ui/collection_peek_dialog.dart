/// Xem bộ sưu tập của người khác (bấm một hàng ở bảng xếp hạng Sưu tập): lưới 50
/// ô, món họ có hiện emoji, còn thiếu là ❔. Chỉ id món đi qua RPC công khai
/// `accessory_collection_of`; id lạ (bản app cũ hơn) bị bỏ qua.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/accessories.dart';
import '../l10n/app_localizations.dart';
import '../market/accessory_market_repository.dart';
import 'widgets/accessory_rarity.dart';

/// Công khai để test ghi đè. null = lỗi mạng/server.
final collectionOfProvider = FutureProvider.autoDispose
    .family<Set<String>?, String>((ref, userId) async {
      try {
        final ids = await AccessoryMarketRepository(
          Supabase.instance.client,
        ).fetchCollectionOf(userId);
        return knownAccessoryIds(ids);
      } catch (_) {
        return null;
      }
    });

/// Chỉ giữ id có trong danh mục của bản app này (id từ bản mới hơn bị bỏ qua).
Set<String> knownAccessoryIds(Iterable<String> ids) {
  final known = {for (final a in accessories) a.id};
  return ids.where(known.contains).toSet();
}

Future<void> showCollectionPeek(
  BuildContext context, {
  required String userId,
  required String nickname,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _CollectionPeekDialog(userId: userId, nickname: nickname),
  );
}

class _CollectionPeekDialog extends ConsumerWidget {
  const _CollectionPeekDialog({required this.userId, required this.nickname});
  final String userId;
  final String nickname;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(collectionOfProvider(userId));
    return AlertDialog(
      title: Text(
        l10n.collectionPeekTitle(nickname),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: async.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Text(l10n.collectionPeekError),
          data: (owned) {
            if (owned == null) return Text(l10n.collectionPeekError);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.accessoryInventoryOwned(
                    owned.length,
                    accessories.length,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      key: const Key('collection-peek-grid'),
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final a in accessories)
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: rarityColor(a.rarity).withValues(
                                  alpha: owned.contains(a.id) ? 1 : 0.35,
                                ),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              owned.contains(a.id) ? a.emoji : '❔',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}
