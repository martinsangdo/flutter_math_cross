import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_math_cross/features/puzzle/puzzle.dart';
import 'package:flutter_math_cross/features/puzzle/game_session.dart';

void main() {
  final factory = LevelFactory();
  test('all five campaign boards have one solution and distinct content', () {
    final signatures = <String>{};
    for (var id = 1; id <= LevelFactory.campaignCount; id++) {
      final puzzle = factory.campaign(id);
      final solutions = PuzzleSolver().solve(puzzle);
      expect(solutions, hasLength(1), reason: 'Level $id');
      expect(puzzle.isSolved(solutions.single), isTrue);
      expect(solutions.single, puzzle.solution);
      expect(puzzle.blanks.length, id <= 3 ? 1 : greaterThanOrEqualTo(2));
      signatures.add('${puzzle.solution}|${puzzle.givens}|${puzzle.symbols}');
      expect(factory.campaign(id).givens, puzzle.givens);
    }
    expect(signatures, hasLength(LevelFactory.campaignCount));
  });
  test(
    'endless generation is deterministic, unique, and safe across 120 rounds',
    () {
      for (var round = 1; round <= 120; round++) {
        for (final seed in [12, 989, 56789]) {
          final puzzle = factory.endless(round, seed);
          expect(PuzzleSolver().solve(puzzle), hasLength(1));
          expect(puzzle.isSolved(puzzle.solution), isTrue);
          expect(factory.endless(round, seed).givens, puzzle.givens);
        }
      }
    },
  );
  test('solver rejects contradictory clues and detects ambiguity', () {
    Puzzle example(Map<int, int> givens) => Puzzle(
      id: 1,
      chapter: 0,
      equations: const [Equation(0, 2, 4, Operation.add)],
      solution: {0: 1, 2: 2, 4: 3},
      givens: givens,
      maxValue: 9,
    );
    expect(PuzzleSolver().solve(example({0: 1, 2: 2, 4: 8})), isEmpty);
    expect(PuzzleSolver().solve(example({4: 3})), hasLength(2));
    expect(PuzzleSolver().solve(example({0: 1, 4: 3})), [
      {0: 1, 2: 2, 4: 3},
    ]);
  });
  test('division rejects fractions and zero divisors', () {
    expect(Operation.divide.apply(4, 0), isNull);
    expect(Operation.divide.apply(7, 2), isNull);
    expect(Operation.divide.apply(12, 3), 4);
  });
  test('editing, replacement, erase, undo, reset and draft sanitation', () {
    final puzzle = factory.campaign(1);
    final game = GameSession(puzzle, draft: {999: 4, puzzle.blanks.first: -1});
    expect(game.entries, isEmpty);
    game.digit(1);
    game.digit(2);
    expect(game.entries[game.selected], 12);
    game.select(game.selected);
    game.digit(3);
    expect(game.entries[game.selected], 3);
    game.erase();
    expect(game.entries, isEmpty);
    game.undo();
    expect(game.entries[game.selected], 3);
    game.reset();
    expect(game.entries, isEmpty);
    game.undo();
    expect(game.entries[game.selected], 3);
    final selected = game.selected;
    game.select(puzzle.givens.keys.first);
    expect(game.selected, selected);
    game.entries
      ..clear()
      ..addAll({
        for (final cell in puzzle.blanks) cell: puzzle.solution[cell]!,
      });
    expect(game.solved, isTrue);
    game.entries[puzzle.givens.keys.first] = 999;
    expect(game.solved, isFalse);
  });
}
