import 'game_mode.dart';
import 'mode_puzzle.dart';

class ModeSession {
  ModeSession(this.puzzle, {Map<int, int> draft = const {}}) {
    for (final entry in draft.entries) {
      if (puzzle.blanks.contains(entry.key) &&
          entry.value >= 0 &&
          entry.value <= puzzle.inputMaximum) {
        entries[entry.key] = entry.value;
      }
    }
    if (puzzle.mode == GameMode.honeycomb) {
      final clean = <int, int>{};
      for (var i = 0; i < puzzle.pathLength; i++) {
        final value = entries[i];
        if (value == null ||
            clean.containsValue(value) ||
            (i > 0 && !puzzle.adjacent(clean[i - 1]!, value))) {
          break;
        }
        clean[i] = value;
      }
      entries
        ..clear()
        ..addAll(clean);
    }
    selected = puzzle.blanks.first;
  }
  final ModePuzzle puzzle;
  final Map<int, int> entries = {};
  final List<Map<int, int>> _history = [];
  late int selected;
  bool _replace = true;
  bool get canUndo => _history.isNotEmpty;
  bool get solved => puzzle.isSolved(entries);
  void select(int id) {
    if (puzzle.blanks.contains(id)) {
      selected = id;
      _replace = true;
    }
  }

  void next() {
    final blanks = puzzle.blanks;
    select(blanks[(blanks.indexOf(selected) + 1) % blanks.length]);
  }

  void put(int value) {
    if (value < 0 || value > puzzle.inputMaximum) return;
    _history.add(Map.of(entries));
    entries[selected] = value;
  }

  void digit(int n) {
    if (!puzzle.mode.usesNumbers || n < 0 || n > 9) return;
    final value = _replace ? n : (entries[selected] ?? 0) * 10 + n;
    if (value > puzzle.inputMaximum) return;
    put(value);
    _replace = false;
  }

  String? appendHex(int cell) {
    if (puzzle.mode != GameMode.honeycomb ||
        cell < 0 ||
        cell >= puzzle.numbers.length) {
      return null;
    }
    if (entries.isNotEmpty && entries[entries.length - 1] == cell) {
      erase();
      return null;
    }
    if (entries.containsValue(cell)) {
      return 'Each hexagon can be used once. Tap the last one to step back.';
    }
    if (entries.length >= puzzle.pathLength) {
      return 'Your path is full. Check it, or undo a step.';
    }
    if (entries.isNotEmpty &&
        !puzzle.adjacent(entries[entries.length - 1]!, cell)) {
      return 'Choose a neighboring hexagon to continue the path.';
    }
    _history.add(Map.of(entries));
    entries[entries.length] = cell;
    return null;
  }

  void erase() {
    final id = puzzle.mode == GameMode.honeycomb
        ? entries.length - 1
        : selected;
    if (!entries.containsKey(id)) return;
    _history.add(Map.of(entries));
    entries.remove(id);
    _replace = true;
  }

  void undo() {
    if (_history.isEmpty) return;
    entries
      ..clear()
      ..addAll(_history.removeLast());
    _replace = true;
  }

  void reset() {
    _history.add(Map.of(entries));
    entries.clear();
    _replace = true;
  }
}
