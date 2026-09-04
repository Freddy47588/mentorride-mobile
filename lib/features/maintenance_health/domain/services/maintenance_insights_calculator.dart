import 'package:intl/intl.dart';
import 'package:mentorride/features/maintenance_health/domain/models/maintenance_insight.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';

abstract final class MaintenanceInsightsCalculator {
  static List<MaintenanceInsight> calculate({
    required List<ServiceRecord> records,
    required DateTime now,
  }) {
    if (records.isEmpty) return const [];
    final monthCost = records
        .where(
          (record) =>
              record.serviceDate.year == now.year &&
              record.serviceDate.month == now.month,
        )
        .fold<int>(0, (total, record) => total + record.totalCost);
    final counts = <String, int>{};
    for (final record in records) {
      for (final item in record.items) {
        final name = item.name.trim();
        if (name.isNotEmpty) counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    final top = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    final latest = records.reduce(
      (a, b) => a.serviceDate.isAfter(b.serviceDate) ? a : b,
    );
    final latestDay = DateTime(
      latest.serviceDate.year,
      latest.serviceDate.month,
      latest.serviceDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(latestDay).inDays;
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return List.unmodifiable([
      MaintenanceInsight(
        label: 'Biaya perawatan bulan ini',
        value: currency.format(monthCost),
      ),
      MaintenanceInsight(
        label: 'Komponen paling sering dirawat',
        value: top.isEmpty ? '-' : '${top.first.key} (${top.first.value}×)',
      ),
      MaintenanceInsight(
        label: 'Servis terakhir',
        value: days <= 0 ? 'Hari ini' : '$days hari lalu',
      ),
    ]);
  }
}
