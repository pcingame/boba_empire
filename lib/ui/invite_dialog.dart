/// Hộp "Mời bạn": mã của mình (chép/chia sẻ), thống kê lời mời + nhận thưởng, và ô nhập mã của
/// người mời (một lần). Mở từ hộp "Kiếm thêm" SAU khi đã liên kết email (xem email_gate.dart).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../referral/referral_controller.dart';
import '../referral/referral_repository.dart';

/// Mở share sheet với [text]; công khai để test ghi đè (không mở share sheet thật).
final shareTextProvider = Provider<Future<void> Function(String text, Rect? origin)>(
  (ref) => (text, origin) async {
    await SharePlus.instance.share(
      ShareParams(text: text, sharePositionOrigin: origin),
    );
  },
);

String referralErrorText(AppLocalizations l10n, ReferralFailure f) => switch (f) {
      ReferralFailure.emailRequired => l10n.refErrEmail,
      ReferralFailure.notFound => l10n.refErrNotFound,
      ReferralFailure.invalidCode => l10n.refErrInvalid,
      ReferralFailure.alreadyRedeemed => l10n.refErrAlready,
      ReferralFailure.inviterFull => l10n.refErrFull,
      ReferralFailure.nothingToClaim => l10n.refErrNothing,
      ReferralFailure.network => l10n.refErrNetwork,
    };

Future<void> showInviteDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const _InviteDialog(),
    );

class _InviteDialog extends ConsumerStatefulWidget {
  const _InviteDialog();

  @override
  ConsumerState<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<_InviteDialog> {
  final _codeCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(referralControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _toast(String text) => ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _redeem() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeCtrl.text.trim();
    if (code.isEmpty || _busy) return;
    setState(() => _busy = true);
    final out = await ref.read(referralControllerProvider.notifier).redeem(code);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(out.ok ? l10n.refRedeemedSnack(out.gems) : referralErrorText(l10n, out.failure!));
    if (out.ok) _codeCtrl.clear();
  }

  Future<void> _claim() async {
    final l10n = AppLocalizations.of(context)!;
    if (_busy) return;
    setState(() => _busy = true);
    final out = await ref.read(referralControllerProvider.notifier).claim();
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(out.ok ? l10n.refClaimedSnack(out.gems) : referralErrorText(l10n, out.failure!));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final view = ref.watch(referralControllerProvider);
    return AlertDialog(
      title: Text(l10n.refTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: switch (view) {
            ReferralLoading() => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
            ReferralError(:final failure) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(referralErrorText(l10n, failure), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('invite-retry'),
                    onPressed: () => ref.read(referralControllerProvider.notifier).load(),
                    child: Text(l10n.leaderboardRetry),
                  ),
                ],
              ),
            ReferralLoaded(:final status) => _content(l10n, status),
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Widget _content(AppLocalizations l10n, ReferralStatus s) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.refYourCode, style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SelectableText(
                s.code,
                key: const Key('invite-code'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
            ),
            IconButton(
              key: const Key('invite-copy'),
              tooltip: l10n.refCopy,
              icon: const Icon(Icons.copy),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: s.code));
                if (mounted) _toast(l10n.refCopied);
              },
            ),
            Builder(
              builder: (btnContext) => IconButton(
                key: const Key('invite-share'),
                tooltip: l10n.refShare,
                icon: const Icon(Icons.share),
                onPressed: () {
                  final box = btnContext.findRenderObject() as RenderBox?;
                  final origin = box == null
                      ? null
                      : box.localToGlobal(Offset.zero) & box.size;
                  ref.read(shareTextProvider)(l10n.refShareText(s.code), origin);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(l10n.refRule(referralInviterReward, referralStageNeeded),
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(
          l10n.refStats(s.invited, referralMaxInvites, s.reached),
          key: const Key('invite-stats'),
        ),
        if (s.claimable > 0) ...[
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('invite-claim'),
            onPressed: _busy ? null : _claim,
            child: Text(l10n.refClaim(s.claimable * referralInviterReward)),
          ),
        ],
        const Divider(height: 28),
        if (s.redeemed)
          Text(l10n.refErrAlready,
              key: const Key('invite-already'), style: theme.textTheme.bodySmall)
        else ...[
          Text(l10n.refEnterTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          TextField(
            key: const Key('invite-input'),
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: l10n.refEnterHint,
              border: const OutlineInputBorder(),
            ),
          ),
          FilledButton.tonal(
            key: const Key('invite-redeem'),
            onPressed: _busy ? null : _redeem,
            child: Text(l10n.refRedeem),
          ),
        ],
      ],
    );
  }
}
