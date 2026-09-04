import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mentorride/app/router/app_routes.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/presentation/navigation/service_schedule_completion_flow.dart';
import 'package:mentorride/features/service_schedules/presentation/navigation/service_schedule_navigation.dart';
import 'package:mentorride/features/service_schedules/presentation/widgets/service_schedule_card.dart';
import 'package:mentorride/features/service_schedules/providers/service_schedule_providers.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';
import 'package:mentorride/shared/widgets/empty_state.dart';
import 'package:mentorride/shared/widgets/error_state.dart';

class ServiceScheduleListScreen extends ConsumerWidget {
  const ServiceScheduleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal servis'),
        actions: [
          IconButton(
            tooltip: 'Kalender perawatan',
            onPressed: () => context.push(AppRoutes.maintenanceCalendar),
            icon: const Icon(Icons.calendar_month_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: activeVehicle.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorState(
          message: 'Kendaraan aktif belum dapat dimuat.',
          onRetry: () => ref.invalidate(activeVehicleProvider),
        ),
        data: (vehicle) {
          if (vehicle == null) {
            return const EmptyState(
              icon: Icons.two_wheeler_rounded,
              title: 'Pilih kendaraan dahulu',
              message:
                  'Tambahkan atau pilih kendaraan untuk mengatur jadwal servis.',
            );
          }

          return Column(
            children: [
              _ActiveVehicleHeader(
                name: vehicle.name,
                plateNumber: vehicle.plateNumber,
              ),
              Expanded(
                child: _ScheduleList(currentOdometer: vehicle.currentOdometer),
              ),
            ],
          );
        },
      ),
      floatingActionButton: activeVehicle.value == null
          ? null
          : FloatingActionButton(
              onPressed: () => ServiceScheduleNavigation.openNew<void>(context),
              tooltip: 'Tambah jadwal',
              child: const Icon(Icons.add_rounded),
            ),
    );
  }
}

class _ActiveVehicleHeader extends StatelessWidget {
  const _ActiveVehicleHeader({required this.name, required this.plateNumber});

  final String name;
  final String plateNumber;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Icon(
            Icons.two_wheeler_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  plateNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleList extends ConsumerWidget {
  const _ScheduleList({required this.currentOdometer});

  final int currentOdometer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(serviceSchedulesProvider);
    final isSubmitting = ref.watch(
      serviceScheduleControllerProvider.select((state) => state.isSubmitting),
    );
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: schedules.when(
        loading: () => const Center(
          key: ValueKey('schedule-loading'),
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => ErrorState(
          key: const ValueKey('schedule-error'),
          message: 'Jadwal servis belum dapat dimuat.',
          onRetry: () => ref.invalidate(serviceSchedulesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              key: const ValueKey('schedule-empty'),
              icon: Icons.event_note_rounded,
              title: 'Belum ada jadwal',
              message:
                  'Tambahkan jadwal agar perawatan kendaraan tidak terlewat.',
              actionLabel: 'Tambah jadwal',
              onAction: () => ServiceScheduleNavigation.openNew<void>(context),
            );
          }

          return RefreshIndicator(
            key: const ValueKey('schedule-list'),
            onRefresh: () async {
              ref.invalidate(serviceSchedulesProvider);
              await ref.read(serviceSchedulesProvider.future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final schedule = items[index];
                return ServiceScheduleCard(
                  schedule: schedule,
                  currentOdometer: currentOdometer,
                  actionsEnabled: !isSubmitting,
                  onTap: () => ServiceScheduleNavigation.openDetail<void>(
                    context,
                    schedule.id,
                  ),
                  onComplete: () => _complete(context, ref, schedule),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _complete(
    BuildContext context,
    WidgetRef ref,
    ServiceSchedule schedule,
  ) async {
    await ServiceScheduleCompletionFlow.run(
      context: context,
      ref: ref,
      schedule: schedule,
    );
  }
}
