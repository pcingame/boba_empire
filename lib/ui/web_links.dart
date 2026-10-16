/// Liên kết tới trang web của game (bobaempiregame.com): trang chủ, hướng dẫn, và mở trình duyệt.
/// Chỉ trỏ tới trang THÔNG TIN (hướng dẫn, bảng xếp hạng) — không dẫn tới mua bán/thanh toán ngoài
/// app (quy định IAP của App Store).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../analytics/analytics.dart';
import '../l10n/app_localizations.dart';
import 'invite_dialog.dart' show shareTextProvider;

/// Tên miền của trang web (khớp docs/CNAME; test so khớp).
const webHomeUrl = 'https://bobaempiregame.com';

/// Kênh cộng đồng (khớp footer docs/index.html).
const facebookUrl = 'https://www.facebook.com/dechetrasua';
const tiktokUrl = 'https://www.tiktok.com/@ng.d.th84';

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
  final uri = Uri.parse(url);
  ref.read(analyticsProvider)(
      'web_open', {'page': uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path});
  final ok = await ref.read(urlOpenerProvider)(uri);
  if (!ok) messenger..clearSnackBars()..showSnackBar(SnackBar(content: Text(failText)));
}

/// Các tab bảng xếp hạng trên web (id khớp `BOARDS` trong docs/assets/site.js; test so khớp).
enum WebBoard { income, pearls, collection, speed, guild, vip }

/// Địa chỉ bảng xếp hạng web, mở sẵn tab [board] (site.js đọc tham số `board`, cuộn tới #board).
String webBoardUrl(WebBoard board) => '$webHomeUrl/?board=${board.name}#board';

/// Hồ sơ xếp hạng công khai của [nickname] trên web (site.js đọc tham số `player`).
String webProfileUrl(String nickname) =>
    '$webHomeUrl/?player=${Uri.encodeQueryComponent(nickname)}#board';

/// Hai nút ở AppBar của màn bảng xếp hạng: mở bảng này trên web, và chia sẻ liên kết cho người
/// chưa cài game xem (web công khai, không cần đăng nhập).
class WebBoardActions extends ConsumerWidget {
  const WebBoardActions(this.board, {super.key});
  final WebBoard board;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final url = webBoardUrl(board);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('web-board-open'),
          tooltip: l10n.webBoardOpenTip,
          icon: const Icon(Icons.public),
          onPressed: () => openWebLink(context, ref, url),
        ),
        Builder(
          builder: (btnContext) => IconButton(
            key: const Key('web-board-share'),
            tooltip: l10n.webBoardShareTip,
            icon: const Icon(Icons.share),
            onPressed: () {
              ref.read(analyticsProvider)('web_share', {'board': board.name});
              final box = btnContext.findRenderObject() as RenderBox?;
              final origin =
                  box == null ? null : box.localToGlobal(Offset.zero) & box.size;
              ref.read(shareTextProvider)(l10n.webBoardShareText(url), origin);
            },
          ),
        ),
      ],
    );
  }
}
