class PredictionResultModel {
  final String id;
  final String userId;
  final String type; // 'stroke', 'diabetes'
  final double riskScore; // 0.0 to 1.0
  final String riskLevel; // 'low', 'medium', 'high'
  final Map<String, dynamic> inputData;
  final DateTime createdAt;

  PredictionResultModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.riskScore,
    required this.riskLevel,
    required this.inputData,
    required this.createdAt,
  });

  factory PredictionResultModel.fromJson(Map<String, dynamic> json) {
    return PredictionResultModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      riskScore: (json['riskScore'] as num).toDouble(),
      riskLevel: json['riskLevel'] as String,
      inputData: Map<String, dynamic>.from(json['inputData'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'riskScore': riskScore,
      'riskLevel': riskLevel,
      'inputData': inputData,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
