import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

enum VehicleOdometerUpdateResult { updated, unchanged }

abstract interface class VehicleRepository {
  Stream<List<Vehicle>> watchVehicles(String uid);

  Stream<Vehicle?> watchVehicle(String uid, String vehicleId);

  Future<Vehicle> createVehicle(String uid, Vehicle vehicle);

  Future<void> updateVehicle(String uid, Vehicle vehicle);

  Future<VehicleOdometerUpdateResult> updateOdometer({
    required String uid,
    required String vehicleId,
    required int odometer,
  });

  Future<List<int>> reminderIdsForVehicle(String uid, String vehicleId);

  Future<void> deleteCascade(String uid, String vehicleId);
}
