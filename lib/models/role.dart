enum RoleType {
  manager,
  staff,
  admin,
}

class Role {
  final String id;
  final RoleType type;
  final String displayName;

  const Role({
    required this.id,
    required this.type,
    required this.displayName,
  });

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'displayName': displayName,
    };
  }

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
