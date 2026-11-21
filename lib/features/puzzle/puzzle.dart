import 'dart:math';

enum Operation {
  add('+'),
  subtract('−'),
  multiply('×'),
  divide('÷');

  const Operation(this.symbol);
  final String symbol;
  int? apply(int a, int b) => switch (this) {
    Operation.add => a + b,
    Operation.subtract => a - b,
    Operation.multiply => a * b,
    Operation.divide => b == 0 || a % b != 0 ? null : a ~/ b,
  };
}

class Equation {
  const Equation(this.a, this.b, this.result, this.operation);
  final int a, b, result;
  final Operation operation;
  List<int> get cells => [a, b, result];
  bool satisfied(Map<int, int> values) =>
      cells.every(values.containsKey) &&
      operation.apply(values[a]!, values[b]!) == values[result];
}

class Puzzle {
  Puzzle({
    required this.id,
    required this.equations,
    required this.solution,
    required this.givens,
    required this.maxValue,
    required this.chapter,
  });
  final int id, maxValue, chapter;
  final List<Equation> equations;
  final Map<int, int> solution, givens;
  List<int> get blanks =>
      solution.keys.where((key) => !givens.containsKey(key)).toList();
  bool isSolved(Map<int, int> entries) {
    final values = {...givens, ...entries};
    return givens.entries.every((e) => values[e.key] == e.value) &&
        values.values.every((v) => v >= 0 && v <= maxValue) &&
        equations.every((e) => e.satisfied(values));
  }

  Map<int, String> get symbols => {
    for (var row = 0; row < 3; row++) ...{
      row * 10 + 1: equations[row].operation.symbol,
      row * 10 + 3: '=',
    },
    5: equations[3].operation.symbol,
    15: '=',
    9: equations[4].operation.symbol,
    19: '=',
  };
}

/// Bounded constraint solver. Stops after two solutions to detect ambiguity.
/// Single-unknown equations are propagated first; branching uses the smallest
/// feasible domain. The node budget rejects pathological generated candidates.
class PuzzleSolver {
  List<Map<int, int>> solve(Puzzle puzzle, {int limit = 2}) {
    final solutions = <Map<int, int>>[];
    var nodes = 0;
    void search(Map<int, int> values) {
      if (++nodes > 20000) throw StateError('Solver budget exceeded');
      if (solutions.length >= limit) return;
      while (true) {
        var changed = false;
        for (final equation in puzzle.equations) {
          final missing = equation.cells
              .where((c) => !values.containsKey(c))
              .toList();
          if (missing.isEmpty) {
            if (!equation.satisfied(values)) return;
          } else if (missing.length == 1) {
            final cell = missing.single;
            final candidates = <int>[];
            for (var n = 0; n <= puzzle.maxValue; n++) {
              if (equation.satisfied({...values, cell: n})) candidates.add(n);
            }
            if (candidates.isEmpty) return;
            if (candidates.length == 1) {
              values[cell] = candidates.single;
              changed = true;
            }
          }
        }
        if (!changed) break;
      }
      final missing = puzzle.solution.keys.where((c) => !values.containsKey(c));
      if (missing.isEmpty) {
        solutions.add(Map.of(values));
        return;
      }
      int? choice;
      List<int>? domain;
      for (final cell in missing) {
        final candidates = <int>[];
        for (var n = 0; n <= puzzle.maxValue; n++) {
          final attempt = {...values, cell: n};
          if (puzzle.equations.every(
            (e) => !e.cells.every(attempt.containsKey) || e.satisfied(attempt),
          )) {
            candidates.add(n);
          }
        }
        if (candidates.isEmpty) return;
        if (domain == null || candidates.length < domain.length) {
          choice = cell;
          domain = candidates;
        }
      }
      for (final n in domain!) {
        search({...values, choice!: n});
        if (solutions.length >= limit) return;
      }
    }

    if (puzzle.givens.entries.any(
      (e) =>
          !puzzle.solution.containsKey(e.key) ||
          e.value < 0 ||
          e.value > puzzle.maxValue,
    )) {
      return [];
    }
    search(Map.of(puzzle.givens));
    return solutions;
  }
}

class LevelFactory {
  static const campaignCount = 5;
  static const chapters = [
    'First steps',
    'Finding balance',
    'A little subtraction',
    'Cross connections',
    'Multiply your thinking',
    'Divide & discover',
    'Mixed together',
    'Master the cross',
  ];
  static const descriptions = [
    'Small sums. Lovely beginnings.',
    'Follow the numbers across and down.',
    'Discover what is missing.',
    'One answer opens another path.',
    'Make room for multiplication.',
    'Every division has a whole-number answer.',
    'Four operations. One satisfying solution.',
    'Take your time. Connect every clue.',
  ];

  Puzzle campaign(int id) {
    if (id < 1 || id > campaignCount) {
      throw RangeError.range(id, 1, campaignCount);
    }
    return _generate(id, (id - 1) ~/ 10, 7400 + id * 101);
  }

  Puzzle endless(int round, int seed) =>
      _generate(round, min(7, (round - 1) ~/ 5), seed + round * 7919);

  Puzzle _generate(int id, int chapter, int seed) {
    final random = Random(seed);
    for (var attempt = 0; attempt < 100; attempt++) {
      final range = chapter < 2
          ? 4
          : chapter < 4
          ? 10
          : 12;
      final ops = chapter < 2
          ? [Operation.add]
          : chapter < 4
          ? [Operation.add, Operation.subtract]
          : chapter == 4
          ? [Operation.multiply]
          : chapter == 5
          ? [Operation.divide]
          : Operation.values;
      (int, int, int, Operation) row() {
        final op = ops[random.nextInt(ops.length)];
        var a = 1 + random.nextInt(range);
        var b = 1 + random.nextInt(range);
        if (op == Operation.subtract && a < b) {
          final t = a;
          a = b;
          b = t;
        }
        if (op == Operation.divide) a *= b;
        return (a, b, op.apply(a, b)!, op);
      }

      final top = row();
      final middle = row();
      final leftOp = chapter >= 3 && top.$1 >= middle.$1 && random.nextBool()
          ? Operation.subtract
          : Operation.add;
      final rightOp = chapter >= 3 && top.$3 >= middle.$3 && random.nextBool()
          ? Operation.subtract
          : Operation.add;
      final bottomLeft = leftOp.apply(top.$1, middle.$1)!;
      final bottomRight = rightOp.apply(top.$3, middle.$3)!;
      final bottomOp = bottomRight >= bottomLeft
          ? Operation.add
          : Operation.subtract;
      final solution = <int, int>{
        0: top.$1,
        2: top.$2,
        4: top.$3,
        10: middle.$1,
        12: middle.$2,
        14: middle.$3,
        20: bottomLeft,
        22: (bottomRight - bottomLeft).abs(),
        24: bottomRight,
      };
      final equations = [
        Equation(0, 2, 4, top.$4),
        Equation(10, 12, 14, middle.$4),
        Equation(20, 22, 24, bottomOp),
        Equation(0, 10, 20, leftOp),
        Equation(4, 14, 24, rightOp),
      ];
      final maxValue = chapter < 2 ? 20 : 300;
      if (solution.values.any((v) => v > maxValue)) continue;
      final givens = Map<int, int>.of(solution);
      Puzzle candidate() => Puzzle(
        id: id,
        chapter: chapter,
        equations: equations,
        solution: Map.unmodifiable(solution),
        givens: Map.unmodifiable(givens),
        maxValue: maxValue,
      );
      final cells = solution.keys.toList()..shuffle(random);
      final target = chapter == 0 && id <= 3 ? 1 : min(5, 2 + chapter ~/ 2);
      for (final cell in cells) {
        final value = givens.remove(cell)!;
        try {
          if (PuzzleSolver().solve(candidate()).length != 1) {
            givens[cell] = value;
          }
        } on StateError {
          givens[cell] = value;
        }
        if (solution.length - givens.length == target) break;
      }
      final result = candidate();
      if (result.blanks.length == target &&
          result.isSolved(solution) &&
          PuzzleSolver().solve(result).length == 1) {
        return result;
      }
    }
    throw StateError('No valid puzzle found for seed $seed');
  }
}
