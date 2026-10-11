/// Liên kết tới trang web của game (bobaempiregame.com): trang chủ, hướng dẫn, và mở trình duyệt.
/// Chỉ trỏ tới trang THÔNG TIN (hướng dẫn, bảng xếp hạng) — không dẫn tới mua bán/thanh toán ngoài
/// app (quy định IAP của App Store).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

/// Tên miền của trang web (khớp docs/CNAME; test so khớp).
const webHomeUrl = 'https://bobaempiregame.com';

/// Trang hướng dẫn; [anchor] là id mục trong docs/guide.html (test so khớp).
String webGuideUrl([String? anchor]) =>
    '$webHomeUrl/guide.html${anchor == null ? '' : '#$anchor'}';

/// Mở [uri] ở trình duyệt ngoài; công khai để test ghi đè (không mở trình duyệt thật). Trả false
/// nếu không mở được.
final urlOpenerProvider = Provider<Future<bool> Function(Uri uri)>(
  (ref) => (uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  },
);

/// Mở [url]; không mở được thì báo bằng snackbar thay vì im lặng.
Future<void> openWebLink(BuildContext context, WidgetRef ref, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final failText = AppLocalizations.of(context)!.webOpenFailed;
  final ok = await ref.read(urlOpenerProvider)(Uri.parse(url));
  if (!ok) messenger.showSnackBar(SnackBar(content: Text(failText)));
}
