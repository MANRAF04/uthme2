/// Dining card as reported by the portal. Dates are calendar days in Athens
/// time, kept as the raw `YYYY-MM-DD` strings so they round-trip unchanged.
class DiningCard {
  final bool active;
  final String? validFrom;
  final String? validTo;

  const DiningCard({required this.active, this.validFrom, this.validTo});

  DateTime? get validFromDate => _parseDay(validFrom);
  DateTime? get validToDate => _parseDay(validTo);

  factory DiningCard.fromJson(Map<String, dynamic> json) {
    return DiningCard(
      active: json['active'] == true,
      validFrom: _string(json['valid_from']),
      validTo: _string(json['valid_to']),
    );
  }

  Map<String, dynamic> toJson() => {
    'active': active,
    'valid_from': validFrom,
    'valid_to': validTo,
  };
}

/// Student identity returned alongside grades. Every field may be null: all
/// of them are until the first grade sync on the new backend.
class StudentProfile {
  /// AEM. A string on purpose: leading zeros are significant.
  final String? studentNo;

  /// Academic ID from the dining card, the number scanned at the restaurant.
  final String? academicNo;
  final String? departmentCode;
  final String? programCode;
  final DiningCard? diningCard;

  /// Server computed: card active and today within its validity window.
  final bool freeMeals;

  const StudentProfile({
    this.studentNo,
    this.academicNo,
    this.departmentCode,
    this.programCode,
    this.diningCard,
    this.freeMeals = false,
  });

  bool get hasIdentity => studentNo != null || academicNo != null;

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final card = json['dining_card'];
    return StudentProfile(
      studentNo: _string(json['student_no']),
      academicNo: _string(json['academic_no']),
      departmentCode: _string(json['department_code']),
      programCode: _string(json['program_code']),
      diningCard: card is Map<String, dynamic>
          ? DiningCard.fromJson(card)
          : null,
      freeMeals: json['free_meals'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'student_no': studentNo,
    'academic_no': academicNo,
    'department_code': departmentCode,
    'program_code': programCode,
    'dining_card': diningCard?.toJson(),
    'free_meals': freeMeals,
  };
}

String? _string(Object? value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty) ? null : text;
}

DateTime? _parseDay(String? value) {
  if (value == null) return null;
  final parsed = DateTime.tryParse(value);
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}
