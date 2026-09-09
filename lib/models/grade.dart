class Grade {
  final String id;
  final String title;
  final String code;
  final int semester;
  final int ects;
  final double? grade;
  final bool passed;
  // When the grade value last changed (new grade or a correction). Used to
  // find the most recent grade. Null when talking to an older backend.
  final DateTime? updatedAt;

  Grade({
    required this.id,
    required this.title,
    required this.code,
    required this.semester,
    required this.ects,
    this.grade,
    required this.passed,
    this.updatedAt,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      // The ? checks if it's null before converting to string.
      // The ?? provides a default fallback if it IS null.
      id: json['id']?.toString() ?? 'unknown-id',
      title: json['title']?.toString() ?? 'Unknown Subject',
      code: json['code']?.toString() ?? '-',
      
      // We also ensure numbers safely default to 0
      semester: json['semester'] ?? 0,
      ects: json['ects'] ?? 0,
      
      grade: json['grade'] != null ? (json['grade'] as num).toDouble() : null,
      passed: json['passed'] ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}