import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/story.dart';
import '../core/story_content.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';
import 'story_dialog.dart';

/// Bảng "Cốt truyện": liệt kê 8 chương, chạm để đọc lại chương đã mở.
Future<void> showStoryLog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _StoryLogDialog(),
  );
}

class _StoryLogDialog extends ConsumerWidget {
  const _StoryLogDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final code = Localizations.localeOf(context).languageCode;
    final seen =
        ref.watch(gameControllerProvider.select((s) => s.storyChapter));
    // Tách từng select (so sánh theo giá trị) — select thẳng m3Stars là list
    // mới mỗi tick, sẽ rebuild cả bảng mỗi giây.
    final stage = ref.watch(gameControllerProvider.select((s) => s.stage));
    final ascension =
        ref.watch(gameControllerProvider.select((s) => s.ascensionCount));
    final hasPrestiged =
        ref.watch(gameControllerProvider.select((s) => s.prestigeStars > 0));
    final rivalDefeated =
        ref.watch(gameControllerProvider.select((s) => s.rivalDefeated));
    final m3Key =
        ref.watch(gameControllerProvider.select((s) => s.m3Stars.join(',')));
    final m3Stars = m3Key.isEmpty
        ? <int>[]
        : m3Key.split(',').map(int.parse).toList();

    return AlertDialog(
      title: Text(l10n.storyLogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final chapter in storyChapters)
                chapter.id <= seen
                    ? _row(context, theme, l10n, code, chapter, true, null)
                    : _row(
                        context,
                        theme,
                        l10n,
                        code,
                        chapter,
                        false,
                        _lockedHint(
                          l10n,
                          theme,
                          chapter,
                          isNext: chapter.id == seen + 1,
                          stage: stage,
                          ascension: ascension,
                          hasPrestiged: hasPrestiged,
                          rivalDefeated: rivalDefeated,
                          m3Stars: m3Stars,
                        ),
                      ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          key: const Key('story-log-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  String _condition(AppLocalizations l10n, StoryChapter c) => switch (c.trigger) {
        StoryTrigger.stage =>
          '${l10n.achStage(c.value)} · ${stageName(l10n, c.value)}',
        StoryTrigger.firstPrestige => l10n.storyCondFirst(l10n.navPrestige),
        StoryTrigger.rivalDefeated => l10n.storyCondRival,
        StoryTrigger.ascension =>
          l10n.storyCondAscension(c.value, l10n.ascensionTitle),
        StoryTrigger.m3Level => l10n.storyCondM3(c.value, l10n.m3Title),
        StoryTrigger.gameStart => '',
      };

  /// Gợi ý cho chương chưa mở: điều kiện, hoặc "Mở sau Chương N-1" nếu điều
  /// kiện của nó đã thoả nhưng chương trước chưa xem (chương mở TUẦN TỰ). Chỉ
  /// chương kế tiếp có thanh tiến độ.
  Widget _lockedHint(
    AppLocalizations l10n,
    ThemeData theme,
    StoryChapter chapter, {
    required bool isNext,
    required int stage,
    required int ascension,
    required bool hasPrestiged,
    required bool rivalDefeated,
    required List<int> m3Stars,
  }) {
    final blocked = !isNext &&
        storyTriggerMet(
          chapter,
          stage: stage,
          hasPrestiged: hasPrestiged,
          rivalDefeated: rivalDefeated,
          ascensionCount: ascension,
          m3Stars: m3Stars,
        );
    final text = blocked
        ? l10n.storyUnlockAfter(l10n.storyChapterLabel(chapter.id - 1))
        : l10n.storyUnlockWhen(_condition(l10n, chapter));
    final progress = isNext
        ? storyUnlockProgress(chapter,
            stage: stage, ascensionCount: ascension, m3Stars: m3Stars)
        : null;
    if (progress == null) return Text(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress.current / progress.target,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text('${progress.current}/${progress.target}',
                style: theme.textTheme.labelSmall),
          ],
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    String code,
    StoryChapter chapter,
    bool unlocked,
    Widget? lockedHint,
  ) {
    return ListTile(
      dense: true,
      leading: Text(
        unlocked ? chapter.emoji : '🔒',
        style: const TextStyle(fontSize: 20),
      ),
      title: Text(l10n.storyChapterLabel(chapter.id)),
      // Chương khoá: hiện ĐIỀU KIỆN mở (không lộ tên/nội dung chương) thay vì
      // chỉ "Chương chưa mở". Không dùng enabled:false — nó làm chữ mờ 38%,
      // trong khi gợi ý này chính là thứ người chơi cần đọc.
      subtitle: unlocked
          ? Text(storyText(chapter.id, code).title,
              maxLines: 1, overflow: TextOverflow.ellipsis)
          : lockedHint,
      onTap: unlocked
          ? () => showChapterRecap(context, chapter.id)
          : null,
    );
  }
}
