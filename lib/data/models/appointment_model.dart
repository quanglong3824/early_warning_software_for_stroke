class AppointmentModel {
  final String appointmentId;
  final String userId;
  final String doctorId;
  final String? doctorName;
  final int appointmentTime;
  final String location;
  final String? department;
  final String? building;
  final String? floor;
  final String? room;
  final String reason;
  final String status; // pending, confirmed, cancelled, completed, rescheduled
  final String createdBy;
  final int createdAt;
  final int? updatedAt;
  final int? confirmedAt;
  final int? cancelledAt;
  final String? cancelReason;
  final int? rescheduledAt;
  final String? rescheduleReason;
  final int? proposedTime;
  final String? proposedByUser;
  final String? notes;

  AppointmentModel({
    required this.appointmentId,
    required this.userId,
    required this.doctorId,
    this.doctorName,
    required this.appointmentTime,
    required this.location,
    this.department,
    this.building,
    this.floor,
    this.room,
    required this.reason,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.confirmedAt,
    this.cancelledAt,
    this.cancelReason,
    this.rescheduledAt,
    this.rescheduleReason,
    this.proposedTime,
    this.proposedByUser,
    this.notes,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      appointmentId: json['appointmentId'] ?? '',
      userId: json['userId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      doctorName: json['doctorName'],
      appointmentTime: json['appointmentTime'] ?? 0,
      location: json['location'] ?? '',
      department: json['department'],
      building: json['building'],
      floor: json['floor'],
      room: json['room'],
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      createdBy: json['createdBy'] ?? '',
      createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: json['updatedAt'],
      confirmedAt: json['confirmedAt'],
      cancelledAt: json['cancelledAt'],
      cancelReason: json['cancelReason'],
      rescheduledAt: json['rescheduledAt'],
      rescheduleReason: json['rescheduleReason'],
      proposedTime: json['proposedTime'],
      proposedByUser: json['proposedByUser'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'userId': userId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'appointmentTime': appointmentTime,
      'location': location,
      'department': department,
      'building': building,
      'floor': floor,
      'room': room,
      'reason': reason,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'confirmedAt': confirmedAt,
      'cancelledAt': cancelledAt,
      'cancelReason': cancelReason,
      'rescheduledAt': rescheduledAt,
      'rescheduleReason': rescheduleReason,
      'proposedTime': proposedTime,
      'proposedByUser': proposedByUser,
      'notes': notes,
    };
  }

  bool get isUpcoming => appointmentTime > DateTime.now().millisecondsSinceEpoch;
  bool get isPast => !isUpcoming;
  bool get canCancel => status == 'pending' || status == 'confirmed';
  bool get canReschedule => status == 'pending' || status == 'confirmed';
}
