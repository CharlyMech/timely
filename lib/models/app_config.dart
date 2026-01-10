import 'package:timely/models/shift_type.dart';

class AppConfig {
  final int targetTimeMinutes;
  final int warningThresholdMinutes;
  final int redThresholdMinutes;
  final List<int> workingDays; // Working days (1=Monday, 7=Sunday)
  final List<ShiftType> shiftTypes;

  const AppConfig({
    required this.targetTimeMinutes,
    this.warningThresholdMinutes = 15,
    this.redThresholdMinutes = 60,
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
      warningThresholdMinutes: json['warningThresholdMinutes'] as int? ?? 15,
      redThresholdMinutes: json['redThresholdMinutes'] as int? ?? 60,
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
      'warningThresholdMinutes': warningThresholdMinutes,
      'redThresholdMinutes': redThresholdMinutes,
      'workingDays': workingDays,
      'shiftTypes': shiftTypes.map((st) => st.toJson()).toList(),
    };
  }

  AppConfig copyWith({
    int? targetTimeMinutes,
    int? warningThresholdMinutes,
    int? redThresholdMinutes,
    List<int>? workingDays,
    List<ShiftType>? shiftTypes,
  }) {
    return AppConfig(
      targetTimeMinutes: targetTimeMinutes ?? this.targetTimeMinutes,
      warningThresholdMinutes: warningThresholdMinutes ?? this.warningThresholdMinutes,
      redThresholdMinutes: redThresholdMinutes ?? this.redThresholdMinutes,
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
    const ShiftType(
      id: 'morning',
      name: 'Mañana',
      colorHex: '#81D4FA',
      startTime: '08:00',
      endTime: '15:00',
    ),
    const ShiftType(
      id: 'afternoon',
      name: 'Tarde',
      colorHex: '#FFCC80',
      startTime: '15:00',
      endTime: '22:00',
    ),
    const ShiftType(
      id: 'split',
      name: 'Partido',
      colorHex: '#B39DDB',
      startTime: '08:00',
      endTime: '15:00',
      pauseTime: '12:00',
      resumeTime: '12:30',
    ),
  ];
}
