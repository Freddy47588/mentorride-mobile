import 'package:mentorride/core/errors/app_exception.dart';

enum OdometerChange { unchanged, increased }

abstract final class OdometerUpdatePolicy {
  static OdometerChange evaluate({
    required int current,
    required int proposed,
  }) {
    if (proposed < 0) {
      throw const AppException('Kilometer tidak boleh bernilai negatif.');
    }
    if (proposed < current) {
      throw const AppException(
        'Kilometer baru tidak boleh lebih kecil dari kilometer saat ini.',
      );
    }
    return proposed == current
        ? OdometerChange.unchanged
        : OdometerChange.increased;
  }

  static bool shouldCreateLog({required int current, required int proposed}) {
    return evaluate(current: current, proposed: proposed) ==
        OdometerChange.increased;
  }
}
