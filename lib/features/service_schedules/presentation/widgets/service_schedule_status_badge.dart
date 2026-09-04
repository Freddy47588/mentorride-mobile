import 'package:flutter/material.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/domain/services/service_schedule_due_calculator.dart';

class ServiceScheduleStatusStyle {
  const ServiceScheduleStatusStyle({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  static ServiceScheduleStatusStyle resolve({
    required BuildContext context,
    required ServiceSchedule schedule,
    required ServiceScheduleDueStatus dueStatus,
  }) {
    final colors = Theme.of(context).colorScheme;
    if (schedule.isCompleted) {
      return ServiceScheduleStatusStyle(
        label: 'Selesai',
        icon: Icons.check_circle_outline_rounded,
        foreground: colors.onSecondaryContainer,
        background: colors.secondaryContainer,
      );
    }

    return switch (dueStatus.visualState()) {
      ServiceScheduleVisualState.safe => ServiceScheduleStatusStyle(
        label: dueStatus.visualLabel(),
        icon: Icons.shield_outlined,
        foreground: colors.onSecondaryContainer,
        background: colors.secondaryContainer,
      ),
      ServiceScheduleVisualState.approaching => ServiceScheduleStatusStyle(
        label: dueStatus.visualLabel(),
        icon: Icons.schedule_rounded,
        foreground: colors.onTertiaryContainer,
        background: colors.tertiaryContainer,
      ),
      ServiceScheduleVisualState.due => ServiceScheduleStatusStyle(
        label: dueStatus.visualLabel(),
        icon: Icons.notification_important_outlined,
        foreground: colors.onPrimaryContainer,
        background: colors.primaryContainer,
      ),
      ServiceScheduleVisualState.overdue => ServiceScheduleStatusStyle(
        label: dueStatus.visualLabel(),
        icon: Icons.error_outline_rounded,
        foreground: colors.onErrorContainer,
        background: colors.errorContainer,
      ),
    };
  }
}

class ServiceScheduleStatusBadge extends StatelessWidget {
  const ServiceScheduleStatusBadge({
    required this.schedule,
    required this.dueStatus,
    super.key,
  });

  final ServiceSchedule schedule;
  final ServiceScheduleDueStatus dueStatus;

  @override
  Widget build(BuildContext context) {
    final style = ServiceScheduleStatusStyle.resolve(
      context: context,
      schedule: schedule,
      dueStatus: dueStatus,
    );
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Status jadwal: ${style.label}',
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedSwitcher(
            duration: duration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Row(
              key: ValueKey(style.label),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(style.icon, size: 16, color: style.foreground),
                const SizedBox(width: 5),
                Text(
                  style.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: style.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
