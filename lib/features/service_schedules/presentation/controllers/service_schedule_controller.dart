import 'package:mentorride/core/errors/app_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/features/service_schedules/application/service_schedule_coordinator.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/providers/service_schedule_providers.dart';

class ServiceScheduleActionState {
  const ServiceScheduleActionState({
    this.isSubmitting = false,
    this.errorMessage,
  });

  final bool isSubmitting;
  final String? errorMessage;
}

class ServiceScheduleController extends Notifier<ServiceScheduleActionState> {
  late final ServiceScheduleCoordinator _coordinator;

  @override
  ServiceScheduleActionState build() {
    _coordinator = ref.watch(serviceScheduleCoordinatorProvider);
    return const ServiceScheduleActionState();
  }

  Future<ServiceSchedule?> create(ServiceSchedule schedule) async {
    final scope = _scopeOrReportError();
    if (scope == null || state.isSubmitting) return null;

    state = const ServiceScheduleActionState(isSubmitting: true);
    try {
      final created = await _coordinator.create(
        uid: scope.uid,
        vehicleId: scope.vehicleId,
        schedule: schedule,
      );
      state = const ServiceScheduleActionState();
      return created;
    } on Object catch (error) {
      _reportError(error);
      return null;
    }
  }

  Future<bool> update(
    ServiceSchedule schedule, {
    ServiceSchedule? previousSchedule,
  }) {
    return _run(
      (scope) => _coordinator.update(
        uid: scope.uid,
        vehicleId: scope.vehicleId,
        schedule: schedule,
        previousSchedule: previousSchedule,
      ),
    );
  }

  Future<bool> delete(ServiceSchedule schedule) {
    return _run(
      (scope) => _coordinator.delete(
        uid: scope.uid,
        vehicleId: scope.vehicleId,
        schedule: schedule,
      ),
    );
  }

  Future<bool> complete(ServiceSchedule schedule) {
    return _run((scope) async {
      await _coordinator.complete(
        uid: scope.uid,
        vehicleId: scope.vehicleId,
        schedule: schedule,
      );
    });
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = const ServiceScheduleActionState();
    }
  }

  Future<bool> _run(
    Future<void> Function(ActiveServiceScheduleScope scope) operation,
  ) async {
    final scope = _scopeOrReportError();
    if (scope == null || state.isSubmitting) return false;

    state = const ServiceScheduleActionState(isSubmitting: true);
    try {
      await operation(scope);
      state = const ServiceScheduleActionState();
      return true;
    } on Object catch (error) {
      _reportError(error);
      return false;
    }
  }

  ActiveServiceScheduleScope? _scopeOrReportError() {
    final scope = ref.read(activeServiceScheduleScopeProvider);
    if (scope != null) return scope;
    state = const ServiceScheduleActionState(
      errorMessage: 'Sesi atau kendaraan aktif tidak tersedia.',
    );
    return null;
  }

  void _reportError(Object error) {
    state = ServiceScheduleActionState(
      errorMessage: error is AppException
          ? error.message
          : 'Jadwal servis belum dapat disimpan. Silakan coba lagi.',
    );
  }
}
