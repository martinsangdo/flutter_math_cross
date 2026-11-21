import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_math_cross/data/game_store.dart';
import 'package:flutter_math_cross/features/collection/collection_screen.dart';
import 'package:flutter_math_cross/features/collection/game_mode.dart';
import 'package:flutter_math_cross/features/collection/mode_board.dart';
import 'package:flutter_math_cross/features/collection/mode_game_screen.dart';
import 'package:flutter_math_cross/features/collection/mode_puzzle.dart';
import 'ui_test.dart' show harness;

Future<void> ready(WidgetTester tester) async {
  for (
    var i = 0;
    i < 60 && find.byKey(const ValueKey('mode-ready')).evaluate().isEmpty;
    i++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  expect(find.byKey(const ValueKey('mode-ready')), findsOneWidget);
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).first;
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    finder,
    150,
    scrollable: scrollable,
    maxScrolls: 60,
  );
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
}

void phone(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  for (final mode in GameMode.values.where((m) => m != GameMode.cross)) {
    testWidgets(
      '${mode.title}: solve through real controls, persist stars, return to correct levels',
      (tester) async {
        phone(tester, const Size(390, 844));
        final store = GameStore.memory()..finishGuide(mode);
        await tester.pumpWidget(harness(ModeHubScreen(mode: mode), store));
        final play = find.text('Play level 1');
        await reveal(tester, play);
        await tester.tap(play);
        await ready(tester);
        final p = ModeLevelFactory().campaign(mode, 1);
        final answer = ModeSolver().solve(p)!;
        if (mode == GameMode.honeycomb) {
          for (var i = 0; i < p.pathLength; i++) {
            final tile = find.byKey(ValueKey('hex-${answer[i]}'));
            await reveal(tester, tile);
            await tester.tap(tile);
            await tester.pump();
          }
        } else {
          for (final cell in p.blanks) {
            final tile = find.byKey(ValueKey('mode-cell-$cell'));
            await reveal(tester, tile);
            await tester.tap(tile);
            await tester.pump();
            if (mode.usesNumbers) {
              for (final digit in answer[cell]!.toString().split('')) {
                final button = find.byKey(ValueKey('mode-digit-$digit'));
                await reveal(tester, button);
                await tester.tap(button);
                await tester.pump();
              }
            } else {
              final button = find.byKey(ValueKey('choice-${answer[cell]}'));
              await reveal(tester, button);
              await tester.tap(button);
              await tester.pump();
            }
          }
        }
        final check = find.text('Check my puzzle');
        await reveal(tester, check);
        await tester.tap(check);
        await tester.pumpAndSettle();
        expect(find.text('Beautifully solved!'), findsOneWidget);
        expect(store.starsFor(mode, 1), 3);
        expect(store.unlockedFor(mode, 2), isTrue);
        for (final other in GameMode.values.where((m) => m != mode)) {
          expect(store.completedFor(other), 0);
          expect(store.unlockedFor(other, 2), isFalse);
        }
        await tester.tap(find.text('Back to levels'));
        await tester.pumpAndSettle();
        expect(find.text(mode.title), findsOneWidget);
        expect(find.text('Play level 2'), findsOneWidget);
      },
    );
  }
  for (final size in [
    const Size(320, 568),
    const Size(812, 375),
    const Size(768, 1024),
  ]) {
    testWidgets(
      'all hardest mode boards fit $size at 2x text and reduced motion',
      (tester) async {
        phone(tester, size);
        for (final mode in GameMode.values.where((m) => m != GameMode.cross)) {
          await tester.pumpWidget(
            harness(
              ModeGameScreen(mode: mode, level: 5),
              GameStore.memory(),
              scale: 2,
            ),
          );
          await ready(tester);
          expect(tester.takeException(), isNull, reason: mode.title);
          for (var page = 0; page < 12; page++) {
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -320),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${mode.title} at scroll $page',
            );
          }
          await tester.pumpWidget(const SizedBox());
        }
      },
    );
  }
  testWidgets(
    'all nine games are selectable with five levels each and first-use guides',
    (tester) async {
      phone(tester, const Size(375, 812));
      final store = GameStore.memory();
      await tester.pumpWidget(harness(const GameSelectionScreen(), store));
      for (final mode in GameMode.values) {
        final item = find.byKey(ValueKey('mode-${mode.id}'));
        await reveal(tester, item);
        await tester.tap(item);
        await tester.pumpAndSettle();
        expect(find.text(mode.title), findsOneWidget);
        expect(find.text('0 of 5 complete · 0 stars'), findsOneWidget);
        expect(find.text('6'), findsNothing);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      final item = find.byKey(const ValueKey('mode-sum_grid'));
      await reveal(tester, item);
      await tester.tap(item);
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Play level 1'));
      await tester.tap(find.text('Play level 1'));
      await tester.pumpAndSettle();
      expect(find.text('How to play Sum Grid'), findsOneWidget);
      await reveal(tester, find.text('Let’s play Sum Grid'));
      await tester.tap(find.text('Let’s play Sum Grid'));
      await ready(tester);
      expect(store.guideSeen(GameMode.sumGrid), isTrue);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Play level 1'));
      await tester.tap(find.text('Play level 1'));
      await ready(tester);
      expect(find.text('How to play Sum Grid'), findsNothing);
    },
  );
  testWidgets('last campaign level offers endless and no sixth level', (
    tester,
  ) async {
    phone(tester, const Size(390, 844));
    final mode = GameMode.operators, store = GameStore.memory();
    final p = ModeLevelFactory().campaign(mode, 5);
    store.saveDraft(GameStore.draftKey(mode, 5), ModeSolver().solve(p)!);
    await tester.pumpWidget(
      harness(ModeGameScreen(mode: mode, level: 5), store),
    );
    await ready(tester);
    await reveal(tester, find.text('Check my puzzle'));
    await tester.tap(find.text('Check my puzzle'));
    await tester.pumpAndSettle();
    expect(find.text('Next puzzle'), findsNothing);
    await tester.tap(find.text('Play endless'));
    await ready(tester);
    expect(find.text('Operator Quest · ∞ 1'), findsOneWidget);
    expect(store.unlockedFor(mode, 6), isFalse);
  });
  testWidgets('web-only dollar shortcut advances without awarding progress', (
    tester,
  ) async {
    final store = GameStore.memory();
    await tester.pumpWidget(
      harness(const ModeGameScreen(mode: GameMode.operators, level: 1), store),
    );
    await ready(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit4, character: r'$');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit4);
    await tester.pumpAndSettle();
    if (kIsWeb) {
      await ready(tester);
      expect(find.text('Operator Quest · 2'), findsOneWidget);
    } else {
      expect(find.text('Operator Quest · 1'), findsOneWidget);
    }
    expect(store.completedFor(GameMode.operators), 0);
  });
  testWidgets('restored answers are visible and reset preserves earned stars', (
    tester,
  ) async {
    phone(tester, const Size(390, 844));
    final mode = GameMode.symbols, store = GameStore.memory();
    final p = ModeLevelFactory().campaign(mode, 1);
    store.completeMode(mode, 1, endless: false);
    store.saveDraft(GameStore.draftKey(mode, 1), {p.blanks.first: 9});
    await tester.pumpWidget(
      harness(ModeGameScreen(mode: mode, level: 1), store),
    );
    await ready(tester);
    expect(
      tester.widget<ModeBoard>(find.byType(ModeBoard)).session.entries.values,
      contains(9),
    );
    await reveal(tester, find.byTooltip('Reset puzzle'));
    await tester.tap(find.byTooltip('Reset puzzle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(store.draft(GameStore.draftKey(mode, 1)), isEmpty);
    expect(store.starsFor(mode, 1), 3);
  });
}
