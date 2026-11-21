import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/puzzle/puzzle.dart';
import '../features/collection/game_mode.dart';

final storeProvider = ChangeNotifierProvider<GameStore>(
  (ref) => throw UnimplementedError(),
);

/// v1 schema: `level:id` → {version, stars, completed};
/// `draft:mode:id` → {version, entries}; meta → {version, round, seed}.
class GameStore extends ChangeNotifier {
  GameStore._(this._prefs, this._box);
  GameStore.memory({this.seenTutorial = true}) : _prefs = null, _box = null;
  final SharedPreferences? _prefs;
  final Box<dynamic>? _box;
  final Map<int, int> _stars = {};
  final Map<String, Map<int, int>> _drafts = {};
  final Map<GameMode, Map<int, int>> _modeStars = {};
  final Map<GameMode, int> _rounds = {}, _seeds = {};
  final Set<GameMode> _guides = {};
  Future<void> _pending = Future.value();
  bool sound = true, seenTutorial = false, persistent = true;
  bool _collectionIntro = false;
  int endlessRound = 1, endlessSeed = 12345;
  int get completed =>
      _stars.keys.where((id) => id <= LevelFactory.campaignCount).length;
  int get totalStars => _stars.entries
      .where((e) => e.key <= LevelFactory.campaignCount)
      .fold(0, (sum, e) => sum + e.value);
  int get nextLevel {
    for (var i = 1; i <= LevelFactory.campaignCount; i++) {
      if (!_stars.containsKey(i)) return i;
    }
    return LevelFactory.campaignCount;
  }

  bool unlocked(int id) =>
      id == 1 || _stars.containsKey(id - 1) || _stars.containsKey(id);
  int stars(int id) => _stars[id] ?? 0;
  Map<int, int> draft(String key) => Map.of(_drafts[key] ?? {});

  int completedFor(GameMode mode) => mode == GameMode.cross
      ? completed
      : (_modeStars[mode] ?? {}).keys
            .where((id) => id <= LevelFactory.campaignCount)
            .length;
  int starsFor(GameMode mode, int id) =>
      mode == GameMode.cross ? stars(id) : _modeStars[mode]?[id] ?? 0;
  int nextFor(GameMode mode) {
    for (var id = 1; id <= LevelFactory.campaignCount; id++) {
      if (starsFor(mode, id) == 0) return id;
    }
    return LevelFactory.campaignCount;
  }

  bool unlockedFor(GameMode mode, int id) =>
      id >= 1 &&
      id <= LevelFactory.campaignCount &&
      (id == 1 || starsFor(mode, id - 1) > 0 || starsFor(mode, id) > 0);
  int roundFor(GameMode mode) =>
      mode == GameMode.cross ? endlessRound : _rounds[mode] ?? 1;
  int seedFor(GameMode mode) => mode == GameMode.cross
      ? endlessSeed
      : _seeds[mode] ?? endlessSeed + mode.index * 104729;
  bool guideSeen(GameMode mode) =>
      _guides.contains(mode) ||
      (_prefs?.getBool('guide_${mode.id}') ??
          (mode == GameMode.cross && seenTutorial && !_collectionIntro));
  void finishGuide(GameMode mode) {
    _guides.add(mode);
    _write(() async {
      await _prefs?.setBool('guide_${mode.id}', true);
    });
    notifyListeners();
  }

  static String draftKey(GameMode mode, int id, {bool endless = false}) =>
      '${mode == GameMode.cross ? '' : '${mode.id}:'}${endless ? 'endless' : 'campaign'}:$id';

  void completeMode(GameMode mode, int id, {required bool endless}) {
    if (id < 1 || (!endless && id > LevelFactory.campaignCount)) return;
    if (mode == GameMode.cross) {
      complete(id, endless: endless);
      return;
    }
    _seeds[mode] = seedFor(mode);
    if (endless) {
      _rounds[mode] = max(roundFor(mode), id + 1);
    } else {
      (_modeStars[mode] ??= {})[id] = 3;
    }
    final key = draftKey(mode, id, endless: endless);
    _drafts.remove(key);
    final record = {
      'version': 1,
      'stars': Map<int, int>.of(_modeStars[mode] ?? {}),
      'round': roundFor(mode),
      'seed': seedFor(mode),
    };
    _write(() async => _box?.put('collection:${mode.id}', record));
    _write(() async => _box?.delete('draft:$key'));
    notifyListeners();
  }

  static Future<GameStore> open() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Hive.initFlutter();
      final box = await Hive.openBox<dynamic>('math_cross_v1');
      final store = GameStore._(prefs, box);
      store.sound = prefs.getBool('sound') ?? true;
      store.seenTutorial = prefs.getBool('tutorial') ?? false;
      store._collectionIntro = prefs.getBool('collection_intro') ?? false;
      for (final key in box.keys.whereType<String>()) {
        final raw = box.get(key);
        if (raw is! Map || raw['version'] != 1) continue;
        if (key.startsWith('collection:')) {
          final mode = GameMode.fromId(key.substring(11));
          if (mode == null || mode == GameMode.cross) continue;
          final stars = raw['stars'];
          if (stars is Map) {
            _readStars(stars, store._modeStars[mode] = {});
          }
          if (raw['round'] is int && raw['round'] >= 1) {
            store._rounds[mode] = raw['round'];
          }
          if (raw['seed'] is int) store._seeds[mode] = raw['seed'];
        } else if (key.startsWith('level:')) {
          final id = int.tryParse(key.substring(6));
          final stars = raw['stars'];
          if (id != null &&
              id >= 1 &&
              id <= 80 &&
              stars is int &&
              stars >= 1 &&
              stars <= 3) {
            store._stars[id] = stars;
          }
        } else if (key.startsWith('draft:') && raw['entries'] is Map) {
          final entries = <int, int>{};
          for (final e in (raw['entries'] as Map).entries) {
            final cell = int.tryParse(e.key.toString());
            if (cell != null && e.value is int) entries[cell] = e.value as int;
          }
          store._drafts[key.substring(6)] = entries;
        } else if (key == 'meta') {
          if (raw['round'] is int && raw['round'] >= 1) {
            store.endlessRound = raw['round'];
          }
          if (raw['seed'] is int) store.endlessSeed = raw['seed'];
        }
      }
      if (!box.containsKey('meta')) {
        store.endlessSeed = Random().nextInt(1 << 30);
        await box.put('meta', {
          'version': 1,
          'round': 1,
          'seed': store.endlessSeed,
        });
      }
      return store;
    } catch (_) {
      return GameStore.memory(seenTutorial: false)..persistent = false;
    }
  }

  static void _readStars(Map raw, Map<int, int> destination) {
    for (final entry in raw.entries) {
      final id = int.tryParse(entry.key.toString());
      final stars = entry.value;
      if (id != null && id > 0 && stars is int && stars >= 1 && stars <= 3) {
        destination[id] = stars;
      }
    }
  }

  void _write(Future<void> Function() action) {
    _pending = _pending.then((_) => action()).catchError((Object _) {
      persistent = false;
      notifyListeners();
    });
  }

  Future<void> flush() => _pending;
  void setSound(bool enabled) {
    sound = enabled;
    notifyListeners();
    _write(() async {
      await _prefs?.setBool('sound', enabled);
    });
  }

  void finishTutorial() {
    seenTutorial = true;
    _collectionIntro = true;
    notifyListeners();
    _write(() async {
      await _prefs?.setBool('tutorial', true);
      await _prefs?.setBool('collection_intro', true);
    });
  }

  void saveDraft(String key, Map<int, int> entries) {
    final snapshot = Map<int, int>.of(entries);
    _drafts[key] = snapshot;
    _write(
      () async => _box?.put('draft:$key', {'version': 1, 'entries': snapshot}),
    );
  }

  void complete(int id, {required bool endless}) {
    final key = '${endless ? 'endless' : 'campaign'}:$id';
    _drafts.remove(key);
    if (endless) {
      endlessRound = max(endlessRound, id + 1);
      final round = endlessRound;
      _write(
        () async => _box?.put('meta', {
          'version': 1,
          'round': round,
          'seed': endlessSeed,
        }),
      );
    } else {
      _stars[id] = 3;
      _write(
        () async => _box?.put('level:$id', {
          'version': 1,
          'stars': 3,
          'completed': true,
        }),
      );
    }
    _write(() async => _box?.delete('draft:$key'));
    notifyListeners();
  }
}
