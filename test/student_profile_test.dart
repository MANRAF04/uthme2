import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uthme2/models/student_profile.dart';
import 'package:uthme2/services/api_service.dart';
import 'package:uthme2/services/cache_service.dart';

const _profileJson = {
  'student_no': '03735',
  'academic_no': '215807327634',
  'department_code': '501',
  'program_code': '128',
  'dining_card': {
    'active': true,
    'valid_from': '2026-11-02',
    'valid_to': '2027-06-25',
  },
  'free_meals': true,
};

Future<GradesResponse> _fetchWith(Map<String, Object?> body) {
  return http.runWithClient(
    () => ApiService().fetchGrades('demo', 'secret'),
    () => MockClient((_) async => http.Response(jsonEncode(body), 200)),
  );
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('parses the profile and keeps leading zeros', () async {
    final response = await _fetchWith({
      'status': 'success',
      'source': 'database',
      'data': [],
      'profile': _profileJson,
    });

    final profile = response.profile!;
    expect(profile.studentNo, '03735');
    expect(profile.academicNo, '215807327634');
    expect(profile.freeMeals, isTrue);
    expect(profile.diningCard!.validToDate, DateTime(2027, 6, 25));
  });

  test('a missing profile key is null, an explicit null is empty', () async {
    final missing = await _fetchWith({'status': 'success', 'data': []});
    expect(missing.profile, isNull);

    final explicitNull = await _fetchWith({
      'status': 'success',
      'data': [],
      'profile': null,
    });
    expect(explicitNull.profile, isNotNull);
    expect(explicitNull.profile!.hasIdentity, isFalse);
    expect(explicitNull.profile!.freeMeals, isFalse);
  });

  test('null fields and a null dining card parse safely', () {
    final profile = StudentProfile.fromJson({
      'student_no': null,
      'academic_no': null,
      'dining_card': null,
      'free_meals': null,
    });

    expect(profile.hasIdentity, isFalse);
    expect(profile.diningCard, isNull);
    expect(profile.freeMeals, isFalse);
  });

  test('saving grades without a profile keeps the cached one', () async {
    final profile = StudentProfile.fromJson(_profileJson);
    await CacheService.writeGrades('demo', const [], profile: profile);
    await CacheService.writeGrades('demo', const []);

    final cached = await CacheService.readProfile('demo');
    expect(cached!.data.academicNo, '215807327634');
  });

  test('clearing grades also clears the profile', () async {
    await CacheService.writeGrades(
      'demo',
      const [],
      profile: StudentProfile.fromJson(_profileJson),
    );
    await CacheService.clearGrades('demo');

    expect(await CacheService.readProfile('demo'), isNull);
  });
}
