import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

abstract interface class VehicleRepository {
  Stream<List<Vehicle>> watchVehicles(String uid);

  Stream<Vehicle?> watchVehicle(String uid, String vehicleId);

  Future<Vehicle> createVehicle(String uid, Vehicle vehicle);

  Future<void> updateVehicle(String uid, Vehicle vehicle);

  Future<List<int>> reminderIdsForVehicle(String uid, String vehicleId);

  Future<void> deleteCascade(String uid, String vehicleId);
}
