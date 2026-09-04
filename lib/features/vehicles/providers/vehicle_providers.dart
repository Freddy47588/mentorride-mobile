import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/storage/active_vehicle_store.dart';
import 'package:mentorride/features/auth/providers/auth_providers.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/vehicles/presentation/controllers/vehicle_controller.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_repository_provider.dart';
import 'package:mentorride/features/vehicles/domain/services/active_vehicle_selector.dart';

export 'package:mentorride/features/vehicles/providers/vehicle_repository_provider.dart';

final vehiclesProvider = StreamProvider<List<Vehicle>>((ref) {
  final session = ref.watch(authSessionProvider).value;
  if (session == null) return Stream.value(const <Vehicle>[]);

  return ref
      .watch(vehicleRepositoryProvider)
      .watchVehicles(session.uid)
      .map(
        (vehicles) => vehicles
            .where((vehicle) => !vehicle.isArchived)
            .toList(growable: false),
      );
});

final archivedVehiclesProvider = StreamProvider<List<Vehicle>>((ref) {
  final session = ref.watch(authSessionProvider).value;
  if (session == null) return Stream.value(const <Vehicle>[]);
  return ref
      .watch(vehicleRepositoryProvider)
      .watchVehicles(session.uid)
      .map(
        (vehicles) => vehicles
            .where((vehicle) => vehicle.isArchived)
            .toList(growable: false),
      );
});

final vehicleListProvider = vehiclesProvider;

final vehicleDetailProvider = StreamProvider.family<Vehicle?, String>((
  ref,
  vehicleId,
) {
  final session = ref.watch(authSessionProvider).value;
  if (session == null || vehicleId.isEmpty) return Stream.value(null);

  return ref
      .watch(vehicleRepositoryProvider)
      .watchVehicle(session.uid, vehicleId);
});

final vehicleByIdProvider = vehicleDetailProvider;

final activeVehicleProvider =
    AsyncNotifierProvider<ActiveVehicleController, Vehicle?>(
      ActiveVehicleController.new,
    );

final activeVehicleIdProvider = Provider<String?>((ref) {
  final activeVehicle = ref.watch(activeVehicleProvider);
  if (activeVehicle.isLoading || activeVehicle.hasError) return null;
  return activeVehicle.value?.id;
});

final vehicleControllerProvider =
    NotifierProvider<VehicleController, VehicleActionState>(
      VehicleController.new,
    );

class ActiveVehicleController extends AsyncNotifier<Vehicle?> {
  @override
  Future<Vehicle?> build() async {
    final session = ref.watch(authSessionProvider).value;
    if (session == null) return null;

    final vehicles = await ref.watch(vehiclesProvider.future);

    final store = ref.watch(activeVehicleStoreProvider);
    final storedId = await store.read(session.uid);
    final selected = ActiveVehicleSelector.select(vehicles, storedId);

    if (selected == null) {
      if (storedId != null) await store.clear(session.uid);
      return null;
    }

    if (storedId != selected.id) {
      await store.write(session.uid, selected.id);
    }
    return selected;
  }

  Future<bool> selectVehicle(String vehicleId) async {
    if (vehicleId.isEmpty) return false;

    final session = ref.read(authSessionProvider).value;
    if (session == null) return false;

    final vehiclesValue = ref.read(vehiclesProvider);
    final vehicles =
        vehiclesValue.value ??
        await ref.read(vehiclesProvider.future) ??
        const <Vehicle>[];
    final selected = ActiveVehicleSelector.select(
      vehicles.where((vehicle) => vehicle.id == vehicleId).toList(),
      vehicleId,
    );
    if (selected == null) return false;

    state = const AsyncLoading<Vehicle?>();
    try {
      await ref
          .read(activeVehicleStoreProvider)
          .write(session.uid, selected.id);
      state = AsyncData(selected);
      return true;
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}
