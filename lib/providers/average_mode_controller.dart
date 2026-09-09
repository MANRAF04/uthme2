import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure-storage key holding whether the grade average is ECTS-weighted.
/// Absent means the default: weighted.
const String averageWeightedStorageKey = 'grade_average_weighted';

const FlutterSecureStorage _storage = FlutterSecureStorage();

/// Reads the persisted average mode. Defaults to weighted (true) when unset.
/// Used where there is no [BuildContext]/Riverpod (the home-screen widget runs
/// in a background isolate).
Future<bool> readStoredWeightedMode() async {
  final value = await _storage.read(key: averageWeightedStorageKey);
  if (value == null) return true;
  return value != 'false';
}

/// Seeded in `main()` so the stored value is read once, before the first frame.
final initialWeightedModeProvider = Provider<bool>((ref) {
  throw UnimplementedError('initialWeightedModeProvider must be overridden');
});

/// `true` = ECTS-weighted average, `false` = plain (unweighted) mean.
final averageWeightedProvider =
    NotifierProvider<AverageModeController, bool>(AverageModeController.new);

class AverageModeController extends Notifier<bool> {
  @override
  bool build() => ref.read(initialWeightedModeProvider);

  Future<void> toggle() => setWeighted(!state);

  Future<void> setWeighted(bool weighted) async {
    state = weighted;
    await _storage.write(
      key: averageWeightedStorageKey,
      value: weighted ? 'true' : 'false',
    );
  }
}
