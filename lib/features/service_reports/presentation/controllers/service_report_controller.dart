import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/errors/app_exception.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_records/providers/service_record_providers.dart';
import 'package:mentorride/features/service_reports/application/service_report_export_service.dart';
import 'package:mentorride/features/service_reports/domain/models/service_report.dart';
import 'package:mentorride/features/service_reports/providers/service_report_providers.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';

class ServiceReportExportState {
  const ServiceReportExportState({
    this.isExporting = false,
    this.activeFormat,
    this.lastExport,
    this.errorMessage,
  });

  final bool isExporting;
  final ServiceReportFormat? activeFormat;
  final ExportedServiceReport? lastExport;
  final String? errorMessage;
}

final serviceReportControllerProvider =
    NotifierProvider<ServiceReportController, ServiceReportExportState>(
      ServiceReportController.new,
    );

class ServiceReportController extends Notifier<ServiceReportExportState> {
  late final ServiceReportExportService _exportService;

  @override
  ServiceReportExportState build() {
    _exportService = ref.watch(serviceReportExportServiceProvider);
    return const ServiceReportExportState();
  }

  Future<ExportedServiceReport?> exportActiveVehicle(
    ServiceReportFormat format,
  ) async {
    final vehicleValue = ref.read(activeVehicleProvider);
    if (vehicleValue.isLoading) {
      state = const ServiceReportExportState(
        errorMessage: 'Tunggu hingga kendaraan aktif selesai dimuat.',
      );
      return null;
    }
    if (vehicleValue.hasError) {
      state = const ServiceReportExportState(
        errorMessage: 'Kendaraan aktif belum dapat dimuat.',
      );
      return null;
    }
    final vehicle = vehicleValue.value;
    if (vehicle == null) {
      state = const ServiceReportExportState(
        errorMessage: 'Pilih kendaraan sebelum mengekspor laporan.',
      );
      return null;
    }

    final scope = ref.read(activeServiceRecordScopeProvider);
    if (scope == null || scope.vehicleId != vehicle.id) {
      state = const ServiceReportExportState(
        errorMessage: 'Tunggu hingga riwayat kendaraan aktif siap.',
      );
      return null;
    }

    final recordsValue = ref.read(serviceRecordsProvider);
    if (recordsValue.isLoading) {
      state = const ServiceReportExportState(
        errorMessage: 'Tunggu hingga riwayat servis selesai dimuat.',
      );
      return null;
    }
    if (recordsValue.hasError) {
      state = const ServiceReportExportState(
        errorMessage: 'Riwayat servis belum dapat dimuat.',
      );
      return null;
    }
    final records = recordsValue.value;
    if (records == null) {
      state = const ServiceReportExportState(
        errorMessage: 'Tunggu hingga riwayat servis selesai dimuat.',
      );
      return null;
    }

    return exportAndShare(vehicle: vehicle, records: records, format: format);
  }

  Future<ExportedServiceReport?> exportAndShare({
    required Vehicle vehicle,
    required Iterable<ServiceRecord> records,
    required ServiceReportFormat format,
  }) async {
    if (state.isExporting) return null;

    state = ServiceReportExportState(isExporting: true, activeFormat: format);
    try {
      final result = await _exportService.exportAndShare(
        vehicle: vehicle,
        records: records,
        format: format,
      );
      state = ServiceReportExportState(lastExport: result);
      return result;
    } on Object catch (error) {
      state = ServiceReportExportState(
        errorMessage: userFacingErrorMessage(
          error,
          fallback:
              'Laporan belum dapat dibuat atau dibagikan. Silakan coba lagi.',
        ),
      );
      return null;
    }
  }

  void clearFeedback() {
    if (state.errorMessage != null || state.lastExport != null) {
      state = const ServiceReportExportState();
    }
  }
}
