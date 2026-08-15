import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mentorride/core/maintenance/maintenance_preset.dart';
import 'package:mentorride/features/service_records/presentation/screens/service_record_form_screen.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/presentation/navigation/service_schedule_prefill.dart';
import 'package:mentorride/features/service_schedules/presentation/screens/service_schedule_form_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('MaintenancePresets', () {
    test('menyediakan komponen lokal yang unik dan tindakan valid', () {
      final presets = MaintenancePresets.values;

      expect(presets, isNotEmpty);
      expect(
        presets.map((preset) => preset.componentName).toSet(),
        hasLength(presets.length),
      );
      expect(
        presets.map((preset) => preset.serviceType).toSet(),
        hasLength(presets.length),
      );
      expect(
        presets.map((preset) => preset.actionWireValue),
        everyElement(isIn(const ['periksa', 'servis', 'ganti'])),
      );
      expect(
        MaintenancePresets.serviceTypeSuggestions,
        presets.map((preset) => preset.componentName),
      );
      expect(presets.map((preset) => preset.componentName), const [
        'Oli mesin',
        'Oli gardan',
        'Busi',
        'Filter udara',
        'Kampas rem',
        'CVT',
        'V-belt',
        'Ban',
        'Aki',
        'Rantai dan gear',
        'Coolant',
        'Tune up',
      ]);
    });
  });

  testWidgets('form servis tetap mendukung nama komponen manual', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ServiceRecordFormScreen())),
    );

    expect(find.text('Item 1'), findsOneWidget);
    await tester.tap(find.text('Tambah manual'));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Item 2'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Item 2'), findsOneWidget);
    final secondItemCard = find.ancestor(
      of: find.text('Item 2'),
      matching: find.byType(Card),
    );
    final manualNameField = find.descendant(
      of: secondItemCard,
      matching: find.widgetWithText(TextFormField, 'Nama item'),
    );
    expect(manualNameField, findsOneWidget);
    await tester.enterText(manualNameField, 'Komponen buatan pengguna');
    expect(find.text('Komponen buatan pengguna'), findsOneWidget);
  });

  test('prefill jadwal berikutnya hanya membawa judul dan jenis servis', () {
    final source = ServiceSchedule(
      id: '550e8400-e29b-41d4-a716-446655440000',
      title: 'Servis berkala',
      serviceType: 'Ganti oli mesin',
      dueDate: DateTime(2026, 9, 1),
      dueOdometer: 18000,
      reminderAt: DateTime(2026, 8, 30, 9),
      reminderEnabled: true,
      localNotificationId: 123,
      status: ServiceScheduleStatus.completed,
    );

    final prefill = ServiceSchedulePrefill.fromSchedule(source);

    expect(prefill.title, source.title);
    expect(prefill.serviceType, source.serviceType);
  });

  testWidgets('form follow-up meminta tanggal dan pilihan pengingat baru', (
    tester,
  ) async {
    const prefill = ServiceSchedulePrefill(
      title: 'Servis berkala',
      serviceType: 'Ganti oli mesin',
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ServiceScheduleFormScreen(prefill: prefill)),
      ),
    );

    final titleField = tester.widget<TextFormField>(
      find.byKey(const Key('schedule_title_field')),
    );
    final serviceTypeField = tester.widget<TextFormField>(
      find.byKey(const Key('schedule_service_type_field')),
    );
    final dueOdometerField = tester.widget<TextFormField>(
      find.byKey(const Key('schedule_due_odometer_field')),
    );

    expect(titleField.controller?.text, prefill.title);
    expect(serviceTypeField.controller?.text, prefill.serviceType);
    expect(dueOdometerField.controller?.text, isEmpty);
    expect(find.text('Pilih tanggal'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );

    await tester.dragUntilVisible(
      find.text('Simpan jadwal'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.tap(find.text('Simpan jadwal'));
    await tester.pump();

    expect(find.text('Tanggal jatuh tempo wajib dipilih.'), findsOneWidget);
  });
}
