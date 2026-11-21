import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'game_mode.dart';
import 'mode_puzzle.dart';
import 'mode_session.dart';

const shapeLabels = ['▲', '●', '■', '◆'];
const shapeNames = ['Triangle', 'Circle', 'Square', 'Diamond'];
const mosaicColors = [
  Color(0xFFE9E9DF),
  Color(0xFF146B5A),
  Color(0xFFF3C96A),
  Color(0xFFA24A36),
];
const mosaicNames = ['Cream', 'Teal', 'Gold', 'Coral'];

IconData modeIcon(GameMode mode) => switch (mode) {
  GameMode.cross => Icons.grid_4x4_rounded,
  GameMode.sumGrid => Icons.calculate_outlined,
  GameMode.pyramid => Icons.change_history_rounded,
  GameMode.symbols => Icons.category_outlined,
  GameMode.balance => Icons.balance_rounded,
  GameMode.trails => Icons.route_outlined,
  GameMode.operators => Icons.add_circle_outline_rounded,
  GameMode.honeycomb => Icons.hive_outlined,
  GameMode.mosaic => Icons.palette_outlined,
};

class ModeBoard extends StatelessWidget {
  const ModeBoard({
    super.key,
    required this.session,
    required this.onSelect,
    required this.onHex,
    this.checked = false,
  });
  final ModeSession session;
  final ValueChanged<int> onSelect, onHex;
  final bool checked;
  ModePuzzle get p => session.puzzle;

  Widget _tile(int id, {String? label}) {
    final given = p.givens.containsKey(id);
    final value = p.givens[id] ?? session.entries[id];
    final selected = session.selected == id && !given;
    final wrong = checked && !given && value != null && value != p.solution[id];
    final text = label ?? value?.toString() ?? '?';
    return Semantics(
      label:
          '${label ?? 'Tile ${id + 1}'}, ${value ?? 'empty'}, ${given ? 'clue' : 'editable'}${wrong ? ', check this answer' : ''}',
      selected: selected,
      button: !given,
      onTap: given ? null : () => onSelect(id),
      child: ExcludeSemantics(
        child: Material(
          color: selected
              ? Palette.teal
              : given
              ? Palette.mint
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: wrong
                  ? const Color(0xFFAC4138)
                  : selected
                  ? Palette.teal
                  : Palette.line,
              width: 2,
            ),
          ),
          child: InkWell(
            key: ValueKey('mode-cell-$id'),
            onTap: given ? null : () => onSelect(id),
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: selected ? Colors.white : Palette.ink,
                        ),
                      ),
                    ),
                  ),
                ),
                if (wrong)
                  const Positioned(
                    right: 3,
                    top: 2,
                    child: Icon(
                      Icons.error_outline,
                      size: 13,
                      color: Color(0xFFAC4138),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _total(int value) => Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '$value',
        style: const TextStyle(
          fontSize: 19,
          color: Palette.teal,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );

  String _terms(LinearClue clue) => [
    for (final entry in clue.terms.entries)
      '${entry.value == 1 ? '' : '${entry.value} × '}${shapeLabels[entry.key]}',
    if (clue.offset != 0) '${clue.offset}',
  ].join(' + ');

  Widget _shapeAnswers() => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      for (final id in p.solution.keys)
        SizedBox(
          width: 100,
          child: Column(
            children: [
              Text(
                '${shapeLabels[id]} ${shapeNames[id]}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              SizedBox(height: 56, child: _tile(id)),
            ],
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: switch (p.mode) {
      GameMode.sumGrid => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Row targets →  ·  Column targets ↓'),
          const SizedBox(height: 12),
          for (var row = 0; row < p.width; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SizedBox(
                height: 54,
                child: Row(
                  children: [
                    for (final id in p.rows[row])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _tile(id),
                        ),
                      ),
                    Expanded(child: _total(p.rowTotals[row])),
                  ],
                ),
              ),
            ),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                for (final total in p.columnTotals)
                  Expanded(child: _total(total)),
                const Expanded(
                  child: Icon(Icons.checklist_rounded, color: Palette.teal),
                ),
              ],
            ),
          ),
        ],
      ),
      GameMode.pyramid => Column(
        children: [
          const Text(
            'Two neighbors below add to the block above.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          for (var row = 0; row < p.rows.length; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FractionallySizedBox(
                widthFactor: p.rows[row].length / p.width,
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      for (final id in p.rows[row])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _tile(id),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      GameMode.symbols => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < p.clues.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SurfaceCard(
                padding: 16,
                color: Palette.mint,
                child: Text(
                  '${_terms(p.clues[i])} = ${p.clues[i].total}',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          _shapeAnswers(),
        ],
      ),
      GameMode.balance => Column(
        children: [
          for (final clue in p.clues)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          _terms(clue),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Text(
                          '${clue.total}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const SizedBox(
                    height: 60,
                    width: double.infinity,
                    child: CustomPaint(painter: _ScalePainter()),
                  ),
                ],
              ),
            ),
          _shapeAnswers(),
        ],
      ),
      GameMode.trails => Column(
        children: [
          for (var i = 0; i < p.solution.length; i++) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    i == 0
                        ? 'START'
                        : i == p.solution.length - 1
                        ? 'FINISH'
                        : 'STOP ${i + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Palette.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: 110, height: 52, child: _tile(i)),
                const SizedBox(width: 60),
              ],
            ),
            if (i < p.expressions.length)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '↓  ${p.expressions[i].operation.symbol} ${p.expressions[i].b}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Palette.teal,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ],
      ),
      GameMode.operators => Column(
        children: [
          for (var i = 0; i < p.expressions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                height: 60,
                child: Row(
                  children: [
                    Expanded(child: _total(p.expressions[i].a)),
                    Expanded(
                      child: _tile(
                        i,
                        label: session.entries[i] == null
                            ? '?'
                            : const ['+', '−', '×', '÷'][session.entries[i]!],
                      ),
                    ),
                    Expanded(child: _total(p.expressions[i].b)),
                    const Text('='),
                    Expanded(child: _total(p.expressions[i].target)),
                  ],
                ),
              ),
            ),
        ],
      ),
      GameMode.honeycomb => _honeycomb(),
      GameMode.mosaic => _mosaic(),
      GameMode.cross => const SizedBox.shrink(),
    },
  );

  Widget _honeycomb() {
    final total = session.entries.values.fold<int>(
      0,
      (sum, cell) => sum + p.numbers[cell],
    );
    return Column(
      children: [
        Text(
          'Connect ${p.pathLength} hexagons · Target ${p.target}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          '${session.entries.length}/${p.pathLength} chosen · Total $total',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final size = math.min(
              68.0,
              (constraints.maxWidth - 16) / (p.width + .5),
            );
            return Column(
              children: [
                for (var row = 0; row < p.numbers.length ~/ p.width; row++)
                  Padding(
                    padding: EdgeInsets.only(
                      left: row.isOdd ? size / 2 : 0,
                      right: row.isEven ? size / 2 : 0,
                      bottom: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var col = 0; col < p.width; col++)
                          _hex(row * p.width + col, size),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          session.entries.isEmpty
              ? 'Choose any hexagon to start.'
              : List.generate(
                  session.entries.length,
                  (i) => '${p.numbers[session.entries[i]!]}',
                ).join(' → '),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _hex(int cell, double size) {
    final position = session.entries.values.toList().indexOf(cell);
    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Semantics(
          label:
              'Hexagon ${cell + 1}, value ${p.numbers[cell]}${position >= 0 ? ', path step ${position + 1}' : ''}',
          selected: position >= 0,
          button: true,
          onTap: () => onHex(cell),
          child: ExcludeSemantics(
            child: Material(
              color: position >= 0 ? Palette.teal : Palette.mint,
              shape: const _HexBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: ValueKey('hex-$cell'),
                onTap: () => onHex(cell),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${p.numbers[cell]}',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: position >= 0 ? Colors.white : Palette.ink,
                        ),
                      ),
                      if (position >= 0)
                        Text(
                          '${position + 1}',
                          textScaler: TextScaler.noScaling,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mosaic() => Column(
    children: [
      const Text('Solve a tile, then choose its color below.'),
      const SizedBox(height: 16),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: p.expressions.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: p.width,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (context, id) {
          final code = p.givens[id] ?? session.entries[id];
          final given = p.givens.containsKey(id),
              selected = session.selected == id && !p.givens.containsKey(id);
          final wrong = checked && code != null && code != p.solution[id];
          return Semantics(
            label:
                'Tile ${id + 1}, ${p.expressions[id].text}, ${code == null ? 'unpainted' : mosaicNames[code]}${given ? ', clue' : ''}${wrong ? ', check color' : ''}',
            button: !given,
            selected: selected,
            onTap: given ? null : () => onSelect(id),
            child: ExcludeSemantics(
              child: Material(
                color: code == null ? Colors.white : mosaicColors[code],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(
                    color: wrong
                        ? const Color(0xFFAC4138)
                        : selected
                        ? Palette.ink
                        : Palette.line,
                    width: selected || wrong ? 3 : 1,
                  ),
                ),
                child: InkWell(
                  key: ValueKey('mode-cell-$id'),
                  onTap: given ? null : () => onSelect(id),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          given ? '' : p.expressions[id].text,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: code == 1 || code == 3
                                ? Colors.white
                                : Palette.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 16),
      Text(
        '${p.expressions[session.selected].text} = ?',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _ScalePainter extends CustomPainter {
  const _ScalePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.teal
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    canvas.drawLine(Offset(w * .12, 12), Offset(w * .88, 12), paint);
    canvas.drawLine(Offset(w * .5, 6), Offset(w * .5, 52), paint);
    canvas.drawLine(Offset(w * .38, 54), Offset(w * .62, 54), paint);
    for (final x in [.24, .76]) {
      canvas.drawLine(Offset(w * x, 12), Offset(w * x, 27), paint);
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * x, 25), width: w * .3, height: 20),
        0,
        math.pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ScalePainter oldDelegate) => false;
}

class _HexBorder extends ShapeBorder {
  const _HexBorder();
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..moveTo(rect.center.dx, rect.top)
    ..lineTo(rect.right, rect.top + rect.height * .25)
    ..lineTo(rect.right, rect.top + rect.height * .75)
    ..lineTo(rect.center.dx, rect.bottom)
    ..lineTo(rect.left, rect.top + rect.height * .75)
    ..lineTo(rect.left, rect.top + rect.height * .25)
    ..close();
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect);
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
  @override
  ShapeBorder scale(double t) => this;
}
