// Run: flutter test tool/render_store_assets_test.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_math_cross/core/theme.dart';
import 'package:flutter_math_cross/features/collection/game_mode.dart';
import 'package:flutter_math_cross/features/collection/mode_board.dart';

void main() {
  testWidgets('render original Play Store feature graphic', (tester) async {
    tester.view.physicalSize = const Size(1024, 500);
    tester.view.devicePixelRatio = 1;
    final loader = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
    await tester.runAsync(() => loader.load());
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await tester.runAsync(() => icons.load());
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: gameTheme(),
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: key,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(48),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            CrossMark(size: 48),
                            SizedBox(width: 16),
                            Text(
                              'MATH CROSS',
                              style: TextStyle(
                                fontSize: 20,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'Small puzzles.\nBright moments.',
                          style: TextStyle(
                            fontSize: 50,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                            color: Palette.ink,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '9 games. 45 levels. Endless discovery.',
                          style: TextStyle(fontSize: 19, color: Palette.muted),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Palette.teal,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'OFFLINE  ·  UNTIMED  ·  MADE FOR CURIOUS MINDS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  SizedBox(
                    width: 340,
                    child: SurfaceCard(
                      padding: 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'FIND YOUR KIND OF PUZZLE',
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 1,
                              color: Palette.teal,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 20),
                          GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            mainAxisExtent: 88,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              for (final mode in GameMode.values)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Palette.mint,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        modeIcon(mode),
                                        color: Palette.teal,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        mode.title,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Nine worlds. One curious mind.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'store/feature_graphic_1024x500.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
