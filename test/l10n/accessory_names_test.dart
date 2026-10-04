import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/l10n/l10n_ext.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mọi phụ kiện đều có tên dịch ở cả 6 ngôn ngữ (không rơi về hiển thị id thô).
void main() {
  for (final code in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    test('[$code] mọi phụ kiện có tên, khác id', () async {
      final l10n = await AppLocalizations.delegate.load(Locale(code));
      for (final a in accessories.followedBy(limitedAccessories)) {
        final name = accessoryName(l10n, a.id);
        expect(name, isNot(a.id), reason: '${a.id} thiếu tên ở $code');
        expect(name.trim(), isNotEmpty);
      }
      for (final f in festivals) {
        expect(festivalName(l10n, f.id), isNot(f.id), reason: '${f.id} thiếu tên dịp ở $code');
      }
    });
  }
}
