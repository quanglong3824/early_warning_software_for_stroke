class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String role; // 'patient', 'doctor', 'admin'
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      avatarUrl: json['avatarUrl'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
