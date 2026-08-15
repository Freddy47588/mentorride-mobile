import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mentorride/app/router/app_routes.dart';
import 'package:mentorride/features/service_schedules/presentation/navigation/service_schedule_prefill.dart';

abstract final class ServiceScheduleNavigation {
  static Future<T?> openNew<T>(
    BuildContext context, {
    ServiceSchedulePrefill? prefill,
  }) {
    return context.push<T>(AppRoutes.serviceScheduleNew, extra: prefill);
  }

  static Future<T?> openDetail<T>(BuildContext context, String scheduleId) {
    return context.push<T>(AppRoutes.serviceScheduleDetail(scheduleId));
  }

  static Future<T?> openEdit<T>(BuildContext context, String scheduleId) {
    return context.push<T>(AppRoutes.serviceScheduleEdit(scheduleId));
  }
}
