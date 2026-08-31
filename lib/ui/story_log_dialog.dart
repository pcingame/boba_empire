import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/story.dart';
import '../core/story_content.dart';
import '../l10n/app_localizations.dart';
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

    return AlertDialog(
      title: Text(l10n.storyLogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final chapter in storyChapters)
                _row(context, theme, l10n, code, chapter, chapter.id <= seen),
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

  Widget _row(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    String code,
    StoryChapter chapter,
    bool unlocked,
  ) {
    final title =
        unlocked ? storyText(chapter.id, code).title : l10n.storyLogLocked;
    return ListTile(
      dense: true,
      leading: Text(
        unlocked ? chapter.emoji : '🔒',
        style: const TextStyle(fontSize: 20),
      ),
      title: Text(l10n.storyChapterLabel(chapter.id)),
      subtitle: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      enabled: unlocked,
      onTap: unlocked
          ? () => showChapterRecap(context, chapter.id)
          : null,
    );
  }
}
