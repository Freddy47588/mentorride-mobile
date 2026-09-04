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
    final rawPlateNumber = _sanitizePlate(vehicle.plateNumber);
    final plateNumber = rawPlateNumber.length <= 24
        ? rawPlateNumber
        : rawPlateNumber.substring(0, 24);
    final date = _dateStamp(report.generatedAt);
    final fixedSegments = [
      'mentorride',
      if (plateNumber.isNotEmpty) plateNumber,
      date,
    ];
    final fixedName = fixedSegments.join('_');
    final availableVehicleLength = 120 - fixedName.length - 1;
    final safeVehicleName = vehicleName.length <= availableVehicleLength
        ? vehicleName
        : vehicleName
              .substring(0, availableVehicleLength)
              .replaceFirst(RegExp(r'_+$'), '');
    final baseName = [
      'mentorride',
      if (safeVehicleName.isNotEmpty) safeVehicleName,
      if (plateNumber.isNotEmpty) plateNumber,
      date,
    ].join('_');
    return '$baseName.${format.extension}';
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
