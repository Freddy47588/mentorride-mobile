import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/firebase/firebase_providers.dart';
import 'package:mentorride/features/auth/providers/auth_providers.dart';
import 'package:mentorride/features/service_records/data/repositories/firestore_service_record_repository.dart';
import 'package:mentorride/features/service_records/domain/models/maintenance_statistics.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_records/domain/models/service_record_filter.dart';
import 'package:mentorride/features/service_records/domain/repositories/service_record_repository.dart';
import 'package:mentorride/features/service_records/domain/services/maintenance_statistics_calculator.dart';
import 'package:mentorride/features/service_records/domain/services/service_record_query.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';

export 'package:mentorride/features/service_records/domain/models/service_record_filter.dart';

enum ServiceRecordViewMode { list, timeline }

final serviceRecordViewModeProvider =
    NotifierProvider<ServiceRecordViewModeController, ServiceRecordViewMode>(
      ServiceRecordViewModeController.new,
    );

class ServiceRecordViewModeController extends Notifier<ServiceRecordViewMode> {
  @override
  ServiceRecordViewMode build() => ServiceRecordViewMode.list;

  void select(ServiceRecordViewMode value) => state = value;
}

final serviceRecordRepositoryProvider = Provider<ServiceRecordRepository>((
  ref,
) {
  return FirestoreServiceRecordRepository(ref.watch(firestoreProvider));
});

class ActiveServiceRecordScope {
  const ActiveServiceRecordScope({required this.uid, required this.vehicleId});

  final String uid;
  final String vehicleId;
}

final activeServiceRecordScopeProvider = Provider<ActiveServiceRecordScope?>((
  ref,
) {
  final uid = ref.watch(authSessionProvider).value?.uid;
  final vehicleId = ref.watch(activeVehicleProvider).value?.id;
  if (uid == null || vehicleId == null) return null;
  return ActiveServiceRecordScope(uid: uid, vehicleId: vehicleId);
});

final serviceRecordsProvider = StreamProvider<List<ServiceRecord>>((ref) {
  final scope = ref.watch(activeServiceRecordScopeProvider);
  if (scope == null) return Stream.value(const <ServiceRecord>[]);

  return ref
      .watch(serviceRecordRepositoryProvider)
      .watchServiceRecords(uid: scope.uid, vehicleId: scope.vehicleId);
});

final serviceRecordByIdProvider =
    Provider.family<AsyncValue<ServiceRecord?>, String>((ref, recordId) {
      return ref.watch(serviceRecordsProvider).whenData((records) {
        for (final record in records) {
          if (record.id == recordId) return record;
        }
        return null;
      });
    });

final serviceRecordFilterProvider =
    NotifierProvider<ServiceRecordFilterController, ServiceRecordFilter>(
      ServiceRecordFilterController.new,
    );

class ServiceRecordFilterController extends Notifier<ServiceRecordFilter> {
  @override
  ServiceRecordFilter build() {
    return ServiceRecordFilter(
      type: ServiceRecordFilterType.all,
      anchor: DateTime.now(),
    );
  }

  void selectType(ServiceRecordFilterType type) {
    state = state.copyWith(type: type);
  }

  void selectAnchor(DateTime anchor) {
    state = state.copyWith(anchor: anchor);
  }

  void updateQuery(String query) {
    state = state.copyWith(query: query);
  }

  void updateCostRange({int? minimumCost, int? maximumCost}) {
    state = state.copyWith(
      minimumCost: minimumCost,
      maximumCost: maximumCost,
      clearMinimumCost: minimumCost == null,
      clearMaximumCost: maximumCost == null,
    );
  }

  void clearCostRange() {
    state = state.copyWith(clearMinimumCost: true, clearMaximumCost: true);
  }

  void reset() {
    state = ServiceRecordFilter(
      type: ServiceRecordFilterType.all,
      anchor: DateTime.now(),
    );
  }
}

final filteredServiceRecordsProvider =
    Provider<AsyncValue<List<ServiceRecord>>>((ref) {
      final filter = ref.watch(serviceRecordFilterProvider);
      return ref.watch(serviceRecordsProvider).whenData((records) {
        return ServiceRecordQuery.apply(records: records, filter: filter);
      });
    });

final maintenanceStatisticsProvider =
    Provider<AsyncValue<MaintenanceStatistics>>((ref) {
      return ref
          .watch(serviceRecordsProvider)
          .whenData(MaintenanceStatisticsCalculator.calculate);
    });

final filteredMaintenanceStatisticsProvider =
    Provider<AsyncValue<MaintenanceStatistics>>((ref) {
      return ref
          .watch(filteredServiceRecordsProvider)
          .whenData(MaintenanceStatisticsCalculator.calculate);
    });
