import 'package:flutter/material.dart';

import '../core/story.dart';
import '../core/story_content.dart';
import '../l10n/app_localizations.dart';

/// Cutscene một chương cốt truyện. Nhân vật = emoji lớn trong vòng tròn (không
/// cần asset). Chương thường có nút "Tiếp tục"; chương lựa chọn (6 & 8) hiện 2
/// nút xếp dọc và KHÔNG đóng được tới khi chọn.
Future<void> showStoryBeat(
  BuildContext context, {
  required int chapterId,
  required VoidCallback onContinue,
  required void Function(String optionKey) onChoose,
}) {
  final chapter = chapterById(chapterId);
  return showDialog<void>(
    context: context,
    barrierDismissible: chapter.choice == null,
    builder: (_) => _StoryDialog(
      chapter: chapter,
      onContinue: onContinue,
      onChoose: onChoose,
    ),
  );
}

/// Xem lại một chương đã mở (chỉ đọc — không nút lựa chọn/tiếp tục).
Future<void> showChapterRecap(BuildContext context, int chapterId) {
  final chapter = chapterById(chapterId);
  return showDialog<void>(
    context: context,
    builder: (_) => _StoryDialog(chapter: chapter, recap: true),
  );
}

class _StoryDialog extends StatelessWidget {
  const _StoryDialog({
    required this.chapter,
    this.onContinue,
    this.onChoose,
    this.recap = false,
  });

  final StoryChapter chapter;
  final VoidCallback? onContinue;
  final void Function(String optionKey)? onChoose;
  final bool recap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final code = Localizations.localeOf(context).languageCode;
    final text = storyText(chapter.id, code);
    final isChoice = chapter.choice != null && !recap;

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: ExcludeSemantics(
              child: Text(chapter.emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.storyChapterLabel(chapter.id),
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.primary),
                ),
                Text(
                  text.speaker,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(text.body, style: theme.textTheme.bodyMedium),
            if (isChoice) ...[
              const SizedBox(height: 16),
              Text(
                l10n.storyChoosePrompt,
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _ChoiceButton(
                buttonKey: const Key('story-choice-0'),
                label: text.optionA!,
                desc: text.optionADesc!,
                onTap: () {
                  Navigator.of(context).pop();
                  onChoose!(chapter.choice!.optionA);
                },
              ),
              const SizedBox(height: 8),
              _ChoiceButton(
                buttonKey: const Key('story-choice-1'),
                label: text.optionB!,
                desc: text.optionBDesc!,
                onTap: () {
                  Navigator.of(context).pop();
                  onChoose!(chapter.choice!.optionB);
                },
              ),
            ],
          ],
        ),
      ),
      actions: isChoice
          ? null
          : [
              FilledButton(
                key: const Key('story-continue'),
                onPressed: () {
                  Navigator.of(context).pop();
                  onContinue?.call();
                },
                child: Text(recap ? l10n.close : l10n.storyContinue),
              ),
            ],
    );
  }
}

/// Nút lựa chọn nhánh: nhãn đậm + mô tả perk, chiếm trọn bề ngang, chữ căn trái.
class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.buttonKey,
    required this.label,
    required this.desc,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        key: buttonKey,
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(desc, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
