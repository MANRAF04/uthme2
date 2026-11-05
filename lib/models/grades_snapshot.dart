import 'grade.dart';
import 'student_profile.dart';

/// The grade list the UI renders plus where it came from. [fetchedAt] is when
/// the server last answered. A non-null [refreshError] means the newest
/// attempt failed and these grades are the copy saved on the device.
class GradesSnapshot {
  final List<Grade> grades;
  final StudentProfile? profile;
  final DateTime? fetchedAt;
  final bool isRefreshing;
  final Object? refreshError;

  const GradesSnapshot({
    required this.grades,
    this.profile,
    this.fetchedAt,
    this.isRefreshing = false,
    this.refreshError,
  });

  bool get isStale => refreshError != null;

  GradesSnapshot asRefreshing() => GradesSnapshot(
        grades: grades,
        profile: profile,
        fetchedAt: fetchedAt,
        isRefreshing: true,
      );

  GradesSnapshot withRefreshError(Object error) => GradesSnapshot(
        grades: grades,
        profile: profile,
        fetchedAt: fetchedAt,
        refreshError: error,
      );
}
