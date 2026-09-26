/// Bàn chơi dạng "Xếp khối" của Đấu Trường: bảng 10x20 + điều khiển (trái /
/// phải / xoay / thả). Luật ở `lib/arena/block_rules.dart`; widget chỉ chọn
/// (hướng xoay, cột) rồi gọi [onDrop].
library;

import 'package:flutter/material.dart';

import '../arena/arena_controller.dart';
import '../arena/block_rules.dart';
import '../l10n/app_localizations.dart';

class ArenaBlockPanel extends StatefulWidget {
  const ArenaBlockPanel({super.key, required this.view, required this.onDrop});

  final ArenaInMatch view;
  final void Function(int rot, int col) onDrop;

  @override
  State<ArenaBlockPanel> createState() => _ArenaBlockPanelState();
}

class _ArenaBlockPanelState extends State<ArenaBlockPanel> {
  int _rot = 0;
  int _col = 3;

  int? get _piece => widget.view.currentPiece;

  int _maxCol(int piece) => BlockBoard.maxCol(piece, _rot);

  @override
  void didUpdateWidget(ArenaBlockPanel old) {
    super.didUpdateWidget(old);
    // Khối mới → về hướng/cột mặc định.
    if (old.view.currentPiece != widget.view.currentPiece) {
      _rot = 0;
      _col = 3;
      final piece = _piece;
      if (piece != null && _col > _maxCol(piece)) _col = _maxCol(piece);
    }
  }

  void _move(int delta) {
    final piece = _piece;
    if (piece == null) return;
    setState(() => _col = (_col + delta).clamp(0, _maxCol(piece)));
  }

  void _rotate() {
    final piece = _piece;
    if (piece == null) return;
    setState(() {
      _rot = (_rot + 1) % 4;
      _col = _col.clamp(0, _maxCol(piece));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final view = widget.view;
    final piece = _piece;
    final board = BlockBoard();
    for (var i = 0; i < blockRows && i < view.boardRows.length; i++) {
      board.rows[i] = view.boardRows[i];
    }
    final top = piece == null
        ? null
        : board.dropTop(piece, _rot, _col.clamp(0, _maxCol(piece)));
    final canAct =
        piece != null && !view.stuck && view.remaining > Duration.zero;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, box) {
        final screenH = MediaQuery.sizeOf(context).height;
        final cell = [
          box.maxWidth * 0.62 / blockCols,
          screenH * 0.42 / blockRows,
          26.0,
        ].reduce((a, b) => a < b ? a : b);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  child: CustomPaint(
                    key: const Key('arena-block-board'),
                    size: Size(cell * blockCols, cell * blockRows),
                    painter: _BoardPainter(
                      rows: board.rows,
                      cell: cell,
                      ghost: top == null || piece == null
                          ? null
                          : (
                              blockOrientations[piece][_rot],
                              _col.clamp(0, _maxCol(piece)),
                              top,
                            ),
                      fill: colorScheme.primary,
                      ghostColor: colorScheme.tertiary.withValues(alpha: 0.55),
                      grid: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: (box.maxWidth - cell * blockCols - 12).clamp(
                      0,
                      140,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.arenaBlocksNext,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      if (view.nextPiece != null)
                        CustomPaint(
                          size: Size(cell * 4, cell * 2),
                          painter: _BoardPainter(
                            rows: const [],
                            cell: cell,
                            ghost: (
                              blockOrientations[view.nextPiece!][0],
                              0,
                              0,
                            ),
                            fill: colorScheme.primary,
                            ghostColor: colorScheme.primary,
                            grid: Colors.transparent,
                            showBoard: false,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (view.stuck)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.arenaBlocksStuck,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: colorScheme.error),
                ),
              ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                IconButton.filledTonal(
                  key: const Key('arena-block-left'),
                  tooltip: l10n.arenaBlocksLeftTip,
                  onPressed: canAct ? () => _move(-1) : null,
                  icon: const Icon(Icons.arrow_left),
                ),
                IconButton.filledTonal(
                  key: const Key('arena-block-rotate'),
                  tooltip: l10n.arenaBlocksRotateTip,
                  onPressed: canAct ? _rotate : null,
                  icon: const Icon(Icons.rotate_right),
                ),
                IconButton.filledTonal(
                  key: const Key('arena-block-right'),
                  tooltip: l10n.arenaBlocksRightTip,
                  onPressed: canAct ? () => _move(1) : null,
                  icon: const Icon(Icons.arrow_right),
                ),
                FilledButton(
                  key: const Key('arena-block-drop'),
                  onPressed: canAct && top != null
                      ? () => widget.onDrop(_rot, _col.clamp(0, _maxCol(piece)))
                      : null,
                  child: Text(l10n.arenaBlocksDropButton),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.rows,
    required this.cell,
    required this.ghost,
    required this.fill,
    required this.ghostColor,
    required this.grid,
    this.showBoard = true,
  });

  final List<int> rows;
  final double cell;

  /// (mặt nạ hàng của khối, cột trái nhất, hàng trên cùng) hoặc null.
  final (List<int>, int, int)? ghost;
  final Color fill;
  final Color ghostColor;
  final Color grid;
  final bool showBoard;

  @override
  void paint(Canvas canvas, Size size) {
    if (showBoard) {
      final gridPaint = Paint()
        ..color = grid
        ..style = PaintingStyle.stroke;
      for (var r = 0; r < blockRows; r++) {
        for (var c = 0; c < blockCols; c++) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell, r * cell, cell, cell),
            gridPaint,
          );
        }
      }
    }
    final fillPaint = Paint()..color = fill;
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < blockCols; c++) {
        if (rows[r] & (1 << c) != 0) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell + 1, r * cell + 1, cell - 2, cell - 2),
            fillPaint,
          );
        }
      }
    }
    final g = ghost;
    if (g != null) {
      final ghostPaint = Paint()..color = ghostColor;
      for (var i = 0; i < g.$1.length; i++) {
        for (var c = 0; c < 4; c++) {
          if (g.$1[i] & (1 << c) != 0) {
            canvas.drawRect(
              Rect.fromLTWH(
                (g.$2 + c) * cell + 1,
                (g.$3 + i) * cell + 1,
                cell - 2,
                cell - 2,
              ),
              ghostPaint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) => true;
}
