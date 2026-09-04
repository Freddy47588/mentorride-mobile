import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';

enum VehicleOdometerUpdateResult { updated, unchanged }

abstract interface class VehicleRepository {
  Stream<List<Vehicle>> watchVehicles(String uid);

  Stream<Vehicle?> watchVehicle(String uid, String vehicleId);

  Future<Vehicle> createVehicle(String uid, Vehicle vehicle);

  Future<void> updateVehicle(String uid, Vehicle vehicle);

  Future<void> setArchived({
    required String uid,
    required String vehicleId,
    required bool isArchived,
  });

  Future<VehicleOdometerUpdateResult> updateOdometer({
    required String uid,
    required String vehicleId,
    required int odometer,
  });

  Future<List<int>> reminderIdsForVehicle(String uid, String vehicleId);

  Future<List<ServiceSchedule>> schedulesForVehicle(
    String uid,
    String vehicleId,
  );

  Future<void> deleteCascade(String uid, String vehicleId);
}
