class PrescriptionModel {
  final String prescriptionId;
  final String userId;
  final String doctorId;
  final String? doctorName;
  final String? diagnosis;
  final List<PrescriptionItem> items;
  final String status; // active, completed, cancelled
  final int prescribedDate;
  final int? startDate;
  final int? endDate;
  final String? notes;
  final int createdAt;

  PrescriptionModel({
    required this.prescriptionId,
    required this.userId,
    required this.doctorId,
    this.doctorName,
    this.diagnosis,
    required this.items,
    required this.status,
    required this.prescribedDate,
    this.startDate,
    this.endDate,
    this.notes,
    required this.createdAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      prescriptionId: json['prescriptionId'] ?? '',
      userId: json['userId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      doctorName: json['doctorName'],
      diagnosis: json['diagnosis'],
      items: (json['items'] as List?)
              ?.map((item) => PrescriptionItem.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      status: json['status'] ?? 'active',
      prescribedDate: json['prescribedDate'] ?? DateTime.now().millisecondsSinceEpoch,
      startDate: json['startDate'],
      endDate: json['endDate'],
      notes: json['notes'],
      createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prescriptionId': prescriptionId,
      'userId': userId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'diagnosis': diagnosis,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status,
      'prescribedDate': prescribedDate,
      'startDate': startDate,
      'endDate': endDate,
      'notes': notes,
      'createdAt': createdAt,
    };
  }
}

class PrescriptionItem {
  final String medicationName;
  final String dosage;
  final String frequency;
  final int duration; // days
  final String? instructions;

  PrescriptionItem({
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      medicationName: json['medicationName'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      duration: json['duration'] ?? 0,
      instructions: json['instructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
    };
  }
}

class ReminderModel {
  final String reminderId;
  final String userId;
  final String prescriptionId;
  final String medicationName;
  final String dosage;
  final List<String> times; // HH:mm format
  final bool isActive;
  final int? startDate;
  final int? endDate;
  final int createdAt;

  ReminderModel({
    required this.reminderId,
    required this.userId,
    required this.prescriptionId,
    required this.medicationName,
    required this.dosage,
    required this.times,
    required this.isActive,
    this.startDate,
    this.endDate,
    required this.createdAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      reminderId: json['reminderId'] ?? '',
      userId: json['userId'] ?? '',
      prescriptionId: json['prescriptionId'] ?? '',
      medicationName: json['medicationName'] ?? '',
      dosage: json['dosage'] ?? '',
      times: (json['times'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isActive: json['isActive'] ?? true,
      startDate: json['startDate'],
      endDate: json['endDate'],
      createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reminderId': reminderId,
      'userId': userId,
      'prescriptionId': prescriptionId,
      'medicationName': medicationName,
      'dosage': dosage,
      'times': times,
      'isActive': isActive,
      'startDate': startDate,
      'endDate': endDate,
      'createdAt': createdAt,
    };
  }
}
