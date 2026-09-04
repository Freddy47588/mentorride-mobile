import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

abstract final class ActiveVehicleSelector {
  static Vehicle? select(List<Vehicle> vehicles, String? storedId) {
    final active = vehicles.where((vehicle) => !vehicle.isArchived).toList();
    if (storedId != null && storedId.isNotEmpty) {
      for (final vehicle in active) {
        if (vehicle.id == storedId) return vehicle;
      }
    }
    return active.firstOrNull;
  }
}
