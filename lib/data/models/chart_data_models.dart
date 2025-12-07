// Chart data models for health visualization
// Requirements: 4.1

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
  
  /// Create a date range for the last year
  factory DateRange.lastYear() => DateRange.lastDays(365);
  
  /// Get the number of days in this range
  int get dayCount => end.difference(start).inDays + 1;
  
  @override
  String toString() => 'DateRange($start - $end)';
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
  
  /// Get blood pressure status based on values
  String get status {
    if (systolic >= 180 || diastolic >= 120) return 'crisis';
    if (systolic >= 140 || diastolic >= 90) return 'high';
    if (systolic >= 130 || diastolic >= 80) return 'elevated';
    if (systolic < 90 || diastolic < 60) return 'low';
    return 'normal';
  }
  
  /// Get formatted blood pressure string
  String get formatted => '${systolic.toInt()}/${diastolic.toInt()}';
  
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
  
  /// Check if there is any health data
  bool get hasData => totalRecords > 0;
  
  /// Get formatted blood pressure string
  String? get bloodPressureFormatted {
    if (latestSystolic != null && latestDiastolic != null) {
      return '${latestSystolic!.toInt()}/${latestDiastolic!.toInt()}';
    }
    return null;
  }
  
  /// Get BMI category
  String? get bmiCategory {
    if (latestBmi == null) return null;
    if (latestBmi! < 18.5) return 'Thiếu cân';
    if (latestBmi! < 25) return 'Bình thường';
    if (latestBmi! < 30) return 'Thừa cân';
    return 'Béo phì';
  }
}

/// Utility class for chart data transformations
class ChartDataUtils {
  /// Filter data points by date range
  static List<ChartDataPoint> filterByDateRange(
    List<ChartDataPoint> data,
    DateRange range,
  ) {
    return data.where((point) => range.contains(point.date)).toList();
  }
  
  /// Sort data points by date (ascending)
  static List<ChartDataPoint> sortByDate(List<ChartDataPoint> data) {
    final sorted = List<ChartDataPoint>.from(data);
    sorted.sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }
  
  /// Calculate average value from data points
  static double? calculateAverage(List<ChartDataPoint> data) {
    if (data.isEmpty) return null;
    final sum = data.fold<double>(0, (sum, point) => sum + point.value);
    return sum / data.length;
  }
  
  /// Get min value from data points
  static double? getMinValue(List<ChartDataPoint> data) {
    if (data.isEmpty) return null;
    return data.map((p) => p.value).reduce((a, b) => a < b ? a : b);
  }
  
  /// Get max value from data points
  static double? getMaxValue(List<ChartDataPoint> data) {
    if (data.isEmpty) return null;
    return data.map((p) => p.value).reduce((a, b) => a > b ? a : b);
  }
  
  /// Group data points by day (for aggregation)
  static Map<DateTime, List<ChartDataPoint>> groupByDay(List<ChartDataPoint> data) {
    final grouped = <DateTime, List<ChartDataPoint>>{};
    for (final point in data) {
      final dayKey = DateTime(point.date.year, point.date.month, point.date.day);
      grouped.putIfAbsent(dayKey, () => []).add(point);
    }
    return grouped;
  }
  
  /// Get daily averages from data points
  static List<ChartDataPoint> getDailyAverages(List<ChartDataPoint> data) {
    final grouped = groupByDay(data);
    return grouped.entries.map((entry) {
      final avg = entry.value.fold<double>(0, (sum, p) => sum + p.value) / entry.value.length;
      return ChartDataPoint(
        date: entry.key,
        value: avg,
        label: data.isNotEmpty ? data.first.label : null,
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }
}
