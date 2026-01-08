import 'package:timely/models/shift_type.dart';

class AppConfig {
  final int targetTimeMinutes;
  final List<int> workingDays; // Working days (1=Monday, 7=Sunday)
  final List<ShiftType> shiftTypes;

  const AppConfig({
    required this.targetTimeMinutes,
    required this.workingDays,
    required this.shiftTypes,
  });

  // Default configuration
  factory AppConfig.defaultConfig() {
    return AppConfig(
      targetTimeMinutes: 480, // 8 hours
      workingDays: const [1, 2, 3, 4, 5], // Monday to Friday
      shiftTypes: _defaultShiftTypes(),
    );
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      targetTimeMinutes: json['targetTimeMinutes'] as int? ?? 480,
      workingDays:
          (json['workingDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [1, 2, 3, 4, 5],
      shiftTypes:
          (json['shiftTypes'] as List<dynamic>?)
              ?.map((e) => ShiftType.fromJson(e as Map<String, dynamic>))
              .toList() ??
          _defaultShiftTypes(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetTimeMinutes': targetTimeMinutes,
      'workingDays': workingDays,
      'shiftTypes': shiftTypes.map((st) => st.toJson()).toList(),
    };
  }

  AppConfig copyWith({
    int? targetTimeMinutes,
    List<int>? workingDays,
    List<ShiftType>? shiftTypes,
  }) {
    return AppConfig(
      targetTimeMinutes: targetTimeMinutes ?? this.targetTimeMinutes,
      workingDays: workingDays ?? this.workingDays,
      shiftTypes: shiftTypes ?? this.shiftTypes,
    );
  }

  bool isWorkingDay(DateTime date) {
    return workingDays.contains(date.weekday);
  }

  ShiftType? getShiftTypeById(String id) {
    try {
      return shiftTypes.firstWhere((st) => st.id == id);
    } catch (e) {
      return null;
    }
  }
}

List<ShiftType> _defaultShiftTypes() {
  return [
    const ShiftType(id: 'morning', name: 'Mañana', colorHex: '#81D4FA'),
    const ShiftType(id: 'afternoon', name: 'Tarde', colorHex: '#FFCC80'),
    const ShiftType(id: 'split', name: 'Partido', colorHex: '#B39DDB'),
  ];
}
