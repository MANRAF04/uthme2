import 'dart:async';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_widget/home_widget.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../models/grade.dart';
import '../models/grade_stats.dart';
import '../providers/average_mode_controller.dart';
import '../widgets/widget_card.dart';
import 'api_service.dart';

/// Top-level entry point invoked by home_widget when the widget is tapped.
/// Must be a top-level/static function annotated for the background isolate.
@pragma('vm:entry-point')
Future<void> widgetInteractivityCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (uri?.host == 'refresh') {
    await WidgetService.handleRefreshTap();
  }
}

/// Bridges the app's grade data to the Android home-screen widget: renders the
/// card to an image, persists the headline stats, and handles the tap-to-refresh
/// background flow.
class WidgetService {
  WidgetService._();

  static const _androidProvider = 'GradeWidgetProvider';
  static const _qualifiedProvider = 'com.example.uthme2.GradeWidgetProvider';
  static const _packageName = 'com.example.uthme2';
  static const _mainActivity = 'com.example.uthme2.MainActivity';
  static const _imageKey = 'gradeWidgetImage';
  static const _logicalSize = Size(360, 210);

  static const _storage = FlutterSecureStorage();
  static final _api = ApiService();

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Called from the app whenever fresh grades are available, to keep the
  /// widget in sync.
  static Future<void> syncFromGrades(List<Grade> grades) async {
    if (!_supported) return;
    final weighted = await readStoredWeightedMode();
    await _render(GradeStats.from(grades, weighted: weighted));
  }

  /// Background handler for a widget tap: re-scrape if logged in, otherwise
  /// open the app. Shows a loading state on the widget while scraping.
  static Future<void> handleRefreshTap() async {
    if (!_supported) return;

    final username = (await _storage.read(key: 'username'))?.trim();
    final password = await _storage.read(key: 'password');
    final loggedIn = username != null &&
        username.isNotEmpty &&
        password != null &&
        password.isNotEmpty;

    if (!loggedIn) {
      await _openApp();
      return;
    }

    // Show the loading state using the last persisted stats.
    await _render(await _loadSavedStats(), loading: true);

    try {
      List<Grade> grades;
      try {
        grades = await _api.fetchGrades(username, password, forceRefresh: true);
      } on TaskCompletedException {
        grades = await _api.fetchGrades(username, password, forceRefresh: false);
      }
      final weighted = await readStoredWeightedMode();
      await _render(GradeStats.from(grades, weighted: weighted));
    } catch (_) {
      // Offline or scrape failed: drop the loading state and open the app.
      await _render(await _loadSavedStats());
      await _openApp();
    }
  }

  static Future<void> _render(GradeStats stats, {bool loading = false}) async {
    await _saveStats(stats);
    final locale = resolveLocaleWithoutContext(await readStoredLocale());
    final l10n = await AppLocalizations.delegate.load(locale);
    await HomeWidget.renderFlutterWidget(
      WidgetCard(
        stats: stats,
        l10n: l10n,
        loading: loading,
        logicalSize: _logicalSize,
      ),
      key: _imageKey,
      logicalSize: _logicalSize,
    );
    await HomeWidget.updateWidget(
      androidName: _androidProvider,
      qualifiedAndroidName: _qualifiedProvider,
    );
  }

  static Future<void> _saveStats(GradeStats stats) async {
    await HomeWidget.saveWidgetData<double>('avg', stats.average);
    await HomeWidget.saveWidgetData<int>('passed', stats.passedCount);
    await HomeWidget.saveWidgetData<int>('ects', stats.totalEcts);
    await HomeWidget.saveWidgetData<double>('lastGrade', stats.lastGrade ?? -1);
    await HomeWidget.saveWidgetData<String>(
        'lastTitle', stats.lastGradeTitle ?? '');
  }

  static Future<GradeStats> _loadSavedStats() async {
    final avg = await HomeWidget.getWidgetData<double>('avg', defaultValue: 0);
    final passed =
        await HomeWidget.getWidgetData<int>('passed', defaultValue: 0);
    final ects = await HomeWidget.getWidgetData<int>('ects', defaultValue: 0);
    final lastGrade =
        await HomeWidget.getWidgetData<double>('lastGrade', defaultValue: -1);
    final lastTitle =
        await HomeWidget.getWidgetData<String>('lastTitle', defaultValue: '');

    return GradeStats(
      average: avg ?? 0,
      passedCount: passed ?? 0,
      totalEcts: ects ?? 0,
      lastGrade: (lastGrade ?? -1) < 0 ? null : lastGrade,
      lastGradeTitle:
          (lastTitle == null || lastTitle.isEmpty) ? null : lastTitle,
    );
  }

  static Future<void> _openApp() async {
    const intent = AndroidIntent(
      action: 'android.intent.action.MAIN',
      package: _packageName,
      componentName: _mainActivity,
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
  }
}
