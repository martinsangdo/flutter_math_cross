import 'dart:math';
import '../puzzle/puzzle.dart';
import 'game_mode.dart';

class LinearClue {
  const LinearClue(this.terms, this.total, {this.offset = 0});
  final Map<int, int> terms;
  final int total;
  final int offset;
  bool satisfied(Map<int, int> values) =>
      terms.keys.every(values.containsKey) &&
      terms.entries.fold<int>(
            offset,
            (sum, term) => sum + term.value * values[term.key]!,
          ) ==
          total;
}

class Expression {
  const Expression(this.a, this.b, this.operation, this.target);
  final int a, b, target;
  final Operation operation;
  String get text => '$a ${operation.symbol} $b';
}

/// Mode-specific data, with no Flutter dependency. Numeric modes use independently
/// solvable linear constraints; operator/mosaic modes use arithmetic evaluation;
/// honeycomb uses graph adjacency and a bounded path search.
class ModePuzzle {
  const ModePuzzle({
    required this.mode,
    required this.level,
    required this.tier,
    required this.solution,
    this.givens = const {},
    this.clues = const [],
    this.rows = const [],
    this.rowTotals = const [],
    this.columnTotals = const [],
    this.expressions = const [],
    this.numbers = const [],
    this.palette = const [],
    this.pathLength = 0,
    this.target = 0,
    this.width = 0,
    this.artName = '',
    this.maxValue = 999,
  });
  final GameMode mode;
  final int level, tier, width, pathLength, target, maxValue;
  final String artName;
  final Map<int, int> solution, givens;
  final List<LinearClue> clues;
  final List<List<int>> rows;
  final List<int> rowTotals, columnTotals, numbers, palette;
  final List<Expression> expressions;
  List<int> get blanks =>
      solution.keys.where((id) => !givens.containsKey(id)).toList();
  int get inputMaximum => mode == GameMode.operators || mode == GameMode.mosaic
      ? 3
      : mode == GameMode.honeycomb
      ? numbers.length - 1
      : maxValue;

  bool adjacent(int a, int b) {
    if (a < 0 ||
        b < 0 ||
        a >= numbers.length ||
        b >= numbers.length ||
        a == b) {
      return false;
    }
    final ar = a ~/ width, ac = a % width, br = b ~/ width, bc = b % width;
    if (ar == br) return (ac - bc).abs() == 1;
    if ((ar - br).abs() != 1) return false;
    return ar.isOdd ? bc == ac || bc == ac + 1 : bc == ac || bc == ac - 1;
  }

  bool isSolved(Map<int, int> entries) {
    if (entries.keys.any((id) => !solution.containsKey(id))) return false;
    if (givens.entries.any(
      (e) => entries.containsKey(e.key) && entries[e.key] != e.value,
    )) {
      return false;
    }
    final values = {...givens, ...entries};
    if (!solution.keys.every(values.containsKey)) return false;
    if (values.values.any((n) => n < 0 || n > inputMaximum)) return false;
    switch (mode) {
      case GameMode.honeycomb:
        final path = List.generate(pathLength, (i) => values[i]!);
        return path.toSet().length == pathLength &&
            List.generate(
              pathLength - 1,
              (i) => adjacent(path[i], path[i + 1]),
            ).every((v) => v) &&
            path.fold<int>(0, (sum, cell) => sum + numbers[cell]) == target;
      case GameMode.operators:
        return List.generate(
          expressions.length,
          (i) =>
              Operation.values[values[i]!].apply(
                expressions[i].a,
                expressions[i].b,
              ) ==
              expressions[i].target,
        ).every((v) => v);
      case GameMode.mosaic:
        return List.generate(
          expressions.length,
          (i) =>
              expressions[i].operation.apply(
                expressions[i].a,
                expressions[i].b,
              ) ==
              palette[values[i]!],
        ).every((v) => v);
      default:
        return clues.isNotEmpty && clues.every((c) => c.satisfied(values));
    }
  }
}

class ModeSolver {
  /// Returns an independently calculated solution, not the stored answer.
  /// Numeric boards must have full rank; ambiguous boards are rejected.
  Map<int, int>? solve(ModePuzzle p) {
    if (p.mode == GameMode.honeycomb) return _path(p);
    if (p.mode == GameMode.operators || p.mode == GameMode.mosaic) {
      final answer = <int, int>{};
      for (var i = 0; i < p.expressions.length; i++) {
        final e = p.expressions[i];
        final candidates = <int>[];
        for (var code = 0; code < 4; code++) {
          if (p.mode == GameMode.operators
              ? Operation.values[code].apply(e.a, e.b) == e.target
              : e.operation.apply(e.a, e.b) == p.palette[code]) {
            candidates.add(code);
          }
        }
        if (candidates.length != 1) return null;
        answer[i] = candidates.single;
      }
      return p.isSolved(answer) ? answer : null;
    }
    final keys = p.solution.keys.toList();
    final matrix = <List<double>>[
      for (final c in p.clues)
        [
          for (final key in keys) (c.terms[key] ?? 0).toDouble(),
          (c.total - c.offset).toDouble(),
        ],
      for (final g in p.givens.entries)
        [for (final key in keys) key == g.key ? 1.0 : 0.0, g.value.toDouble()],
    ];
    var pivotRow = 0;
    final pivots = <int>[];
    for (var col = 0; col < keys.length; col++) {
      var best = -1;
      for (var r = pivotRow; r < matrix.length; r++) {
        if (matrix[r][col].abs() > 1e-8 &&
            (best < 0 || matrix[r][col].abs() > matrix[best][col].abs())) {
          best = r;
        }
      }
      if (best < 0) continue;
      final swap = matrix[pivotRow];
      matrix[pivotRow] = matrix[best];
      matrix[best] = swap;
      final divisor = matrix[pivotRow][col];
      for (var c = col; c <= keys.length; c++) {
        matrix[pivotRow][c] /= divisor;
      }
      for (var r = 0; r < matrix.length; r++) {
        if (r == pivotRow) continue;
        final factor = matrix[r][col];
        for (var c = col; c <= keys.length; c++) {
          matrix[r][c] -= factor * matrix[pivotRow][c];
        }
      }
      pivots.add(col);
      pivotRow++;
    }
    if (pivots.length != keys.length) return null;
    final result = <int, int>{};
    for (var r = 0; r < pivots.length; r++) {
      final value = matrix[r].last;
      if ((value - value.round()).abs() > 1e-7) return null;
      result[keys[pivots[r]]] = value.round();
    }
    // Exact integer validation catches inconsistent systems and rounding errors.
    return p.isSolved(result) ? result : null;
  }

  Map<int, int>? _path(ModePuzzle p) {
    var visited = 0;
    List<int>? answer;
    void walk(List<int> path, int sum) {
      if (answer != null || ++visited > 250000 || sum > p.target) return;
      if (path.length == p.pathLength) {
        if (sum == p.target) answer = List.of(path);
        return;
      }
      for (var cell = 0; cell < p.numbers.length; cell++) {
        if (!path.contains(cell) &&
            (path.isEmpty || p.adjacent(path.last, cell))) {
          walk([...path, cell], sum + p.numbers[cell]);
        }
        if (answer != null) return;
      }
    }

    walk([], 0);
    if (answer == null) return null;
    return {for (var i = 0; i < answer!.length; i++) i: answer![i]};
  }
}

class ModeLevelFactory {
  static const levelCount = 5;
  ModePuzzle campaign(GameMode mode, int level) {
    if (level < 1 || level > levelCount) {
      throw RangeError.range(level, 1, levelCount);
    }
    return _generate(
      mode,
      level,
      min(7, (level - 1) * 2),
      123001 + mode.index * 1000003 + level * 7919,
    );
  }

  ModePuzzle endless(GameMode mode, int round, int seed) {
    if (round < 1) throw RangeError.value(round);
    return _generate(
      mode,
      round,
      min(7, (round - 1) ~/ 5),
      seed + mode.index * 1000003 + round * 7919,
    );
  }

  ModePuzzle _generate(GameMode mode, int level, int tier, int seed) {
    if (mode == GameMode.cross) {
      throw ArgumentError('Use the existing Math Cross factory.');
    }
    final random = Random(seed);
    for (var attempt = 0; attempt < 60; attempt++) {
      final p = switch (mode) {
        GameMode.sumGrid => _sumGrid(level, tier, random),
        GameMode.pyramid => _pyramid(level, tier, random),
        GameMode.symbols ||
        GameMode.balance => _symbols(mode, level, tier, random),
        GameMode.trails => _trails(level, tier, random),
        GameMode.operators => _operators(level, tier, random),
        GameMode.honeycomb => _honeycomb(level, tier, random),
        GameMode.mosaic => _mosaic(level, tier, random),
        _ => throw StateError('Unsupported mode'),
      };
      final answer = ModeSolver().solve(p);
      if (answer != null && p.isSolved(answer) && p.isSolved(p.solution)) {
        return p;
      }
    }
    throw StateError('Could not generate validated content');
  }

  Map<int, int> _hide(
    Map<int, int> solution,
    int count,
    Random random,
    ModePuzzle Function(Map<int, int>) build,
  ) {
    final givens = Map<int, int>.of(solution);
    for (final cell in solution.keys.toList()..shuffle(random)) {
      final old = givens.remove(cell)!;
      if (ModeSolver().solve(build(givens)) == null) givens[cell] = old;
      if (solution.length - givens.length >= count) break;
    }
    return Map.unmodifiable(givens);
  }

  int _hidden(int level, int tier, int maxCount) =>
      level <= 3 && tier == 0 ? 1 : min(maxCount, 2 + tier);

  ModePuzzle _sumGrid(int level, int tier, Random r) {
    final n = tier >= 5 ? 4 : 3;
    final rows = List.generate(
      n,
      (row) => List.generate(n, (col) => row * n + col),
    );
    final solution = {
      for (var i = 0; i < n * n; i++) i: 1 + r.nextInt(5 + tier * 4),
    };
    final rt = [
      for (final row in rows) row.fold<int>(0, (s, i) => s + solution[i]!),
    ];
    final ct = [
      for (var c = 0; c < n; c++)
        List.generate(
          n,
          (row) => solution[row * n + c]!,
        ).reduce((a, b) => a + b),
    ];
    final clues = [
      for (var row = 0; row < n; row++)
        LinearClue({for (final cell in rows[row]) cell: 1}, rt[row]),
      for (var col = 0; col < n; col++)
        LinearClue({
          for (var row = 0; row < n; row++) row * n + col: 1,
        }, ct[col]),
    ];
    ModePuzzle build(Map<int, int> givens) => ModePuzzle(
      mode: GameMode.sumGrid,
      level: level,
      tier: tier,
      solution: solution,
      givens: givens,
      clues: clues,
      rows: rows,
      width: n,
      rowTotals: rt,
      columnTotals: ct,
    );
    return build(_hide(solution, _hidden(level, tier, 2 * n - 1), r, build));
  }

  ModePuzzle _pyramid(int level, int tier, Random r) {
    final n = tier < 2
        ? 3
        : tier < 5
        ? 4
        : 5;
    var index = 0;
    final rows = List.generate(
      n,
      (row) => List.generate(row + 1, (_) => index++),
    );
    final solution = <int, int>{
      for (final i in rows.last) i: 1 + r.nextInt(4 + tier * 2),
    };
    final clues = <LinearClue>[];
    for (var row = n - 2; row >= 0; row--) {
      for (var col = 0; col <= row; col++) {
        final cell = rows[row][col],
            left = rows[row + 1][col],
            right = rows[row + 1][col + 1];
        solution[cell] = solution[left]! + solution[right]!;
        clues.add(LinearClue({cell: 1, left: -1, right: -1}, 0));
      }
    }
    ModePuzzle build(Map<int, int> givens) => ModePuzzle(
      mode: GameMode.pyramid,
      level: level,
      tier: tier,
      solution: solution,
      givens: givens,
      clues: clues,
      rows: rows,
      width: n,
    );
    return build(_hide(solution, _hidden(level, tier, index - n), r, build));
  }

  ModePuzzle _symbols(GameMode mode, int level, int tier, Random r) {
    final n = level <= 3 && tier == 0 ? 1 : min(4, 2 + tier ~/ 3);
    final solution = {
      for (var i = 0; i < n; i++) i: 1 + r.nextInt(5 + tier * 3),
    };
    final clues = <LinearClue>[];
    for (var i = 0; i < n; i++) {
      final terms = <int, int>{};
      if (tier >= 5) {
        for (var j = 0; j < n; j++) {
          if (j != i) terms[j] = 1 + r.nextInt(2);
        }
        terms[i] = terms.values.fold<int>(1, (s, v) => s + v);
      } else {
        terms[i] = 1 + r.nextInt(tier < 2 ? 2 : 3);
        if (i > 0) terms[i - 1] = 1;
      }
      final offset = mode == GameMode.balance ? 1 + r.nextInt(4 + tier * 2) : 0;
      final total = terms.entries.fold<int>(
        offset,
        (sum, e) => sum + e.value * solution[e.key]!,
      );
      clues.add(LinearClue(terms, total, offset: offset));
    }
    if (tier > 1) clues.shuffle(r);
    return ModePuzzle(
      mode: mode,
      level: level,
      tier: tier,
      solution: solution,
      clues: clues,
    );
  }

  ModePuzzle _trails(int level, int tier, Random r) {
    final n = min(7, 3 + tier ~/ 2);
    final solution = <int, int>{0: 2 + r.nextInt(8 + tier)};
    final clues = <LinearClue>[];
    final expressions = <Expression>[];
    for (var i = 1; i < n; i++) {
      final before = solution[i - 1]!;
      var op =
          Operation.values[r.nextInt(
            tier < 2
                ? 1
                : tier < 4
                ? 2
                : 4,
          )];
      var operand = 1 + r.nextInt(3 + tier);
      if (op == Operation.subtract && before < operand) op = Operation.add;
      if (op == Operation.multiply && before * operand > 300) {
        op = Operation.add;
      }
      if (op == Operation.divide) {
        final divisors = [
          for (var d = 2; d <= 9; d++)
            if (before % d == 0) d,
        ];
        if (divisors.isEmpty) {
          op = Operation.add;
        } else {
          operand = divisors[r.nextInt(divisors.length)];
        }
      }
      final after = op.apply(before, operand)!;
      solution[i] = after;
      expressions.add(Expression(before, operand, op, after));
      clues.add(switch (op) {
        Operation.add => LinearClue({i: 1, i - 1: -1}, operand),
        Operation.subtract => LinearClue({i: 1, i - 1: -1}, -operand),
        Operation.multiply => LinearClue({i: 1, i - 1: -operand}, 0),
        Operation.divide => LinearClue({i: operand, i - 1: -1}, 0),
      });
    }
    ModePuzzle build(Map<int, int> givens) => ModePuzzle(
      mode: GameMode.trails,
      level: level,
      tier: tier,
      solution: solution,
      givens: givens,
      clues: clues,
      expressions: expressions,
    );
    return build(_hide(solution, _hidden(level, tier, n - 1), r, build));
  }

  ModePuzzle _operators(int level, int tier, Random r) {
    final n = level <= 3 && tier == 0 ? 1 : min(5, 2 + tier ~/ 2);
    final expressions = <Expression>[];
    final solution = <int, int>{};
    while (expressions.length < n) {
      final op = Operation.values[r.nextInt(tier < 2 ? 2 : 4)];
      var a = 2 + r.nextInt(8 + tier * 3), b = 2 + r.nextInt(7 + tier);
      if (op == Operation.divide) a *= b;
      if (op == Operation.subtract && b > a) {
        final tmp = a;
        a = b;
        b = tmp;
      }
      final target = op.apply(a, b)!;
      if (Operation.values.where((o) => o.apply(a, b) == target).length != 1) {
        continue;
      }
      solution[expressions.length] = op.index;
      expressions.add(Expression(a, b, op, target));
    }
    return ModePuzzle(
      mode: GameMode.operators,
      level: level,
      tier: tier,
      solution: solution,
      expressions: expressions,
    );
  }

  ModePuzzle _honeycomb(int level, int tier, Random r) {
    final width = tier < 3 ? 3 : 4, height = tier < 3 ? 3 : 4;
    final numbers = List.generate(
      width * height,
      (_) => 1 + r.nextInt(6 + tier * 2),
    );
    final length = min(6, 2 + tier ~/ 2);
    final skeleton = ModePuzzle(
      mode: GameMode.honeycomb,
      level: level,
      tier: tier,
      solution: const {},
      numbers: numbers,
      width: width,
    );
    var path = <int>[r.nextInt(numbers.length)];
    while (path.length < length) {
      final choices = [
        for (var i = 0; i < numbers.length; i++)
          if (!path.contains(i) && skeleton.adjacent(path.last, i)) i,
      ];
      if (choices.isEmpty) {
        path = [r.nextInt(numbers.length)];
        continue;
      }
      path.add(choices[r.nextInt(choices.length)]);
    }
    return ModePuzzle(
      mode: GameMode.honeycomb,
      level: level,
      tier: tier,
      solution: {for (var i = 0; i < length; i++) i: path[i]},
      numbers: numbers,
      width: width,
      pathLength: length,
      target: path.fold<int>(0, (sum, i) => sum + numbers[i]),
    );
  }

  ModePuzzle _mosaic(int level, int tier, Random r) {
    const pictures = [
      ['0110', '1221', '0110', '0000'],
      ['0100', '1210', '0100', '0300'],
      ['0110', '1221', '1221', '0330'],
      ['0100', '0110', '1111', '0220'],
    ];
    final picture = r.nextInt(pictures.length);
    final base = pictures[picture];
    final palette = [for (var c = 0; c < 4; c++) 2 + c * 8 + r.nextInt(6)];
    final solution = <int, int>{};
    final expressions = <Expression>[];
    for (var i = 0; i < 16; i++) {
      final code = int.parse(base[i ~/ 4][i % 4]);
      solution[i] = code;
      final target = palette[code];
      var op =
          Operation.values[r.nextInt(
            tier < 2
                ? 1
                : tier < 4
                ? 2
                : 4,
          )];
      var a = r.nextInt(target + 1), b = target - a;
      if (op == Operation.subtract) {
        b = 1 + r.nextInt(20);
        a = target + b;
      }
      if (op == Operation.multiply) {
        final divisors = [
          for (var d = 2; d <= 9; d++)
            if (target % d == 0) d,
        ];
        if (divisors.isEmpty) {
          op = Operation.add;
        } else {
          b = divisors[r.nextInt(divisors.length)];
          a = target ~/ b;
        }
      }
      if (op == Operation.divide) {
        b = 2 + r.nextInt(7);
        a = target * b;
      }
      expressions.add(Expression(a, b, op, target));
    }
    final hidden = level <= 3 && tier == 0 ? level : min(16, 3 + tier * 2);
    final indices = List.generate(16, (i) => i)..shuffle(r);
    final givens = {for (final i in indices.skip(hidden)) i: solution[i]!};
    return ModePuzzle(
      mode: GameMode.mosaic,
      level: level,
      tier: tier,
      solution: solution,
      givens: givens,
      width: 4,
      palette: palette,
      expressions: expressions,
      artName: const ['Heart', 'Kite', 'Rocket', 'Sailboat'][picture],
    );
  }
}
