enum GameMode {
  cross(
    'cross',
    'Math Cross',
    'Make every crossing count.',
    'Fill the empty number tiles so every equation reads correctly across and down.',
    '3 + ? = 7 → enter 4',
  ),
  sumGrid(
    'sum_grid',
    'Sum Grid',
    'Every row has a reason.',
    'Fill the blank squares. Each row must add up to the target on its right, and each column to the target below. Numbers may repeat.',
    'A row with 2, ?, 3 and target 9 needs 4.',
  ),
  pyramid(
    'pyramid',
    'Number Pyramid',
    'Build your way to the top.',
    'Each block is the sum of the two touching blocks directly below it. Use addition going up and subtraction to work back down.',
    'Bottom blocks 3 and 5 make 8 above.',
  ),
  symbols(
    'symbols',
    'Symbol Detective',
    'Crack the shape code.',
    'The same shape always has the same value. Use the clues to find each shape’s number. A number before a shape means multiplication.',
    '2 × ▲ = 10 means ▲ = 5.',
  ),
  balance(
    'balance',
    'Balance Lab',
    'Find a little equilibrium.',
    'Find the weight of each shape so both sides of every scale have equal weight. The same shape has the same weight on every scale.',
    '▲ + 3 balances 8 when ▲ weighs 5.',
  ),
  trails(
    'trails',
    'Number Trails',
    'Follow the next discovery.',
    'Follow the trail from top to bottom. Apply the operation on each arrow to get the next number. Work backward from a clue when useful.',
    '6 → +4 → ? means the next stop is 10.',
  ),
  operators(
    'operators',
    'Operator Quest',
    'A small sign makes a difference.',
    'Choose the missing operation that makes each equation true. Division must produce a whole number; division by zero is never allowed.',
    '6 ? 3 = 2 needs ÷.',
  ),
  honeycomb(
    'honeycomb',
    'Honeycomb Hunt',
    'Find a sweet connection.',
    'Tap neighboring hexagons to make a path of the required length and total. Use each cell once. Any path that meets the rules wins. Tap the last cell again to undo.',
    'A connected path 2 → 4 → 3 totals 9.',
  ),
  mosaic(
    'mosaic',
    'Math Mosaic',
    'Let the numbers paint.',
    'Solve the expression in a tile, then choose the color with that result in the color key. Complete every tile to reveal the picture.',
    'If the gold color is 7, paint 3 + 4 gold.',
  );

  const GameMode(this.id, this.title, this.tagline, this.rules, this.example);
  final String id, title, tagline, rules, example;
  static GameMode? fromId(String id) {
    for (final mode in values) {
      if (mode.id == id) return mode;
    }
    return null;
  }

  bool get usesNumbers =>
      this != operators && this != honeycomb && this != mosaic;
  String chapter(int index) => const [
    'First discoveries',
    'A little practice',
    'New connections',
    'Think it through',
    'A deeper look',
    'Follow the clues',
    'Bring it together',
    'Master your craft',
  ][index.clamp(0, 7)];
}
