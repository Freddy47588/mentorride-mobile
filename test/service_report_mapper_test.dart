import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/features/service_records/domain/models/service_action.dart';
import 'package:mentorride/features/service_records/domain/models/service_item.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_reports/domain/services/service_report_mapper.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

void main() {
  group('ServiceReportMapper.map', () {
    test(
      'memetakan kendaraan dan ringkasan dari riwayat yang tidak terurut',
      () {
        const vehicle = Vehicle(
          id: 'vehicle-1',
          name: ' Motor Harian ',
          brand: ' Honda ',
          model: ' Beat ',
          year: 2024,
          plateNumber: ' B 1234 ABC ',
          currentOdometer: 18000,
        );
        final older = _record(
          id: 'older',
          date: DateTime(2026, 1, 10),
          cost: 100000,
        );
        final newer = _record(
          id: 'newer',
          date: DateTime(2026, 9, 3),
          cost: 250000,
        );
        final generatedAt = DateTime(2026, 9, 3, 12);

        final report = ServiceReportMapper.map(
          vehicle: vehicle,
          records: [older, newer],
          generatedAt: generatedAt,
        );

        expect(report.vehicle.name, 'Motor Harian');
        expect(report.vehicle.brand, 'Honda');
        expect(report.vehicle.model, 'Beat');
        expect(report.vehicle.plateNumber, 'B 1234 ABC');
        expect(report.vehicle.currentOdometer, 18000);
        expect(report.summary.serviceCount, 2);
        expect(report.summary.totalCost, 350000);
        expect(report.summary.periodStart, older.serviceDate);
        expect(report.summary.periodEnd, newer.serviceDate);
        expect(report.transactions.map((record) => record.id), [
          'newer',
          'older',
        ]);
        expect(report.transactions.first.items.single.component, 'Oli mesin');
        expect(report.transactions.first.items.single.action, 'Ganti');
        expect(report.transactions.first.items.single.actionValue, 'ganti');
        expect(report.generatedAt, generatedAt);
      },
    );

    test('menghasilkan periode null untuk laporan tanpa transaksi', () {
      final report = ServiceReportMapper.map(
        vehicle: _vehicle,
        records: const [],
        generatedAt: DateTime(2026, 9, 3),
      );

      expect(report.summary.serviceCount, 0);
      expect(report.summary.totalCost, 0);
      expect(report.summary.periodStart, isNull);
      expect(report.summary.periodEnd, isNull);
      expect(report.transactions, isEmpty);
    });

    test('hasil mapping tidak dapat dimodifikasi dari luar', () {
      final report = ServiceReportMapper.map(
        vehicle: _vehicle,
        records: [_record(id: 'one', date: DateTime(2026), cost: 1)],
        generatedAt: DateTime(2026),
      );

      expect(() => report.transactions.clear(), throwsUnsupportedError);
      expect(
        () => report.transactions.single.items.clear(),
        throwsUnsupportedError,
      );
    });
  });
}

const _vehicle = Vehicle(
  id: 'vehicle-1',
  name: 'Motor Harian',
  brand: 'Honda',
  model: 'Beat',
  year: 2024,
  plateNumber: 'B 1234 ABC',
  currentOdometer: 18000,
);

ServiceRecord _record({
  required String id,
  required DateTime date,
  required int cost,
}) {
  return ServiceRecord(
    id: id,
    serviceDate: date,
    odometer: 17000,
    workshop: ' Bengkel Jaya ',
    items: [
      ServiceItem(name: ' Oli mesin ', action: ServiceAction.ganti, cost: cost),
    ],
    notes: ' Servis rutin ',
  );
}
