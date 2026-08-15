class Vehicle {
  const Vehicle({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.currentOdometer,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String brand;
  final String model;
  final int year;
  final String plateNumber;
  final int currentOdometer;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Vehicle.fromMap(Map<String, Object?> map) {
    return Vehicle(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      model: map['model'] as String? ?? '',
      year: _intFrom(map['year']),
      plateNumber: map['plateNumber'] as String? ?? '',
      currentOdometer: _intFrom(map['currentOdometer']),
      createdAt: _dateTimeFrom(map['createdAt']),
      updatedAt: _dateTimeFrom(map['updatedAt']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'brand': brand,
      'model': model,
      'year': year,
      'plateNumber': plateNumber,
      'currentOdometer': currentOdometer,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Vehicle copyWith({
    String? id,
    String? name,
    String? brand,
    String? model,
    int? year,
    String? plateNumber,
    int? currentOdometer,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      plateNumber: plateNumber ?? this.plateNumber,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _intFrom(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _dateTimeFrom(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
