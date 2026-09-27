/// Bàn chơi dạng "Ghép 3": lưới 8x8 ô trà sữa/trân châu/... Dùng chung cho Đấu
/// Trường (PvP) và Hành trình Ghép 3 (chơi đơn) — widget chỉ nhận [Match3View],
/// không biết gì về trận đấu hay màn chơi.
/// Chạm ô rồi chạm ô kề (hoặc vuốt sang ô kề) để đổi; luật ở
/// `lib/arena/match3_rules.dart`, widget chỉ chọn (ô, hướng) và phát hoạt ảnh.
///
/// Mỗi ô có danh tính riêng (id) để trượt/rơi mượt: các frame từ luật chỉ cho
/// giá trị ô, nên ở đây suy ra chuyển động — đổi chỗ 2 ô, ô bị xoá nổ tung, ô
/// còn lại dồn xuống đáy theo thứ tự cột, ô mới rơi từ trên vào.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../arena/match3_rules.dart';
import '../l10n/app_localizations.dart';

/// Số lần hoạt ảnh phải bỏ suy luận chuyển động và dựng lại ô từ bảng cuối (đáng
/// lẽ luôn 0; test dùng để bắt lệch logic rơi/bù).
@visibleForTesting
int match3DebugFallbacks = 0;

const List<String> match3Icons = ['🧋', '🟤', '🍓', '🥭', '🍵'];

/// Biểu tượng của một ô, kể cả kẹo đặc biệt (chỉ chơi đơn mới có — xem
/// `m3CrossBase`/`m3ColorBase` trong match3_rules.dart).
String match3IconFor(int value) {
  if (value >= m3ColorBase) return '🌈';
  if (value >= m3CrossBase) return '💥';
  return (value >= 0 && value < match3Icons.length) ? match3Icons[value] : '';
}

const List<Color> _tileColors = [
  Color(0xFFFFCC80),
  Color(0xFFBCAAA4),
  Color(0xFFF48FB1),
  Color(0xFFFFF176),
  Color(0xFFA5D6A7),
];

const Duration _swapDur = Duration(milliseconds: 200);
const Duration _popDur = Duration(milliseconds: 170);
const Duration _fallDur = Duration(milliseconds: 220);
const Duration _hintDelay = Duration(seconds: 6);

class _T {
  _T(this.id, this.value, this.row, this.col);
  final int id;
  int value;
  double row;
  double col;
  bool dying = false;
}

class _Popup {
  _Popup(this.id, this.text, this.x, this.y, this.big);
  final int id;
  final String text;
  final double x;
  final double y;
  final bool big;
}

/// Những gì bàn cờ cần biết để vẽ — nguồn nào cũng được (trận PvP hay màn chơi
/// đơn), miễn dựng được đủ 5 thứ này.
class Match3View {
  const Match3View({
    required this.cells,
    this.frames = const [],
    this.moveId = 0,
    this.stuck = false,
    this.finished = false,
  });

  /// Bảng hiện tại (64 ô, loại 0..4).
  final List<int> cells;

  /// Các bảng trung gian của nước vừa đi để phát hoạt ảnh; [moveId] tăng mỗi
  /// nước hợp lệ.
  final List<List<int>> frames;
  final int moveId;

  /// Hết nước đi hợp lệ (chỉ Đấu Trường mới rơi vào — chơi đơn tự xáo bàn).
  final bool stuck;

  /// Hết giờ / hết lượt → khoá bàn.
  final bool finished;
}

class Match3Panel extends StatefulWidget {
  const Match3Panel({super.key, required this.view, required this.onSwap});

  final Match3View view;

  /// Trả true nếu nước hợp lệ và đã được nhận.
  final bool Function(int cell, int dir) onSwap;

  @override
  State<Match3Panel> createState() => _Match3PanelState();
}

class _Match3PanelState extends State<Match3Panel> {
  late List<_T> _tiles = _tilesFrom(widget.view.cells);
  final List<_Popup> _popups = [];
  final List<Timer> _timers = [];
  int _nextId = 0;
  int _nextPopup = 0;
  int? _selected;
  int? _flashA;
  int? _flashB;
  int? _hintCell;
  int? _hintOther;
  bool _animating = false;
  int _playToken = 0;
  Timer? _hintTimer;

  List<_T> _tilesFrom(List<int> cells) {
    final src = cells.isEmpty ? List<int>.filled(m3Cells, 0) : cells;
    return [
      for (var i = 0; i < m3Cells; i++) _T(_nextId++, src[i], (i ~/ m3Size).toDouble(), (i % m3Size).toDouble()),
    ];
  }

  int _valueAt(int cell) {
    final r = (cell ~/ m3Size).toDouble(), c = (cell % m3Size).toDouble();
    for (final t in _tiles) {
      if (t.row == r && t.col == c && !t.dying) return t.value;
    }
    return -1;
  }

  _T? _tileAt(int cell) {
    final r = (cell ~/ m3Size).toDouble(), c = (cell % m3Size).toDouble();
    for (final t in _tiles) {
      if (t.row == r && t.col == c) return t;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _scheduleHint();
  }

  @override
  void didUpdateWidget(Match3Panel old) {
    super.didUpdateWidget(old);
    final v = widget.view;
    if (v.moveId != old.view.moveId && v.frames.isNotEmpty) {
      _play(v.frames);
    } else if (!_animating && v.cells.isNotEmpty) {
      // Dựng lại từ log (vào lại trận / server chối nước) — không có hoạt ảnh.
      var same = true;
      for (var i = 0; i < m3Cells && same; i++) {
        same = _valueAt(i) == v.cells[i];
      }
      if (!same) {
        _tiles = _tilesFrom(v.cells);
        _scheduleHint();
      }
    }
  }

  @override
  void dispose() {
    _playToken++;
    _hintTimer?.cancel();
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  Future<bool> _sleep(Duration d, int token) {
    final c = Completer<bool>();
    late final Timer t;
    t = Timer(d, () {
      _timers.remove(t);
      c.complete(mounted && token == _playToken);
    });
    _timers.add(t);
    return c.future;
  }

  void _scheduleHint() {
    _hintTimer?.cancel();
    if (_hintCell != null) setState(() => _hintCell = _hintOther = null);
    _hintTimer = Timer(_hintDelay, () {
      if (!mounted || _animating || widget.view.stuck || widget.view.finished) return;
      final cells = [for (var i = 0; i < m3Cells; i++) _valueAt(i)];
      if (cells.contains(-1)) return;
      final move = Match3Board.fromCells(cells).findMove();
      if (move == null) return;
      setState(() {
        _hintCell = move.$1;
        _hintOther = Match3Board.neighbor(move.$1, move.$2);
      });
    });
  }

  Future<void> _play(List<List<int>> frames) async {
    final token = ++_playToken;
    _hintTimer?.cancel();
    setState(() {
      _animating = true;
      _selected = null;
      _hintCell = _hintOther = null;
    });

    // Frame 0: hai ô đổi chỗ.
    final f0 = frames.first;
    final changed = [
      for (var i = 0; i < m3Cells; i++)
        if (_valueAt(i) != f0[i]) i,
    ];
    if (changed.length == 2) {
      final a = _tileAt(changed[0]), b = _tileAt(changed[1]);
      if (a != null && b != null) {
        setState(() {
          final r = a.row, c = a.col;
          a.row = b.row;
          a.col = b.col;
          b.row = r;
          b.col = c;
        });
      }
    }
    if (!await _sleep(_swapDur, token)) return;

    // Từng bước dây chuyền: (xoá, rơi + bù).
    for (var i = 1; i + 1 < frames.length; i += 2) {
      final clear = frames[i];
      final fall = frames[i + 1];
      final step = (i + 1) ~/ 2;
      final removed = [
        for (var k = 0; k < m3Cells; k++)
          if (clear[k] == -1) k,
      ];
      setState(() {
        for (final k in removed) {
          _tileAt(k)?.dying = true;
        }
        _addPopups(removed, step);
      });
      HapticFeedback.lightImpact();
      if (!await _sleep(_popDur, token)) return;

      // Rơi: ô còn lại dồn xuống đáy giữ thứ tự cột; ô mới rơi từ trên vào.
      final spawns = <(_T, double)>[];
      setState(() {
        _tiles.removeWhere((t) => t.dying);
        for (var c = 0; c < m3Size; c++) {
          final col = _tiles.where((t) => t.col == c).toList()..sort((a, b) => b.row.compareTo(a.row));
          for (var k = 0; k < col.length; k++) {
            col[k].row = (m3Size - 1 - k).toDouble();
          }
          final empties = m3Size - col.length;
          for (var r = 0; r < empties; r++) {
            final t = _T(_nextId++, fall[r * m3Size + c], (r - empties).toDouble(), c.toDouble());
            _tiles.add(t);
            spawns.add((t, r.toDouble()));
          }
        }
      });
      if (!await _sleep(const Duration(milliseconds: 20), token)) return;
      setState(() {
        for (final (t, r) in spawns) {
          t.row = r;
        }
      });
      if (!await _sleep(_fallDur, token)) return;
    }

    if (!mounted || token != _playToken) return;
    setState(() {
      final target = widget.view.cells;
      var same = target.isNotEmpty;
      for (var i = 0; i < m3Cells && same; i++) {
        same = _valueAt(i) == target[i];
      }
      if (!same && target.isNotEmpty) {
        match3DebugFallbacks++;
        _tiles = _tilesFrom(target);
      }
      _animating = false;
    });
    _scheduleHint();
  }

  void _addPopups(List<int> removed, int step) {
    if (removed.isEmpty) return;
    var sx = 0.0, sy = 0.0;
    for (final k in removed) {
      sx += (k % m3Size) + 0.5;
      sy += (k ~/ m3Size) + 0.5;
    }
    final x = sx / removed.length, y = sy / removed.length;
    final points = removed.length * m3TilePoints * step;
    final popup = _Popup(_nextPopup++, step >= 2 ? '+$points  x$step' : '+$points', x, y, step >= 2);
    _popups.add(popup);
    late final Timer t;
    t = Timer(const Duration(milliseconds: 900), () {
      _timers.remove(t);
      if (mounted) setState(() => _popups.remove(popup));
    });
    _timers.add(t);
  }

  bool get _locked => _animating || widget.view.stuck || widget.view.finished;

  void _flashInvalid(int a, int b) {
    HapticFeedback.mediumImpact();
    setState(() {
      _flashA = a;
      _flashB = b;
      _selected = null;
    });
    late final Timer t;
    t = Timer(const Duration(milliseconds: 300), () {
      _timers.remove(t);
      if (mounted) setState(() => _flashA = _flashB = null);
    });
    _timers.add(t);
  }

  /// Đổi [a] với [b] nếu kề nhau; trả false nếu không kề.
  bool _swapCells(int a, int b) {
    final int cell, dir;
    if (b == a + 1 && a % m3Size != m3Size - 1) {
      cell = a;
      dir = 0;
    } else if (a == b + 1 && b % m3Size != m3Size - 1) {
      cell = b;
      dir = 0;
    } else if (b == a + m3Size) {
      cell = a;
      dir = 1;
    } else if (a == b + m3Size) {
      cell = b;
      dir = 1;
    } else {
      return false;
    }
    if (!widget.onSwap(cell, dir)) _flashInvalid(a, b);
    return true;
  }

  void _onTap(int cell) {
    if (_locked) return;
    final sel = _selected;
    if (_hintCell != null) setState(() => _hintCell = _hintOther = null);
    _scheduleHint();
    if (sel == null) {
      HapticFeedback.selectionClick();
      setState(() => _selected = cell);
      return;
    }
    if (sel == cell) {
      setState(() => _selected = null);
      return;
    }
    if (_swapCells(sel, cell)) {
      setState(() => _selected = null);
    } else {
      HapticFeedback.selectionClick();
      setState(() => _selected = cell);
    }
  }

  void _onSwipe(int cell, Offset delta) {
    if (_locked) return;
    final r = cell ~/ m3Size, c = cell % m3Size;
    int? target;
    if (delta.dx.abs() > delta.dy.abs()) {
      final nc = c + (delta.dx > 0 ? 1 : -1);
      if (nc >= 0 && nc < m3Size) target = r * m3Size + nc;
    } else {
      final nr = r + (delta.dy > 0 ? 1 : -1);
      if (nr >= 0 && nr < m3Size) target = nr * m3Size + c;
    }
    if (target != null) {
      _scheduleHint();
      setState(() => _selected = null);
      _swapCells(cell, target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, box) {
      final screenH = MediaQuery.sizeOf(context).height;
      // Khung bảng = padding 4 + viền 1 mỗi bên = 10px, phải nằm trong bề ngang.
      final cell = [(box.maxWidth - 10) / m3Size, screenH * 0.5 / m3Size, 52.0].reduce((a, b) => a < b ? a : b);
      final side = cell * m3Size;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.view.stuck)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.arenaMatch3Stuck,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.error),
              ),
            ),
          Container(
            key: const Key('arena-match3-board'),
            width: side + 10,
            height: side + 10,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colorScheme.surfaceContainerHighest, colorScheme.surfaceContainer],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (final t in _tiles)
                    AnimatedPositioned(
                      key: ValueKey(t.id),
                      duration: t.row < 0 || t.dying ? Duration.zero : _swapDur,
                      curve: Curves.easeOutCubic,
                      left: t.col * cell,
                      top: t.row * cell,
                      width: cell,
                      height: cell,
                      child: _TileFace(size: cell, value: t.value, dying: t.dying),
                    ),
                  IgnorePointer(
                    child: Stack(
                      children: [
                        for (final p in _popups)
                          Positioned(
                            left: (p.x * cell - 50).clamp(0, side - 100),
                            top: p.y * cell - 14,
                            width: 100,
                            child: _PopupText(key: ValueKey('p${p.id}'), text: p.text, big: p.big),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      for (var r = 0; r < m3Size; r++)
                        Row(
                          children: [
                            for (var c = 0; c < m3Size; c++)
                              _HitCell(
                                key: Key('m3-tile-${r * m3Size + c}'),
                                size: cell,
                                selected: _selected == r * m3Size + c,
                                flashing: _flashA == r * m3Size + c || _flashB == r * m3Size + c,
                                hint: _hintCell == r * m3Size + c || _hintOther == r * m3Size + c,
                                onTap: () => _onTap(r * m3Size + c),
                                onSwipe: (v) => _onSwipe(r * m3Size + c, v),
                              ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _TileFace extends StatelessWidget {
  const _TileFace({required this.size, required this.value, required this.dying});

  final double size;
  final int value;
  final bool dying;

  @override
  Widget build(BuildContext context) {
    // Kẹo đặc biệt giữ màu nền theo LOẠI gốc của nó, chỉ đổi biểu tượng.
    final type = m3BaseType(value);
    final valid = type >= 0 && type < match3Icons.length;
    final base = valid ? _tileColors[type] : Colors.transparent;
    final special = m3IsSpecial(value);
    return AnimatedScale(
      scale: dying ? 1.35 : 1,
      duration: _popDur,
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: dying ? 0 : 1,
        duration: _popDur,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(Colors.white, base, 0.55)!, base],
              ),
              borderRadius: BorderRadius.circular(size * 0.24),
              // Viền sáng cho kẹo đặc biệt: nhìn lướt là thấy ô nào khác thường.
              border: special
                  ? Border.all(color: Colors.white, width: size * 0.07)
                  : null,
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1.5))],
            ),
            child: valid
                ? Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: EdgeInsets.all(size * 0.1),
                        child: Text(match3IconFor(value),
                            style: TextStyle(fontSize: size * 0.58)),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _PopupText extends StatelessWidget {
  const _PopupText({super.key, required this.text, required this.big});

  final String text;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      builder: (context, t, _) => Transform.translate(
        offset: Offset(0, -36 * t),
        child: Opacity(
          opacity: (1 - t * t).clamp(0, 1),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: big ? 22 : 17,
                  fontWeight: FontWeight.w900,
                  color: big ? const Color(0xFFFF6F00) : Colors.white,
                  shadows: const [Shadow(color: Colors.black87, blurRadius: 4), Shadow(color: Colors.black54, offset: Offset(0, 1))],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HitCell extends StatefulWidget {
  const _HitCell({
    super.key,
    required this.size,
    required this.selected,
    required this.flashing,
    required this.hint,
    required this.onTap,
    required this.onSwipe,
  });

  final double size;
  final bool selected;
  final bool flashing;
  final bool hint;
  final VoidCallback onTap;
  final void Function(Offset delta) onSwipe;

  @override
  State<_HitCell> createState() => _HitCellState();
}

class _HitCellState extends State<_HitCell> {
  Offset _drag = Offset.zero;
  bool _fired = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = widget.size, selected = widget.selected, flashing = widget.flashing, hint = widget.hint;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onPanStart: (_) {
        _drag = Offset.zero;
        _fired = false;
      },
      // Đổi ngay khi ngón kéo đủ xa (~30% ô), không đợi thả tay.
      onPanUpdate: (d) {
        if (_fired) return;
        _drag += d.delta;
        if (_drag.distance >= size * 0.3) {
          _fired = true;
          widget.onSwipe(_drag);
        }
      },
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: EdgeInsets.all(selected ? 0.5 : 2),
          decoration: BoxDecoration(
            color: flashing ? scheme.error.withValues(alpha: 0.45) : (hint ? Colors.amber.withValues(alpha: 0.28) : null),
            borderRadius: BorderRadius.circular(size * 0.24),
            border: selected
                ? Border.all(color: scheme.primary, width: 3)
                : (hint ? Border.all(color: Colors.amber, width: 2.5) : null),
            boxShadow: selected ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.55), blurRadius: 8)] : null,
          ),
        ),
      ),
    );
  }
}
