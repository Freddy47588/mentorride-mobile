enum ServiceScheduleStatus {
  pending('pending', 'Menunggu'),
  completed('completed', 'Selesai');

  const ServiceScheduleStatus(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static ServiceScheduleStatus fromValue(Object? value) {
    return ServiceScheduleStatus.values.firstWhere(
      (status) => status.storageValue == value,
      orElse: () => ServiceScheduleStatus.pending,
    );
  }
}

class ServiceSchedule {
  const ServiceSchedule({
    required this.id,
    required this.title,
    required this.serviceType,
    required this.dueDate,
    required this.dueOdometer,
    required this.reminderAt,
    required this.reminderEnabled,
    required this.localNotificationId,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String serviceType;
  final DateTime dueDate;
  final int? dueOdometer;
  final DateTime reminderAt;
  final bool reminderEnabled;
  final int localNotificationId;
  final ServiceScheduleStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isCompleted => status == ServiceScheduleStatus.completed;

  factory ServiceSchedule.fromMap(Map<String, Object?> map) {
    return ServiceSchedule(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      serviceType: map['serviceType'] as String? ?? '',
      dueDate:
          _dateTimeFrom(map['dueDate']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dueOdometer: _nullableIntFrom(map['dueOdometer']),
      reminderAt:
          _dateTimeFrom(map['reminderAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      reminderEnabled: map['reminderEnabled'] as bool? ?? false,
      localNotificationId: _intFrom(map['localNotificationId']),
      status: ServiceScheduleStatus.fromValue(map['status']),
      createdAt: _dateTimeFrom(map['createdAt']),
      updatedAt: _dateTimeFrom(map['updatedAt']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'title': title,
      'serviceType': serviceType,
      'dueDate': dueDate,
      'dueOdometer': dueOdometer,
      'reminderAt': reminderAt,
      'reminderEnabled': reminderEnabled,
      'localNotificationId': localNotificationId,
      'status': status.storageValue,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ServiceSchedule copyWith({
    String? id,
    String? title,
    String? serviceType,
    DateTime? dueDate,
    int? dueOdometer,
    bool clearDueOdometer = false,
    DateTime? reminderAt,
    bool? reminderEnabled,
    int? localNotificationId,
    ServiceScheduleStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceSchedule(
      id: id ?? this.id,
      title: title ?? this.title,
      serviceType: serviceType ?? this.serviceType,
      dueDate: dueDate ?? this.dueDate,
      dueOdometer: clearDueOdometer ? null : dueOdometer ?? this.dueOdometer,
      reminderAt: reminderAt ?? this.reminderAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      localNotificationId: localNotificationId ?? this.localNotificationId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _intFrom(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _nullableIntFrom(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _dateTimeFrom(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
