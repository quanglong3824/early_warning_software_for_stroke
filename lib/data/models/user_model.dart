class UserModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String role; // 'patient', 'doctor', 'admin'
  final DateTime createdAt;
  final String? address;
  final String? gender;
  final DateTime? dateOfBirth;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
    this.address,
    this.gender,
    this.dateOfBirth,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['uid'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      email: json['email'],
      phone: json['phone'],
      avatarUrl: json['photoURL'] ?? json['avatarUrl'],
      role: json['role'] ?? 'user',
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(json['createdAt']) 
              : DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      address: json['address'],
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['dateOfBirth'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photoURL': avatarUrl,
      'role': role,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'address': address,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
    };
  }
}
