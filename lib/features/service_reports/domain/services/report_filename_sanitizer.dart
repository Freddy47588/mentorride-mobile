import 'package:mentorride/features/service_reports/domain/models/service_report.dart';

abstract final class ReportFilenameSanitizer {
  static String build({
    required ServiceReportData report,
    required ServiceReportFormat format,
  }) {
    final vehicle = report.vehicle;
    final vehicleSegments = <String>[
      if (vehicle.brand.trim().isNotEmpty) vehicle.brand,
      if (vehicle.model.trim().isNotEmpty) vehicle.model,
      if (vehicle.brand.trim().isEmpty && vehicle.model.trim().isEmpty)
        vehicle.name,
    ];
    final vehicleName = sanitizeSegment(vehicleSegments.join(' '));
    final plateNumber = _sanitizePlate(vehicle.plateNumber);
    final date = _dateStamp(report.generatedAt);

    final baseName = [
      'mentorride',
      if (vehicleName.isNotEmpty) vehicleName,
      if (plateNumber.isNotEmpty) plateNumber,
      date,
    ].join('_');
    final safeBaseName = baseName.length <= 120
        ? baseName
        : baseName.substring(0, 120).replaceFirst(RegExp(r'_+$'), '');
    return '$safeBaseName.${format.extension}';
  }

  static String sanitizeSegment(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static String _sanitizePlate(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static String _dateStamp(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
