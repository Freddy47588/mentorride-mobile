import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mentorride/app/router/app_routes.dart';
import 'package:mentorride/features/maintenance_calendar/domain/services/calendar_schedule_grouper.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/domain/services/service_schedule_due_calculator.dart';
import 'package:mentorride/features/service_schedules/providers/service_schedule_providers.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';
import 'package:mentorride/shared/widgets/empty_state.dart';
import 'package:mentorride/shared/widgets/error_state.dart';

class MaintenanceCalendarScreen extends ConsumerStatefulWidget {
  const MaintenanceCalendarScreen({this.now, super.key});

  final DateTime? now;

  @override
  ConsumerState<MaintenanceCalendarScreen> createState() =>
      _MaintenanceCalendarScreenState();
}

class _MaintenanceCalendarScreenState
    extends ConsumerState<MaintenanceCalendarScreen> {
  late DateTime _displayedMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = widget.now ?? DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(activeVehicleProvider).value;
    final schedulesValue = ref.watch(serviceSchedulesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kalender Perawatan')),
      body: vehicle == null
          ? const EmptyState(
              icon: Icons.calendar_month_rounded,
              title: 'Belum ada kendaraan aktif',
              message: 'Pilih kendaraan untuk melihat kalender perawatan.',
            )
          : schedulesValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ErrorState(
                message: 'Kalender perawatan belum dapat dimuat.',
                onRetry: () => ref.invalidate(serviceSchedulesProvider),
              ),
              data: (schedules) {
                final grouped = CalendarScheduleGrouper.group(schedules);
                final selected = grouped[_selectedDay] ?? const [];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Bulan sebelumnya',
                                  onPressed: () => _moveMonth(-1),
                                  icon: const Icon(Icons.chevron_left_rounded),
                                ),
                                Expanded(
                                  child: Text(
                                    DateFormat.yMMMM(
                                      'id_ID',
                                    ).format(_displayedMonth),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Bulan berikutnya',
                                  onPressed: () => _moveMonth(1),
                                  icon: const Icon(Icons.chevron_right_rounded),
                                ),
                              ],
                            ),
                            const _WeekdayHeader(),
                            _MonthGrid(
                              month: _displayedMonth,
                              selectedDay: _selectedDay,
                              grouped: grouped,
                              onSelected: (day) =>
                                  setState(() => _selectedDay = day),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDay),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (selected.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('Tidak ada jadwal pada tanggal ini.'),
                      )
                    else
                      for (final schedule in selected)
                        _ScheduleTile(
                          schedule: schedule,
                          currentOdometer: vehicle.currentOdometer,
                        ),
                  ],
                );
              },
            ),
    );
  }

  void _moveMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + delta,
      );
      _selectedDay = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    });
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final value in ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(value, textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDay,
    required this.grouped,
    required this.onSelected,
  });

  final DateTime month;
  final DateTime selectedDay;
  final Map<DateTime, List<ServiceSchedule>> grouped;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final leading = DateTime(month.year, month.month, 1).weekday - 1;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final count = ((leading + days + 6) ~/ 7) * 7;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.85,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        final dayNumber = index - leading + 1;
        if (dayNumber < 1 || dayNumber > days) return const SizedBox.shrink();
        final day = DateTime(month.year, month.month, dayNumber);
        final selected = day == selectedDay;
        final scheduleCount = grouped[day]?.length ?? 0;
        final hasSchedules = scheduleCount > 0;
        return Semantics(
          button: true,
          selected: selected,
          label: hasSchedules
              ? 'Tanggal $dayNumber, $scheduleCount jadwal'
              : 'Tanggal $dayNumber, tidak ada jadwal',
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onSelected(day),
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$dayNumber'),
                  const SizedBox(height: 4),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: hasSchedules
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.schedule, required this.currentOdometer});

  final ServiceSchedule schedule;
  final int currentOdometer;

  @override
  Widget build(BuildContext context) {
    final status = schedule.isCompleted
        ? 'Selesai'
        : ServiceScheduleDueCalculator.calculate(
            schedule: schedule,
            now: DateTime.now(),
            currentOdometer: currentOdometer,
          ).visualLabel();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push(AppRoutes.serviceScheduleDetail(schedule.id)),
        leading: const Icon(Icons.build_outlined),
        title: Text(schedule.title),
        subtitle: Text('${schedule.serviceType} · $status'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
