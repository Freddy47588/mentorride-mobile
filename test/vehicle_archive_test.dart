import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/vehicles/domain/services/active_vehicle_selector.dart';

void main() {
  const active = Vehicle(
    id: 'active',
    name: 'Aktif',
    brand: 'Honda',
    model: 'Vario',
    year: 2024,
    plateNumber: 'B 1 A',
    currentOdometer: 1000,
  );
  const archived = Vehicle(
    id: 'archived',
    name: 'Arsip',
    brand: 'Yamaha',
    model: 'Nmax',
    year: 2023,
    plateNumber: 'B 2 B',
    currentOdometer: 2000,
    isArchived: true,
  );

  test('archive vehicle parsing default false dan explicit true', () {
    expect(Vehicle.fromMap(const {}).isArchived, isFalse);
    expect(Vehicle.fromMap(const {'isArchived': true}).isArchived, isTrue);
  });

  test('archived vehicle tidak menjadi active vehicle', () {
    expect(
      ActiveVehicleSelector.select([archived, active], 'archived'),
      active,
    );
    expect(ActiveVehicleSelector.select([archived], 'archived'), isNull);
  });

  test('restore archived vehicle', () {
    final restored = archived.copyWith(isArchived: false);
    expect(restored.isArchived, isFalse);
    expect(ActiveVehicleSelector.select([restored], restored.id), restored);
  });
}
