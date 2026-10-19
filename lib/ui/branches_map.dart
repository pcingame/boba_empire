/// Bản đồ thế giới của Chi nhánh: lục địa tự vẽ bằng đa giác đơn giản, mỗi chi nhánh là một ghim (landmark + vòng đầy kho),
/// đường nối giữa các chi nhánh đã mở. Vuốt/phóng to được; bấm ghim gọi [BranchesMap.onPin]. Vị trí ghim là toạ độ trên
/// khung 1000×480 (đã nới nhẹ ở Đông Nam Á cho khỏi chồng nhau), không phải kinh/vĩ độ chính xác.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/branches.dart';
import 'widgets/effects_quality.dart';
import 'widgets/motion.dart' show reduceMotion;

const double _w = 1000, _h = 480, _pin = 46;

/// Vị trí ghim trên khung bản đồ. 'moon' không nằm trên bản đồ (ghim cố định ở góc).
const Map<String, Offset> branchMapPos = {
  'saigon': Offset(790, 285),
  'danang': Offset(830, 235),
  'hanoi': Offset(765, 170),
  'singapore': Offset(745, 340),
  'tokyo': Offset(910, 150),
  'hongkong': Offset(835, 178),
  'seoul': Offset(850, 118),
  'sydney': Offset(920, 392),
  'bangkok': Offset(735, 228),
  'istanbul': Offset(590, 125),
  'paris': Offset(520, 112),
  'london': Offset(488, 68),
  'newyork': Offset(294, 130),
  'rio': Offset(380, 351),
  'dubai': Offset(665, 200),
  'cairo': Offset(590, 185),
};

/// Lục địa/đảo: danh sách (kinh độ, vĩ độ), chiếu phẳng lên khung 1000×480. Vẽ tay, đủ nhận ra bờ biển chứ không chính xác.
const List<List<(double, double)>> _land = [
  // Châu Âu | Châu Á (ranh Ural – Caucasus – Bosphorus)
  [
    (-9, 37),
    (-9, 43),
    (-1.5, 43.5),
    (-1, 46),
    (-4.5, 48.5),
    (-1.5, 49),
    (2, 51),
    (4, 52),
    (8, 54),
    (8.5, 57),
    (10.5, 57.5),
    (10.5, 55),
    (12.5, 54.5),
    (14, 54),
    (19, 54.5),
    (21, 57),
    (24, 57),
    (24, 59.5),
    (30, 60),
    (23, 60),
    (22, 63),
    (25, 65.5),
    (21.5, 65),
    (17.5, 62),
    (19, 60),
    (16.5, 57),
    (13, 55.5),
    (11, 59),
    (6, 58),
    (5, 61),
    (14, 67),
    (20, 70),
    (30, 70.5),
    (41, 67),
    (44, 68),
    (60, 69),
    (60, 55),
    (58, 51),
    (51, 50),
    (48, 46.5),
    (47, 43.5),
    (44, 42.5),
    (41.5, 41.5),
    (36, 41.8),
    (33, 42),
    (29.5, 41.2),
    (29, 41.2),
    (26.3, 40.5),
    (24, 40),
    (23, 38),
    (22, 36.5),
    (21, 38.5),
    (19.5, 41.5),
    (15, 45),
    (13, 45.5),
    (12.5, 44),
    (16, 41.5),
    (18.5, 40),
    (16, 38),
    (15.7, 40),
    (12.5, 41.5),
    (10.5, 43),
    (8.5, 44.3),
    (6, 43),
    (3, 43.2),
    (3, 42),
    (0.7, 40.7),
    (-0.5, 38.5),
    (-2, 36.8),
    (-5.5, 36.1),
    (-6.5, 37),
  ],
  [
    (60, 69),
    (70, 73),
    (80, 73),
    (87, 75),
    (100, 77),
    (113, 74),
    (130, 71),
    (140, 72),
    (160, 70),
    (170, 69.5),
    (180, 68),
    (180, 65),
    (172, 64),
    (165, 62),
    (160, 54),
    (156, 51),
    (150, 59),
    (142, 59),
    (137, 54),
    (141, 52),
    (140, 48),
    (135, 43),
    (131, 42.5),
    (129, 41),
    (128, 39),
    (129, 35.5),
    (126.5, 34.5),
    (126, 37.5),
    (125, 39.5),
    (121.5, 39),
    (121, 41),
    (118, 39),
    (119, 37),
    (122.5, 37),
    (120, 34),
    (122, 30),
    (121, 28),
    (119, 25),
    (116.5, 23),
    (113.5, 22),
    (110.5, 21),
    (108, 21.5),
    (106, 20),
    (105.8, 19),
    (108.5, 16),
    (109.3, 13),
    (109, 11.5),
    (107, 10.4),
    (105, 8.6),
    (104.8, 10.2),
    (103, 10.5),
    (101, 12.5),
    (100.5, 13.5),
    (99.5, 10),
    (100.5, 7),
    (102, 6),
    (103.5, 4),
    (104, 1.4),
    (103, 1.5),
    (101.5, 3),
    (100.4, 5.5),
    (98.5, 8),
    (98.5, 10),
    (98, 13),
    (97.8, 16.5),
    (94.5, 16),
    (94, 19),
    (92, 21),
    (91, 22.5),
    (88, 21.7),
    (86.5, 20),
    (84, 18),
    (80.5, 15.5),
    (80, 13),
    (79.8, 10.3),
    (78, 8.3),
    (76.5, 9),
    (75, 12.5),
    (73, 17.5),
    (72.8, 21),
    (70, 20.8),
    (68.5, 23),
    (66, 25.3),
    (62, 25),
    (57, 25.8),
    (56.5, 27),
    (54, 26.7),
    (51.5, 27.8),
    (50, 30),
    (48, 30),
    (47.8, 29.5),
    (50, 26.5),
    (51.5, 24.5),
    (54, 24),
    (56, 26),
    (56.5, 24.5),
    (59.5, 22.5),
    (57.5, 19),
    (55, 17),
    (52, 16),
    (48, 14),
    (45, 12.8),
    (43.5, 12.7),
    (42.8, 15),
    (41, 19),
    (38.5, 23.5),
    (36.5, 26.5),
    (35, 28),
    (34.5, 29.5),
    (34, 31.3),
    (35.5, 33.5),
    (36, 36),
    (32, 36.2),
    (29, 36.6),
    (27, 37.2),
    (26.5, 39.5),
    (26.3, 40.5),
    (29, 41.2),
    (29.5, 41.2),
    (33, 42),
    (36, 41.8),
    (41.5, 41.5),
    (44, 42.5),
    (47, 43.5),
    (48, 46.5),
    (51, 50),
    (58, 51),
    (60, 55),
  ],
  // Châu Phi
  [
    (-9.5, 35.8),
    (-6, 35.8),
    (-2, 35.1),
    (3, 36.8),
    (10, 37.2),
    (11, 33.5),
    (15, 32.3),
    (20, 32.2),
    (20, 30.5),
    (25, 31.8),
    (32, 31.2),
    (34, 28),
    (35.7, 24),
    (37.5, 18.5),
    (39, 15.5),
    (43.2, 12.6),
    (44, 10.5),
    (51, 11.8),
    (48, 5),
    (42, -1),
    (40, -5),
    (39, -9),
    (40.5, -15),
    (35, -20),
    (35.5, -24),
    (32.5, -26),
    (30, -31),
    (27, -33.5),
    (22, -34.2),
    (18.5, -34.2),
    (17, -29),
    (14.5, -22.5),
    (12, -17),
    (13.5, -11),
    (12, -5),
    (9, -1),
    (9.5, 3.5),
    (6, 4.3),
    (2, 6.2),
    (-4, 5.2),
    (-8, 4.5),
    (-13, 8),
    (-15.5, 11.5),
    (-17.3, 14.7),
    (-16, 19),
    (-17, 21),
    (-13, 27.5),
    (-9.8, 30),
    (-9.7, 32.5),
    (-8, 35),
  ],
  // Bắc Mỹ
  [
    (-168, 65.5),
    (-162, 63),
    (-165, 60),
    (-158, 58),
    (-153, 59),
    (-148, 60.5),
    (-140, 59.8),
    (-135, 57),
    (-130, 54),
    (-127, 50),
    (-124.5, 48.5),
    (-124, 43),
    (-124, 40),
    (-122.5, 37.5),
    (-120.5, 34.5),
    (-117, 32.5),
    (-112, 26),
    (-110, 23),
    (-108, 25),
    (-106, 22),
    (-105.5, 20),
    (-103, 18.5),
    (-99, 16.7),
    (-95, 16),
    (-92, 14.5),
    (-90, 13.7),
    (-87.5, 13),
    (-86, 11),
    (-85.5, 9.8),
    (-83.5, 8.5),
    (-80, 7.3),
    (-78, 8.5),
    (-77.5, 9),
    (-79.5, 9.5),
    (-83, 10.5),
    (-83.5, 15),
    (-87.5, 15.8),
    (-88.5, 16),
    (-87.8, 21.5),
    (-90.5, 21),
    (-90.5, 19.5),
    (-94, 18.3),
    (-97.5, 22),
    (-97.3, 26),
    (-95, 29),
    (-90, 29.2),
    (-89, 30.3),
    (-85, 29.8),
    (-83, 29.2),
    (-82.7, 27.5),
    (-81.2, 25.2),
    (-80.2, 25.5),
    (-80.5, 28.5),
    (-81, 31.5),
    (-76, 35),
    (-75.5, 38),
    (-74, 40.5),
    (-70, 41.5),
    (-70, 43.7),
    (-67, 44.8),
    (-61, 45.5),
    (-57, 50),
    (-60, 55),
    (-62, 58),
    (-65, 60),
    (-70, 58.5),
    (-78, 62),
    (-77, 57),
    (-80, 51.5),
    (-86, 55),
    (-92, 57),
    (-94.5, 59),
    (-90, 64),
    (-82, 66),
    (-85, 69),
    (-95, 68),
    (-105, 68.5),
    (-115, 68),
    (-125, 69.5),
    (-135, 69),
    (-141, 69.7),
    (-150, 70.3),
    (-157, 71),
    (-163, 70),
    (-166, 68.5),
  ],
  // Nam Mỹ
  [
    (-77.5, 9),
    (-75.5, 11),
    (-72, 12),
    (-71, 10.5),
    (-68, 10.5),
    (-64, 10.5),
    (-61.5, 10.5),
    (-60, 8.5),
    (-57, 6),
    (-53, 5.5),
    (-51, 4),
    (-50, 1.5),
    (-48, -0.5),
    (-44, -2.5),
    (-40, -3),
    (-35.2, -5.5),
    (-35, -8.5),
    (-37.5, -12.5),
    (-39, -16),
    (-40, -20),
    (-42, -22.9),
    (-45, -23.7),
    (-48, -26),
    (-48.7, -28.5),
    (-52, -32),
    (-54, -34.5),
    (-57, -34.9),
    (-58.5, -38),
    (-62, -39),
    (-65, -41),
    (-65, -45),
    (-67.5, -46.5),
    (-66, -48),
    (-69, -51),
    (-68.5, -53),
    (-72, -53.5),
    (-75, -50),
    (-74, -45),
    (-73.5, -40),
    (-73.5, -37),
    (-71.5, -32),
    (-70.5, -25),
    (-70.2, -18.5),
    (-75, -15),
    (-78, -10),
    (-81, -6),
    (-80.5, -3),
    (-80, -1),
    (-80, 1),
    (-78.5, 2),
    (-77.5, 4),
    (-77, 7),
  ],
  // Úc
  [
    (113.5, -22),
    (114, -26),
    (115, -30),
    (115, -34.2),
    (118, -35),
    (123.5, -34),
    (129, -31.5),
    (134, -32.5),
    (137.5, -33.5),
    (138, -35.5),
    (140, -37.8),
    (144, -38.5),
    (147, -38),
    (150, -37.5),
    (151, -33.5),
    (153, -28.5),
    (153, -25),
    (150.5, -22.5),
    (146.5, -19),
    (145.5, -15),
    (143.5, -14),
    (142.5, -10.8),
    (141.5, -13),
    (141, -17),
    (139, -17.5),
    (136, -15),
    (136.5, -12),
    (132, -11.3),
    (130, -12.5),
    (129, -15),
    (126, -14),
    (123.5, -17),
    (121, -19.5),
    (117, -20.5),
  ],
  // Greenland, Iceland, Anh, Ireland
  [
    (-73, 78.5),
    (-62, 82),
    (-30, 83.5),
    (-20, 81),
    (-18, 76),
    (-22, 70.5),
    (-32, 68),
    (-40, 65),
    (-43, 60),
    (-49, 61),
    (-53, 66),
    (-55, 70),
    (-62, 76),
  ],
  [(-24, 65.5), (-18, 66.2), (-14, 65), (-18, 63.4), (-22, 63.8)],
  [
    (-5.7, 50),
    (1.3, 51.2),
    (1.7, 52.8),
    (-0.5, 54),
    (-1.8, 55.8),
    (-2, 57.6),
    (-4, 57.8),
    (-3, 58.6),
    (-5, 58.6),
    (-6, 56.5),
    (-5, 55),
    (-3, 54.5),
    (-3, 53.3),
    (-4.7, 52.5),
    (-5.2, 51.7),
    (-3.2, 51.4),
    (-4.5, 50.3),
  ],
  [(-10, 51.8), (-6, 52.2), (-6, 54.5), (-8, 55.2), (-10, 54)],
  // Nhật (Honshu, Hokkaido, Kyushu), Sakhalin, Đài Loan, Hải Nam
  [
    (130.9, 34),
    (133, 35.5),
    (136, 36),
    (137, 37),
    (139, 38.5),
    (140, 40.5),
    (141.5, 41.2),
    (142, 39.5),
    (141, 37),
    (140.5, 35.2),
    (139, 35),
    (136.8, 34.5),
    (135, 33.5),
    (132, 33.8),
  ],
  [(140, 42), (141.5, 43.5), (145, 43.5), (143, 42)],
  [(129.8, 33), (131.5, 34), (131.8, 32), (130.5, 31)],
  [(142, 46), (143.5, 49), (143, 54), (142, 52)],
  [(120.2, 23), (121.5, 25.2), (122, 24.8), (120.8, 22)],
  [(108.7, 19.2), (110.5, 20), (111, 19.5), (109.5, 18.3)],
  // Đông Nam Á hải đảo: Sumatra, Java, Borneo, Sulawesi, Luzon, Mindanao
  [
    (95.3, 5.5),
    (98.5, 4),
    (103, -0.5),
    (106, -3),
    (105.8, -5.8),
    (102, -4),
    (99, 0.5),
  ],
  [
    (105.5, -6.5),
    (109, -6.8),
    (112.5, -6.8),
    (114.5, -8),
    (108, -8),
    (106, -7.2),
  ],
  [
    (109, 1.5),
    (111, 2.5),
    (114, 4.3),
    (117, 7),
    (119, 5),
    (118, 1),
    (116.5, -3.5),
    (114, -3.5),
    (110, -3),
    (109, -1),
  ],
  [
    (119.5, -5),
    (120.5, -3),
    (120, 0.5),
    (124.5, 1.5),
    (122, -1),
    (123, -4),
    (121, -2.5),
  ],
  [(120, 18.5), (122, 18.2), (122, 14), (124, 13), (121, 13.5), (120, 15)],
  [(122, 8), (126, 9.5), (126.5, 7), (125, 6), (122.5, 7)],
  [(80, 9.7), (81.8, 7.5), (80.3, 6)],
  // Madagascar, New Zealand (Bắc/Nam), Tasmania, Cuba, Sicily
  [(43.5, -23.5), (47, -25), (50, -15.5), (49, -12), (44, -16.5)],
  [(172.7, -34.5), (178.5, -37.7), (175.2, -41.5), (174.5, -39), (173, -37)],
  [
    (172.5, -40.5),
    (174, -41.5),
    (171, -44.5),
    (169, -46.5),
    (166.5, -46),
    (170.5, -43),
  ],
  [(145, -41), (148.3, -41), (147, -43.5)],
  [(-85, 22), (-80, 23.2), (-74.2, 20.2), (-77.5, 19.9), (-82, 22.5)],
  [(12.5, 38), (15.5, 38.2), (15, 36.8)],
];

/// Châu lục của từng polygon trong [_land] (0 Á, 1 Âu, 2 Phi, 3 Bắc Mỹ, 4 Nam Mỹ, 5 Đại Dương); khớp theo thứ tự.
const List<int> _landContinent = [
  1, 0, // Âu, Á
  2, // Phi
  3, 4, 5, // Bắc Mỹ, Nam Mỹ, Úc
  3, 1, 1, 1, // Greenland, Iceland, Anh, Ireland
  0, 0, 0, 0, 0, 0, // Honshu, Hokkaido, Kyushu, Sakhalin, Đài Loan, Hải Nam
  0,
  0,
  0,
  0,
  0,
  0,
  0, // Sumatra, Java, Borneo, Sulawesi, Luzon, Mindanao, Sri Lanka
  2, 5, 5, 5, // Madagascar, NZ Bắc, NZ Nam, Tasmania
  3, 1, // Cuba, Sicily
];

/// Màu lục địa (sáng, tối) theo chỉ số châu lục: đầu–cuối gradient dọc + nét bờ.
const List<(Color, Color, Color)> _contLight = [
  (Color(0xFFEAF5CF), Color(0xFFCFE6A4), Color(0xFF8FB074)), // Á
  (Color(0xFFFFF3C4), Color(0xFFF6E096), Color(0xFFCDB56A)), // Âu
  (Color(0xFFFBE2BD), Color(0xFFF2C990), Color(0xFFC79A5E)), // Phi
  (Color(0xFFD3F0E1), Color(0xFFABDCC4), Color(0xFF6FAE96)), // Bắc Mỹ
  (Color(0xFFF0DDF5), Color(0xFFDDBFE8), Color(0xFFA98BB8)), // Nam Mỹ
  (Color(0xFFFBDCE1), Color(0xFFF3B9C4), Color(0xFFC98A98)), // Đại Dương
];
const List<(Color, Color, Color)> _contDark = [
  (Color(0xFF4F7C57), Color(0xFF37603F), Color(0xFF7FB08C)),
  (Color(0xFF7A7340), Color(0xFF615B2F), Color(0xFFB0A56A)),
  (Color(0xFF86683F), Color(0xFF6B512E), Color(0xFFB8975E)),
  (Color(0xFF3F7A6A), Color(0xFF2F5E52), Color(0xFF6FB09C)),
  (Color(0xFF75588A), Color(0xFF5C436E), Color(0xFFA98BB8)),
  (Color(0xFF8A5560), Color(0xFF6E404A), Color(0xFFC98A98)),
];

/// Vị trí nhãn tên châu lục (khung 1000×480), cùng thứ tự chỉ số châu lục.
const List<Offset> _contLabelPos = [
  Offset(700, 78),
  Offset(560, 40),
  Offset(520, 262),
  Offset(160, 80),
  Offset(300, 318),
  Offset(850, 346),
];

/// Biển nội địa khoét lên lục địa.
const List<List<(double, double)>> _lakes = [
  [
    (28, 41.5),
    (28.5, 43.5),
    (30, 46),
    (33, 46),
    (35, 45),
    (37.5, 44.8),
    (41.5, 42),
    (41.5, 41),
    (36, 41.8),
    (33, 42),
    (29.5, 41.2),
  ], // Biển Đen
  [
    (47, 45),
    (50, 46.5),
    (53, 45),
    (53, 41),
    (54, 37.5),
    (50, 37),
    (49, 40),
    (47, 43),
  ], // Biển Caspi
];

Offset _proj(double lon, double lat) =>
    Offset((lon + 180) / 360 * _w, (78 - lat) / 138 * _h);

class BranchesMap extends StatefulWidget {
  const BranchesMap({
    super.key,
    required this.levels,
    required this.since,
    required this.stage,
    required this.now,
    this.manager = false,
    required this.nameOf,
    required this.onPin,
    this.continentNames = const [],
    this.animations,
  });
  final Map<String, int> levels;
  final Map<String, int> since;
  final int stage;
  final int now;
  final bool manager;
  final String Function(String id) nameOf;
  final void Function(BranchCity c) onPin;

  /// Tên 6 châu lục (Á, Âu, Phi, Bắc Mỹ, Nam Mỹ, Đại Dương) để in mờ trên bản đồ; rỗng thì không in.
  final List<String> continentNames;

  /// Bật/tắt máy bay + hiệu ứng khai trương. null = tự động: tắt khi giảm chuyển động hoặc hiệu ứng tắt/máy yếu.
  final bool? animations;

  @override
  State<BranchesMap> createState() => _BranchesMapState();
}

class _BranchesMapState extends State<BranchesMap>
    with TickerProviderStateMixin {
  TransformationController? _ctrl;

  /// Máy bay bay dọc đường nối (lặp chậm); null khi tắt hoặc chưa đủ 2 chi nhánh.
  AnimationController? _flight;

  /// Hiệu ứng khai trương đang chạy theo id chi nhánh vừa mở.
  final Map<String, AnimationController> _bursts = {};
  late Set<String> _opened = _openedIds();

  Set<String> _openedIds() => {
    for (final c in branchCities)
      if (branchLevel(widget.levels, c.id) > 0) c.id,
  };

  bool get _fxOn => widget.animations ?? !reduceMotion;

  /// Số máy bay tối đa theo mức hiệu ứng: thấp 0, vừa 4, cao 8 (ép bật trong test = 4).
  int get _planeBudget {
    if (!_fxOn) return 0;
    if (widget.animations == true) return 4;
    return switch (EffectsController.instance.quality.value) {
      EffectsQuality.off || EffectsQuality.low => 0,
      EffectsQuality.medium => 4,
      EffectsQuality.high => 8,
    };
  }

  void _syncFlight() {
    final want = _planeBudget > 0 && _opened.length >= 2;
    if (want && _flight == null) {
      _flight = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 16),
      )..repeat();
    } else if (!want && _flight != null) {
      _flight!.dispose();
      _flight = null;
    }
  }

  void _onQuality() {
    _syncFlight();
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _syncFlight();
    EffectsController.instance.quality.addListener(_onQuality);
  }

  @override
  void didUpdateWidget(BranchesMap old) {
    super.didUpdateWidget(old);
    final now = _openedIds();
    // Chi nhánh MỚI mở (không có trong tập đã thấy): khai trương. So với tập tự giữ, không so với [old.levels] (có thể cùng instance).
    for (final id in now.difference(_opened)) {
      if (_fxOn) _startBurst(id);
    }
    _opened = now;
    _syncFlight();
  }

  void _startBurst(String id) {
    _bursts.remove(id)?.dispose();
    final c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _bursts[id] = c;
    c.addStatusListener((st) {
      if (st == AnimationStatus.completed && mounted && _bursts[id] == c) {
        setState(() => _bursts.remove(id));
        c.dispose();
      }
    });
    c.forward();
  }

  @override
  void dispose() {
    EffectsController.instance.quality.removeListener(_onQuality);
    _flight?.dispose();
    for (final c in _bursts.values) {
      c.dispose();
    }
    _ctrl?.dispose();
    super.dispose();
  }

  Widget _pinWidget(BranchCity c, {double size = _pin}) {
    final lvl = branchLevel(widget.levels, c.id);
    final locked = lvl == 0 && widget.stage < c.minStage;
    final tint = Color(c.color);
    final fill = branchFill(widget.levels, widget.since, c, widget.now, manager: widget.manager);
    return GestureDetector(
      key: Key('branch-pin-${c.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onPin(c),
      child: Opacity(
        opacity: locked ? 0.55 : (lvl == 0 ? 0.8 : 1),
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: size - 6,
                      height: size - 6,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white,
                            tint.withValues(alpha: lvl > 0 ? 0.55 : 0.3),
                          ],
                        ),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: tint.withValues(alpha: lvl > 0 ? 0.7 : 0.35),
                            blurRadius: lvl > 0 ? 10 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        locked ? '🔒' : c.emoji,
                        style: const TextStyle(fontSize: 21),
                      ),
                    ),
                    if (lvl > 0)
                      SizedBox(
                        width: size,
                        height: size,
                        child: CircularProgressIndicator(
                          value: fill,
                          strokeWidth: 3.5,
                          color: fill >= 1 ? const Color(0xFFE53935) : tint,
                          backgroundColor: tint.withValues(alpha: 0.18),
                        ),
                      ),
                    if (lvl > 0)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: tint,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.2),
                          ),
                          child: Text(
                            '$lvl',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    if (fill >= 1)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          key: Key('branch-pin-full-${c.id}'),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: lvl > 0
                      ? tint.withValues(alpha: 0.92)
                      : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  widget.nameOf(c.id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: lvl > 0 ? Colors.white : const Color(0xFF5D4037),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Các chi nhánh đã mở theo thứ tự mở khoá (để nối đường).
  List<Offset> _route() => [
    for (final c in branchCities)
      if (branchLevel(widget.levels, c.id) > 0 && branchMapPos[c.id] != null)
        branchMapPos[c.id]!,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    // Ngày/đêm theo giờ máy.
    final t = DateTime.fromMillisecondsSinceEpoch(widget.now);
    final hour = t.hour + t.minute / 60;
    final night = mapNightness(hour), warmth = mapWarmth(hour);
    return LayoutBuilder(
      builder: (context, box) {
        final vw = box.maxWidth,
            vh = box.maxHeight.isFinite ? box.maxHeight : vw;
        // Khởi đầu: phóng sao cho bản đồ phủ kín khung, canh giữa Đông Nam Á (nơi chi nhánh đầu tiên).
        final sc = math.max(vw / _w * 1.7, vh / _h);
        _ctrl ??= TransformationController(
          Matrix4.identity()
            ..translateByDouble(
              (vw / 2 - 760 * sc).clamp(vw - _w * sc, 0.0),
              (vh / 2 - 215 * sc).clamp(vh - _h * sc, 0.0),
              0,
              1,
            )
            ..scaleByDouble(sc, sc, 1, 1),
        );
        final moon = branchCityById('moon')!;
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  key: const Key('branch-map-viewer'),
                  transformationController: _ctrl,
                  constrained: false,
                  minScale: sc,
                  maxScale: sc * 3,
                  boundaryMargin: EdgeInsets.zero,
                  child: SizedBox(
                    width: _w,
                    height: _h,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: BranchesMapPainter(
                              route: _route(),
                              dark: dark,
                              night: night,
                              warmth: warmth,
                              lights: _route(),
                            ),
                          ),
                        ),
                        // Tên châu lục in mờ trên lục địa.
                        if (widget.continentNames.length == 6)
                          for (var i = 0; i < 6; i++)
                            Positioned(
                              left: _contLabelPos[i].dx - 90,
                              top: _contLabelPos[i].dy,
                              width: 180,
                              child: IgnorePointer(
                                child: Text(
                                  widget.continentNames[i].toUpperCase(),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 17,
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.w900,
                                    color: (dark ? _contDark : _contLight)[i].$3
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ),
                        // Trang trí biển (không bấm được).
                        for (final d in const [
                          ('⛵', Offset(250, 250)),
                          ('🐋', Offset(430, 400)),
                          ('🚢', Offset(640, 290)),
                          ('🐙', Offset(120, 380)),
                          ('⛵', Offset(880, 300)),
                          ('🧭', Offset(60, 430)),
                        ])
                          Positioned(
                            left: d.$2.dx,
                            top: d.$2.dy,
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: 0.8,
                                child: Text(
                                  d.$1,
                                  style: const TextStyle(fontSize: 26),
                                ),
                              ),
                            ),
                          ),
                        // Máy bay bay dọc các đường nối (chỉ khi bật hiệu ứng).
                        if (_flight != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: _Planes(
                                key: const Key('branch-planes'),
                                anim: _flight!,
                                route: _route(),
                                count: _planeBudget,
                              ),
                            ),
                          ),
                        for (final c in branchCities)
                          if (branchMapPos[c.id] != null)
                            Positioned(
                              left: branchMapPos[c.id]!.dx - 32,
                              top: branchMapPos[c.id]!.dy - _pin / 2,
                              child: _bursts[c.id] == null
                                  ? _pinWidget(c)
                                  : AnimatedBuilder(
                                      animation: _bursts[c.id]!,
                                      builder: (_, child) => Transform.scale(
                                        scale:
                                            1 +
                                            0.35 *
                                                math.sin(
                                                  _bursts[c.id]!.value *
                                                      math.pi *
                                                      3,
                                                ) *
                                                (1 - _bursts[c.id]!.value),
                                        child: child,
                                      ),
                                      child: _pinWidget(c),
                                    ),
                            ),
                        // Khai trương: vòng sóng + tia lấp lánh + 🎉 bung ra quanh ghim.
                        for (final e in _bursts.entries)
                          if (branchMapPos[e.key] != null)
                            Positioned(
                              left: branchMapPos[e.key]!.dx - 100,
                              top: branchMapPos[e.key]!.dy - 100,
                              width: 200,
                              height: 200,
                              child: IgnorePointer(
                                child: AnimatedBuilder(
                                  key: Key('branch-burst-${e.key}'),
                                  animation: e.value,
                                  builder: (_, _) => CustomPaint(
                                    painter: _BurstPainter(
                                      e.value.value,
                                      Color(branchCityById(e.key)!.color),
                                    ),
                                    child: Center(
                                      child: Transform.translate(
                                        offset: Offset(
                                          0,
                                          -34 - 40 * e.value.value,
                                        ),
                                        child: Opacity(
                                          opacity: (1 - e.value.value).clamp(
                                            0.0,
                                            1.0,
                                          ),
                                          child: const Text(
                                            '🎉',
                                            style: TextStyle(fontSize: 30),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
              // Mặt Trăng: ngoài bản đồ, ghim cố định ở góc trên phải.
              Positioned(top: 6, right: 6, child: _pinWidget(moon, size: 42)),
            ],
          ),
        );
      },
    );
  }
}

/// Độ "đêm" (0 = ban ngày, 1 = ban đêm) theo giờ địa phương [hour] (0..24): tối hẳn 19:30–05:00, chuyển dần 17:30–19:30 và 05:00–07:00.
double mapNightness(double hour) {
  final h = hour % 24;
  if (h >= 19.5 || h < 5) return 1;
  if (h >= 17.5) return (h - 17.5) / 2;
  if (h < 7) return 1 - (h - 5) / 2;
  return 0;
}

/// Sắc cam hoàng hôn/bình minh (0..1): đỉnh giữa hai khoảng chuyển ngày-đêm.
double mapWarmth(double hour) {
  final h = hour % 24;
  if (h >= 17.5 && h < 19.5) return math.sin((h - 17.5) / 2 * math.pi);
  if (h >= 5 && h < 7) return math.sin((h - 5) / 2 * math.pi);
  return 0;
}

/// Điểm điều khiển của cung nối [a]→[b] (nhô lên trên) — dùng chung cho nét vẽ và máy bay.
Offset branchCurveControl(Offset a, Offset b) =>
    Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 - (b - a).distance * 0.2);

/// Điểm và hướng bay tại [t] (0..1) trên cung [a]→[b].
(Offset, double) branchCurveAt(Offset a, Offset b, double t) {
  final c = branchCurveControl(a, b);
  final u = 1 - t;
  final pos = a * (u * u) + c * (2 * u * t) + b * (t * t);
  final d = (c - a) * (2 * u) + (b - c) * (2 * t);
  return (pos, math.atan2(d.dy, d.dx));
}

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

/// Nền bản đồ (biển, lục địa, đường nối, ánh đèn thành phố). Công khai để kiểm thử/chụp ảnh nền.
/// [night] 0..1 trộn bảng màu ngày → đêm (chế độ tối của app = luôn đêm), [warmth] là sắc cam hoàng hôn,
/// [lights] là vị trí các thành phố đã mở (đêm thì sáng đèn).
class BranchesMapPainter extends CustomPainter {
  BranchesMapPainter({
    required this.route,
    required this.dark,
    this.night = 0,
    this.warmth = 0,
    this.lights = const [],
  });
  final List<Offset> route;
  final bool dark;
  final double night;
  final double warmth;
  final List<Offset> lights;

  Path _path(List<(double, double)> poly) {
    final path = Path();
    for (var i = 0; i < poly.length; i++) {
      final p = _proj(poly[i].$1, poly[i].$2);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final k = dark ? 1.0 : night.clamp(0.0, 1.0);
    // Biển: gradient ngày → đêm.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _mix(
              _mix(
                const Color(0xFF9ED8F2),
                dark ? const Color(0xFF1B3550) : const Color(0xFF0E2238),
                k,
              ),
              const Color(0xFF6C5B9E), // trời hoàng hôn: tím ở trên, đào ở dưới
              dark ? 0 : warmth * 0.6,
            ),
            _mix(
              _mix(
                const Color(0xFFD3F0FB),
                dark ? const Color(0xFF142536) : const Color(0xFF0A1826),
                k,
              ),
              const Color(0xFFF0A27C),
              dark ? 0 : warmth * 0.6,
            ),
          ],
        ).createShader(rect),
    );
    // Sao lấp lánh trên biển khi trời tối (lục địa vẽ đè lên sau).
    if (k > 0.5) {
      final star = Paint()
        ..color = Colors.white.withValues(alpha: (k - 0.5) * 1.4);
      final sr = math.Random(11);
      for (var i = 0; i < 60; i++) {
        canvas.drawCircle(
          Offset(sr.nextDouble() * _w, sr.nextDouble() * _h),
          0.8 + sr.nextDouble() * 1.4,
          star,
        );
      }
    }
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.28 - 0.22 * k)
      ..strokeWidth = 1;
    for (var i = 1; i < 12; i++) {
      canvas.drawLine(Offset(_w * i / 12, 0), Offset(_w * i / 12, _h), grid);
    }
    for (var i = 1; i < 6; i++) {
      canvas.drawLine(Offset(0, _h * i / 6), Offset(_w, _h * i / 6), grid);
    }
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.55 - 0.45 * k);
    final rnd = math.Random(7);
    for (var i = 0; i < 70; i++) {
      final o = Offset(rnd.nextDouble() * _w, rnd.nextDouble() * _h);
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy)
          ..quadraticBezierTo(o.dx + 7, o.dy - 6, o.dx + 14, o.dy)
          ..quadraticBezierTo(o.dx + 21, o.dy + 6, o.dx + 28, o.dy),
        wave,
      );
    }
    final lands = [for (final poly in _land) _path(poly)];
    // Quầng nước nông quanh bờ, rồi bóng đổ, rồi lục địa (mỗi châu một tông) và nét bờ.
    final shallow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
      ..color = _mix(
        Colors.white.withValues(alpha: 0.8),
        const Color(0xFF3F7A99).withValues(alpha: 0.35),
        k,
      );
    final shadow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..color = Colors.black.withValues(alpha: 0.14 + 0.21 * k);
    for (final path in lands) {
      canvas.drawPath(path, shallow);
    }
    for (final path in lands) {
      canvas.drawPath(path.shift(const Offset(2, 4)), shadow);
    }
    for (var i = 0; i < lands.length; i++) {
      final (lt, lb, ll) = _contLight[_landContinent[i]];
      final (dt, db, dl) = _contDark[_landContinent[i]];
      canvas.drawPath(
        lands[i],
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_mix(lt, dt, k), _mix(lb, db, k)],
          ).createShader(lands[i].getBounds()),
      );
      canvas.drawPath(
        lands[i],
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeJoin = StrokeJoin.round
          ..color = _mix(ll, dl, k),
      );
    }
    final water = Paint()
      ..color = _mix(const Color(0xFFB4E1F5), const Color(0xFF1E3E58), k);
    final lakeEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = _mix(const Color(0xFF8FB074), const Color(0xFF7FB08C), k);
    for (final lake in _lakes) {
      final path = _path(lake);
      canvas.drawPath(path, water);
      canvas.drawPath(path, lakeEdge);
    }
    // Đường nối các chi nhánh đã mở: vầng sáng + nét đứt, cung cong lên trên.
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
      ..color = const Color(0xFFAB47BC).withValues(alpha: 0.35 + 0.2 * k);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = _mix(const Color(0xFF7E57C2), const Color(0xFFB39DDB), k);
    for (var i = 1; i < route.length; i++) {
      final a = route[i - 1], b = route[i];
      final c = branchCurveControl(a, b);
      final curve = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(c.dx, c.dy, b.dx, b.dy);
      canvas.drawPath(curve, glow);
      for (final m in curve.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 14) {
          canvas.drawPath(m.extractPath(d, math.min(d + 8, m.length)), line);
        }
      }
    }
    // Hoàng hôn/bình minh: phủ nhẹ sắc cam.
    if (warmth > 0 && !dark) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFF8A50).withValues(alpha: 0.12 * warmth),
              const Color(0xFFFFC27A).withValues(alpha: 0.08 * warmth),
            ],
          ).createShader(rect),
      );
    }
    // Đèn thành phố đã mở: đêm sáng rực (vầng vàng + vài chấm đèn), ngày không hiện.
    if (k > 0.15) {
      final a = ((k - 0.15) / 0.85).clamp(0.0, 1.0);
      for (final o in lights) {
        canvas.drawCircle(
          o,
          34,
          Paint()
            ..shader = RadialGradient(
              colors: [
                const Color(0xFFFFE082).withValues(alpha: 0.75 * a),
                const Color(0xFFFFB74D).withValues(alpha: 0.25 * a),
                Colors.transparent,
              ],
            ).createShader(Rect.fromCircle(center: o, radius: 34)),
        );
        final lr = math.Random(o.dx.toInt() * 31 + o.dy.toInt());
        final dot = Paint()
          ..color = const Color(0xFFFFF59D).withValues(alpha: a);
        for (var i = 0; i < 7; i++) {
          final ang = lr.nextDouble() * math.pi * 2,
              rr = 12 + lr.nextDouble() * 20;
          canvas.drawCircle(
            o + Offset(math.cos(ang) * rr, math.sin(ang) * rr),
            1.3 + lr.nextDouble(),
            dot,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(BranchesMapPainter old) =>
      old.dark != dark ||
      (old.night - night).abs() > 0.02 ||
      (old.warmth - warmth).abs() > 0.02 ||
      !_sameList(old.route, route) ||
      !_sameList(old.lights, lights);

  static bool _sameList(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Các máy bay ✈️ bay chậm dọc đường nối (chia đều trên tối đa [count] đoạn), mờ dần ở hai đầu, lặp theo [anim].
class _Planes extends StatelessWidget {
  const _Planes({
    super.key,
    required this.anim,
    required this.route,
    required this.count,
  });
  final Animation<double> anim;
  final List<Offset> route;
  final int count;

  @override
  Widget build(BuildContext context) {
    final segs = route.length - 1;
    if (segs < 1 || count < 1) return const SizedBox.shrink();
    final n = math.min(count, segs);
    return AnimatedBuilder(
      animation: anim,
      builder: (_, _) => Stack(
        children: [
          for (var i = 0; i < n; i++)
            () {
              final seg = (i * segs / n).floor();
              final t = (anim.value + i / n) % 1.0;
              final (pos, ang) = branchCurveAt(route[seg], route[seg + 1], t);
              return Positioned(
                left: pos.dx - 14,
                top: pos.dy - 14,
                child: Opacity(
                  opacity: math.sqrt(math.sin(t * math.pi)).clamp(0.0, 1.0),
                  // ✈️ chỉ hướng Đông-Bắc (−45°) nên xoay thêm +45° để mũi bay theo đường.
                  child: Transform.rotate(
                    angle: ang + math.pi / 4,
                    child: const Text('✈️', style: TextStyle(fontSize: 24)),
                  ),
                ),
              );
            }(),
        ],
      ),
    );
  }
}

/// Khai trương: ba vòng sóng nở dần + 12 tia lấp lánh bay ra, mờ theo [t] (0..1).
class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = 0; i < 3; i++) {
      final tt = ((t - i * 0.14) / 0.7).clamp(0.0, 1.0);
      if (tt <= 0 || tt >= 1) continue;
      canvas.drawCircle(
        c,
        12 + 80 * Curves.easeOut.transform(tt),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * (1 - tt) + 1
          ..color = (i == 1 ? Colors.white : color).withValues(
            alpha: 0.8 * (1 - tt),
          ),
      );
    }
    final spark = Paint()
      ..color = const Color(
        0xFFFFD54F,
      ).withValues(alpha: (1 - t).clamp(0.0, 1.0));
    for (var i = 0; i < 12; i++) {
      final ang = i / 12 * math.pi * 2 + t * 0.6;
      final r = 22 + 70 * Curves.easeOut.transform(t) * (i.isEven ? 1 : 0.7);
      final o = c + Offset(math.cos(ang) * r, math.sin(ang) * r);
      final s = (i.isEven ? 5.0 : 3.5) * (1 - t * 0.5);
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy - s)
          ..lineTo(o.dx + s * 0.35, o.dy - s * 0.35)
          ..lineTo(o.dx + s, o.dy)
          ..lineTo(o.dx + s * 0.35, o.dy + s * 0.35)
          ..lineTo(o.dx, o.dy + s)
          ..lineTo(o.dx - s * 0.35, o.dy + s * 0.35)
          ..lineTo(o.dx - s, o.dy)
          ..lineTo(o.dx - s * 0.35, o.dy - s * 0.35)
          ..close(),
        spark,
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t || old.color != color;
}
