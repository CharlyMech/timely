import 'package:flutter/material.dart';

class ShiftType {
  final String id;
  final String name;
  final String colorHex;
  final String startTime;
  final String endTime;
  final String? pauseTime;
  final String? resumeTime;
  final int targetTimeMinutes; // Target time in minutes for this shift type

  const ShiftType({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.startTime,
    required this.endTime,
    this.pauseTime,
    this.resumeTime,
    required this.targetTimeMinutes,
  });

  Color get color {
    return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  }

  factory ShiftType.fromJson(Map<String, dynamic> json) {
    return ShiftType(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: json['colorHex'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      pauseTime: json['pauseTime'] as String?,
      resumeTime: json['resumeTime'] as String?,
      targetTimeMinutes: json['targetTimeMinutes'] as int? ?? 480,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'startTime': startTime,
      'endTime': endTime,
      'pauseTime': pauseTime,
      'resumeTime': resumeTime,
      'targetTimeMinutes': targetTimeMinutes,
    };
  }

  ShiftType copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? startTime,
    String? endTime,
    String? pauseTime,
    String? resumeTime,
    int? targetTimeMinutes,
  }) {
    return ShiftType(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      pauseTime: pauseTime ?? this.pauseTime,
      resumeTime: resumeTime ?? this.resumeTime,
      targetTimeMinutes: targetTimeMinutes ?? this.targetTimeMinutes,
    );
  }

  // Helper to check if this shift type has pause/resume times
  bool get hasPauseResume => pauseTime != null && resumeTime != null;
}
