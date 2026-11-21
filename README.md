# Math Cross · Puzzle Worlds

Nine offline Flutter math games, with **five campaign levels per game (45 total)**,
separate saved progress, and independent endless play. The latest user scope of
five levels overrides the template's original 80-level minimum.

## Games

| Game | What you do |
| --- | --- |
| Math Cross | Fill missing values in intersecting arithmetic equations. |
| Sum Grid | Make every row and column add up to its target. |
| Number Pyramid | Each block equals the sum of the two blocks below. |
| Symbol Detective | Deduce consistent values for shapes from linked clues. |
| Balance Lab | Find shape weights that balance every scale. |
| Number Trails | Complete a chain by applying operations along its arrows. |
| Operator Quest | Choose the missing arithmetic operators. |
| Honeycomb Hunt | Connect distinct neighboring hexagons to reach a required length and total. |
| Math Mosaic | Solve tile expressions and paint their corresponding colors to reveal a picture. |

Each game has its own guide, five-level path, unlocks, stars, unfinished puzzle
save, and endless round. Every mode starts unlocked; progress inside it unlocks
its subsequent levels. No timer, lives, accounts, or penalties for trying again.
All completed puzzles earn three stars.

## Run and verify

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
flutter build web
flutter build apk --debug
flutter build ios --simulator
flutter run --dart-define=PERF_OVERLAY=true
```

Keyboard: numbers enter answers in numeric modes, Backspace/Delete erases,
Enter checks, and Right selects the next editable cell. On web only, `$` previews
the next puzzle without awarding completion. At the fifth campaign level it
returns to the mode's level list. Touch controls support every mode.

## Architecture

| Location | Responsibility |
| --- | --- |
| `lib/main.dart` | Two-second studio splash, boot, collection welcome |
| `lib/core/` | Shared theme, sounds, isolated ad/hint placeholders |
| `lib/data/game_store.dart` | Riverpod reactive state, versioned Hive records, preferences |
| `lib/features/collection/game_mode.dart` | Stable mode IDs, descriptions, rules |
| `lib/features/collection/collection_screen.dart` | Game selection, mode hubs, individual tutorials |
| `lib/features/collection/mode_puzzle.dart` | Eight new generators, rule validation, independent solvers |
| `lib/features/collection/mode_session.dart` | Input, undo/reset, path editing, draft sanitation |
| `lib/features/collection/mode_board.dart` | Eight distinct board layouts and vector graphics |
| `lib/features/collection/mode_game_screen.dart` | Input controls, checking, results, next/endless routing |
| `lib/features/puzzle/` | Existing Math Cross engine and gameplay |
| `lib/features/home/`, `lib/features/settings/` | Home route and preferences |
| `test/` | Content, persistence, interaction, responsive-layout regressions |
| `tool/`, `store/` | Content validator, reproducible store graphics, launcher icon |

Math Cross's original level 1–5 seeds and legacy storage keys are preserved.
Previously completed levels 6–80 remain stored but are hidden from this five-level
release; their stars do not inflate the visible five-level totals.

## Content validation

- Math Cross uses its existing bounded equation solver and unique-solution check.
- Sum Grid, Pyramid, Symbols, Balance, and Trails use linear constraints. A separate
  solver requires full rank, then checks the result with exact integer arithmetic.
- Operator Quest evaluates all four operators and rejects ambiguous questions.
- Mosaic validates every expression against a distinct four-color number key.
- Honeycomb uses adjacency/path search. **Every valid path wins**, not just the
  generator's original path. Repeated cells and non-neighbor jumps are rejected.
- Generation happens on demand. Every board is validated before it reaches play.
  Native generation runs through `compute`; on web it runs on the event loop.

## Verification completed

- 52 tests passed, including all 45 campaign boards, 1,080 sampled endless boards,
  solver rejection cases, restore/edit/reset, per-mode unlock isolation, legacy
  storage compatibility, and full completion through each mode's controls.
- 15 collection UI tests also passed in Chrome, including the `$` shortcut.
- Layout checks include small phone, landscape, and tablet sizes, 2× text and
  reduced motion, including the hardest board of every new mode.
- Android debug APK, web build, and iOS simulator build/run passed.
- Native Sum Grid solve/unlock flow and Flutter debug performance overlay inspected.
  This does not establish production performance on low-end devices.

## Environment and prototype boundaries

Verified with installed **Flutter 3.41.2 stable / Dart 3.11.0**; the machine-wide SDK
was not upgraded. Android minimum API 26, target API 36, Java/Kotlin bytecode 1.8.
iOS deployment target 13.0. Lockfiles are tracked.

Campaign content uses deterministic templates and still needs human difficulty
review. New modes' five levels span introductory to advanced constraints. Existing
Math Cross levels retain their original beginner difficulty to preserve saves.
Endless difficulty increases to a capped tier, then continues with remixed boards.
Mosaic currently has four original small motifs: heart, kite, rocket, and sailboat.

Banner and rewarded-hint integrations remain placeholders. Native banner sizing
uses Google's adaptive API with a temporary 50dp fallback; no ads are requested.
Web hides ads. Only test IDs are configured. Hint dialogs explain each game's rules.
Sound effects are bundled; optional background music is not included. One light
theme is provided. Progress stays on the device/browser with no cloud backup.

Release work: additional levels when requested, human playtesting, physical-device
release profiling, VoiceOver/TalkBack checks, latest-stable SDK revalidation,
production signing, and store submission. Android's generated release build still
uses debug signing and must be configured before distribution.

The supplied XP Group logo is used for splash/icon. Nunito's license is in
`assets/fonts/OFL.txt`; screenshots are not bundled. See `CLAUDE.md` for handoff.
