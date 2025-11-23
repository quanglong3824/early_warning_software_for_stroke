class DoctorModel {
  final String doctorId;
  final String name;
  final String? email;
  final String? phone;
  final String? photoURL;
  final String? specialization;
  final String? hospital;
  final String? department;
  final String? licenseNumber;
  final int? yearsOfExperience;
  final String? bio;
  final bool isVerified;
  final bool isAvailable;
  final int createdAt;

  DoctorModel({
    required this.doctorId,
    required this.name,
    this.email,
    this.phone,
    this.photoURL,
    this.specialization,
    this.hospital,
    this.department,
    this.licenseNumber,
    this.yearsOfExperience,
    this.bio,
    required this.isVerified,
    required this.isAvailable,
    required this.createdAt,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      doctorId: json['doctorId'] ?? json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      photoURL: json['photoURL'],
      specialization: json['specialization'] ?? json['specialty'], // Support both fields
      hospital: json['hospital'],
      department: json['department'],
      licenseNumber: json['licenseNumber'],
      yearsOfExperience: json['yearsOfExperience'],
      bio: json['bio'],
      isVerified: json['isVerified'] ?? true, // Default true for existing doctors
      isAvailable: json['isAvailable'] ?? true,
      createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'name': name,
      'email': email,
      'phone': phone,
      'photoURL': photoURL,
      'specialization': specialization,
      'hospital': hospital,
      'department': department,
      'licenseNumber': licenseNumber,
      'yearsOfExperience': yearsOfExperience,
      'bio': bio,
      'isVerified': isVerified,
      'isAvailable': isAvailable,
      'createdAt': createdAt,
    };
  }
}

class DoctorStatsModel {
  final String doctorId;
  final int totalPatients;
  final int totalAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final int totalConsultations;
  final int totalPrescriptions;
  final double averageRating;
  final int totalReviews;
  final int updatedAt;

  DoctorStatsModel({
    required this.doctorId,
    required this.totalPatients,
    required this.totalAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.totalConsultations,
    required this.totalPrescriptions,
    required this.averageRating,
    required this.totalReviews,
    required this.updatedAt,
  });

  factory DoctorStatsModel.fromJson(Map<String, dynamic> json) {
    return DoctorStatsModel(
      doctorId: json['doctorId'] ?? '',
      totalPatients: json['totalPatients'] ?? 0,
      totalAppointments: json['totalAppointments'] ?? 0,
      completedAppointments: json['completedAppointments'] ?? 0,
      cancelledAppointments: json['cancelledAppointments'] ?? 0,
      totalConsultations: json['totalConsultations'] ?? 0,
      totalPrescriptions: json['totalPrescriptions'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      updatedAt: json['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'totalPatients': totalPatients,
      'totalAppointments': totalAppointments,
      'completedAppointments': completedAppointments,
      'cancelledAppointments': cancelledAppointments,
      'totalConsultations': totalConsultations,
      'totalPrescriptions': totalPrescriptions,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'updatedAt': updatedAt,
    };
  }
}
