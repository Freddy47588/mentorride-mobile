import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/features/auth/domain/models/auth_session.dart';
import 'package:mentorride/features/auth/providers/auth_providers.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:mentorride/features/vehicles/presentation/widgets/quick_odometer_update_dialog.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';

void main() {
  test(
    'VehicleController memakai UID sesi dan mencegah submit ganda',
    () async {
      final repository = _DelayedVehicleRepository();
      final container = ProviderContainer(
        overrides: [
          vehicleRepositoryProvider.overrideWithValue(repository),
          authSessionProvider.overrideWithValue(
            const AsyncData(
              AuthSession(
                uid: 'session-user',
                email: 'rider@example.test',
                isEmailVerified: true,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(vehicleControllerProvider.notifier);

      final first = controller.updateOdometer(
        vehicleId: 'vehicle-1',
        odometer: 12500,
      );
      expect(container.read(vehicleControllerProvider).isSubmitting, isTrue);
      expect(repository.updateCalls, 1);
      expect(repository.lastUid, 'session-user');

      final second = await controller.updateOdometer(
        vehicleId: 'vehicle-1',
        odometer: 13000,
      );
      expect(second, isNull);
      expect(repository.updateCalls, 1);

      repository.completeUpdate(VehicleOdometerUpdateResult.updated);
      expect(await first, VehicleOdometerUpdateResult.updated);
      expect(container.read(vehicleControllerProvider).isSubmitting, isFalse);
    },
  );

  testWidgets('dialog melewati write yang sama dan menolak nilai lebih kecil', (
    tester,
  ) async {
    final repository = _DelayedVehicleRepository();
    const vehicle = Vehicle(
      id: 'vehicle-1',
      name: 'Motor harian',
      brand: 'Honda',
      model: 'Vario',
      year: 2024,
      plateNumber: 'B 1234 XYZ',
      currentOdometer: 12000,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [vehicleRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => showQuickOdometerUpdateDialog(
                  context: context,
                  vehicle: vehicle,
                ),
                child: const Text('Buka dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka dialog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(repository.updateCalls, 0);

    await tester.tap(find.text('Buka dialog'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '11999');
    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.textContaining('tidak boleh lebih kecil'), findsOneWidget);
    expect(repository.updateCalls, 0);
  });
}

class _DelayedVehicleRepository implements VehicleRepository {
  final Completer<VehicleOdometerUpdateResult> _updateCompleter =
      Completer<VehicleOdometerUpdateResult>();

  int updateCalls = 0;
  String? lastUid;

  void completeUpdate(VehicleOdometerUpdateResult result) {
    _updateCompleter.complete(result);
  }

  @override
  Future<VehicleOdometerUpdateResult> updateOdometer({
    required String uid,
    required String vehicleId,
    required int odometer,
  }) {
    updateCalls += 1;
    lastUid = uid;
    return _updateCompleter.future;
  }

  @override
  Future<Vehicle> createVehicle(String uid, Vehicle vehicle) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteCascade(String uid, String vehicleId) {
    throw UnimplementedError();
  }

  @override
  Future<List<int>> reminderIdsForVehicle(String uid, String vehicleId) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateVehicle(String uid, Vehicle vehicle) {
    throw UnimplementedError();
  }

  @override
  Stream<Vehicle?> watchVehicle(String uid, String vehicleId) {
    return const Stream.empty();
  }

  @override
  Stream<List<Vehicle>> watchVehicles(String uid) {
    return const Stream.empty();
  }
}
