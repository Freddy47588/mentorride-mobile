import 'package:mentorride/features/service_records/domain/models/service_item.dart';

class ServiceRecord {
  const ServiceRecord({
    required this.id,
    required this.serviceDate,
    required this.odometer,
    required this.workshop,
    required this.items,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final DateTime serviceDate;
  final int odometer;
  final String workshop;
  final List<ServiceItem> items;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get totalCost => items.fold(0, (total, item) => total + item.cost);

  factory ServiceRecord.fromMap(Map<String, Object?> map) {
    final rawItems = map['items'];
    return ServiceRecord(
      id: map['id'] as String? ?? '',
      serviceDate: _dateTimeFromValue(map['serviceDate']) ?? DateTime.now(),
      odometer: _intFromValue(map['odometer']),
      workshop: map['workshop'] as String? ?? '',
      items: rawItems is Iterable
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) => ServiceItem.fromMap(
                    item.map((key, value) => MapEntry(key.toString(), value)),
                  ),
                )
                .toList(growable: false)
          : const [],
      notes: map['notes'] as String? ?? '',
      createdAt: _dateTimeFromValue(map['createdAt']),
      updatedAt: _dateTimeFromValue(map['updatedAt']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'serviceDate': serviceDate,
      'odometer': odometer,
      'workshop': workshop,
      'items': items.map((item) => item.toMap()).toList(growable: false),
      'totalCost': totalCost,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ServiceRecord copyWith({
    String? id,
    DateTime? serviceDate,
    int? odometer,
    String? workshop,
    List<ServiceItem>? items,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceRecord(
      id: id ?? this.id,
      serviceDate: serviceDate ?? this.serviceDate,
      odometer: odometer ?? this.odometer,
      workshop: workshop ?? this.workshop,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _intFromValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _dateTimeFromValue(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
