import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/features/service_records/domain/models/service_action.dart';
import 'package:mentorride/features/service_records/domain/models/service_item.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_records/domain/services/maintenance_statistics_calculator.dart';

void main() {
  group('MaintenanceStatisticsCalculator.calculate', () {
    test(
      'menghitung total, rata-rata, jumlah servis, dan komponen teratas',
      () {
        final statistics = MaintenanceStatisticsCalculator.calculate([
          _record('one', [
            const ServiceItem(
              name: 'Oli mesin',
              action: ServiceAction.ganti,
              cost: 120000,
            ),
            const ServiceItem(
              name: 'CVT',
              action: ServiceAction.servis,
              cost: 180000,
            ),
          ]),
          _record('two', [
            const ServiceItem(
              name: '  oli   MESIN ',
              action: ServiceAction.ganti,
              cost: 130001,
            ),
          ]),
        ]);

        expect(statistics.serviceCount, 2);
        expect(statistics.totalCost, 430001);
        expect(statistics.averageCostPerService, 215001);
        expect(statistics.components, hasLength(2));
        expect(statistics.mostFrequentComponent?.name, 'Oli mesin');
        expect(statistics.mostFrequentComponent?.occurrenceCount, 2);
        expect(statistics.mostFrequentComponent?.totalCost, 250001);
      },
    );

    test(
      'memecahkan frekuensi seri secara deterministik berdasarkan biaya',
      () {
        final statistics = MaintenanceStatisticsCalculator.calculate([
          _record('one', const [
            ServiceItem(
              name: 'Filter udara',
              action: ServiceAction.servis,
              cost: 50000,
            ),
            ServiceItem(
              name: 'CVT',
              action: ServiceAction.servis,
              cost: 150000,
            ),
          ]),
        ]);

        expect(statistics.components.map((item) => item.name), [
          'CVT',
          'Filter udara',
        ]);
      },
    );

    test('menghasilkan statistik nol untuk riwayat kosong', () {
      final statistics = MaintenanceStatisticsCalculator.calculate(const []);

      expect(statistics.serviceCount, 0);
      expect(statistics.totalCost, 0);
      expect(statistics.averageCostPerService, 0);
      expect(statistics.components, isEmpty);
      expect(statistics.mostFrequentComponent, isNull);
    });
  });
}

ServiceRecord _record(String id, List<ServiceItem> items) {
  return ServiceRecord(
    id: id,
    serviceDate: DateTime(2026, 9, 3),
    odometer: 10000,
    workshop: 'Bengkel',
    items: items,
    notes: '',
  );
}
