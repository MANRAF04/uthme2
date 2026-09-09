import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/grade.dart';
import '../services/api_service.dart';
import '../services/widget_service.dart';

// 1. Provide the ApiService globally
final apiProvider = Provider((ref) => ApiService());

// 2. The Notifier that holds our Grades state
class GradesNotifier extends AsyncNotifier<List<Grade>> {
  final _storage = const FlutterSecureStorage();

  @override
  Future<List<Grade>> build() async {
    // This runs automatically when the screen loads (fetches instant cache)
    return _fetchData(forceRefresh: false);
  }

  Future<List<Grade>> _fetchData({required bool forceRefresh}) async {
    final username = (await _storage.read(key: 'username'))?.trim();
    final password = await _storage.read(key: 'password');

    if (username == null || username.isEmpty || password == null || password.isEmpty) {
      throw Exception("Missing credentials");
    }

    final api = ref.read(apiProvider);

    List<Grade> grades;
    try {
      grades = await api.fetchGrades(username, password, forceRefresh: forceRefresh);
    } on TaskCompletedException {
      // Background scrape finished! Fetch the fresh data from the DB.
      grades = await api.fetchGrades(username, password, forceRefresh: false);
    }

    await WidgetService.syncFromGrades(grades);
    return grades;
  }

  // Triggered by the "Pull to Refresh" gesture
  Future<void> refreshGrades() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchData(forceRefresh: true));
  }
}

// 3. The Provider we will listen to in the UI
final gradesProvider = AsyncNotifierProvider.autoDispose<GradesNotifier, List<Grade>>(() {
  return GradesNotifier();
});