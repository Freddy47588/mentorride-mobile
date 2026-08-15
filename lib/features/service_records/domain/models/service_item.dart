import 'package:mentorride/features/service_records/domain/models/service_action.dart';

class ServiceItem {
  const ServiceItem({
    required this.name,
    required this.action,
    required this.cost,
  });

  final String name;
  final ServiceAction action;
  final int cost;

  factory ServiceItem.fromMap(Map<String, Object?> map) {
    return ServiceItem(
      name: map['name'] as String? ?? '',
      action: ServiceAction.fromWire(map['action']),
      cost: _intFromValue(map['cost']),
    );
  }

  Map<String, Object?> toMap() {
    return {'name': name, 'action': action.wireValue, 'cost': cost};
  }

  ServiceItem copyWith({String? name, ServiceAction? action, int? cost}) {
    return ServiceItem(
      name: name ?? this.name,
      action: action ?? this.action,
      cost: cost ?? this.cost,
    );
  }

  static int _intFromValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
