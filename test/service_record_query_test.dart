import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/features/service_records/domain/models/service_action.dart';
import 'package:mentorride/features/service_records/domain/models/service_item.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_records/domain/models/service_record_filter.dart';
import 'package:mentorride/features/service_records/domain/services/service_record_query.dart';

void main() {
  final records = [
    _record(
      id: 'september',
      date: DateTime(2026, 9, 3),
      workshop: 'Bengkel Jaya',
      component: 'Oli Mesin',
      notes: 'Servis rutin harian',
      cost: 125000,
    ),
    _record(
      id: 'august',
      date: DateTime(2026, 8, 15),
      workshop: 'Servis Mandiri',
      component: 'CVT',
      notes: 'Bunyi kasar',
      cost: 300000,
    ),
    _record(
      id: 'previous-year',
      date: DateTime(2025, 9, 3),
      workshop: 'Bengkel Lama',
      component: 'Filter udara',
      notes: '',
      cost: 75000,
    ),
  ];

  group('ServiceRecordQuery.apply', () {
    test('mencari bengkel, komponen, dan catatan tanpa membedakan kapital', () {
      for (final query in ['BENGKEL JAYA', 'oli mesin', 'RUTIN harian']) {
        final result = ServiceRecordQuery.apply(
          records: records,
          filter: ServiceRecordFilter(
            type: ServiceRecordFilterType.all,
            anchor: DateTime(2026, 9),
            query: query,
          ),
        );

        expect(result.map((record) => record.id), ['september']);
      }
    });

    test('mendukung beberapa kata yang tersebar pada field pencarian', () {
      final result = ServiceRecordQuery.apply(
        records: records,
        filter: ServiceRecordFilter(
          type: ServiceRecordFilterType.all,
          anchor: DateTime(2026, 9),
          query: '  jaya   oli rutin ',
        ),
      );

      expect(result.single.id, 'september');
    });

    test('memfilter bulan dan tahun dengan tanggal lokal', () {
      final monthResult = ServiceRecordQuery.apply(
        records: records,
        filter: ServiceRecordFilter(
          type: ServiceRecordFilterType.month,
          anchor: DateTime(2026, 9, 30),
        ),
      );
      final yearResult = ServiceRecordQuery.apply(
        records: records,
        filter: ServiceRecordFilter(
          type: ServiceRecordFilterType.year,
          anchor: DateTime(2026, 1),
        ),
      );

      expect(monthResult.map((record) => record.id), ['september']);
      expect(yearResult.map((record) => record.id), ['september', 'august']);
    });

    test(
      'rentang biaya bersifat inklusif dan dapat digabung dengan periode',
      () {
        final result = ServiceRecordQuery.apply(
          records: records,
          filter: ServiceRecordFilter(
            type: ServiceRecordFilterType.year,
            anchor: DateTime(2026),
            minimumCost: 125000,
            maximumCost: 300000,
          ),
        );

        expect(result.map((record) => record.id), ['september', 'august']);
      },
    );

    test('mempertahankan urutan input dan tidak memodifikasi koleksi asal', () {
      final originalIds = records.map((record) => record.id).toList();
      final result = ServiceRecordQuery.apply(
        records: records,
        filter: ServiceRecordFilter(
          type: ServiceRecordFilterType.all,
          anchor: DateTime(2026),
        ),
      );

      expect(result.map((record) => record.id), originalIds);
      expect(records.map((record) => record.id), originalIds);
    });
  });

  test('ServiceRecordFilter dapat membersihkan rentang biaya', () {
    final filter = ServiceRecordFilter(
      type: ServiceRecordFilterType.all,
      anchor: DateTime(2026),
      query: 'oli',
      minimumCost: 100000,
      maximumCost: 200000,
    );

    final cleared = filter.copyWith(
      clearMinimumCost: true,
      clearMaximumCost: true,
    );

    expect(cleared.query, 'oli');
    expect(cleared.minimumCost, isNull);
    expect(cleared.maximumCost, isNull);
    expect(cleared.hasCostRange, isFalse);
    expect(cleared.hasActiveFilter, isTrue);
  });
}

ServiceRecord _record({
  required String id,
  required DateTime date,
  required String workshop,
  required String component,
  required String notes,
  required int cost,
}) {
  return ServiceRecord(
    id: id,
    serviceDate: date,
    odometer: 10000,
    workshop: workshop,
    items: [
      ServiceItem(name: component, action: ServiceAction.servis, cost: cost),
    ],
    notes: notes,
  );
}
