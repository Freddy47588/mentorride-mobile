import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/features/auth/domain/models/user_profile.dart';
import 'package:mentorride/features/service_records/domain/models/service_action.dart';
import 'package:mentorride/features/service_records/domain/models/service_item.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

void main() {
  group('Vehicle', () {
    test('melakukan serialisasi dengan timestamp null', () {
      final vehicle = Vehicle.fromMap({
        'id': 'vehicle-1',
        'name': 'Motor Harian',
        'brand': 'Honda',
        'model': 'Vario',
        'year': '2022',
        'plateNumber': 'B 1234 XYZ',
        'currentOdometer': 12500.9,
        'createdAt': null,
        'updatedAt': null,
      });

      expect(vehicle.id, 'vehicle-1');
      expect(vehicle.year, 2022);
      expect(vehicle.currentOdometer, 12500);
      expect(vehicle.createdAt, isNull);
      expect(vehicle.updatedAt, isNull);
      expect(vehicle.toMap(), {
        'name': 'Motor Harian',
        'brand': 'Honda',
        'model': 'Vario',
        'year': 2022,
        'plateNumber': 'B 1234 XYZ',
        'currentOdometer': 12500,
        'isArchived': false,
        'createdAt': null,
        'updatedAt': null,
      });
      expect(vehicle.toMap().containsKey('id'), isFalse);
    });

    test('copyWith mengganti field terpilih dan mempertahankan lainnya', () {
      const original = Vehicle(
        id: 'vehicle-1',
        name: 'Motor Harian',
        brand: 'Honda',
        model: 'Vario',
        year: 2022,
        plateNumber: 'B 1234 XYZ',
        currentOdometer: 12500,
      );

      final copied = original.copyWith(name: 'Motor Touring', year: 2023);

      expect(copied.id, original.id);
      expect(copied.name, 'Motor Touring');
      expect(copied.year, 2023);
      expect(copied.brand, original.brand);
      expect(copied.createdAt, isNull);
    });
  });

  group('ServiceItem', () {
    test('melakukan serialisasi dan copyWith', () {
      final item = ServiceItem.fromMap({
        'name': 'Oli mesin',
        'action': 'ganti',
        'cost': '125000',
      });

      expect(item.name, 'Oli mesin');
      expect(item.action, ServiceAction.ganti);
      expect(item.cost, 125000);
      expect(item.toMap(), {
        'name': 'Oli mesin',
        'action': 'ganti',
        'cost': 125000,
      });

      final copied = item.copyWith(action: ServiceAction.periksa, cost: 0);
      expect(copied.name, item.name);
      expect(copied.action, ServiceAction.periksa);
      expect(copied.cost, 0);
    });
  });

  group('ServiceRecord', () {
    test('menghitung total biaya dan melakukan serialisasi', () {
      final record = ServiceRecord.fromMap({
        'id': 'record-1',
        'serviceDate': '2026-08-10T09:00:00.000',
        'odometer': '15000',
        'workshop': 'Bengkel Mentor',
        'items': [
          {'name': 'Oli mesin', 'action': 'ganti', 'cost': '125000'},
          {'name': 'Tune up', 'action': 'servis', 'cost': 75000.9},
        ],
        'notes': 'Servis rutin',
        'createdAt': null,
        'updatedAt': null,
      });

      expect(record.id, 'record-1');
      expect(record.serviceDate, DateTime(2026, 8, 10, 9));
      expect(record.odometer, 15000);
      expect(record.items, hasLength(2));
      expect(record.totalCost, 200000);
      expect(record.createdAt, isNull);
      expect(record.updatedAt, isNull);

      final serialized = record.toMap();
      expect(serialized['totalCost'], 200000);
      expect(serialized['createdAt'], isNull);
      expect(serialized['updatedAt'], isNull);
      expect(serialized['items'], [
        {'name': 'Oli mesin', 'action': 'ganti', 'cost': 125000},
        {'name': 'Tune up', 'action': 'servis', 'cost': 75000},
      ]);
      expect(serialized.containsKey('id'), isFalse);
    });

    test('copyWith memperbarui item dan menghitung ulang total', () {
      final original = ServiceRecord(
        id: 'record-1',
        serviceDate: DateTime(2026, 8, 10),
        odometer: 15000,
        workshop: 'Bengkel Mentor',
        items: const [
          ServiceItem(
            name: 'Oli mesin',
            action: ServiceAction.ganti,
            cost: 125000,
          ),
        ],
        notes: '',
      );

      final copied = original.copyWith(
        items: const [
          ServiceItem(
            name: 'Kampas rem',
            action: ServiceAction.ganti,
            cost: 200000,
          ),
        ],
        notes: 'Rem depan',
      );

      expect(copied.id, original.id);
      expect(copied.workshop, original.workshop);
      expect(copied.notes, 'Rem depan');
      expect(copied.totalCost, 200000);
      expect(copied.createdAt, isNull);
    });
  });

  group('ServiceSchedule', () {
    test('melakukan serialisasi termasuk timestamp null', () {
      final schedule = ServiceSchedule.fromMap({
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'title': 'Servis berkala',
        'serviceType': 'Ganti oli',
        'dueDate': '2026-09-01T08:00:00.000',
        'dueOdometer': '18000',
        'reminderAt': '2026-08-30T08:00:00.000',
        'reminderEnabled': true,
        'localNotificationId': 123.9,
        'status': 'completed',
        'createdAt': null,
        'updatedAt': null,
      });

      expect(schedule.dueDate, DateTime(2026, 9, 1, 8));
      expect(schedule.dueOdometer, 18000);
      expect(schedule.localNotificationId, 123);
      expect(schedule.status, ServiceScheduleStatus.completed);
      expect(schedule.isCompleted, isTrue);
      expect(schedule.createdAt, isNull);
      expect(schedule.updatedAt, isNull);
      expect(schedule.toMap(), {
        'title': 'Servis berkala',
        'serviceType': 'Ganti oli',
        'dueDate': DateTime(2026, 9, 1, 8),
        'dueOdometer': 18000,
        'reminderAt': DateTime(2026, 8, 30, 8),
        'reminderEnabled': true,
        'localNotificationId': 123,
        'status': 'completed',
        'createdAt': null,
        'updatedAt': null,
      });
    });

    test('copyWith dapat membersihkan odometer jatuh tempo', () {
      final original = ServiceSchedule(
        id: '550e8400-e29b-41d4-a716-446655440000',
        title: 'Servis berkala',
        serviceType: 'Ganti oli',
        dueDate: DateTime(2026, 9),
        dueOdometer: 18000,
        reminderAt: DateTime(2026, 8, 30),
        reminderEnabled: true,
        localNotificationId: 123,
        status: ServiceScheduleStatus.pending,
      );

      final copied = original.copyWith(
        clearDueOdometer: true,
        reminderEnabled: false,
        status: ServiceScheduleStatus.completed,
      );

      expect(copied.id, original.id);
      expect(copied.title, original.title);
      expect(copied.dueOdometer, isNull);
      expect(copied.reminderEnabled, isFalse);
      expect(copied.isCompleted, isTrue);
      expect(copied.createdAt, isNull);
    });
  });

  group('UserProfile', () {
    test('melakukan serialisasi dengan timestamp null', () {
      final profile = UserProfile.fromMap({
        'uid': 'user-1',
        'displayName': 'Mentor Rider',
        'email': 'rider@mentorride.id',
        'createdAt': null,
        'updatedAt': null,
      });

      expect(profile.createdAt, isNull);
      expect(profile.updatedAt, isNull);
      expect(profile.toMap(), {
        'uid': 'user-1',
        'displayName': 'Mentor Rider',
        'email': 'rider@mentorride.id',
        'createdAt': null,
        'updatedAt': null,
      });
    });

    test('copyWith memperbarui profil tanpa mengubah identitas', () {
      const profile = UserProfile(
        uid: 'user-1',
        displayName: 'Mentor Rider',
        email: 'rider@mentorride.id',
      );

      final copied = profile.copyWith(displayName: 'Rider Baru');

      expect(copied.uid, profile.uid);
      expect(copied.email, profile.email);
      expect(copied.displayName, 'Rider Baru');
      expect(copied.createdAt, isNull);
      expect(copied.updatedAt, isNull);
    });
  });
}
