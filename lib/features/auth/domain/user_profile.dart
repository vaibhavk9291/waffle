class UserProfile {
  final String id;
  final String displayName;
  final String role; // 'staff' | 'owner'

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.role,
  });

  bool get isOwner => role == 'owner';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? 'Counter Staff',
      role: json['role'] as String? ?? 'staff',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'role': role,
      };
}
