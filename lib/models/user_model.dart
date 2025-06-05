class UserModel {
  final String email;
  final String password; // Note: In production, you should hash passwords
  final String role; // 'driver' or 'passenger'
  final String name;
  final DateTime? createdAt;

  UserModel({
    required this.email,
    required this.password,
    required this.role,
    required this.name,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
      'role': role,
      'name': name,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      email: map['email'] as String,
      password: map['password'] as String,
      role: map['role'] as String,
      name: map['name'] as String,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel.fromMap(json);
}
