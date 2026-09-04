import 'dart:io';
import 'dart:typed_data';

import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/features/service_reports/domain/models/service_report.dart';
import 'package:mentorride/features/service_reports/domain/services/service_report_document_generator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfServiceReportGenerator implements ServiceReportDocumentGenerator {
  static const _primaryColor = PdfColor.fromInt(0xff2563eb);
  static const _lightBackground = PdfColor.fromInt(0xffeff6ff);

  Future<pw.ThemeData>? _theme;

  @override
  ServiceReportFormat get format => ServiceReportFormat.pdf;

  @override
  Future<Uint8List> generate(ServiceReportData report) async {
    final theme = await (_theme ??= _loadLocalFontTheme());
    final document = pw.Document(
      title: 'Laporan servis ${report.vehicle.name}',
      author: 'MentorRide',
      creator: 'MentorRide',
      subject: 'Riwayat servis kendaraan',
      theme: theme,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(28, 30, 28, 26),
        maxPages: 200,
        footer: (context) => _footer(context, report.generatedAt),
        build: (context) => [
          _header(report),
          pw.SizedBox(height: 18),
          _vehicleInformation(report.vehicle),
          pw.SizedBox(height: 14),
          _summary(report.summary),
          pw.SizedBox(height: 18),
          pw.Text(
            'Riwayat servis',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (report.transactions.isEmpty)
            _emptyState()
          else
            _serviceTable(report.transactions),
        ],
      ),
    );

    return document.save();
  }

  Future<pw.ThemeData> _loadLocalFontTheme() async {
    final regular = await _firstAvailableFont(_regularFontCandidates);
    if (regular == null) {
      throw StateError(
        'Font Unicode lokal tidak tersedia untuk membuat laporan PDF.',
      );
    }
    final bold = await _firstAvailableFont(_boldFontCandidates) ?? regular;
    final fallback = await _firstAvailableFont(_fallbackFontCandidates);

    return pw.ThemeData.withFont(
      base: pw.Font.ttf(regular.data),
      bold: pw.Font.ttf(bold.data),
      italic: pw.Font.ttf(regular.data),
      boldItalic: pw.Font.ttf(bold.data),
      fontFallback: [
        if (fallback != null && fallback.path != regular.path)
          pw.Font.ttf(fallback.data),
      ],
    );
  }

  Future<_LocalFontData?> _firstAvailableFont(
    Iterable<String> candidates,
  ) async {
    for (final path in candidates) {
      final file = File(path);
      try {
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          return _LocalFontData(path, ByteData.sublistView(bytes));
        }
      } on FileSystemException {
        // Beberapa vendor membatasi font tertentu; lanjutkan ke kandidat lain.
      }
    }
    return null;
  }

  pw.Widget _header(ServiceReportData report) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 8,
          height: 42,
          decoration: const pw.BoxDecoration(
            color: _primaryColor,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MentorRide',
                style: pw.TextStyle(
                  color: _primaryColor,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Laporan riwayat servis kendaraan',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
        pw.Text(
          'Dibuat ${AppFormatters.date(report.generatedAt)}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _vehicleInformation(ServiceReportVehicle vehicle) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: _lightBackground,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _informationLine('Nama kendaraan', vehicle.name),
                _informationLine('Merek', vehicle.brand),
                _informationLine('Model', vehicle.model),
              ],
            ),
          ),
          pw.SizedBox(width: 24),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _informationLine('Tahun', vehicle.year.toString()),
                _informationLine('Nomor polisi', vehicle.plateNumber),
                _informationLine(
                  'Kilometer saat ini',
                  AppFormatters.kilometer(vehicle.currentOdometer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _informationLine(String label, String value) {
    final displayValue = value.trim().isEmpty ? '-' : value.trim();
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 105,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              displayValue,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _summary(ServiceReportSummary summary) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _summaryItem('Jumlah servis', summary.serviceCount.toString()),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _summaryItem(
            'Total biaya perawatan',
            AppFormatters.rupiah(summary.totalCost),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(child: _summaryItem('Periode data', _period(summary))),
      ],
    );
  }

  pw.Widget _summaryItem(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _serviceTable(List<ServiceReportTransaction> transactions) {
    return pw.TableHelper.fromTextArray(
      headers: const [
        'Tanggal',
        'Kilometer',
        'Bengkel',
        'Komponen / tindakan',
        'Total biaya',
        'Catatan singkat',
      ],
      data: transactions
          .map(
            (transaction) => [
              AppFormatters.date(transaction.serviceDate),
              AppFormatters.kilometer(transaction.odometer),
              _fallback(transaction.workshop),
              _itemsDescription(transaction.items),
              AppFormatters.rupiah(transaction.totalCost),
              _shorten(_fallback(transaction.notes), 220),
            ],
          )
          .toList(growable: false),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
      headerDecoration: const pw.BoxDecoration(color: _primaryColor),
      headerAlignment: pw.Alignment.centerLeft,
      cellStyle: const pw.TextStyle(fontSize: 7.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.9),
        1: pw.FlexColumnWidth(0.85),
        2: pw.FlexColumnWidth(1.25),
        3: pw.FlexColumnWidth(2.25),
        4: pw.FlexColumnWidth(1.05),
        5: pw.FlexColumnWidth(1.8),
      },
    );
  }

  pw.Widget _emptyState() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Text(
        'Belum ada riwayat servis untuk kendaraan ini.',
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      ),
    );
  }

  pw.Widget _footer(pw.Context context, DateTime generatedAt) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'MentorRide - ${AppFormatters.dateTime(generatedAt)}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  String _period(ServiceReportSummary summary) {
    final start = summary.periodStart;
    final end = summary.periodEnd;
    if (start == null || end == null) return 'Belum ada data';
    if (_isSameDay(start, end)) return AppFormatters.date(start);
    return '${AppFormatters.date(start)} - ${AppFormatters.date(end)}';
  }

  String _itemsDescription(List<ServiceReportItem> items) {
    if (items.isEmpty) return '-';
    final description = items
        .map((item) => '${_fallback(item.component)} (${item.action})')
        .join('\n');
    return _shorten(description, 320);
  }

  String _fallback(String value) {
    final compact = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return compact.isEmpty ? '-' : compact;
  }

  String _shorten(String value, int maximumLength) {
    if (value.length <= maximumLength) return value;
    return '${value.substring(0, maximumLength - 3).trimRight()}...';
  }

  bool _isSameDay(DateTime left, DateTime right) {
    final localLeft = left.toLocal();
    final localRight = right.toLocal();
    return localLeft.year == localRight.year &&
        localLeft.month == localRight.month &&
        localLeft.day == localRight.day;
  }
}

class _LocalFontData {
  const _LocalFontData(this.path, this.data);

  final String path;
  final ByteData data;
}

const _regularFontCandidates = <String>[
  '/system/fonts/RobotoStatic-Regular.ttf',
  '/system/fonts/Roboto-Regular.ttf',
  '/system/fonts/NotoSans-Regular.ttf',
  'C:/Windows/Fonts/arial.ttf',
  'C:/Windows/Fonts/segoeui.ttf',
  '/System/Library/Fonts/Supplemental/Arial.ttf',
  '/Library/Fonts/Arial.ttf',
  '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
  '/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf',
];

const _boldFontCandidates = <String>[
  '/system/fonts/RobotoStatic-Bold.ttf',
  '/system/fonts/Roboto-Bold.ttf',
  '/system/fonts/NotoSans-Bold.ttf',
  'C:/Windows/Fonts/arialbd.ttf',
  'C:/Windows/Fonts/segoeuib.ttf',
  '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
  '/Library/Fonts/Arial Bold.ttf',
  '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
  '/usr/share/fonts/truetype/liberation2/LiberationSans-Bold.ttf',
];

const _fallbackFontCandidates = <String>[
  '/system/fonts/NotoSansSymbols2-Regular.ttf',
  '/system/fonts/NotoSansSymbols-Regular-Subsetted.ttf',
  '/system/fonts/NotoSansSymbols-Regular.ttf',
  'C:/Windows/Fonts/seguisym.ttf',
  '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
];
