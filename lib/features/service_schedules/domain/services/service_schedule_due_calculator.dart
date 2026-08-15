import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';

enum ServiceDueDateState { overdue, today, upcoming }

enum ServiceDueOdometerState { overdue, upcoming }

class ServiceDueDateStatus {
  const ServiceDueDateStatus._({
    required this.state,
    required this.daysUntilDue,
  });

  final ServiceDueDateState state;

  /// Positif untuk hari yang tersisa, nol untuk hari ini, dan negatif bila
  /// tanggal jatuh tempo telah lewat.
  final int daysUntilDue;

  bool get isOverdue => state == ServiceDueDateState.overdue;

  bool get isDueToday => state == ServiceDueDateState.today;

  int? get daysRemaining {
    return state == ServiceDueDateState.upcoming ? daysUntilDue : null;
  }

  int? get daysOverdue {
    return state == ServiceDueDateState.overdue ? -daysUntilDue : null;
  }

  String get label {
    return switch (state) {
      ServiceDueDateState.overdue => 'Terlambat $daysOverdue hari',
      ServiceDueDateState.today => 'Jatuh tempo hari ini',
      ServiceDueDateState.upcoming => '$daysRemaining hari lagi',
    };
  }
}

class ServiceDueOdometerStatus {
  const ServiceDueOdometerStatus._({
    required this.state,
    required this.kilometersUntilDue,
  });

  final ServiceDueOdometerState state;

  /// Positif untuk kilometer yang tersisa. Nilai nol atau negatif berarti
  /// ambang odometer telah tercapai atau terlewati.
  final int kilometersUntilDue;

  bool get isOverdue => state == ServiceDueOdometerState.overdue;

  int? get kilometersRemaining {
    return state == ServiceDueOdometerState.upcoming
        ? kilometersUntilDue
        : null;
  }

  int? get kilometersOverdue {
    return state == ServiceDueOdometerState.overdue
        ? -kilometersUntilDue
        : null;
  }

  String get label {
    if (state == ServiceDueOdometerState.upcoming) {
      return '${_formatInteger(kilometersRemaining!)} km lagi';
    }
    if (kilometersOverdue == 0) {
      return 'Terlambat berdasarkan kilometer';
    }
    return 'Terlambat ${_formatInteger(kilometersOverdue!)} km';
  }
}

class ServiceScheduleDueStatus {
  const ServiceScheduleDueStatus({required this.date, required this.odometer});

  final ServiceDueDateStatus date;
  final ServiceDueOdometerStatus? odometer;

  /// Jadwal dianggap terlambat bila salah satu dimensinya telah melewati
  /// ambang, tanpa menghilangkan hasil dimensi yang lain.
  bool get isOverdue => date.isOverdue || (odometer?.isOverdue ?? false);

  bool get isDueToday => date.isDueToday;

  List<String> get labels {
    return List.unmodifiable([
      date.label,
      if (odometer case final value?) value.label,
    ]);
  }
}

abstract final class ServiceScheduleDueCalculator {
  /// Mengevaluasi ambang tanggal dan odometer secara independen.
  ///
  /// Status lifecycle jadwal (`pending` atau `completed`) sengaja tidak diubah
  /// maupun dipakai untuk perhitungan. Pemanggil dapat menentukan apakah hasil
  /// perlu ditampilkan untuk jadwal yang sudah selesai.
  static ServiceScheduleDueStatus calculate({
    required ServiceSchedule schedule,
    required DateTime now,
    required int currentOdometer,
  }) {
    final dueDay = _localCalendarDay(schedule.dueDate);
    final today = _localCalendarDay(now);
    final daysUntilDue = dueDay.difference(today).inDays;
    final dateState = switch (daysUntilDue) {
      < 0 => ServiceDueDateState.overdue,
      0 => ServiceDueDateState.today,
      _ => ServiceDueDateState.upcoming,
    };

    final dueOdometer = schedule.dueOdometer;
    ServiceDueOdometerStatus? odometerStatus;
    if (dueOdometer != null) {
      final kilometersUntilDue = dueOdometer - currentOdometer;
      odometerStatus = ServiceDueOdometerStatus._(
        state: kilometersUntilDue <= 0
            ? ServiceDueOdometerState.overdue
            : ServiceDueOdometerState.upcoming,
        kilometersUntilDue: kilometersUntilDue,
      );
    }

    return ServiceScheduleDueStatus(
      date: ServiceDueDateStatus._(
        state: dateState,
        daysUntilDue: daysUntilDue,
      ),
      odometer: odometerStatus,
    );
  }

  static DateTime _localCalendarDay(DateTime value) {
    final local = value.toLocal();
    return DateTime.utc(local.year, local.month, local.day);
  }
}

String _formatInteger(int value) {
  final digits = value.toString();
  final output = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      output.write('.');
    }
    output.write(digits[index]);
  }
  return output.toString();
}
