import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/domain/services/service_schedule_due_calculator.dart';
import 'package:mentorride/features/service_schedules/presentation/navigation/service_schedule_completion_flow.dart';
import 'package:mentorride/features/service_schedules/presentation/navigation/service_schedule_navigation.dart';
import 'package:mentorride/features/service_schedules/presentation/widgets/service_schedule_status_badge.dart';
import 'package:mentorride/features/service_schedules/providers/service_schedule_providers.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';
import 'package:mentorride/shared/widgets/error_state.dart';

class ServiceScheduleDetailScreen extends ConsumerStatefulWidget {
  const ServiceScheduleDetailScreen({required this.scheduleId, super.key});

  final String scheduleId;

  @override
  ConsumerState<ServiceScheduleDetailScreen> createState() =>
      _ServiceScheduleDetailScreenState();
}

class _ServiceScheduleDetailScreenState
    extends ConsumerState<ServiceScheduleDetailScreen> {
  bool _isWorking = false;

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(serviceScheduleByIdProvider(widget.scheduleId));
    final currentOdometer =
        ref.watch(activeVehicleProvider).value?.currentOdometer ?? 0;

    return schedule.when(
      loading: () => const Scaffold(
        appBar: _DetailAppBar(),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: const _DetailAppBar(),
        body: ErrorState(
          message: 'Jadwal servis belum dapat dimuat.',
          onRetry: () => ref.invalidate(serviceSchedulesProvider),
        ),
      ),
      data: (value) {
        if (value == null) {
          return Scaffold(
            appBar: const _DetailAppBar(),
            body: ErrorState(
              message: 'Jadwal servis tidak ditemukan.',
              onRetry: () => ref.invalidate(serviceSchedulesProvider),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail jadwal'),
            actions: [
              IconButton(
                tooltip: 'Edit jadwal',
                onPressed: _isWorking
                    ? null
                    : () => ServiceScheduleNavigation.openEdit<void>(
                        context,
                        value.id,
                      ),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Hapus jadwal',
                onPressed: _isWorking ? null : () => _confirmDelete(value),
                icon: _isWorking
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          body: _DetailBody(
            schedule: value,
            currentOdometer: currentOdometer,
            isWorking: _isWorking,
            onComplete: () => _complete(value),
          ),
        );
      },
    );
  }

  Future<void> _complete(ServiceSchedule schedule) async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      await ServiceScheduleCompletionFlow.run(
        context: context,
        ref: ref,
        schedule: schedule,
      );
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _confirmDelete(ServiceSchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus jadwal servis?'),
        content: const Text(
          'Jadwal dan pengingat terkait akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _isWorking) return;

    setState(() => _isWorking = true);
    final success = await ref
        .read(serviceScheduleControllerProvider.notifier)
        .delete(schedule);
    if (!mounted) return;

    if (success) {
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isWorking = false);
      context.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Jadwal servis berhasil dihapus.')),
      );
      return;
    }

    setState(() => _isWorking = false);
    final state = ref.read(serviceScheduleControllerProvider);
    _showMessage(state.errorMessage ?? 'Jadwal belum dapat dihapus.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DetailAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Detail jadwal'));
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.schedule,
    required this.currentOdometer,
    required this.isWorking,
    required this.onComplete,
  });

  final ServiceSchedule schedule;
  final int currentOdometer;
  final bool isWorking;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueStatus = ServiceScheduleDueCalculator.calculate(
      schedule: schedule,
      now: DateTime.now(),
      currentOdometer: currentOdometer,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(schedule.serviceType),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ServiceScheduleStatusBadge(
                      schedule: schedule,
                      dueStatus: dueStatus,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _InfoRow(
                  icon: Icons.event_outlined,
                  label: 'Tanggal jatuh tempo',
                  value: schedule.isCompleted
                      ? AppFormatters.date(schedule.dueDate)
                      : '${AppFormatters.date(schedule.dueDate)} • '
                            '${dueStatus.date.label}',
                  valueColor: !schedule.isCompleted && dueStatus.date.isOverdue
                      ? theme.colorScheme.error
                      : null,
                ),
                if (schedule.dueOdometer case final odometer?) ...[
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: Icons.speed_rounded,
                    label: 'Kilometer jatuh tempo',
                    value: schedule.isCompleted
                        ? AppFormatters.kilometer(odometer)
                        : '${AppFormatters.kilometer(odometer)} • '
                              '${dueStatus.odometer!.label}',
                    valueColor:
                        !schedule.isCompleted && dueStatus.odometer!.isOverdue
                        ? theme.colorScheme.error
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Pengingat', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: schedule.reminderEnabled && !schedule.isCompleted
                ? _InfoRow(
                    icon: Icons.notifications_active_outlined,
                    label: 'Aktif pada',
                    value: AppFormatters.dateTime(schedule.reminderAt),
                  )
                : const _InfoRow(
                    icon: Icons.notifications_off_outlined,
                    label: 'Status',
                    value: 'Pengingat nonaktif',
                  ),
          ),
        ),
        if (!schedule.isCompleted) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: isWorking ? null : onComplete,
            icon: isWorking
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Tandai selesai'),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final valueText = Text(
          value,
          style: TextStyle(color: valueColor, fontWeight: FontWeight.w600),
        );
        if (constraints.maxWidth < 340) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    valueText,
                  ],
                ),
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            SizedBox(width: 130, child: Text(label)),
            Expanded(child: valueText),
          ],
        );
      },
    );
  }
}
