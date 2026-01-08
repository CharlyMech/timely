import 'package:flutter/material.dart';

class ShiftType {
  final String id;
  final String name;
  final String colorHex;

  const ShiftType({
    required this.id,
    required this.name,
    required this.colorHex,
  });

  Color get color {
    return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  }

  factory ShiftType.fromJson(Map<String, dynamic> json) {
    return ShiftType(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: json['colorHex'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'colorHex': colorHex};
  }

  ShiftType copyWith({String? id, String? name, String? colorHex}) {
    return ShiftType(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}
