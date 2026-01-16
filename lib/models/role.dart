/// Defines the type of role an employee can have.
enum RoleType {
  /// Management-level role.
  manager,

  /// Standard staff member role.
  staff,

  /// Administrative role with elevated privileges.
  admin,
}

/// Represents an employee role with a type and display name.
///
/// Roles define an employee's position and potentially their access level
/// within the application.
class Role {
  /// Unique identifier for the role.
  final String id;

  /// The type of role (manager, staff, or admin).
  final RoleType type;

  /// Human-readable name for the role.
  final String displayName;

  const Role({
    required this.id,
    required this.type,
    required this.displayName,
  });

  /// Creates a [Role] from a JSON map.
  ///
  /// Defaults to [RoleType.staff] if the type is not recognized.
  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as String,
      type: RoleType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RoleType.staff,
      ),
      displayName: json['displayName'] as String,
    );
  }

  /// Converts this [Role] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'displayName': displayName,
    };
  }

  /// Creates a copy of this [Role] with the given fields replaced.
  Role copyWith({
    String? id,
    RoleType? type,
    String? displayName,
  }) {
    return Role(
      id: id ?? this.id,
      type: type ?? this.type,
      displayName: displayName ?? this.displayName,
    );
  }
}
