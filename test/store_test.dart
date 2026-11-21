import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_math_cross/data/game_store.dart';
import 'package:flutter_math_cross/features/collection/game_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('collection welcome does not mark individual mode guides as seen', () {
    final fresh = GameStore.memory(seenTutorial: false);
    fresh.finishTutorial();
    for (final mode in GameMode.values) {
      expect(fresh.guideSeen(mode), isFalse);
    }
    fresh.finishGuide(GameMode.cross);
    expect(fresh.guideSeen(GameMode.cross), isTrue);
    expect(fresh.guideSeen(GameMode.sumGrid), isFalse);
  });
  test(
    'progress, drafts, preferences and endless survive reopening storage',
    () async {
      final dir = await Directory.systemTemp.createTemp('math_cross_test');
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => dir.path);
      SharedPreferences.setMockInitialValues({});
      final store = await GameStore.open();
      expect(store.persistent, isTrue);
      expect(store.unlocked(2), isFalse);
      var notifications = 0;
      store.addListener(() => notifications++);
      store.complete(1, endless: false);
      expect(store.unlocked(2), isTrue);
      expect(notifications, 1);
      store.complete(1, endless: false);
      expect(store.totalStars, 3);
      store.saveDraft('campaign:2', {4: 12});
      store.setSound(false);
      store.finishTutorial();
      store.complete(1, endless: true);
      for (final mode in GameMode.values.where((m) => m != GameMode.cross)) {
        store.completeMode(mode, 1, endless: false);
        store.saveDraft(GameStore.draftKey(mode, 2), {0: mode.index});
        store.completeMode(mode, mode.index + 1, endless: true);
        store.finishGuide(mode);
      }
      await store.flush();
      // Old Math Cross records beyond the currently exposed five levels survive.
      await Hive.box<dynamic>(
        'math_cross_v1',
      ).put('level:7', {'version': 1, 'stars': 3, 'completed': true});
      await Hive.close();
      final reloaded = await GameStore.open();
      expect(reloaded.persistent, isTrue);
      expect(reloaded.stars(1), 3);
      expect(reloaded.nextLevel, 2);
      expect(reloaded.draft('campaign:2'), {4: 12});
      expect(reloaded.endlessRound, 2);
      expect(reloaded.endlessSeed, store.endlessSeed);
      expect(reloaded.sound, isFalse);
      expect(reloaded.seenTutorial, isTrue);
      expect(reloaded.stars(7), 3);
      expect(reloaded.completed, 1);
      for (final mode in GameMode.values.where((m) => m != GameMode.cross)) {
        expect(reloaded.starsFor(mode, 1), 3);
        expect(reloaded.nextFor(mode), 2);
        expect(reloaded.unlockedFor(mode, 2), isTrue);
        expect(reloaded.unlockedFor(mode, 6), isFalse);
        expect(reloaded.draft(GameStore.draftKey(mode, 2)), {0: mode.index});
        expect(reloaded.roundFor(mode), mode.index + 2);
        expect(reloaded.seedFor(mode), store.seedFor(mode));
        expect(reloaded.guideSeen(mode), isTrue);
      }
      await Hive.close();
      await dir.delete(recursive: true);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );
}
