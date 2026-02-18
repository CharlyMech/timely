import 'package:timely/models/time_registration.dart';
import 'package:timely/models/shift.dart';

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

  /// UUID of the current active time registration (from API withRelations=true).
  final String? currentRegistrationId;

  /// Today's assigned shift, if any.
  final Shift? todayShift;

  /// UUID of today's assigned shift (from API withRelations=true).
  final String? todayShiftId;

  /// Reference to the employee's status.
  final String statusId;

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
    this.currentRegistrationId,
    this.todayShift,
    this.todayShiftId,
    required this.statusId,
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
  ///
  /// Supports workType as enum name string or workTypeId as a UUID string.
  factory Employee.fromJson(Map<String, dynamic> json) {
    // Parse workType from either 'workType' (enum name) or 'workTypeId' (UUID, API)
    WorkType parsedWorkType = WorkType.complete; // default
    final workTypeValue = json['workType'] ?? json['workTypeId'];
    if (workTypeValue != null) {
      if (workTypeValue is String) {
        parsedWorkType = WorkType.values.firstWhere(
          (e) => e.name == workTypeValue,
          orElse: () => WorkType.complete,
        );
      }
    }

    // Parse currentRegistration: full object (API withRelations) or UUID string
    final rawReg = json['currentRegistration'] ?? json['current_registration'];
    TimeRegistration? currentRegistration;
    String? currentRegistrationId;
    if (rawReg != null) {
      if (rawReg is Map<String, dynamic>) {
        currentRegistration = TimeRegistration.fromJson(rawReg);
      } else if (rawReg is Map) {
        currentRegistration =
            TimeRegistration.fromJson(Map<String, dynamic>.from(rawReg));
      } else if (rawReg is String) {
        currentRegistrationId = rawReg;
      }
    }

    // Parse todayShift: full object (API withRelations) or UUID string
    final rawShift = json['todayShift'] ?? json['today_shift'];
    Shift? todayShift;
    String? todayShiftId;
    if (rawShift != null) {
      if (rawShift is Map<String, dynamic>) {
        todayShift = Shift.fromJson(rawShift);
      } else if (rawShift is Map) {
        todayShift = Shift.fromJson(Map<String, dynamic>.from(rawShift));
      } else if (rawShift is String) {
        todayShiftId = rawShift;
      }
    }

    return Employee(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      pin: (json['pin'] as String?) ?? '',
      currentRegistration: currentRegistration,
      currentRegistrationId: currentRegistrationId,
      todayShift: todayShift,
      todayShiftId: todayShiftId,
      statusId: json['statusId'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String? ?? '600000000',
      address: json['address'] as String?,
      personId: json['personId'] as String,
      roleId: json['roleId'] as String,
      workType: parsedWorkType,
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
      'currentRegistration': currentRegistration?.toJson() ?? currentRegistrationId,
      'todayShift': todayShift?.toJson() ?? todayShiftId,
      'statusId': statusId,
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
    String? currentRegistrationId,
    Shift? todayShift,
    String? todayShiftId,
    String? statusId,
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
      currentRegistrationId: clearRegistration
          ? null
          : (currentRegistrationId ?? this.currentRegistrationId),
      todayShift: clearTodayShift ? null : (todayShift ?? this.todayShift),
      todayShiftId: clearTodayShift
          ? null
          : (todayShiftId ?? this.todayShiftId),
      statusId: statusId ?? this.statusId,
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
