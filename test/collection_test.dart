import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_math_cross/features/collection/game_mode.dart';
import 'package:flutter_math_cross/features/collection/mode_puzzle.dart';
import 'package:flutter_math_cross/features/collection/mode_session.dart';
import 'package:flutter_math_cross/features/puzzle/puzzle.dart';

void main() {
  final factory = ModeLevelFactory();
  for (final mode in GameMode.values.where((m) => m != GameMode.cross)) {
    test(
      '${mode.title}: five distinct, solvable levels with safe input and invalid-answer rejection',
      () {
        final fingerprints = <String>{};
        for (var id = 1; id <= ModeLevelFactory.levelCount; id++) {
          final p = factory.campaign(mode, id);
          final solved = ModeSolver().solve(p);
          expect(solved, isNotNull);
          expect(p.isSolved(solved!), isTrue);
          expect(p.isSolved(p.solution), isTrue);
          expect(p.isSolved({}), isFalse);
          expect(
            p.isSolved({...solved, p.blanks.first: p.inputMaximum + 1}),
            isFalse,
          );
          expect(factory.campaign(mode, id).solution, p.solution);
          expect(p.blanks, isNotEmpty);
          fingerprints.add(
            '${p.solution}|${p.givens}|${p.target}|${p.palette}|${p.expressions.map((e) => e.text).join(',')}',
          );
          final session = ModeSession(p, draft: {999: 1, p.blanks.first: -1});
          expect(session.entries, isEmpty);
          expect(p.isSolved({...solved, 999: 1}), isFalse);
        }
        expect(fingerprints, hasLength(5));
        expect(() => factory.campaign(mode, 6), throwsRangeError);
      },
    );
    test('${mode.title}: endless samples across every difficulty tier', () {
      for (var round = 1; round <= 45; round++) {
        for (final seed in [191, 887]) {
          final p = factory.endless(mode, round, seed);
          final answer = ModeSolver().solve(p);
          expect(answer, isNotNull);
          expect(p.isSolved(answer!), isTrue);
          expect(p.isSolved(p.solution), isTrue);
        }
      }
    });
  }
  test('numeric solver rejects ambiguous and inconsistent clue systems', () {
    ModePuzzle example(List<LinearClue> clues) => ModePuzzle(
      mode: GameMode.sumGrid,
      level: 1,
      tier: 0,
      solution: {0: 2, 1: 3},
      clues: clues,
    );
    expect(
      ModeSolver().solve(
        example([
          const LinearClue({0: 1, 1: 1}, 5),
        ]),
      ),
      isNull,
    );
    expect(
      ModeSolver().solve(
        example([
          const LinearClue({0: 1}, 2),
          const LinearClue({1: 1}, 3),
          const LinearClue({0: 1, 1: 1}, 9),
        ]),
      ),
      isNull,
    );
  });
  test(
    'honeycomb accepts alternate valid routes, rejects repeats and jumps, and restores contiguous drafts',
    () {
      final p = ModePuzzle(
        mode: GameMode.honeycomb,
        level: 1,
        tier: 0,
        solution: {0: 0, 1: 1},
        width: 3,
        numbers: List.filled(9, 2),
        pathLength: 2,
        target: 4,
      );
      expect(p.isSolved({0: 3, 1: 4}), isTrue);
      expect(p.isSolved({0: 0, 1: 8}), isFalse);
      expect(p.isSolved({0: 0, 1: 0}), isFalse);
      final session = ModeSession(p, draft: {0: 0, 1: 8});
      expect(session.entries, {0: 0});
      expect(session.appendHex(8), isNotNull);
      expect(session.entries, {0: 0});
      session.appendHex(1);
      expect(session.solved, isTrue);
      session.appendHex(1);
      expect(session.entries, {0: 0});
      session.undo();
      expect(session.solved, isTrue);
      session.reset();
      expect(session.entries, isEmpty);
    },
  );
  test(
    'operator solver rejects equations with multiple possible operators',
    () {
      const p = ModePuzzle(
        mode: GameMode.operators,
        level: 1,
        tier: 0,
        solution: {0: 0},
        expressions: [Expression(2, 2, Operation.add, 4)],
      );
      expect(ModeSolver().solve(p), isNull);
    },
  );
  test(
    'number editing supports replacement, erase, undo and preserved drafts',
    () {
      final p = factory.campaign(GameMode.pyramid, 1);
      final s = ModeSession(p);
      s.digit(1);
      s.digit(2);
      expect(s.entries[s.selected], 12);
      s.select(s.selected);
      s.digit(3);
      expect(s.entries[s.selected], 3);
      s.erase();
      expect(s.entries, isEmpty);
      s.undo();
      expect(s.entries[s.selected], 3);
      expect(ModeSession(p, draft: s.entries).entries, s.entries);
    },
  );
}
