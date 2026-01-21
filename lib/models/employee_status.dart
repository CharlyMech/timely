import 'package:flutter/material.dart';
import 'package:timely/utils/color_utils.dart';

/// Represents an employee status with display information and colors.
///
/// Employee statuses define the current work state of an employee (active,
/// inactive, on medical leave, etc.) with associated visual styling.
class EmployeeStatus {
  /// Unique identifier for the status.
  final String id;

  /// Internal status code (e.g., 'active', 'inactive', 'medical_leave').
  final String status;

  /// Human-readable name for the status.
  final String displayName;

  /// Primary color hex code for the status (e.g., '#2E7D32').
  final String colorHex;

  /// Text/icon color hex code for use on the primary color.
  final String onColorHex;

  /// Container/background color hex code for the status.
  final String colorContainerHex;

  const EmployeeStatus({
    required this.id,
    required this.status,
    required this.displayName,
    required this.colorHex,
    required this.onColorHex,
    required this.colorContainerHex,
  });

  /// Returns the primary [Color] for this status.
  Color get color => ColorUtils.parseHexColor(colorHex);

  /// Returns the text/icon [Color] for use on the primary color.
  Color get onColor => ColorUtils.parseHexColor(onColorHex);

  /// Returns the container/background [Color] for this status.
  Color get colorContainer => ColorUtils.parseHexColor(colorContainerHex);

  /// Creates an [EmployeeStatus] from a JSON map.
  factory EmployeeStatus.fromJson(Map<String, dynamic> json) {
    return EmployeeStatus(
      id: json['id'] as String,
      status: json['status'] as String,
      displayName: json['displayName'] as String,
      colorHex: json['color'] as String,
      onColorHex: json['onColor'] as String,
      colorContainerHex: json['colorContainer'] as String,
    );
  }

  /// Converts this [EmployeeStatus] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'displayName': displayName,
      'color': colorHex,
      'onColor': onColorHex,
      'colorContainer': colorContainerHex,
    };
  }

  /// Creates a copy of this [EmployeeStatus] with the given fields replaced.
  EmployeeStatus copyWith({
    String? id,
    String? status,
    String? displayName,
    String? colorHex,
    String? onColorHex,
    String? colorContainerHex,
  }) {
    return EmployeeStatus(
      id: id ?? this.id,
      status: status ?? this.status,
      displayName: displayName ?? this.displayName,
      colorHex: colorHex ?? this.colorHex,
      onColorHex: onColorHex ?? this.onColorHex,
      colorContainerHex: colorContainerHex ?? this.colorContainerHex,
    );
  }
}
