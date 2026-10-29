import 'package:boba_empire/core/branches.dart';
import 'package:boba_empire/core/trophies.dart';
import 'package:flutter_test/flutter_test.dart';

TrophyStats _stats({Map<String, int> branches = const {}, int stage = 1, int ascension = 0, int owned = 0}) => TrophyStats(
      branchLevels: branches,
      stage: stage,
      ascension: ascension,
      owned: owned,
      achievements: 0,
      storyChapter: 0,
      vipExp: 0,
    );

Set<String> _earned(TrophyStats s) => {for (final t in trophies) if (t.earned(s)) t.id};

void main() {
  test('người mới chưa có huy hiệu nào; id duy nhất', () {
    expect(_earned(_stats()), isEmpty);
    expect(trophies.map((t) => t.id).toSet().length, trophies.length);
  });

  test('chi nhánh: một nơi → đầu tiên; đủ 17 → phủ sóng; cấp 10 → tối đa', () {
    expect(_earned(_stats(branches: {'saigon': 1})), {'firstBranch'});
    final all = {for (final c in branchCities) c.id: 1};
    expect(_earned(_stats(branches: all)), {'firstBranch', 'allBranches'});
    all['moon'] = branchMaxLevel;
    expect(_earned(_stats(branches: all)), containsAll(['maxBranch', 'allBranches']));
  });

  test('mốc giai đoạn, Kỷ Nguyên và sưu tập', () {
    expect(_earned(_stats(stage: 18)), {'moon'});
    expect(_earned(_stats(ascension: 1)), {'ascend'});
    expect(_earned(_stats(ascension: 4)), {'ascend', 'ascend4'});
    expect(_earned(_stats(owned: 100)), {'collector'});
  });
}
