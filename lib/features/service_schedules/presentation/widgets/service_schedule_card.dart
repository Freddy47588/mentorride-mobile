import 'package:flutter/material.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/domain/services/service_schedule_due_calculator.dart';
import 'package:mentorride/features/service_schedules/presentation/widgets/service_schedule_status_badge.dart';

class ServiceScheduleCard extends StatelessWidget {
  const ServiceScheduleCard({
    required this.schedule,
    required this.currentOdometer,
    required this.onTap,
    required this.onComplete,
    this.actionsEnabled = true,
    this.now,
    super.key,
  });

  final ServiceSchedule schedule;
  final int currentOdometer;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final bool actionsEnabled;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueStatus = ServiceScheduleDueCalculator.calculate(
      schedule: schedule,
      now: now ?? DateTime.now(),
      currentOdometer: currentOdometer,
    );
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        color: schedule.isCompleted
            ? theme.colorScheme.surfaceContainerLow
            : theme.colorScheme.surface,
        child: InkWell(
          onTap: actionsEnabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: schedule.isCompleted
                                  ? theme.colorScheme.onSurfaceVariant
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            schedule.serviceType,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
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
                const Divider(height: 24),
                _ScheduleLine(
                  label:
                      '${AppFormatters.date(schedule.dueDate)} • '
                      '${schedule.isCompleted ? 'Jadwal selesai' : dueStatus.date.label}',
                  icon: Icons.event_outlined,
                  isOverdue: !schedule.isCompleted && dueStatus.date.isOverdue,
                ),
                if (schedule.dueOdometer case final dueOdometer?) ...[
                  const SizedBox(height: 7),
                  _ScheduleLine(
                    label:
                        '${AppFormatters.kilometer(dueOdometer)} • '
                        '${schedule.isCompleted ? 'Jadwal selesai' : dueStatus.odometer!.label}',
                    icon: Icons.speed_rounded,
                    isOverdue:
                        !schedule.isCompleted && dueStatus.odometer!.isOverdue,
                  ),
                ],
                if (schedule.reminderEnabled && !schedule.isCompleted) ...[
                  const SizedBox(height: 7),
                  const _ScheduleLine(
                    label: 'Pengingat aktif',
                    icon: Icons.notifications_active_outlined,
                  ),
                ],
                if (!schedule.isCompleted) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: actionsEnabled ? onComplete : null,
                      child: const Text('Tandai selesai'),
                    ),
                  ),
                ] else
                  const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleLine extends StatelessWidget {
  const _ScheduleLine({
    required this.label,
    required this.icon,
    this.isOverdue = false,
  });

  final String label;
  final IconData icon;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final color = isOverdue
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
