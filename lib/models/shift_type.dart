import 'package:flutter/material.dart';

/// Defines a type of work shift with its schedule and visual appearance.
///
/// A shift type represents a specific work schedule template (e.g., "Morning Shift",
/// "Night Shift") with defined start/end times, optional pause/resume times,
/// and a color for visual identification.
class ShiftType {
  /// Unique identifier for the shift type.
  final String id;

  /// Display name of the shift type.
  final String name;

  /// Hex color code for visual identification (e.g., '#FF5733').
  final String colorHex;

  /// Scheduled start time in 24-hour format (e.g., '09:00').
  final String startTime;

  /// Scheduled end time in 24-hour format (e.g., '17:00').
  final String endTime;

  /// Optional scheduled pause time in 24-hour format.
  final String? pauseTime;

  /// Optional scheduled resume time in 24-hour format.
  final String? resumeTime;

  /// Target work time in minutes for this shift type.
  ///
  /// Used to calculate compliance when comparing actual vs expected hours.
  final int targetTimeMinutes;

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

  /// Converts [colorHex] to a Flutter [Color] object.
  Color get color {
    return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  }

  /// Creates a [ShiftType] from a JSON map.
  ///
  /// Defaults [targetTimeMinutes] to 480 (8 hours) if not provided.
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

  /// Converts this [ShiftType] to a JSON map.
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

  /// Creates a copy of this [ShiftType] with the given fields replaced.
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

  /// Returns `true` if this shift type includes a scheduled pause and resume time.
  bool get hasPauseResume => pauseTime != null && resumeTime != null;
}
