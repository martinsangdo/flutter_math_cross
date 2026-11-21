import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_math_cross/core/sound_service.dart';
import 'package:flutter_math_cross/core/theme.dart';
import 'package:flutter_math_cross/data/game_store.dart';
import 'package:flutter_math_cross/features/home/home_screen.dart';
import 'package:flutter_math_cross/features/collection/collection_screen.dart';
import 'package:flutter_math_cross/features/puzzle/game_screen.dart';
import 'package:flutter_math_cross/features/puzzle/puzzle.dart';
import 'package:flutter_math_cross/features/settings/settings_screen.dart';

class SilentSound extends SoundService {
  @override
  Future<void> preload() async {}
  @override
  Future<void> play(String event, {required bool enabled}) async {}
  @override
  Future<void> dispose() async {}
}

Widget harness(Widget screen, GameStore store, {double scale = 1}) =>
    ProviderScope(
      overrides: [
        storeProvider.overrideWith((ref) => store),
        soundProvider.overrideWithValue(SilentSound()),
      ],
      child: MaterialApp(
        theme: gameTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: screen,
      ),
    );

Future<void> loadGame(WidgetTester tester) async {
  for (
    var i = 0;
    i < 30 &&
        find
            .text('Make every equation true. Take your time.')
            .evaluate()
            .isEmpty;
    i++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();
  }
  expect(
    find.text('Make every equation true. Take your time.'),
    findsOneWidget,
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [
    const Size(375, 812),
    const Size(320, 568),
    const Size(812, 375),
    const Size(768, 1024),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('screens fit $size at text scale $scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final screen in <Widget>[
          const HomeScreen(),
          const LevelSelectScreen(),
          const SettingsScreen(),
          CollectionWelcome(onDone: () {}),
          const GameScreen(level: 1),
        ]) {
          await tester.pumpWidget(
            harness(screen, GameStore.memory(), scale: scale),
          );
          if (screen is GameScreen) await loadGame(tester);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType}',
          );
          for (var page = 0; page < 8; page++) {
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -400),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${screen.runtimeType}, scroll $page',
            );
          }
          await tester.pumpWidget(const SizedBox());
        }
      });
    }
  }
  testWidgets(
    'solve a puzzle, earn stars, unlock next and return to reactive level list',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = GameStore.memory();
      await tester.pumpWidget(harness(const LevelSelectScreen(), store));
      await tester.tap(find.text('1').first);
      await loadGame(tester);
      final puzzle = LevelFactory().campaign(1);
      for (final cell in puzzle.blanks) {
        await tester.ensureVisible(find.byKey(ValueKey('cell-$cell')));
        await tester.tap(find.byKey(ValueKey('cell-$cell')));
        for (final digit in puzzle.solution[cell]!.toString().split('')) {
          final button = find.byKey(ValueKey('digit-$digit'));
          await tester.scrollUntilVisible(
            button,
            160,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(button);
          await tester.pump();
        }
      }
      final check = find.text('Check my puzzle');
      await tester.scrollUntilVisible(
        check,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(find.text('Beautifully solved!'), findsOneWidget);
      expect(store.stars(1), 3);
      expect(store.unlocked(2), isTrue);
      await tester.tap(find.text('Back to puzzles'));
      await tester.pumpAndSettle();
      expect(find.text('The puzzle path'), findsOneWidget);
      final two = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('2'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(two.onPressed, isNotNull);
    },
  );
  testWidgets(
    'incomplete and incorrect boards do not award completion; keyboard edits save draft',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = GameStore.memory();
      await tester.pumpWidget(harness(const GameScreen(level: 1), store));
      await loadGame(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(store.completed, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.digit9, character: '9');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.digit9);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(store.completed, 0);
      expect(store.draft('campaign:1').values, contains(9));
      expect(
        find.text('Not quite yet. Check the equations marked with !.'),
        findsOneWidget,
      );
    },
  );
}
