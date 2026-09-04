import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/firebase/firebase_providers.dart';
import 'package:mentorride/features/auth/providers/auth_providers.dart';
import 'package:mentorride/features/odometer/data/repositories/firestore_odometer_log_repository.dart';
import 'package:mentorride/features/odometer/domain/models/odometer_log.dart';
import 'package:mentorride/features/odometer/domain/models/odometer_period.dart';
import 'package:mentorride/features/odometer/domain/repositories/odometer_log_repository.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';

final odometerLogRepositoryProvider = Provider<OdometerLogRepository>((ref) {
  return FirestoreOdometerLogRepository(ref.watch(firestoreProvider));
});

final odometerPeriodProvider =
    NotifierProvider<OdometerPeriodController, OdometerPeriod>(
      OdometerPeriodController.new,
    );

class OdometerPeriodController extends Notifier<OdometerPeriod> {
  @override
  OdometerPeriod build() => OdometerPeriod.thirtyDays;

  void select(OdometerPeriod period) => state = period;
}

final odometerLogsProvider = StreamProvider<List<OdometerLog>>((ref) {
  final uid = ref.watch(authSessionProvider).value?.uid;
  final vehicleId = ref.watch(activeVehicleIdProvider);
  if (uid == null || vehicleId == null) return Stream.value(const []);
  return ref
      .watch(odometerLogRepositoryProvider)
      .watchLogs(
        uid: uid,
        vehicleId: vehicleId,
        since: DateTime.now().subtract(const Duration(days: 365)),
      );
});
