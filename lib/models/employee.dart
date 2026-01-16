import 'package:timely/models/time_registration.dart';
import 'package:timely/models/shift.dart';

/// Defines the current status of an employee.
enum EmployeeStatus {
  /// Employee is actively working.
  active,

  /// Employee is inactive or on leave.
  inactive,

  /// Employee is on vacation.
  vacation,

  /// Employee is on leave.
  leave,
}

/// Defines the work schedule type for an employee.
enum WorkType {
  /// Full-time work schedule.
  complete,

  /// Part-time work schedule.
  partial,
}

/// Extension on [WorkType] providing display names in Spanish.
extension WorkTypeExtension on WorkType {
  /// Returns the display name for this work type in Spanish.
  String get displayName {
    switch (this) {
      case WorkType.complete:
        return 'Jornada completa';
      case WorkType.partial:
        return 'Jornada parcial';
    }
  }
}

/// Represents an employee with personal information and work details.
///
/// Contains all employee data including identification, contact information,
/// current time registration status, and shift assignment. Includes validation
/// regex patterns for Spanish identification documents and contact data.
class Employee {
  /// Unique identifier for the employee.
  final String id;

  /// Spanish identification document number (DNI or NIE).
  final String personId;

  /// Employee's first name.
  final String firstName;

  /// Employee's last name.
  final String lastName;

  /// Optional URL to the employee's avatar image.
  final String? avatarUrl;

  /// 6-digit PIN for employee data access and profile verification.
  final String pin;

  /// Current active time registration, if any.
  final TimeRegistration? currentRegistration;

  /// Today's assigned shift, if any.
  final Shift? todayShift;

  /// Current employment status.
  final EmployeeStatus status;

  /// Optional email address.
  final String? email;

  /// Phone number (required).
  final String phone;

  /// Optional physical address.
  final String? address;

  /// Reference to the employee's role.
  final String roleId;

  /// Work schedule type (full-time or part-time).
  final WorkType workType;

  /// Optional Spanish Social Security Number (Número de la seguridad social).
  final String? socialSecurityNumber;

  /// Regex pattern for validating email addresses.
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Regex pattern for validating Spanish mobile phone numbers.
  ///
  /// Must start with 6 or 7 and be followed by 8 digits.
  static final RegExp phoneRegex = RegExp(r'^[67]\d{8}$');

  /// Regex pattern for validating Spanish DNI.
  ///
  /// Format: 8 digits followed by an uppercase letter.
  static final RegExp dniRegex = RegExp(r'^\d{8}[A-Z]$');

  /// Regex pattern for validating Spanish NIE.
  ///
  /// Format: X, Y, or Z followed by 7 digits and an uppercase letter.
  static final RegExp nieRegex = RegExp(r'^[XYZ]\d{7}[A-Z]$');

  /// Combined regex pattern for validating DNI or NIE.
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
    this.socialSecurityNumber,
  }) : assert(
         email == null || email.length > 0,
         'Email must not be empty if provided',
       );

  /// Returns the employee's full name (first name + last name).
  String get fullName => '$firstName $lastName';

  /// Creates an [Employee] from a JSON map.
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
      socialSecurityNumber: json['socialSecurityNumber'] as String?,
    );
  }

  /// Converts this [Employee] to a JSON map.
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
      'socialSecurityNumber': socialSecurityNumber,
    };
  }

  /// Creates a copy of this [Employee] with the given fields replaced.
  ///
  /// Supports clearing nullable fields using `clear*` boolean parameters.
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
    String? socialSecurityNumber,
    bool clearRegistration = false,
    bool clearTodayShift = false,
    bool clearEmail = false,
    bool clearAddress = false,
    bool clearSocialSecurityNumber = false,
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
      socialSecurityNumber: clearSocialSecurityNumber
          ? null
          : (socialSecurityNumber ?? this.socialSecurityNumber),
    );
  }
}
