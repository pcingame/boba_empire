/// Avatar tròn: ảnh công khai theo [avatarKey]; chưa có / lỗi tải → biểu tượng 🧋.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../leaderboard/player_avatar.dart';

class AvatarCircle extends ConsumerWidget {
  const AvatarCircle({super.key, required this.avatarKey, this.size = 56});
  final String avatarKey;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Center(child: Text('🧋', style: TextStyle(fontSize: size * 0.5)));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primaryContainer),
      clipBehavior: Clip.antiAlias,
      child: avatarKey.isEmpty
          ? fallback
          : Image.network(
              ref.read(avatarRepositoryProvider).urlFor(avatarKey),
              key: const Key('avatar-image'),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
              loadingBuilder: (_, child, p) => p == null ? child : fallback,
            ),
    );
  }
}
