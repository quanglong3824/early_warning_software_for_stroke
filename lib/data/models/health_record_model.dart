class HealthRecordModel {
  final String id;
  final String userId;
  final int recordedAt;
  final int? systolicBP;
  final int? diastolicBP;
  final int? heartRate;
  final double? bloodSugar;
  final double? weight;
  final double? height;
  final double? temperature;
  final String? notes;
  final int createdAt;

  HealthRecordModel({
    required this.id,
    required this.userId,
    required this.recordedAt,
    this.systolicBP,
    this.diastolicBP,
    this.heartRate,
    this.bloodSugar,
    this.weight,
    this.height,
    this.temperature,
    this.notes,
    required this.createdAt,
  });

  factory HealthRecordModel.fromJson(Map<String, dynamic> json) {
    return HealthRecordModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      recordedAt: json['recordedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      systolicBP: json['systolicBP'],
      diastolicBP: json['diastolicBP'],
      heartRate: json['heartRate'],
      bloodSugar: json['bloodSugar']?.toDouble(),
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      temperature: json['temperature']?.toDouble(),
      notes: json['notes'],
      createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'recordedAt': recordedAt,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'heartRate': heartRate,
      'bloodSugar': bloodSugar,
      'weight': weight,
      'height': height,
      'temperature': temperature,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  String get bloodPressure {
    if (systolicBP != null && diastolicBP != null) {
      return '$systolicBP/$diastolicBP';
    }
    return 'N/A';
  }

  String getBPStatus() {
    if (systolicBP == null || diastolicBP == null) return 'unknown';
    if (systolicBP! >= 140 || diastolicBP! >= 90) return 'high';
    if (systolicBP! < 90 || diastolicBP! < 60) return 'low';
    return 'normal';
  }

  String getHeartRateStatus() {
    if (heartRate == null) return 'unknown';
    if (heartRate! > 100) return 'high';
    if (heartRate! < 60) return 'low';
    return 'normal';
  }
}
