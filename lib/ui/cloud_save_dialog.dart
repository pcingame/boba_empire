/// Dialog "Đồng bộ đám mây" (cloud save qua email OTP) — xem
/// PROPOSAL_CLOUD_SAVE.md. Mở từ Cài đặt (`settings_dialog.dart`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../data/cloud_save_controller.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';

Future<void> showCloudSaveDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _CloudSaveDialog(),
  );
}

class _CloudSaveDialog extends ConsumerStatefulWidget {
  const _CloudSaveDialog();

  @override
  ConsumerState<_CloudSaveDialog> createState() => _CloudSaveDialogState();
}

class _CloudSaveDialogState extends ConsumerState<_CloudSaveDialog> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Gán callback mỗi lần build (rẻ, luôn đúng) — controller tách biệt khỏi
    // GameController, chỉ chạm qua đây, giống cách arena_page.dart nối
    // onRewardGems.
    final notifier = ref.read(cloudSaveControllerProvider.notifier);
    notifier.getLocalSave =
        () => ref.read(gameControllerProvider.notifier).exportSaveJson();
    notifier.getLocalLifetimeEarnings =
        () => ref.read(gameControllerProvider).lifetimeEarnings;
    notifier.onRestore =
        (json) => ref.read(gameControllerProvider.notifier).restoreFromCloud(json);

    final viewState = ref.watch(cloudSaveControllerProvider);

    return AlertDialog(
      title: Text(l10n.cloudSaveTitle),
      content: SizedBox(
        width: 320,
        child: switch (viewState) {
          CloudSaveUnlinked() => _EmailForm(l10n: l10n, emailCtrl: _emailCtrl),
          CloudSaveSendingCode() => const _Loading(),
          CloudSaveAwaitingCode(email: final email) =>
            _CodeForm(l10n: l10n, email: email, codeCtrl: _codeCtrl),
          CloudSaveVerifying() => const _Loading(),
          CloudSaveConflict(:final localLifetimeEarnings, :final cloud) =>
            _ConflictView(
              l10n: l10n,
              localLifetimeEarnings: localLifetimeEarnings,
              cloudLifetimeEarnings:
                  (cloud.data['lifetimeEarnings'] as num?)?.toDouble() ?? 0,
            ),
          CloudSaveLinked(email: final email) => _LinkedView(l10n: l10n, email: email),
          CloudSaveError(:final message) => _ErrorView(l10n: l10n, message: message),
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
}

class _EmailForm extends ConsumerWidget {
  const _EmailForm({required this.l10n, required this.emailCtrl});
  final AppLocalizations l10n;
  final TextEditingController emailCtrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.cloudSaveIntro),
        const SizedBox(height: 16),
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(
            labelText: l10n.cloudSaveEmailHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            final email = emailCtrl.text.trim();
            if (email.contains('@')) {
              ref.read(cloudSaveControllerProvider.notifier).sendCode(email);
            }
          },
          child: Text(l10n.cloudSaveSendCode),
        ),
      ],
    );
  }
}

class _CodeForm extends ConsumerWidget {
  const _CodeForm({required this.l10n, required this.email, required this.codeCtrl});
  final AppLocalizations l10n;
  final String email;
  final TextEditingController codeCtrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.cloudSaveCodeSentTo(email)),
        const SizedBox(height: 16),
        TextField(
          controller: codeCtrl,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          maxLength: 6,
          decoration: InputDecoration(
            labelText: l10n.cloudSaveCodeHint,
            border: const OutlineInputBorder(),
          ),
        ),
        FilledButton(
          onPressed: () {
            final code = codeCtrl.text.trim();
            if (code.isNotEmpty) {
              ref.read(cloudSaveControllerProvider.notifier).verifyCode(email, code);
            }
          },
          child: Text(l10n.cloudSaveVerify),
        ),
        TextButton(
          onPressed: () => ref.read(cloudSaveControllerProvider.notifier).backToUnlinked(),
          child: Text(l10n.cloudSaveChangeEmail),
        ),
      ],
    );
  }
}

class _ConflictView extends ConsumerWidget {
  const _ConflictView({
    required this.l10n,
    required this.localLifetimeEarnings,
    required this.cloudLifetimeEarnings,
  });
  final AppLocalizations l10n;
  final double localLifetimeEarnings;
  final double cloudLifetimeEarnings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.cloudSaveConflictTitle,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Text(l10n.cloudSaveConflictLocal(formatNumber(localLifetimeEarnings))),
        Text(l10n.cloudSaveConflictCloud(formatNumber(cloudLifetimeEarnings))),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () =>
              ref.read(cloudSaveControllerProvider.notifier).restoreFromCloud(),
          child: Text(l10n.cloudSaveRestoreButton),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => ref.read(cloudSaveControllerProvider.notifier).keepLocal(),
          child: Text(l10n.cloudSaveKeepLocalButton),
        ),
      ],
    );
  }
}

class _LinkedView extends ConsumerWidget {
  const _LinkedView({required this.l10n, required this.email});
  final AppLocalizations l10n;
  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.cloud_done, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.cloudSaveLinkedStatus(email))),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => ref.read(cloudSaveControllerProvider.notifier).signOut(),
          child: Text(l10n.cloudSaveDisconnect),
        ),
      ],
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.l10n, required this.message});
  final AppLocalizations l10n;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => ref.read(cloudSaveControllerProvider.notifier).backToUnlinked(),
          child: Text(l10n.cloudSaveRetry),
        ),
      ],
    );
  }
}
