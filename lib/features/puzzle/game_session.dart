import 'puzzle.dart';

class GameSession {
  GameSession(this.puzzle, {Map<int, int> draft = const {}}) {
    for (final entry in draft.entries) {
      if (puzzle.blanks.contains(entry.key) &&
          entry.value >= 0 &&
          entry.value <= puzzle.maxValue) {
        entries[entry.key] = entry.value;
      }
    }
    selected = puzzle.blanks.first;
  }
  final Puzzle puzzle;
  final Map<int, int> entries = {};
  final List<Map<int, int>> _history = [];
  late int selected;
  bool replaceOnInput = true;
  bool get canUndo => _history.isNotEmpty;
  bool get solved => puzzle.isSolved(entries);
  void select(int cell) {
    if (!puzzle.blanks.contains(cell)) return;
    selected = cell;
    replaceOnInput = true;
  }

  void digit(int digit) {
    if (digit < 0 || digit > 9) return;
    final old = replaceOnInput ? '' : (entries[selected]?.toString() ?? '');
    final value = int.parse('$old$digit');
    if (value > puzzle.maxValue) return;
    _history.add(Map.of(entries));
    entries[selected] = value;
    replaceOnInput = false;
  }

  void erase() {
    if (!entries.containsKey(selected)) return;
    _history.add(Map.of(entries));
    entries.remove(selected);
    replaceOnInput = true;
  }

  void undo() {
    if (_history.isEmpty) return;
    entries
      ..clear()
      ..addAll(_history.removeLast());
    replaceOnInput = true;
  }

  void reset() {
    _history.add(Map.of(entries));
    entries.clear();
    replaceOnInput = true;
  }

  void next() {
    final blanks = puzzle.blanks;
    select(blanks[(blanks.indexOf(selected) + 1) % blanks.length]);
  }
}
