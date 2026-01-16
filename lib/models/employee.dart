import 'package:timely/models/time_registration.dart';
import 'package:timely/models/shift.dart';

enum EmployeeStatus { active, inactive, vacation, leave }

enum WorkType { complete, partial }

extension WorkTypeExtension on WorkType {
  String get displayName {
    switch (this) {
      case WorkType.complete:
        return 'Jornada completa';
      case WorkType.partial:
        return 'Jornada parcial';
    }
  }
}

class Employee {
  final String id;
  final String personId; // DNI or NIE
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String pin; // 6-digit PIN for employee data access
  final TimeRegistration? currentRegistration;
  final Shift? todayShift;
  final EmployeeStatus status;
  final String? email;
  final String phone;
  final String? address;
  final String roleId;
  final WorkType workType;

  // Email regex
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Spanish phone regex
  static final RegExp phoneRegex = RegExp(r'^[67]\d{8}$');

  // DNI: 8 digits followed by a letter
  static final RegExp dniRegex = RegExp(r'^\d{8}[A-Z]$');

  // NIE: X, Y, or Z followed by 7 digits and a letter
  static final RegExp nieRegex = RegExp(r'^[XYZ]\d{7}[A-Z]$');

  // Combined DNI/NIE regex
  static final RegExp personIdRegex = RegExp(r'^(\d{8}[A-Z]|[XYZ]\d{7}[A-Z])$');

  const Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.pin,
    this.currentRegistration,
    this.todayShift,
    this.status = EmployeeStatus.active,
    this.email,
    required this.phone,
    this.address,
    required this.personId,
    required this.roleId,
    this.workType = WorkType.complete,
  }) : assert(
         email == null || email.length > 0,
         'Email must not be empty if provided',
       );

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
          ? Shift.fromJson(json['todayShift'] as Map<String, dynamic>)
          : null,
      status: json['status'] != null
          ? EmployeeStatus.values.firstWhere(
              (e) => e.name == json['status'],
              orElse: () => EmployeeStatus.active,
            )
          : EmployeeStatus.active,
      email: json['email'] as String?,
      phone: json['phone'] as String? ?? '600000000',
      address: json['address'] as String?,
      personId: json['personId'] as String,
      roleId: json['roleId'] as String,
      workType: json['workType'] != null
          ? WorkType.values.firstWhere(
              (e) => e.name == json['workType'],
              orElse: () => WorkType.complete,
            )
          : WorkType.complete,
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
      'status': status.name,
      'email': email,
      'phone': phone,
      'address': address,
      'personId': personId,
      'roleId': roleId,
      'workType': workType.name,
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
    EmployeeStatus? status,
    String? email,
    String? phone,
    String? address,
    String? personId,
    String? roleId,
    WorkType? workType,
    bool clearRegistration = false,
    bool clearTodayShift = false,
    bool clearEmail = false,
    bool clearAddress = false,
  }) {
    return Employee(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      pin: pin ?? this.pin,
      currentRegistration: clearRegistration
          ? null
          : (currentRegistration ?? this.currentRegistration),
      todayShift: clearTodayShift ? null : (todayShift ?? this.todayShift),
      status: status ?? this.status,
      email: clearEmail ? null : (email ?? this.email),
      phone: phone ?? this.phone,
      address: clearAddress ? null : (address ?? this.address),
      personId: personId ?? this.personId,
      roleId: roleId ?? this.roleId,
      workType: workType ?? this.workType,
    );
  }
}
