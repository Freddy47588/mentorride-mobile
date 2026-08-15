import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/firebase/firebase_providers.dart';
import 'package:mentorride/features/vehicles/data/repositories/firestore_vehicle_repository.dart';
import 'package:mentorride/features/vehicles/data/services/vehicle_reminder_canceller.dart';
import 'package:mentorride/features/vehicles/domain/repositories/vehicle_repository.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return FirestoreVehicleRepository(firestore: ref.watch(firestoreProvider));
});

final vehicleReminderCancellerProvider = Provider<VehicleReminderCanceller>((
  ref,
) {
  return LocalVehicleReminderCanceller(FlutterLocalNotificationsPlugin());
});
