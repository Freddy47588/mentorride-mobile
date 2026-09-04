import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mentorride/features/dashboard/domain/models/dashboard_summary.dart';
import 'package:mentorride/features/dashboard/presentation/widgets/dashboard_overview.dart';
import 'package:mentorride/features/service_records/providers/service_record_providers.dart';
import 'package:mentorride/features/service_schedules/providers/service_schedule_providers.dart';
import 'package:mentorride/features/maintenance_health/domain/services/maintenance_health_calculator.dart';
import 'package:mentorride/app/router/app_routes.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:mentorride/features/vehicles/presentation/widgets/quick_odometer_update_dialog.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';
import 'package:mentorride/shared/widgets/empty_state.dart';
import 'package:mentorride/shared/widgets/error_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({this.now, super.key});

  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            tooltip: 'Kelola kendaraan',
            onPressed: () => context.push('/vehicles'),
            icon: const Icon(Icons.two_wheeler_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: activeVehicle.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorState(
          message: 'Kendaraan aktif belum dapat dimuat.',
          onRetry: () => ref.invalidate(activeVehicleProvider),
        ),
        data: (vehicle) {
          if (vehicle == null) {
            return _NoVehicleDashboard(onRefresh: () => _refreshVehicle(ref));
          }
          return _DashboardData(vehicle: vehicle, now: now ?? DateTime.now());
        },
      ),
    );
  }

  Future<void> _refreshVehicle(WidgetRef ref) async {
    ref.invalidate(activeVehicleProvider);
    await ref.read(activeVehicleProvider.future);
  }
}

class _DashboardData extends ConsumerWidget {
  const _DashboardData({required this.vehicle, required this.now});

  final Vehicle vehicle;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsValue = ref.watch(serviceRecordsProvider);
    final schedulesValue = ref.watch(serviceSchedulesProvider);

    if (recordsValue.hasError) {
      return ErrorState(
        message: 'Ringkasan riwayat servis belum dapat dimuat.',
        onRetry: () => ref.invalidate(serviceRecordsProvider),
      );
    }
    if (schedulesValue.hasError) {
      return ErrorState(
        message: 'Ringkasan jadwal servis belum dapat dimuat.',
        onRetry: () => ref.invalidate(serviceSchedulesProvider),
      );
    }

    final records = recordsValue.value;
    final schedules = schedulesValue.value;
    if (records == null || schedules == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = DashboardAggregator.aggregate(
      activeVehicle: vehicle,
      serviceRecords: records,
      serviceSchedules: schedules,
      now: now,
    );
    final healthSummary = MaintenanceHealthCalculator.calculate(
      records: records,
      schedules: schedules,
      currentOdometer: vehicle.currentOdometer,
      now: now,
    );
    return DashboardOverview(
      summary: summary,
      healthSummary: healthSummary,
      now: now,
      onRefresh: () => _refreshDashboard(ref),
      onManageVehicles: () => context.push('/vehicles'),
      onAddService: () => context.push('/history/new'),
      onAddSchedule: () => context.push('/schedules/new'),
      onUpdateOdometer: () => _updateOdometer(context, vehicle),
      onViewMaintenanceHealth: () => context.push(AppRoutes.maintenanceHealth),
    );
  }

  Future<void> _refreshDashboard(WidgetRef ref) async {
    ref.invalidate(activeVehicleProvider);
    ref.invalidate(serviceRecordsProvider);
    ref.invalidate(serviceSchedulesProvider);
    await Future.wait([
      ref.read(activeVehicleProvider.future),
      ref.read(serviceRecordsProvider.future),
      ref.read(serviceSchedulesProvider.future),
    ]);
  }

  Future<void> _updateOdometer(BuildContext context, Vehicle vehicle) async {
    final result = await showQuickOdometerUpdateDialog(
      context: context,
      vehicle: vehicle,
    );
    if (!context.mounted || result == null) return;

    final message = switch (result) {
      VehicleOdometerUpdateResult.updated =>
        'Kilometer kendaraan berhasil diperbarui.',
      VehicleOdometerUpdateResult.unchanged =>
        'Kilometer kendaraan tidak berubah.',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _NoVehicleDashboard extends StatelessWidget {
  const _NoVehicleDashboard({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
          EmptyState(
            icon: Icons.two_wheeler_rounded,
            title: 'Tambahkan kendaraan pertama',
            message: 'Pilih kendaraan untuk mulai mencatat servis dan jadwal.',
            actionLabel: 'Tambah kendaraan',
            onAction: () => context.push('/vehicles/new'),
          ),
        ],
      ),
    );
  }
}
