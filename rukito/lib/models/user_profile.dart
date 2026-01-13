class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String role; // 'admin', 'manager', 'technician'
  final String? avatarUrl;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone_number': phoneNumber,
        'role': role,
        'avatar_url': avatarUrl,
      };

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? role,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
