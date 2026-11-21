import 'package:flutter/material.dart';

abstract final class Palette {
  static const ink = Color(0xFF203D38);
  static const teal = Color(0xFF146B5A);
  static const cream = Color(0xFFF7F6F0);
  static const mint = Color(0xFFE2EFE6);
  static const gold = Color(0xFFF3C96A);
  static const muted = Color(0xFF5B6C65);
  static const line = Color(0xFFD7DFD7);
}

ThemeData gameTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: Palette.cream,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Palette.teal,
    primary: Palette.teal,
    surface: Palette.cream,
    onSurface: Palette.ink,
  ),
  fontFamily: 'Nunito',
  appBarTheme: const AppBarTheme(
    backgroundColor: Palette.cream,
    foregroundColor: Palette.ink,
    centerTitle: false,
    scrolledUnderElevation: 0,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 52),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 36,
      height: 1.15,
      fontWeight: FontWeight.w900,
      color: Palette.ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 1.2,
      fontWeight: FontWeight.w800,
      color: Palette.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: Palette.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: Palette.ink,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: Palette.ink),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: Palette.muted),
  ),
);

class Content extends StatelessWidget {
  const Content({super.key, required this.child, this.width = 600});
  final Widget child;
  final double width;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: child,
    ),
  );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = 24,
  });
  final Widget child;
  final Color color;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Palette.line),
    ),
    child: child,
  );
}

class CrossMark extends StatelessWidget {
  const CrossMark({super.key, this.size = 56});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size,
      child: GridView.count(
        crossAxisCount: 3,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        children: List.generate(
          9,
          (i) => Container(
            decoration: BoxDecoration(
              color: [1, 3, 4, 5, 7].contains(i)
                  ? (i == 4 ? Palette.gold : Palette.teal)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: i == 4
                ? const FittedBox(
                    child: Text('+', style: TextStyle(color: Palette.ink)),
                  )
                : null,
          ),
        ),
      ),
    ),
  );
}
