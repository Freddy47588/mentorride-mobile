import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/core/errors/app_exception.dart';
import 'package:mentorride/features/odometer/domain/models/odometer_log.dart';
import 'package:mentorride/features/odometer/domain/services/odometer_statistics_calculator.dart';
import 'package:mentorride/features/vehicles/domain/services/odometer_update_policy.dart';

void main() {
  test('odometer log dibuat saat km naik', () {
    expect(
      OdometerUpdatePolicy.shouldCreateLog(current: 12000, proposed: 12500),
      isTrue,
    );
  });

  test('odometer log tidak dibuat saat km sama', () {
    expect(
      OdometerUpdatePolicy.shouldCreateLog(current: 12000, proposed: 12000),
      isFalse,
    );
  });

  test('odometer tetap tidak bisa turun', () {
    expect(
      () => OdometerUpdatePolicy.evaluate(current: 12000, proposed: 11999),
      throwsA(isA<AppException>()),
    );
  });

  test('odometer statistics dan average monthly usage', () {
    final stats = OdometerStatisticsCalculator.calculate(
      logs: [
        OdometerLog(
          id: '1',
          odometer: 10000,
          recordedAt: DateTime(2026, 8, 1),
          source: OdometerLogSource.manualUpdate,
        ),
        OdometerLog(
          id: '2',
          odometer: 10740,
          recordedAt: DateTime(2026, 8, 31),
          source: OdometerLogSource.serviceRecord,
        ),
      ],
      currentOdometer: 10740,
      now: DateTime(2026, 8, 31),
      periodDays: 30,
    );
    expect(stats.periodIncrease, 740);
    expect(stats.averageMonthlyUsage, 740);
  });
}
