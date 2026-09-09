import 'grade.dart';

/// Derived summary shown on the hero card and the home-screen widget.
/// `lastGrade` is the most recently received grade: the numeric grade with the
/// newest `updatedAt`. Falls back to API list order when timestamps are absent
/// (older backend).
class GradeStats {
  final double average;
  final int passedCount;
  final int totalEcts;
  final double? lastGrade;
  final String? lastGradeTitle;

  const GradeStats({
    required this.average,
    required this.passedCount,
    required this.totalEcts,
    required this.lastGrade,
    required this.lastGradeTitle,
  });

  /// [weighted] selects the average formula: ECTS-weighted
  /// `Σ(grade × ects) / Σ(ects)` (the default) versus the plain mean
  /// `Σ(grade) / count` over every passed, graded subject.
  factory GradeStats.from(List<Grade> grades, {bool weighted = true}) {
    double totalWeighted = 0;
    int totalEcts = 0;
    double plainSum = 0;
    int gradedCount = 0;
    int passedCount = 0;
    Grade? latest;

    for (final g in grades) {
      if (g.passed && g.grade != null) {
        plainSum += g.grade!;
        gradedCount++;
        if (g.ects > 0) {
          totalWeighted += g.grade! * g.ects;
          totalEcts += g.ects;
        }
      }
      if (g.passed) passedCount++;
      if (g.grade != null && (latest == null || _isNewer(g, latest))) {
        latest = g;
      }
    }

    final double average = weighted
        ? (totalEcts > 0 ? totalWeighted / totalEcts : 0)
        : (gradedCount > 0 ? plainSum / gradedCount : 0);

    return GradeStats(
      average: average,
      passedCount: passedCount,
      totalEcts: totalEcts,
      lastGrade: latest?.grade,
      lastGradeTitle: latest?.title,
    );
  }

  /// Whether [candidate] is more recent than [current]. Prefers the newer
  /// timestamp; a timestamped grade always beats one without; when neither has
  /// a timestamp, later list position wins (the old behaviour).
  static bool _isNewer(Grade candidate, Grade current) {
    final a = candidate.updatedAt;
    final b = current.updatedAt;
    if (a != null && b != null) return a.isAfter(b);
    if (a != null) return true;
    if (b != null) return false;
    return true;
  }
}
