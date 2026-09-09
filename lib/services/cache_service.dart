import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/grade.dart';
import '../models/restaurant.dart';
import '../models/restaurant_menu.dart';

/// A payload read back from device storage, with the moment the server last
/// answered for it. [fetchedAt] is null only when the stored stamp is missing
/// or unparseable.
class Cached<T> {
  final T data;
  final DateTime? fetchedAt;

  const Cached(this.data, this.fetchedAt);
}

/// Last-known-good copies of the server payloads, so every screen still has
/// something to render when a request fails or the server is unreachable.
///
/// Everything goes through [FlutterSecureStorage]: grades are personal data,
/// and it is the one store that works on all the platforms the app targets.
/// Failures are always swallowed - a broken cache must never take down the
/// screen that reads it.
class CacheService {
  CacheService._();

  static const _storage = FlutterSecureStorage();

  static const _gradesPrefix = 'grades_cache_';
  static const _restaurantsKey = 'restaurants_cache';
  static const _menuKey = 'menu_cache';
  static const _fetchedAtField = 'fetched_at';

  static Future<Cached<List<Grade>>?> readGrades(String username) async {
    final json = await _readJson(_gradesKey(username));
    if (json == null) return null;

    final items = (json['data'] as List<dynamic>?) ?? const [];
    return Cached(
      items.whereType<Map<String, dynamic>>().map(Grade.fromJson).toList(),
      _readFetchedAt(json),
    );
  }

  static Future<void> writeGrades(String username, List<Grade> grades) {
    return _writeJson(_gradesKey(username), {
      'data': grades.map((grade) => grade.toJson()).toList(),
    });
  }

  static Future<void> clearGrades(String username) =>
      _delete(_gradesKey(username));

  static Future<Cached<List<UniversityRestaurant>>?> readRestaurants() async {
    final json = await _readJson(_restaurantsKey);
    if (json == null) return null;

    final items = (json['data'] as List<dynamic>?) ?? const [];
    return Cached(
      items
          .whereType<Map<String, dynamic>>()
          .map(UniversityRestaurant.fromJson)
          .toList(),
      _readFetchedAt(json),
    );
  }

  static Future<void> writeRestaurants(
    List<UniversityRestaurant> restaurants,
  ) {
    return _writeJson(_restaurantsKey, {
      'data': restaurants.map((restaurant) => restaurant.toJson()).toList(),
    });
  }

  /// Only the most recently loaded week is kept, so this answers null unless
  /// the saved slot was written for exactly this restaurant and range.
  ///
  /// The match is made against the range that was *requested*, never the one
  /// the response echoed back, so a server that answers with a wider or
  /// shifted range cannot make every read miss.
  static Future<Cached<RestaurantMenuRange>?> readMenu({
    required String restaurantId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final json = await _readJson(_menuKey);
    if (json == null) return null;

    final matches = json['restaurant_id']?.toString() == restaurantId &&
        json['requested_start']?.toString() == _dayKey(startDate) &&
        json['requested_end']?.toString() == _dayKey(endDate);
    if (!matches) return null;

    return Cached(RestaurantMenuRange.fromJson(json), _readFetchedAt(json));
  }

  static Future<void> writeMenu({
    required String restaurantId,
    required DateTime startDate,
    required DateTime endDate,
    required RestaurantMenuRange menu,
  }) {
    return _writeJson(_menuKey, {
      'restaurant_id': restaurantId,
      'requested_start': _dayKey(startDate),
      'requested_end': _dayKey(endDate),
      ...menu.toJson(),
    });
  }

  static String _gradesKey(String username) => '$_gradesPrefix$username';

  static Future<Map<String, dynamic>?> _readJson(String key) async {
    try {
      final raw = await _storage.read(key: key);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Unreadable or malformed entry: fall through and drop it.
    }

    await _delete(key);
    return null;
  }

  static Future<void> _writeJson(String key, Map<String, dynamic> value) async {
    try {
      await _storage.write(
        key: key,
        value: jsonEncode({
          _fetchedAtField: DateTime.now().toIso8601String(),
          ...value,
        }),
      );
    } catch (_) {
      // Caching is best-effort.
    }
  }

  static Future<void> _delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // Nothing to recover from here.
    }
  }

  static DateTime? _readFetchedAt(Map<String, dynamic> json) =>
      DateTime.tryParse(json[_fetchedAtField]?.toString() ?? '');

  static String _dayKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
