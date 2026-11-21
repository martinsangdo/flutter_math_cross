import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/game_store.dart';
import '../collection/collection_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Make yourself at home')),
      body: SafeArea(
        child: Content(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const CrossMark(),
              const SizedBox(height: 24),
              Text(
                'Your quiet corner',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              SurfaceCard(
                padding: 8,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Sound effects'),
                      subtitle: const Text('Soft taps and little celebrations'),
                      value: store.sound,
                      onChanged: store.setSound,
                    ),
                    const Divider(),
                    ListTile(
                      minVerticalPadding: 16,
                      leading: const Icon(Icons.help_outline_rounded),
                      title: const Text('How to play'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => CollectionWelcome(
                            onDone: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SurfaceCard(
                color: Palette.mint,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.offline_bolt_outlined,
                      color: Palette.teal,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      store.persistent
                          ? 'Your progress stays with you'
                          : 'Enjoy this session',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      store.persistent
                          ? 'Puzzles work offline. Progress is saved on this device, with no account needed.'
                          : 'Saving is unavailable right now. Keep this session open to retain your progress.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'MATH CROSS  /  1.0\nMade for curious minds.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
