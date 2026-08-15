import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/presentation/navigation/service_schedule_navigation.dart';
import 'package:mentorride/features/service_schedules/presentation/navigation/service_schedule_prefill.dart';
import 'package:mentorride/features/service_schedules/providers/service_schedule_providers.dart';

enum _CompletionChoice { doneOnly, createNext }

abstract final class ServiceScheduleCompletionFlow {
  static Future<bool> run({
    required BuildContext context,
    required WidgetRef ref,
    required ServiceSchedule schedule,
  }) async {
    final completed = await ref
        .read(serviceScheduleControllerProvider.notifier)
        .complete(schedule);
    if (!context.mounted) return completed;

    if (!completed) {
      final state = ref.read(serviceScheduleControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Jadwal belum dapat diperbarui.'),
        ),
      );
      return false;
    }

    final choice = await showDialog<_CompletionChoice>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Jadwal selesai'),
        content: const Text(
          'Jadwal dan pengingat telah diselesaikan. Apakah Anda ingin '
          'membuat jadwal berikutnya untuk jenis servis yang sama?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(_CompletionChoice.doneOnly);
            },
            child: const Text('Selesai saja'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(_CompletionChoice.createNext);
            },
            child: const Text('Buat jadwal berikutnya'),
          ),
        ],
      ),
    );
    if (!context.mounted) return true;

    if (choice == _CompletionChoice.createNext) {
      await ServiceScheduleNavigation.openNew<void>(
        context,
        prefill: ServiceSchedulePrefill.fromSchedule(schedule),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil ditandai selesai.')),
      );
    }
    return true;
  }
}
