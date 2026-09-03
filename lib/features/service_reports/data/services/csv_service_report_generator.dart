import 'dart:convert';
import 'dart:typed_data';

import 'package:mentorride/features/service_reports/domain/models/service_report.dart';
import 'package:mentorride/features/service_reports/domain/services/service_report_document_generator.dart';

class CsvServiceReportGenerator implements ServiceReportDocumentGenerator {
  static const _headers = <String>[
    'tanggal_servis',
    'kilometer',
    'bengkel',
    'komponen',
    'jenis_tindakan',
    'biaya',
    'total_transaksi',
    'catatan',
  ];

  @override
  ServiceReportFormat get format => ServiceReportFormat.csv;

  @override
  Future<Uint8List> generate(ServiceReportData report) async {
    return serialize(report);
  }

  Uint8List serialize(ServiceReportData report) {
    final rows = <List<Object?>>[_headers];
    for (final transaction in report.transactions) {
      final items = transaction.items;
      if (items.isEmpty) {
        rows.add(_rowFor(transaction));
        continue;
      }

      for (final item in items) {
        rows.add(_rowFor(transaction, item: item));
      }
    }

    final csv = rows.map(_encodeRow).join('\r\n');
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode('$csv\r\n')]);
  }

  List<Object?> _rowFor(
    ServiceReportTransaction transaction, {
    ServiceReportItem? item,
  }) {
    return [
      _dateStamp(transaction.serviceDate),
      transaction.odometer,
      transaction.workshop,
      item?.component ?? '',
      item?.action ?? '',
      item?.cost ?? 0,
      transaction.totalCost,
      transaction.notes,
    ];
  }

  String _encodeRow(List<Object?> values) {
    return values.map(_encodeField).join(',');
  }

  String _encodeField(Object? value) {
    final text = value?.toString() ?? '';
    if (!text.contains(RegExp('[,"\r\n]'))) return text;
    return '"${text.replaceAll('"', '""')}"';
  }

  String _dateStamp(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
