import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'data/game_store.dart';
import 'features/home/home_screen.dart';
import 'features/collection/collection_screen.dart';
import 'features/puzzle/game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Bootstrap());
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  GameStore? _store;
  bool _splashDone = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    unawaited(
      GameStore.open().then((store) {
        if (mounted) setState(() => _store = store);
      }),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _timer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _splashDone = true);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: gameTheme(),
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Image.asset(
              'assets/images/studio_logo.png',
              width: 240,
              semanticLabel: 'XP Group Game Studio',
            ),
          ),
        ),
      );
    }
    if (_store == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: gameTheme(),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return ProviderScope(
      overrides: [storeProvider.overrideWith((ref) => _store!)],
      child: const MathCrossApp(),
    );
  }
}

class MathCrossApp extends ConsumerWidget {
  const MathCrossApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(soundProvider);
    final seenTutorial = ref.watch(storeProvider.select((s) => s.seenTutorial));
    return MaterialApp(
      title: 'Math Cross',
      debugShowCheckedModeBanner: false,
      theme: gameTheme(),
      showPerformanceOverlay: const bool.fromEnvironment('PERF_OVERLAY'),
      home: seenTutorial
          ? const HomeScreen()
          : CollectionWelcome(
              onDone: () => ref.read(storeProvider).finishTutorial(),
            ),
    );
  }
}
