import 'package:mentorride/features/odometer/domain/models/odometer_log.dart';
import 'package:mentorride/features/odometer/domain/models/odometer_statistics.dart';

abstract final class OdometerStatisticsCalculator {
  static OdometerStatistics calculate({
    required List<OdometerLog> logs,
    required int currentOdometer,
    required DateTime now,
    required int periodDays,
  }) {
    final dated =
        logs.where((log) => log.recordedAt != null).toList(growable: false)
          ..sort((a, b) => a.recordedAt!.compareTo(b.recordedAt!));
    final cutoff = now.subtract(Duration(days: periodDays));
    final inPeriod = dated
        .where((log) => !log.recordedAt!.isBefore(cutoff))
        .toList(growable: false);
    final selected = inPeriod.length >= 2 ? inPeriod : dated;

    var increase = 0;
    int? average;
    if (selected.length >= 2) {
      increase = selected.last.odometer - selected.first.odometer;
      if (increase < 0) increase = 0;
      final elapsedDays =
          selected.last.recordedAt!
              .difference(selected.first.recordedAt!)
              .inHours /
          24;
      if (elapsedDays >= 14 && increase > 0) {
        average = (increase * 30 / elapsedDays).round();
      }
    }

    return OdometerStatistics(
      currentOdometer: currentOdometer,
      periodIncrease: increase,
      averageMonthlyUsage: average,
    );
  }
}
