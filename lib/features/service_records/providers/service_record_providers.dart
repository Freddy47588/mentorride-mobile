import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/firebase/firebase_providers.dart';
import 'package:mentorride/features/auth/providers/auth_providers.dart';
import 'package:mentorride/features/service_records/data/repositories/firestore_service_record_repository.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_records/domain/repositories/service_record_repository.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';

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

enum ServiceRecordFilterType { all, month, year }

class ServiceRecordFilter {
  const ServiceRecordFilter({required this.type, required this.anchor});

  final ServiceRecordFilterType type;
  final DateTime anchor;

  ServiceRecordFilter copyWith({
    ServiceRecordFilterType? type,
    DateTime? anchor,
  }) {
    return ServiceRecordFilter(
      type: type ?? this.type,
      anchor: anchor ?? this.anchor,
    );
  }
}

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
        return records
            .where((record) {
              final serviceDate = record.serviceDate.toLocal();
              return switch (filter.type) {
                ServiceRecordFilterType.all => true,
                ServiceRecordFilterType.month =>
                  serviceDate.year == filter.anchor.year &&
                      serviceDate.month == filter.anchor.month,
                ServiceRecordFilterType.year =>
                  serviceDate.year == filter.anchor.year,
              };
            })
            .toList(growable: false);
      });
    });
