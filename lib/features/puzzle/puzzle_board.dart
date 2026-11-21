import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'puzzle.dart';

class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({
    super.key,
    required this.puzzle,
    required this.entries,
    this.selected,
    this.onSelect,
    this.checked = false,
  });
  final Puzzle puzzle;
  final Map<int, int> entries;
  final int? selected;
  final ValueChanged<int>? onSelect;
  final bool checked;
  @override
  Widget build(BuildContext context) {
    final symbols = puzzle.symbols;
    final active = puzzle.equations.where((e) => e.cells.contains(selected));
    final related = active.expand((e) => e.cells).toSet();
    final values = {...puzzle.givens, ...entries};
    Widget cell(int index) {
      if (symbols.containsKey(index)) {
        return Center(
          child: Text(
            symbols[index]!,
            textScaler: TextScaler.noScaling,
            style: const TextStyle(
              fontSize: 24,
              color: Palette.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
      if (!puzzle.solution.containsKey(index)) {
        return const SizedBox.shrink();
      }
      final given = puzzle.givens.containsKey(index);
      final value = values[index];
      final chosen = selected == index;
      final incorrect =
          checked &&
          !given &&
          value != null &&
          puzzle.equations.any(
            (e) =>
                e.cells.contains(index) &&
                e.cells.every(values.containsKey) &&
                !e.satisfied(values),
          );
      final color = chosen
          ? Palette.teal
          : given
          ? Palette.mint
          : Colors.white;
      final label =
          'Row ${index ~/ 5 + 1}, column ${index % 5 + 1}, '
          '${value ?? 'empty'}${given ? ', given' : ', editable'}${incorrect ? ', check equation' : ''}';
      final tile = AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: incorrect
                ? const Color(0xFFAD4733)
                : chosen || related.contains(index)
                ? Palette.teal
                : Palette.line,
            width: chosen || incorrect ? 2.5 : 1.2,
          ),
          boxShadow: given
              ? []
              : [
                  BoxShadow(
                    color: Palette.ink.withValues(alpha: 0.06),
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value?.toString() ?? '·',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: chosen ? Colors.white : Palette.ink,
                    ),
                  ),
                ),
              ),
            ),
            if (incorrect)
              Positioned(
                right: 3,
                top: 3,
                child: Icon(
                  Icons.priority_high_rounded,
                  size: 12,
                  color: chosen ? Colors.white : const Color(0xFFAD4733),
                ),
              ),
          ],
        ),
      );
      return Semantics(
        label: label,
        selected: chosen,
        button: !given,
        onTap: given || onSelect == null ? null : () => onSelect!(index),
        child: ExcludeSemantics(
          child: given
              ? tile
              : InkWell(
                  key: ValueKey('cell-$index'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: onSelect == null ? null : () => onSelect!(index),
                  child: tile,
                ),
        ),
      );
    }

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileHeight = ((constraints.maxWidth - 24) / 5).clamp(
            48.0,
            60.0,
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var row = 0; row < 5; row++) ...[
                if (row > 0) const SizedBox(height: 6),
                SizedBox(
                  height: row.isEven ? tileHeight : 28,
                  child: Row(
                    children: [
                      for (var col = 0; col < 5; col++) ...[
                        if (col > 0) const SizedBox(width: 6),
                        Expanded(child: cell(row * 5 + col)),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
