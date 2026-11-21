# Puzzle Worlds — engineering handoff

## Current scope

All nine originally proposed modes are implemented. The user's latest instruction
is **five campaign levels per mode**, 45 total, with more levels to be added later.
This overrides the template's 80-level minimum. Each mode has independent stars,
unlocks, unfinished board, tutorial flag, and endless continuation. Keep gameplay
untimed, offline, and forgiving. Discuss accounts, backend, production advertising,
or other significant scope changes before implementing them.

The local `flutter-game-prompt-template.md` and screenshot references are ignored
by the original `.gitignore`. Platform setup still follows that template: API 26
minimum / 36 target, Java 1.8, iOS 13+, `com.xufagroup.` IDs, INTERNET permission,
two-second studio splash, shared sound settings, ad placeholders, and store assets.
Verified SDK is Flutter 3.41.2 stable/Dart 3.11.0, not a machine-wide SDK upgrade.

## Code map

- `lib/main.dart`: boot, splash, collection welcome, provider scope.
- `lib/core/`: palette/layout primitives, preloaded sounds, ad/hint components.
- `lib/features/collection/game_mode.dart`: stable IDs and mode rules.
- `collection_screen.dart`: selector, per-mode hub, guide, collection welcome.
- `mode_puzzle.dart`: eight new generators and independently calculated solutions.
- `mode_session.dart`: answer state, replacement input, undo/reset, hex paths.
- `mode_board.dart`: grids, pyramid, symbolic clues, scales, trails, operator rows,
  selectable hexagons, and mosaic canvas. Vector artwork is drawn locally.
- `mode_game_screen.dart`: asynchronous loading, input, validation/results, routing.
- `lib/features/puzzle/`: original Math Cross generator/solver/session/board/screen.
- `lib/data/game_store.dart`: Riverpod ChangeNotifier and local persistence.
- `test/`: rules, invalid inputs, storage round-trip, UI flows and responsive layouts.
- `tool/`: all-mode validator and reproducible Flutter store-art renderer.

The collection dispatches Math Cross to its existing engine. New modes share
session/control infrastructure but have their own rules and board layouts.
Avoid adding a separate app or duplicating persistence per game.

## Definition and validation

`LevelFactory.campaignCount` and `ModeLevelFactory.levelCount` are currently 5.
Math Cross seeds 1–5 are unchanged. New mode seeds depend on stable mode index,
level and a fixed salt. Their five campaign tiers are 0, 2, 4, 6, 7. Endless tiers
rise every five rounds, cap at 7, then continue remixing. Do not reorder the enum,
change existing seeds, or reinterpret saved level IDs without a content migration.

Math Cross: nine numeric cells in a 5×5 logical grid, three horizontal and two
vertical binary-operation equations. The existing bounded solver requires uniqueness.

New numeric modes use `LinearClue(terms, total, offset)`, representing a weighted
sum plus an optional offset. Sum Grid imposes row/column targets; Pyramid imposes
parent = left + right; Symbol/Balance use linked weighted shape clues; Trails
encode fixed-operation transitions. `ModeSolver` performs Gaussian elimination,
requires full rank, rounds only near-integral results, then checks every original
constraint with exact integer arithmetic. Inconsistent/ambiguous content is rejected.

Operator Quest enumerates four operations and requires one matching answer per
question. Mosaic evaluates expressions against four distinct numeric color keys.
Honeycomb uses odd-row-offset adjacency and bounded simple-path search. It accepts
all player paths meeting length, adjacency, no-repeat, and sum rules; it never
compares the player's route to only the stored witness. Generator and solver are
separate, and each generated board is checked before display. Native loading uses
`compute`; web generation runs on its event loop, so keep it bounded and small.

## Persistence and compatibility

Continue using Hive box `math_cross_v1`; do not clear it on upgrade.
Existing Math Cross records remain untouched:

- `level:<id>` → `{version: 1, completed: true, stars: 3}`.
- `draft:<campaign|endless>:<id>` → `{version: 1, entries: {cell: value}}`.
- `meta` → `{version: 1, round, seed}`.

New modes:

- `collection:<modeId>` → `{version: 1, stars: {level: stars}, round, seed}`.
- `draft:<modeId>:<campaign|endless>:<id>` → `{version: 1, entries: {cell: value}}`.
- Use `GameStore.draftKey`, `completeMode`, `nextFor`, `unlockedFor`, `roundFor`,
  `seedFor`, `starsFor`, and `completedFor`; don't hand-build divergent save keys.

Old Math Cross progress past level 5 remains stored, but visible totals and unlocks
are capped to the current five levels. New modes never reuse Math Cross's keys.
Writes are serialized and wins are idempotent. Session constructors sanitize drafts.
Hex paths restore only a contiguous, adjacent, non-repeating prefix.

Preferences: `sound`, `tutorial`, `collection_intro`, and `guide_<modeId>` booleans.
Legacy `tutorial=true` without `collection_intro=true` counts as the old Math Cross
intro already seen. Completing the new collection welcome does not mark individual
guides complete. Guides show automatically on first mode play and reopen from the
mode hub's help button. Shared preferences and existing audio apply to all modes.

## UX and integrations

The selector exposes all nine games immediately. Each hub shows exactly five
campaign entries and a separate endless button. Three stars are awarded on any
valid completion with no time/attempt penalty. Back navigation refreshes progress
reactively. The final level offers endless play rather than a nonexistent sixth
level (Math Cross returns to its hub, where endless is available).

Keyboard controls: numeric entry, erase, Enter to check, Right to select next.
Web-only `$` previews next level without earning stars; at the campaign end it
returns to the hub. All controls are also available through touch.

Banner sizing is isolated in `BannerPlaceholder`: Google's adaptive-size API only,
50dp temporary fallback, no ad initialization/request, no banner on web. All IDs
are Google's test IDs. `HintButton` accepts mode-specific advice, with rewarded
hints still a placeholder. Future real ads require approved product/privacy scope,
consent handling, production IDs, correct disposal, and test IDs in debug builds.
No background music or cloud account system is included.

## Commands

```sh
flutter pub get
flutter run
flutter run -d chrome
flutter analyze
flutter test
flutter test --platform chrome test/collection_ui_test.dart
dart run tool/validate_levels.dart
flutter test tool/render_store_assets_test.dart
dart run flutter_launcher_icons
flutter build apk --debug
flutter build ios --simulator
flutter build web
flutter run --dart-define=PERF_OVERLAY=true
```

Store renderer uses `tester.runAsync` for fonts and image export. Track pubspec.lock
and ios/Podfile.lock. Do not commit build products, reference worksheets, signing
keys, or machine-local paths.

## Adding levels later

Raise both campaign limits intentionally and update visible copy/tests/store assets.
Preserve existing mode IDs, seed mappings and level meanings. Do not simply stretch
the five-level tier formula: define new appended tiers/content so levels 1–5 remain
unchanged. Existing Math Cross archived levels need a compatibility check before
re-exposure. Run the all-mode validator and independent progress tests after any
content/storage change. Test both campaign-end and endless transitions.

## Validation and limitations

52 automated tests and 15 Chrome interaction tests pass. Content tests cover all
45 campaign boards plus 1,080 sampled endless boards, ambiguity/inconsistency,
editing, persistence, legacy retention, separate progression, and solve/unlock UI.
Hardest boards are tested at small phone, landscape and tablet sizes with 2× text
and reduced motion. Android/web builds and iOS simulator run pass. Debug simulator
performance overlay inspection is not proof of low-end production frame rates.

Remaining release work: human difficulty review, physical-device release profiling,
VoiceOver/TalkBack checks, latest-stable SDK revalidation, release signing, production
integrations if requested, and store submission. More campaign levels are deferred
at the user's request, not part of the current implementation.
