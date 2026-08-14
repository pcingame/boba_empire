import 'package:boba_empire/l10n/locale_provider.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Khoá persist (khớp LocaleNotifier._key) — kiểm tra trực tiếp giá trị lưu.
const _key = 'app_locale';

ProviderContainer _container(SharedPreferences prefs) {
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('mặc định (prefs rỗng) → null = theo hệ thống', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = _container(prefs);

    expect(container.read(localeProvider), isNull);
  });

  test('set(locale) cập nhật state và ghi vào prefs', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = _container(prefs);

    await container.read(localeProvider.notifier).set(const Locale('en'));

    expect(container.read(localeProvider), const Locale('en'));
    expect(prefs.getString(_key), 'en'); // đã persist
  });

  test('restore: container mới đọc lại locale đã lưu', () async {
    SharedPreferences.setMockInitialValues({_key: 'th'});
    final prefs = await SharedPreferences.getInstance();
    final container = _container(prefs);

    expect(container.read(localeProvider), const Locale('th'));
  });

  test('set(null) xoá pref và quay về theo hệ thống', () async {
    SharedPreferences.setMockInitialValues({_key: 'vi'});
    final prefs = await SharedPreferences.getInstance();
    final container = _container(prefs);
    expect(container.read(localeProvider), const Locale('vi'));

    await container.read(localeProvider.notifier).set(null);

    expect(container.read(localeProvider), isNull);
    expect(prefs.getString(_key), isNull); // đã xoá khỏi prefs
  });
}
