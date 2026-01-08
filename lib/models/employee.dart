import 'package:timely/models/time_registration.dart';

class Employee {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String pin; // 6-digit PIN for employee data access
  final TimeRegistration? currentRegistration;

  const Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.pin,
    this.currentRegistration,
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
    };
  }

  Employee copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? pin,
    TimeRegistration? currentRegistration,
    bool clearRegistration = false,
  }) {
    return Employee(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      pin: pin ?? this.pin,
      currentRegistration: clearRegistration ? null : (currentRegistration ?? this.currentRegistration),
    );
  }
}
