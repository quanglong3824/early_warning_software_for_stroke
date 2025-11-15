class PatientModel {
  final String id;
  final String name;
  final String status; // 'high_risk', 'warning', 'stable'
  final String mainValue;
  final String unit;
  final DateTime lastUpdate;

  PatientModel({
    required this.id,
    required this.name,
    required this.status,
    required this.mainValue,
    required this.unit,
    required this.lastUpdate,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      mainValue: json['mainValue'] as String,
      unit: json['unit'] as String,
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'mainValue': mainValue,
      'unit': unit,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }
}
