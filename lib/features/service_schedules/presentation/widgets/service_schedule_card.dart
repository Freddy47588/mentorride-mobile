import 'package:flutter/material.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';

class ServiceScheduleCard extends StatelessWidget {
  const ServiceScheduleCard({
    required this.schedule,
    required this.onTap,
    required this.onComplete,
    this.actionsEnabled = true,
    super.key,
  });

  final ServiceSchedule schedule;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final bool actionsEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue =
        !schedule.isCompleted && schedule.dueDate.isBefore(_startOfToday());

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: actionsEnabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.build_circle_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          schedule.serviceType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(schedule: schedule, overdue: overdue),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _MetaItem(
                    icon: Icons.event_outlined,
                    label: AppFormatters.date(schedule.dueDate),
                    color: overdue ? theme.colorScheme.error : null,
                  ),
                  if (schedule.dueOdometer case final odometer?)
                    _MetaItem(
                      icon: Icons.speed_rounded,
                      label: AppFormatters.kilometer(odometer),
                    ),
                  _MetaItem(
                    icon: schedule.reminderEnabled && !schedule.isCompleted
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    label: schedule.reminderEnabled && !schedule.isCompleted
                        ? 'Pengingat aktif'
                        : 'Pengingat nonaktif',
                  ),
                ],
              ),
              if (!schedule.isCompleted) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: actionsEnabled ? onComplete : null,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Tandai selesai'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.schedule, required this.overdue});

  final ServiceSchedule schedule;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, background, foreground) = schedule.isCompleted
        ? (
            'Selesai',
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.onSecondaryContainer,
          )
        : overdue
        ? (
            'Terlambat',
            theme.colorScheme.errorContainer,
            theme.colorScheme.onErrorContainer,
          )
        : (
            'Menunggu',
            theme.colorScheme.primaryContainer,
            theme.colorScheme.onPrimaryContainer,
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: effectiveColor),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: effectiveColor)),
      ],
    );
  }
}
