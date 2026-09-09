import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/grade.dart';
import '../models/grades_snapshot.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/widget_service.dart';

typedef _Credentials = ({String username, String password});

// 1. Provide the ApiService globally
final apiProvider = Provider((ref) => ApiService());

// 2. The Notifier that holds our Grades state
class GradesNotifier extends AsyncNotifier<GradesSnapshot> {
  final _storage = const FlutterSecureStorage();
  bool _disposed = false;

  @override
  Future<GradesSnapshot> build() async {
    ref.onDispose(() => _disposed = true);

    final credentials = await _readCredentials();
    final cached = await CacheService.readGrades(credentials.username);

    if (cached == null) {
      return _fetchData(credentials, forceRefresh: false);
    }

    // Saved grades paint straight away; the server answer replaces them when
    // (and if) it arrives.
    _refreshBehindCache(credentials);
    return GradesSnapshot(
      grades: cached.data,
      fetchedAt: cached.fetchedAt,
      isRefreshing: true,
    );
  }

  // Triggered by the "Pull to Refresh" gesture
  Future<void> refreshGrades() async {
    final previous = state.value;
    state = previous == null
        ? const AsyncValue<GradesSnapshot>.loading()
        : AsyncValue.data(previous.asRefreshing());

    try {
      final credentials = await _readCredentials();
      final snapshot = await _fetchData(credentials, forceRefresh: true);
      if (_disposed) return;
      state = AsyncValue.data(snapshot);
    } catch (error, stack) {
      if (_disposed) return;
      // Keep whatever we were already showing rather than dropping the user
      // back to an error screen.
      state = previous == null
          ? AsyncValue.error(error, stack)
          : AsyncValue.data(previous.withRefreshError(error));
    }
  }

  /// Starts the network fetch once the cached snapshot has been handed to the
  /// UI. The timer defers it past Riverpod publishing [build]'s result, which
  /// would otherwise overwrite the fresh state.
  void _refreshBehindCache(_Credentials credentials) {
    Future.delayed(Duration.zero, () async {
      if (_disposed) return;

      try {
        final snapshot = await _fetchData(credentials, forceRefresh: false);
        if (_disposed) return;
        state = AsyncValue.data(snapshot);
      } catch (error) {
        if (_disposed) return;
        final current = state.value;
        if (current == null) return;
        state = AsyncValue.data(current.withRefreshError(error));
      }
    });
  }

  Future<GradesSnapshot> _fetchData(
    _Credentials credentials, {
    required bool forceRefresh,
  }) async {
    final api = ref.read(apiProvider);
    final username = credentials.username;
    final password = credentials.password;

    List<Grade> grades;
    try {
      grades = await api.fetchGrades(username, password, forceRefresh: forceRefresh);
    } on TaskCompletedException {
      // Background scrape finished! Fetch the fresh data from the DB.
      grades = await api.fetchGrades(username, password, forceRefresh: false);
    }

    await CacheService.writeGrades(username, grades);
    await WidgetService.syncFromGrades(grades);
    return GradesSnapshot(grades: grades, fetchedAt: DateTime.now());
  }

  Future<_Credentials> _readCredentials() async {
    final username = (await _storage.read(key: 'username'))?.trim();
    final password = await _storage.read(key: 'password');

    if (username == null || username.isEmpty || password == null || password.isEmpty) {
      throw Exception("Missing credentials");
    }

    return (username: username, password: password);
  }
}

// 3. The Provider we will listen to in the UI
final gradesProvider = AsyncNotifierProvider.autoDispose<GradesNotifier, GradesSnapshot>(() {
  return GradesNotifier();
});
