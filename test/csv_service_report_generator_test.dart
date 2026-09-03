import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/features/service_records/domain/models/service_action.dart';
import 'package:mentorride/features/service_records/domain/models/service_item.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_reports/data/services/csv_service_report_generator.dart';
import 'package:mentorride/features/service_reports/domain/services/service_report_mapper.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

void main() {
  group('CsvServiceReportGenerator', () {
    test('menulis BOM UTF-8, header tetap, dan satu baris per item', () {
      final report = ServiceReportMapper.map(
        vehicle: _vehicle,
        records: [
          ServiceRecord(
            id: 'record-1',
            serviceDate: DateTime(2026, 9, 3),
            odometer: 15000,
            workshop: 'Bengkel Maju',
            items: const [
              ServiceItem(
                name: 'Oli mesin',
                action: ServiceAction.ganti,
                cost: 125000,
              ),
              ServiceItem(
                name: 'CVT',
                action: ServiceAction.servis,
                cost: 175000,
              ),
            ],
            notes: 'Servis berkala',
          ),
        ],
        generatedAt: DateTime(2026, 9, 3),
      );

      final bytes = CsvServiceReportGenerator().serialize(report);
      final csv = utf8.decode(bytes.sublist(3));

      expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
      expect(
        csv,
        startsWith(
          'tanggal_servis,kilometer,bengkel,komponen,jenis_tindakan,'
          'biaya,total_transaksi,catatan\r\n',
        ),
      );
      expect(
        csv,
        contains(
          '2026-09-03,15000,Bengkel Maju,Oli mesin,Ganti,125000,300000,'
          'Servis berkala\r\n',
        ),
      );
      expect(
        csv,
        contains(
          '2026-09-03,15000,Bengkel Maju,CVT,Servis,175000,300000,'
          'Servis berkala\r\n',
        ),
      );
    });

    test(
      'meng-escape koma, quote, baris baru, dan menjaga karakter Unicode',
      () {
        final report = ServiceReportMapper.map(
          vehicle: _vehicle,
          records: [
            ServiceRecord(
              id: 'record-1',
              serviceDate: DateTime(2026, 9, 3),
              odometer: 15000,
              workshop: 'Bengkel "Maju", Jakarta',
              items: const [
                ServiceItem(
                  name: 'Busi, iridium',
                  action: ServiceAction.ganti,
                  cost: 90000,
                ),
              ],
              notes: 'Baris pertama\nCek ulang ✓',
            ),
          ],
          generatedAt: DateTime(2026, 9, 3),
        );

        final bytes = CsvServiceReportGenerator().serialize(report);
        final csv = utf8.decode(bytes.sublist(3));

        expect(csv, contains('"Bengkel ""Maju"", Jakarta"'));
        expect(csv, contains('"Busi, iridium"'));
        expect(csv, contains('"Baris pertama\nCek ulang ✓"'));
        expect(csv, endsWith('\r\n'));
      },
    );

    test('tetap menulis transaksi lama yang tidak memiliki item', () {
      final report = ServiceReportMapper.map(
        vehicle: _vehicle,
        records: [
          ServiceRecord(
            id: 'legacy',
            serviceDate: DateTime(2026, 9, 3),
            odometer: 15000,
            workshop: 'Bengkel',
            items: const [],
            notes: '',
          ),
        ],
        generatedAt: DateTime(2026, 9, 3),
      );

      final csv = utf8.decode(
        CsvServiceReportGenerator().serialize(report).sublist(3),
      );

      expect(csv, contains('2026-09-03,15000,Bengkel,,,0,0,\r\n'));
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
  currentOdometer: 15000,
);
