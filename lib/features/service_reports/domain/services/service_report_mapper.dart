import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_reports/domain/models/service_report.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

abstract final class ServiceReportMapper {
  static ServiceReportData map({
    required Vehicle vehicle,
    required Iterable<ServiceRecord> records,
    required DateTime generatedAt,
  }) {
    final sortedRecords = records.toList(growable: false)
      ..sort((left, right) {
        final dateOrder = right.serviceDate.compareTo(left.serviceDate);
        return dateOrder != 0 ? dateOrder : left.id.compareTo(right.id);
      });

    final transactions = List<ServiceReportTransaction>.unmodifiable(
      sortedRecords.map(
        (record) => ServiceReportTransaction(
          id: record.id,
          serviceDate: record.serviceDate,
          odometer: record.odometer,
          workshop: record.workshop.trim(),
          items: List<ServiceReportItem>.unmodifiable(
            record.items.map(
              (item) => ServiceReportItem(
                component: item.name.trim(),
                action: item.action.label,
                actionValue: item.action.wireValue,
                cost: item.cost,
              ),
            ),
          ),
          totalCost: record.totalCost,
          notes: record.notes.trim(),
        ),
      ),
    );

    DateTime? periodStart;
    DateTime? periodEnd;
    var totalCost = 0;
    for (final transaction in transactions) {
      totalCost += transaction.totalCost;
      final date = transaction.serviceDate;
      if (periodStart == null || date.isBefore(periodStart)) {
        periodStart = date;
      }
      if (periodEnd == null || date.isAfter(periodEnd)) {
        periodEnd = date;
      }
    }

    return ServiceReportData(
      vehicle: ServiceReportVehicle(
        name: vehicle.name.trim(),
        brand: vehicle.brand.trim(),
        model: vehicle.model.trim(),
        year: vehicle.year,
        plateNumber: vehicle.plateNumber.trim(),
        currentOdometer: vehicle.currentOdometer,
      ),
      summary: ServiceReportSummary(
        serviceCount: transactions.length,
        totalCost: totalCost,
        periodStart: periodStart,
        periodEnd: periodEnd,
      ),
      transactions: transactions,
      generatedAt: generatedAt,
    );
  }
}
