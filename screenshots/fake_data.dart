import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uthme2/models/grade.dart';
import 'package:uthme2/models/student_profile.dart';

/// Deterministic demo content for the screenshot harness.

final List<Grade> demoGrades = [
  _g('1', 'Ανάλυση I', 'ECE101', 1, 6, 7.5, DateTime(2024, 2, 10)),
  _g('2', 'Γραμμική Άλγεβρα', 'ECE102', 1, 5, 8.0, DateTime(2024, 2, 12)),
  _g(
    '3',
    'Εισαγωγή στον Προγραμματισμό',
    'ECE103',
    1,
    6,
    9.0,
    DateTime(2024, 2, 15),
  ),
  _g(
    '4',
    'Φυσική I',
    'ECE104',
    1,
    5,
    4.0,
    DateTime(2024, 2, 18),
    passed: false,
  ),
  _g('5', 'Ανάλυση II', 'ECE201', 2, 6, 6.5, DateTime(2024, 7, 1)),
  _g('6', 'Δομές Δεδομένων', 'ECE202', 2, 6, 8.5, DateTime(2024, 7, 3)),
  _g('7', 'Ψηφιακή Σχεδίαση', 'ECE203', 2, 5, 7.0, DateTime(2024, 7, 5)),
  _g(
    '8',
    'Πιθανότητες και Στατιστική',
    'ECE204',
    2,
    5,
    null,
    null,
    passed: false,
  ),
  _g('9', 'Αλγόριθμοι', 'ECE301', 3, 6, 9.5, DateTime(2025, 2, 2)),
  _g(
    '10',
    'Αρχιτεκτονική Υπολογιστών',
    'ECE302',
    3,
    6,
    6.0,
    DateTime(2025, 2, 6),
  ),
  _g('11', 'Σήματα και Συστήματα', 'ECE303', 3, 5, 7.5, DateTime(2025, 2, 9)),
  _g('12', 'Λειτουργικά Συστήματα', 'ECE401', 4, 6, 8.0, DateTime(2025, 7, 2)),
  _g('13', 'Βάσεις Δεδομένων', 'ECE402', 4, 6, 9.0, DateTime(2025, 7, 8)),
  _g('14', 'Δίκτυα Υπολογιστών', 'ECE403', 4, 5, null, null, passed: false),
];

Grade _g(
  String id,
  String title,
  String code,
  int semester,
  int ects,
  double? grade,
  DateTime? updatedAt, {
  bool passed = true,
}) {
  return Grade(
    id: id,
    title: title,
    code: code,
    semester: semester,
    ects: ects,
    grade: grade,
    passed: passed,
    updatedAt: updatedAt,
  );
}

const List<Map<String, String>> _restaurants = [
  {'id': 'volos', 'title': 'Λέσχη Βόλου', 'city': 'Βόλος'},
  {'id': 'larisa', 'title': 'Λέσχη Λάρισας', 'city': 'Λάρισα'},
  {'id': 'trikala', 'title': 'Λέσχη Τρικάλων', 'city': 'Τρίκαλα'},
  {'id': 'karditsa', 'title': 'Λέσχη Καρδίτσας', 'city': 'Καρδίτσα'},
  {'id': 'lamia', 'title': 'Λέσχη Λαμίας', 'city': 'Λαμία'},
];

const List<Map<String, Object>> _mealTypes = [
  {
    'id': 'b',
    'meal_type_id': 'b',
    'title': 'Πρωινό',
    'sort_order': 1,
    'hour_from': '07:30',
    'hour_to': '09:30',
  },
  {
    'id': 'l',
    'meal_type_id': 'l',
    'title': 'Μεσημεριανό',
    'sort_order': 2,
    'hour_from': '12:00',
    'hour_to': '16:00',
  },
  {
    'id': 'd',
    'meal_type_id': 'd',
    'title': 'Βραδινό',
    'sort_order': 3,
    'hour_from': '18:00',
    'hour_to': '21:00',
  },
];

const Map<String, List<List<String>>> _dishes = {
  'b': [
    ['Πρωινό', 'Γιαούρτι με μέλι'],
    ['Πρωινό', 'Φρυγανιές με βούτυρο και μαρμελάδα'],
    ['Ρόφημα', 'Γάλα ή χυμός πορτοκάλι'],
  ],
  'l': [
    ['Κυρίως πιάτο', 'Μουσακάς'],
    ['Κυρίως πιάτο', 'Φασολάκια λαδερά'],
    ['Γαρνιτούρα', 'Ρύζι πιλάφι'],
    ['Σαλάτα', 'Χωριάτικη σαλάτα'],
    ['Επιδόρπιο', 'Φρούτο εποχής'],
  ],
  'd': [
    ['Κυρίως πιάτο', 'Κοτόπουλο λεμονάτο με πατάτες'],
    ['Κυρίως πιάτο', 'Σπανακόρυζο'],
    ['Σαλάτα', 'Λάχανο καρότο'],
    ['Επιδόρπιο', 'Ρυζόγαλο'],
  ],
};

const Map<String, int> _courseOrder = {
  'Πρωινό': 1,
  'Ρόφημα': 2,
  'Κυρίως πιάτο': 1,
  'Γαρνιτούρα': 2,
  'Σαλάτα': 3,
  'Επιδόρπιο': 4,
};

/// Fake backend. [menuFails] makes every menu request return 500, [emptyMenu]
/// returns a week with no dishes.
MockClient fakeBackend({bool menuFails = false, bool emptyMenu = false}) {
  return MockClient((request) async {
    final path = request.url.path;

    if (path.endsWith('/restaurants')) {
      return _json({'data': _restaurants});
    }

    if (path.contains('/restaurants/') && path.endsWith('/menu')) {
      if (menuFails) {
        return http.Response(jsonEncode({'error': 'Server unavailable'}), 500);
      }
      final start = DateTime.parse(request.url.queryParameters['start']!);
      final end = DateTime.parse(request.url.queryParameters['end']!);
      return _json(_menuWeek(start, end, empty: emptyMenu));
    }

    if (path.endsWith('/user/preference')) {
      return _json({'ok': true});
    }

    return http.Response('not found', 404);
  });
}

Map<String, Object> _menuWeek(
  DateTime start,
  DateTime end, {
  required bool empty,
}) {
  final items = <Map<String, Object>>[];
  if (!empty) {
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      for (final meal in _mealTypes) {
        final mealId = meal['meal_type_id'] as String;
        final dishes = _dishes[mealId]!;
        for (var i = 0; i < dishes.length; i++) {
          items.add({
            'id': '${day.toIso8601String()}-$mealId-$i',
            'date': _date(day),
            'meal_type_id': mealId,
            'meal_type': meal['title']!,
            'meal_type_sort_order': meal['sort_order']!,
            'meal_hour_from': meal['hour_from']!,
            'meal_hour_to': meal['hour_to']!,
            'course_type': dishes[i][0],
            'course_sort_order': _courseOrder[dishes[i][0]]!,
            'item_sort_order': i,
            'food_name': dishes[i][1],
          });
        }
      }
    }
  }

  return {
    'range': {'start': _date(start), 'end': _date(end)},
    'meal_types': _mealTypes,
    'data': items,
  };
}

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const StudentProfile demoProfile = StudentProfile(
  studentNo: '03735',
  academicNo: '215807327634',
  departmentCode: '501',
  programCode: '128',
  diningCard: DiningCard(
    active: true,
    validFrom: '2026-11-02',
    validTo: '2027-06-25',
  ),
  freeMeals: true,
);

const StudentProfile demoProfileNoCard = StudentProfile(
  studentNo: '03735',
  academicNo: '215807327634',
);

const StudentProfile demoProfileInactive = StudentProfile(
  studentNo: '03735',
  academicNo: '215807327634',
  diningCard: DiningCard(
    active: false,
    validFrom: '2025-11-03',
    validTo: '2026-06-26',
  ),
);
