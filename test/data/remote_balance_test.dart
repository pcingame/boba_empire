// Nút vặn Remote Config: key phải khớp field thật, và giá trị bậy trên console
// phải bị chặn TRƯỚC khi chạm vào Balance (milestoneStep = 0 là chia cho 0
// trong economy.dart → Infinity/NaN → đúng lớp bug làm Xu âm).
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/data/remote_balance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Balance giờ có field mutable → mỗi test phải trả lại nguyên trạng.
  late Map<String, Object> original;
  setUp(() => original = RemoteBalance.defaults());
  tearDown(() => RemoteBalance.applyValues(original.cast<String, num>()));

  test('defaults() đọc đúng giá trị đang biên dịch trong app', () {
    expect(RemoteBalance.defaults()['prestigeK'], Balance.prestigeK);
    expect(
      RemoteBalance.defaults()['milestoneStep'],
      Balance.milestoneStep.toDouble(),
    );
  });

  test('áp giá trị hợp lệ: double giữ nguyên, int làm tròn', () {
    final n = RemoteBalance.applyValues({
      'prestigeK': 0.03,
      'milestoneStep': 40.6,
    });
    expect(n, 2);
    expect(Balance.prestigeK, 0.03);
    expect(Balance.milestoneStep, 41);
  });

  test('bỏ qua giá trị ngoài khoảng hợp lệ và key lạ', () {
    final step = Balance.milestoneStep;
    final k = Balance.prestigeK;
    final n = RemoteBalance.applyValues({
      'milestoneStep': 0, // chia cho 0
      'prestigeK': 0.5, // vượt trần chống gian lận của server (0.05)
      'bonusPerStar': -1,
      'khongCoNutNay': 999,
      'maxOfflineSeconds': double.nan,
    });
    expect(n, 0);
    expect(Balance.milestoneStep, step);
    expect(Balance.prestigeK, k);
    expect(Balance.bonusPerStar, greaterThan(0));
  });

  test('trả lại giá trị gốc được (khoá luôn đường về của setUp/tearDown)', () {
    RemoteBalance.applyValues({'prestigeK': 0.04});
    expect(Balance.prestigeK, 0.04);
    RemoteBalance.applyValues(RemoteBalance.defaults().cast<String, num>()..['prestigeK'] = 0.02);
    expect(Balance.prestigeK, 0.02);
  });
}
