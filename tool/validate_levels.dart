import 'dart:io';
import 'package:flutter_math_cross/features/puzzle/puzzle.dart';
import 'package:flutter_math_cross/features/collection/game_mode.dart';
import 'package:flutter_math_cross/features/collection/mode_puzzle.dart';

void main() {
  final watch = Stopwatch()..start();
  var count = 0;
  for (final mode in GameMode.values) {
    for (var id = 1; id <= LevelFactory.campaignCount; id++) {
      if (mode == GameMode.cross) {
        final p = LevelFactory().campaign(id);
        if (PuzzleSolver().solve(p).length != 1 || !p.isSolved(p.solution)) {
          throw StateError('Invalid Math Cross level $id');
        }
      } else {
        final p = ModeLevelFactory().campaign(mode, id);
        final answer = ModeSolver().solve(p);
        if (answer == null || !p.isSolved(answer) || !p.isSolved(p.solution)) {
          throw StateError('Invalid ${mode.title} level $id');
        }
      }
      count++;
    }
  }
  stdout.writeln(
    'Validated $count campaign puzzles across nine modes in ${watch.elapsedMilliseconds} ms.',
  );
}
