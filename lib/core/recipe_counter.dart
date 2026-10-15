/// Kệ trưng bày ở màn Pha theo đơn: phụ kiện đang trưng bày quanh cốc ở màn chính, cộng thêm vài chỗ phụ
/// mở dần theo số món đã từng đạt Thạo (lấy món hiếm nhất còn lại trong kho). Hàm thuần.
library;

import 'accessories.dart';

/// Số món Thạo cần để mở thêm 1 chỗ phụ (mỗi mốc +1 chỗ).
const List<int> counterSlotThresholds = [10, 30, 60];

int counterExtraSlots(int mastered) => counterSlotThresholds.where((t) => mastered >= t).length;

/// Mốc kế tiếp để mở thêm chỗ; null nếu đã mở hết.
int? counterNextThreshold(int mastered) => counterSlotThresholds.where((t) => mastered < t).firstOrNull;

/// Các món xếp trên kệ: trưng bày sẵn ([equipped], giữ thứ tự) rồi tới [counterExtraSlots] món hiếm nhất
/// trong số còn lại ([owned] gồm cả độc quyền lễ hội).
List<Accessory> counterShelf({required List<String> equipped, required Set<String> owned, required int mastered}) {
  final shelf = [for (final id in equipped) accessoryById(id)];
  final taken = {...equipped};
  final rest = [for (final id in owned) if (!taken.contains(id)) accessoryById(id)]
    ..sort((a, b) {
      final r = b.rarity.index.compareTo(a.rarity.index);
      return r != 0 ? r : a.id.compareTo(b.id);
    });
  return [...shelf, ...rest.take(counterExtraSlots(mastered))];
}
