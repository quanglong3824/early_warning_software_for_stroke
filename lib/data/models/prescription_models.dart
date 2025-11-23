import 'medication_models.dart';

class PrescriptionModel {
  final String prescriptionId;
  final String prescriptionCode; // Mã đơn thuốc unique (8-10 ký tự)
  final String userId;
  final String? patientName;
  final String doctorId;
  final String? doctorName;
  final String? diagnosis;
  final List<PrescriptionMedicationModel> medications; // Changed from items
  final String status; // active, completed, cancelled
  final int prescribedDate;
  final int? startDate;
  final int? endDate;
  final String? notes;
  final double totalAmount; // Tổng tiền ước tính
  final bool isPurchased; // Đã mua chưa
  final int? purchaseDate;
  final String? orderId; // ID đơn hàng nếu đã mua
  final int createdAt;
  final int? updatedAt;

  PrescriptionModel({
    required this.prescriptionId,
    required this.prescriptionCode,
    required this.userId,
    this.patientName,
    required this.doctorId,
    this.doctorName,
    this.diagnosis,
    required this.medications,
    required this.status,
    required this.prescribedDate,
    this.startDate,
    this.endDate,
    this.notes,
    this.totalAmount = 0,
    this.isPurchased = false,
    this.purchaseDate,
    this.orderId,
    required this.createdAt,
    this.updatedAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    final medsList = json['medications'] as List<dynamic>? ?? 
                     json['items'] as List<dynamic>? ?? []; // Support old format
    final medications = medsList
        .map((item) => PrescriptionMedicationModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return PrescriptionModel(
      prescriptionId: json['prescriptionId'] as String? ?? '',
      prescriptionCode: json['prescriptionCode'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      patientName: json['patientName'] as String?,
      doctorId: json['doctorId'] as String? ?? '',
      doctorName: json['doctorName'] as String?,
      diagnosis: json['diagnosis'] as String?,
      medications: medications,
      status: json['status'] as String? ?? 'active',
      prescribedDate: json['prescribedDate'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      startDate: json['startDate'] as int?,
      endDate: json['endDate'] as int?,
      notes: json['notes'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      isPurchased: json['isPurchased'] as bool? ?? false,
      purchaseDate: json['purchaseDate'] as int?,
      orderId: json['orderId'] as String?,
      createdAt: json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: json['updatedAt'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prescriptionId': prescriptionId,
      'prescriptionCode': prescriptionCode,
      'userId': userId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'diagnosis': diagnosis,
      'medications': medications.map((med) => med.toJson()).toList(),
      'status': status,
      'prescribedDate': prescribedDate,
      'startDate': startDate,
      'endDate': endDate,
      'notes': notes,
      'totalAmount': totalAmount,
      'isPurchased': isPurchased,
      'purchaseDate': purchaseDate,
      'orderId': orderId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  PrescriptionModel copyWith({
    String? prescriptionId,
    String? prescriptionCode,
    String? userId,
    String? patientName,
    String? doctorId,
    String? doctorName,
    String? diagnosis,
    List<PrescriptionMedicationModel>? medications,
    String? status,
    int? prescribedDate,
    int? startDate,
    int? endDate,
    String? notes,
    double? totalAmount,
    bool? isPurchased,
    int? purchaseDate,
    String? orderId,
    int? createdAt,
    int? updatedAt,
  }) {
    return PrescriptionModel(
      prescriptionId: prescriptionId ?? this.prescriptionId,
      prescriptionCode: prescriptionCode ?? this.prescriptionCode,
      userId: userId ?? this.userId,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      diagnosis: diagnosis ?? this.diagnosis,
      medications: medications ?? this.medications,
      status: status ?? this.status,
      prescribedDate: prescribedDate ?? this.prescribedDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      totalAmount: totalAmount ?? this.totalAmount,
      isPurchased: isPurchased ?? this.isPurchased,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      orderId: orderId ?? this.orderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


// PrescriptionItem is now replaced by PrescriptionMedicationModel from medication_models.dart


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
