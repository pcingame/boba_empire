/// Cổng email trước khi nạp tiền thật: mua IAP cần đã liên kết email (đồng bộ đám mây)
/// để gắn giao dịch với một tài khoản khôi phục được — đổi máy/cài lại vẫn giữ 💎, VIP.
/// KHÔI PHỤC mua hàng không bị chặn (không tốn tiền). Chỉ chặn ở UI; store vẫn là
/// nơi xử lý thanh toán thật.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cloud_save_controller.dart';
import '../l10n/app_localizations.dart';
import 'cloud_save_dialog.dart';

bool _linked(WidgetRef ref) {
  try {
    return ref.read(cloudSaveControllerProvider) is CloudSaveLinked;
  } catch (_) {
    return false; // Supabase chưa khởi tạo → coi như chưa liên kết
  }
}

/// true nếu được phép mua. Chưa liên kết thì hỏi và mở màn liên kết email; trả true chỉ
/// khi liên kết xong. Gọi xong nhớ kiểm `mounted` trước khi dùng context/ref tiếp.
Future<bool> ensureEmailLinked(BuildContext context, WidgetRef ref) async {
  if (_linked(ref)) return true;
  final l10n = AppLocalizations.of(context)!;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('email-gate-dialog'),
      title: Text(l10n.emailGateTitle),
      content: Text(l10n.emailGateBody),
      actions: [
        TextButton(
          key: const Key('email-gate-cancel'),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('email-gate-link'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.emailGateLink),
        ),
      ],
    ),
  );
  if (go != true || !context.mounted) return false;
  await showCloudSaveDialog(context);
  return context.mounted && _linked(ref);
}

/// Cổng cho tính năng ONLINE (Hội, Chợ, Đấu Trường, bảng xếp hạng…): chỉ tài khoản đã liên kết email
/// mới vào được (xem data/linked_session.dart). Chưa liên kết thì giải thích và mở màn liên kết email;
/// trả true chỉ khi liên kết xong. Không cần WidgetRef — lấy container từ context.
Future<bool> ensureOnlineLinked(BuildContext context) async {
  final container = ProviderScope.containerOf(context);
  bool linked() {
    try {
      return container.read(cloudSaveControllerProvider) is CloudSaveLinked;
    } catch (_) {
      return false;
    }
  }

  if (linked()) return true;
  final l10n = AppLocalizations.of(context)!;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('online-gate-dialog'),
      title: Text(l10n.emailGateOnlineTitle),
      content: Text(l10n.emailGateOnlineBody),
      actions: [
        TextButton(
          key: const Key('online-gate-cancel'),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('online-gate-link'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.emailGateLink),
        ),
      ],
    ),
  );
  if (go != true || !context.mounted) return false;
  await showCloudSaveDialog(context);
  return context.mounted && linked();
}
