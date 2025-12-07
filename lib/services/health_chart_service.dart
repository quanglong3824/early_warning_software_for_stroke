import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

/// Date range for filtering health data
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
  
  /// Check if a date falls within this range (inclusive)
  bool contains(DateTime date) {
    final startOfDay = DateTime(start.year, start.month, start.day);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return !date.isBefore(startOfDay) && !date.isAfter(endOfDay);
  }
  
  /// Create a date range for the last N days
  factory DateRange.lastDays(int days) {
    final now = DateTime.now();
    return DateRange(
      start: now.subtract(Duration(days: days)),
      end: now,
    );
  }
  
  /// Create a date range for the last week
  factory DateRange.lastWeek() => DateRange.lastDays(7);
  
  /// Create a date range for the last month
  factory DateRange.lastMonth() => DateRange.lastDays(30);
  
  /// Create a date range for the last 3 months
  factory DateRange.last3Months() => DateRange.lastDays(90);
}

/// Data point for charts
class ChartDataPoint {
  final DateTime date;
  final double value;
  final String? label;

  ChartDataPoint({
    required this.date,
    required this.value,
    this.label,
  });
  
  Map<String, dynamic> toJson() => {
    'date': date.millisecondsSinceEpoch,
    'value': value,
    'label': label,
  };
  
  factory ChartDataPoint.fromJson(Map<String, dynamic> json) => ChartDataPoint(
    date: DateTime.fromMillisecondsSinceEpoch(json['date'] ?? 0),
    value: (json['value'] ?? 0).toDouble(),
    label: json['label'],
  );
  
  @override
  String toString() => 'ChartDataPoint(date: $date, value: $value, label: $label)';
}

/// Blood pressure data point with systolic and diastolic values
class BloodPressureDataPoint {
  final DateTime date;
  final double systolic;
  final double diastolic;

  BloodPressureDataPoint({
    required this.date,
    required this.systolic,
    required this.diastolic,
  });
  
  @override
  String toString() => 'BP(date: $date, sys: $systolic, dia: $diastolic)';
}

/// Health summary for dashboard
class HealthSummary {
  final double? latestSystolic;
  final double? latestDiastolic;
  final double? latestBmi;
  final String? latestStrokeRisk;
  final String? latestDiabetesRisk;
  final int totalRecords;
  final DateTime? lastUpdated;

  HealthSummary({
    this.latestSystolic,
    this.latestDiastolic,
    this.latestBmi,
    this.latestStrokeRisk,
    this.latestDiabetesRisk,
    this.totalRecords = 0,
    this.lastUpdated,
  });
}


/// Abstract interface for Health Chart Service
/// Implements Requirements 4.1, 4.2, 4.3
abstract class IHealthChartService {
  /// Gets blood pressure data for charting (systolic values)
  /// Requirements: 4.1
  Future<List<ChartDataPoint>> getBloodPressureData(
    String userId,
    DateRange range,
  );
  
  /// Gets complete blood pressure data with both systolic and diastolic
  /// Requirements: 4.1
  Future<List<BloodPressureDataPoint>> getBloodPressureDataComplete(
    String userId,
    DateRange range,
  );
  
  /// Gets prediction history for charting
  /// Requirements: 4.2
  Future<List<ChartDataPoint>> getPredictionHistory(
    String userId,
    String predictionType,
  );
  
  /// Gets health summary for dashboard
  Future<HealthSummary> getHealthSummary(String userId);
  
  /// Filters data points by date range
  /// Requirements: 4.3
  List<ChartDataPoint> filterByDateRange(
    List<ChartDataPoint> data,
    DateRange range,
  );
}

/// Implementation of Health Chart Service
class HealthChartService implements IHealthChartService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  @override
  Future<List<ChartDataPoint>> getBloodPressureData(
    String userId,
    DateRange range,
  ) async {
    // Try user-specific path first (health_records/{userId})
    var snapshot = await _database
        .child('health_records')
        .child(userId)
        .get();
    
    // Fallback to query by userId field if user-specific path is empty
    if (!snapshot.exists) {
      snapshot = await _database
          .child('health_records')
          .orderByChild('userId')
          .equalTo(userId)
          .get();
    }
    
    if (!snapshot.exists) return [];
    
    final records = <ChartDataPoint>[];
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    
    data.forEach((key, value) {
      final record = Map<String, dynamic>.from(value as Map);
      // Support both 'recordedAt' and 'createdAt' timestamp fields
      final timestamp = record['recordedAt'] as int? ?? record['createdAt'] as int?;
      // Support both 'systolicBP' and 'systolic' field names
      final systolic = record['systolicBP'] ?? record['systolic'];
      
      if (timestamp != null && systolic != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        records.add(ChartDataPoint(
          date: date,
          value: (systolic as num).toDouble(),
          label: 'Systolic',
        ));
      }
    });
    
    // Filter by date range and sort
    final filtered = filterByDateRange(records, range);
    filtered.sort((a, b) => a.date.compareTo(b.date));
    
    return filtered;
  }
  
  @override
  Future<List<BloodPressureDataPoint>> getBloodPressureDataComplete(
    String userId,
    DateRange range,
  ) async {
    // Try user-specific path first (health_records/{userId})
    var snapshot = await _database
        .child('health_records')
        .child(userId)
        .get();
    
    // Fallback to query by userId field if user-specific path is empty
    if (!snapshot.exists) {
      snapshot = await _database
          .child('health_records')
          .orderByChild('userId')
          .equalTo(userId)
          .get();
    }
    
    if (!snapshot.exists) return [];
    
    final records = <BloodPressureDataPoint>[];
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    
    data.forEach((key, value) {
      final record = Map<String, dynamic>.from(value as Map);
      final timestamp = record['recordedAt'] as int? ?? record['createdAt'] as int?;
      final systolic = record['systolicBP'] ?? record['systolic'];
      final diastolic = record['diastolicBP'] ?? record['diastolic'];
      
      if (timestamp != null && systolic != null && diastolic != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (range.contains(date)) {
          records.add(BloodPressureDataPoint(
            date: date,
            systolic: (systolic as num).toDouble(),
            diastolic: (diastolic as num).toDouble(),
          ));
        }
      }
    });
    
    // Sort by date
    records.sort((a, b) => a.date.compareTo(b.date));
    
    return records;
  }


  @override
  Future<List<ChartDataPoint>> getPredictionHistory(
    String userId,
    String predictionType,
  ) async {
    final path = predictionType == 'stroke' 
        ? 'stroke_predictions' 
        : 'diabetes_predictions';
    
    // Try user-specific path first
    var snapshot = await _database
        .child(path)
        .child(userId)
        .get();
    
    // Fallback to query by userId field
    if (!snapshot.exists) {
      snapshot = await _database
          .child(path)
          .orderByChild('userId')
          .equalTo(userId)
          .get();
    }
    
    if (!snapshot.exists) return [];
    
    final records = <ChartDataPoint>[];
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    
    data.forEach((key, value) {
      final record = Map<String, dynamic>.from(value as Map);
      final timestamp = record['createdAt'] as int? ?? record['timestamp'] as int?;
      // Support multiple field names for risk score
      final riskScore = record['riskScore'] ?? record['probability'] ?? record['risk_percentage'];
      
      if (timestamp != null && riskScore != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        // Convert risk score to percentage if needed (0-1 to 0-100)
        double scoreValue = (riskScore as num).toDouble();
        if (scoreValue <= 1.0) {
          scoreValue = scoreValue * 100;
        }
        
        records.add(ChartDataPoint(
          date: date,
          value: scoreValue,
          label: predictionType == 'stroke' ? 'Đột quỵ' : 'Tiểu đường',
        ));
      }
    });
    
    records.sort((a, b) => a.date.compareTo(b.date));
    return records;
  }
  
  @override
  Future<HealthSummary> getHealthSummary(String userId) async {
    double? systolic, diastolic, bmi;
    DateTime? lastUpdated;
    int totalRecords = 0;
    
    // Try user-specific path first for health records
    var healthSnapshot = await _database
        .child('health_records')
        .child(userId)
        .orderByChild('recordedAt')
        .limitToLast(1)
        .get();
    
    // Fallback to query by userId field
    if (!healthSnapshot.exists) {
      healthSnapshot = await _database
          .child('health_records')
          .orderByChild('userId')
          .equalTo(userId)
          .limitToLast(1)
          .get();
    }
    
    if (healthSnapshot.exists) {
      final data = Map<String, dynamic>.from(healthSnapshot.value as Map);
      // Get the most recent record
      Map<String, dynamic>? latestRecord;
      int latestTimestamp = 0;
      
      data.forEach((key, value) {
        final record = Map<String, dynamic>.from(value as Map);
        final timestamp = record['recordedAt'] as int? ?? record['createdAt'] as int? ?? 0;
        if (timestamp > latestTimestamp) {
          latestTimestamp = timestamp;
          latestRecord = record;
        }
      });
      
      if (latestRecord != null) {
        systolic = (latestRecord!['systolicBP'] as num?)?.toDouble() ?? 
                   (latestRecord!['systolic'] as num?)?.toDouble();
        diastolic = (latestRecord!['diastolicBP'] as num?)?.toDouble() ?? 
                    (latestRecord!['diastolic'] as num?)?.toDouble();
        bmi = (latestRecord!['bmi'] as num?)?.toDouble();
        
        // Calculate BMI if weight and height are available
        if (bmi == null) {
          final weight = (latestRecord!['weight'] as num?)?.toDouble();
          final height = (latestRecord!['height'] as num?)?.toDouble();
          if (weight != null && height != null && height > 0) {
            final heightInMeters = height > 3 ? height / 100 : height;
            bmi = weight / (heightInMeters * heightInMeters);
          }
        }
        
        if (latestTimestamp > 0) {
          lastUpdated = DateTime.fromMillisecondsSinceEpoch(latestTimestamp);
        }
      }
    }
    
    // Count total records
    var countSnapshot = await _database
        .child('health_records')
        .child(userId)
        .get();
    
    if (!countSnapshot.exists) {
      countSnapshot = await _database
          .child('health_records')
          .orderByChild('userId')
          .equalTo(userId)
          .get();
    }
    
    if (countSnapshot.exists) {
      totalRecords = (countSnapshot.value as Map).length;
    }
    
    // Get latest predictions
    String? strokeRisk, diabetesRisk;
    
    var strokeSnapshot = await _database
        .child('stroke_predictions')
        .child(userId)
        .orderByChild('createdAt')
        .limitToLast(1)
        .get();
    
    if (!strokeSnapshot.exists) {
      strokeSnapshot = await _database
          .child('stroke_predictions')
          .orderByChild('userId')
          .equalTo(userId)
          .limitToLast(1)
          .get();
    }
    
    if (strokeSnapshot.exists) {
      final data = Map<String, dynamic>.from(strokeSnapshot.value as Map);
      final latest = Map<String, dynamic>.from(data.values.first as Map);
      strokeRisk = latest['riskLevel'] as String? ?? latest['risk_level'] as String?;
    }
    
    var diabetesSnapshot = await _database
        .child('diabetes_predictions')
        .child(userId)
        .orderByChild('createdAt')
        .limitToLast(1)
        .get();
    
    if (!diabetesSnapshot.exists) {
      diabetesSnapshot = await _database
          .child('diabetes_predictions')
          .orderByChild('userId')
          .equalTo(userId)
          .limitToLast(1)
          .get();
    }
    
    if (diabetesSnapshot.exists) {
      final data = Map<String, dynamic>.from(diabetesSnapshot.value as Map);
      final latest = Map<String, dynamic>.from(data.values.first as Map);
      diabetesRisk = latest['riskLevel'] as String? ?? latest['risk_level'] as String?;
    }
    
    return HealthSummary(
      latestSystolic: systolic,
      latestDiastolic: diastolic,
      latestBmi: bmi,
      latestStrokeRisk: strokeRisk,
      latestDiabetesRisk: diabetesRisk,
      totalRecords: totalRecords,
      lastUpdated: lastUpdated,
    );
  }
  
  @override
  List<ChartDataPoint> filterByDateRange(
    List<ChartDataPoint> data,
    DateRange range,
  ) {
    return data.where((point) => range.contains(point.date)).toList();
  }
}
