import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:ds_easy_db/ds_easy_db.dart';

/// Hive CE implementation of [DatabaseRepository].
///
/// Provides fast, local key-value storage using Hive Community Edition.
/// Perfect for preferences, cached data, and offline-first applications.
///
/// Features:
/// - Zero native dependencies
/// - Fast read/write operations
/// - Automatic box management
/// - No encryption (use SecureStorageDatabase for sensitive data)
///
/// Every collection is stored in its own Hive box. Hive treats box names
/// case-insensitively, so `Users` and `users` refer to the same collection.
///
/// Example:
/// ```dart
/// db.configure(
///   prefs: HiveDatabase(),
///   // ...
/// );
/// ```
class HiveDatabase implements DatabaseRepository {
  /// Creates a Hive database.
  ///
  /// By default Hive stores its files in the app's documents directory
  /// (`Hive.initFlutter()`). Pass [path] to use a specific directory instead,
  /// for example a temporary directory in tests.
  HiveDatabase({this.path});

  /// Optional directory for the Hive files. `null` uses `Hive.initFlutter()`.
  final String? path;

  @override
  Future<void> init() async {
    final directory = path;
    if (directory != null) {
      Hive.init(directory);
    } else {
      await Hive.initFlutter();
    }
  }

  Future<Box<dynamic>> _box(String collection) async {
    return Hive.isBoxOpen(collection)
        ? Hive.box(collection)
        : await Hive.openBox(collection);
  }

  Map<String, dynamic> _resolveServerTimestamps(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value == DatabaseRepository.serverTS) {
        return MapEntry(key, DateTime.now());
      }
      return MapEntry(key, value);
    });
  }

  @override
  Future<void> set(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    final box = await _box(collection);
    await box.put(id, _resolveServerTimestamps(data));
  }

  @override
  Future<void> update(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    final box = await _box(collection);
    final existing = _toDocument(box.get(id)) ?? <String, dynamic>{};
    await box.put(id, {...existing, ..._resolveServerTimestamps(data)});
  }

  @override
  Future<Map<String, dynamic>?> get(
    String collection,
    String id, {
    dynamic defaultValue,
  }) async {
    final box = await _box(collection);
    return _toDocument(box.get(id)) ?? defaultValue;
  }

  @override
  Future<Map<String, dynamic>?> getAll(String collection) async {
    final box = await _box(collection);

    final result = <String, dynamic>{};
    for (final key in box.keys) {
      final document = _toDocument(box.get(key));
      if (document != null) result[key.toString()] = document;
    }
    return result.isEmpty ? null : result;
  }

  @override
  Future<bool> exists(String collection, String id) async {
    final box = await _box(collection);
    return box.containsKey(id);
  }

  @override
  Future<bool> existsWhere(
    String collection, {
    required Map<String, dynamic> where,
  }) async {
    final box = await _box(collection);
    for (final value in box.values) {
      final document = _toDocument(value);
      if (document != null && _matches(document, where)) return true;
    }
    return false;
  }

  @override
  Future<void> delete(String collection, String id) async {
    final box = await _box(collection);
    await box.delete(id);
  }

  /// Returns the matching documents, each with its document id under `id`.
  ///
  /// A document that carries its own `id` field keeps it.
  @override
  Future<List<Map<String, dynamic>>> query(
    String collection, {
    Map<String, dynamic> where = const {},
  }) async {
    final box = await _box(collection);

    final result = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final document = _toDocument(box.get(key));
      if (document == null || !_matches(document, where)) continue;
      result.add(<String, dynamic>{'id': key.toString(), ...document});
    }
    return result;
  }

  bool _matches(Map<String, dynamic> document, Map<String, dynamic> where) {
    for (final entry in where.entries) {
      if (document[entry.key] != entry.value) return false;
    }
    return true;
  }

  /// Converts what Hive hands back into a document.
  ///
  /// Hive returns every stored map as `Map<dynamic, dynamic>` — nested maps
  /// included — so a shallow cast would leave nested values with the wrong
  /// type and make callers fail on `as Map<String, dynamic>`. Values that are
  /// not maps at all (written by other code into the same box) yield `null`.
  static Map<String, dynamic>? _toDocument(Object? value) {
    if (value is! Map) return null;
    return _deepConvert(value) as Map<String, dynamic>;
  }

  static Object? _deepConvert(Object? value) {
    if (value is Map) {
      return <String, dynamic>{
        for (final entry in value.entries)
          entry.key.toString(): _deepConvert(entry.value),
      };
    }
    if (value is List) return value.map(_deepConvert).toList();
    return value;
  }
}
