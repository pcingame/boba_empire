// Kệ trưng bày Pha theo đơn: chỗ phụ mở theo số món Thạo, lấy món hiếm nhất còn lại.
import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/recipe_counter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chỗ phụ mở theo mốc 10 / 30 / 60 món Thạo; mốc kế tiếp', () {
    expect([for (final m in [0, 9, 10, 29, 30, 59, 60, 100]) counterExtraSlots(m)], [0, 0, 1, 1, 2, 2, 3, 3]);
    expect([for (final m in [0, 10, 29, 30, 60, 100]) counterNextThreshold(m)], [10, 30, 30, 60, null, null]);
  });

  test('kệ: trưng bày sẵn giữ thứ tự, rồi tới món hiếm nhất còn lại; không trùng', () {
    final top = ([...accessories]..sort((a, b) {
        final r = b.rarity.index.compareTo(a.rarity.index);
        return r != 0 ? r : a.id.compareTo(b.id);
      }))
        .first;
    final other = accessories.firstWhere((a) => a.id != top.id && a.rarity != top.rarity);
    final owned = {top.id, other.id};
    final shelf0 = counterShelf(equipped: [other.id], owned: owned, mastered: 0);
    expect([for (final a in shelf0) a.id], [other.id], reason: 'chưa mở chỗ phụ');
    final shelf1 = counterShelf(equipped: [other.id], owned: owned, mastered: 10);
    expect([for (final a in shelf1) a.id], [other.id, top.id], reason: '1 chỗ phụ: món hiếm nhất chưa trưng bày');
    final shelf3 = counterShelf(equipped: [other.id], owned: owned, mastered: 99);
    expect(shelf3.map((a) => a.id).toSet().length, shelf3.length, reason: 'không trùng');
    expect(shelf3.length, lessThanOrEqualTo(1 + 3));
  });

  test('không có phụ kiện → kệ trống; độc quyền lễ hội cũng xếp được', () {
    expect(counterShelf(equipped: const [], owned: const {}, mastered: 99), isEmpty);
    final f = festivals.first.items.first;
    expect(counterShelf(equipped: const [], owned: {f.id}, mastered: 10).single.id, f.id);
  });
}
