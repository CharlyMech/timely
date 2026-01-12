import 'package:timely/models/time_registration.dart';
import 'package:timely/models/shift.dart';

class Employee {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String pin; // 6-digit PIN for employee data access
  final TimeRegistration? currentRegistration;
  final Shift? todayShift; // Shift assigned for today

  const Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.pin,
    this.currentRegistration,
    this.todayShift,
  });

  String get fullName => '$firstName $lastName';

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      pin: json['pin'] as String,
      currentRegistration: json['currentRegistration'] != null
          ? TimeRegistration.fromJson(
              json['currentRegistration'] as Map<String, dynamic>,
            )
          : null,
      todayShift: json['todayShift'] != null
          ? Shift.fromJson(
              json['todayShift'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'avatarUrl': avatarUrl,
      'pin': pin,
      'currentRegistration': currentRegistration?.toJson(),
      'todayShift': todayShift?.toJson(),
    };
  }

  Employee copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? pin,
    TimeRegistration? currentRegistration,
    Shift? todayShift,
    bool clearRegistration = false,
    bool clearTodayShift = false,
  }) {
    return Employee(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      pin: pin ?? this.pin,
      currentRegistration: clearRegistration ? null : (currentRegistration ?? this.currentRegistration),
      todayShift: clearTodayShift ? null : (todayShift ?? this.todayShift),
    );
  }
}
