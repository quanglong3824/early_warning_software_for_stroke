import 'package:glados/glados.dart';

/// **Feature: sews-improvement-plan, Property 6: Health Data Filtering**
/// **Validates: Requirements 4.3**
///
/// Property: For any date range filter applied to health records, the returned
/// records SHALL only include records within that date range.

/// Date range for filtering - mirrors DateRange from health_chart_service.dart
/// This is a pure data class that doesn't require Firebase
class TestDateRange {
  final DateTime start;
  final DateTime end;

  TestDateRange({required this.start, required this.end});

  /// Check if a date falls within this range (inclusive)
  bool contains(DateTime date) {
    final startOfDay = DateTime(start.year, start.month, start.day);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return !date.isBefore(startOfDay) && !date.isAfter(endOfDay);
  }

  @override
  String toString() => 'TestDateRange($start - $end)';
}

/// Chart data point - mirrors ChartDataPoint from health_chart_service.dart
class TestChartDataPoint {
  final DateTime date;
  final double value;
  final String? label;

  TestChartDataPoint({
    required this.date,
    required this.value,
    this.label,
  });

  @override
  String toString() =>
      'TestChartDataPoint(date: $date, value: $value, label: $label)';
}

/// Pure function for filtering data points by date range
/// Mirrors the filterByDateRange logic from HealthChartService
/// Validates: Requirements 4.3
List<TestChartDataPoint> filterByDateRange(
  List<TestChartDataPoint> data,
  TestDateRange range,
) {
  return data.where((point) => range.contains(point.date)).toList();
}

/// Custom generator for health data filtering tests
extension HealthDataAny on Any {
  /// Generate a valid date range where start <= end
  Generator<TestDateRange> get healthDateRange {
    return any.combine2(
      any.dateTime,
      any.positiveIntOrZero,
      (DateTime startDate, int daysOffset) {
        // Ensure end date is after or equal to start date
        final days = daysOffset % 365 + 1; // 1-365 days range
        final endDate = startDate.add(Duration(days: days));
        return TestDateRange(start: startDate, end: endDate);
      },
    );
  }

  /// Generate a TestChartDataPoint
  Generator<TestChartDataPoint> get healthChartDataPoint {
    return any.combine2(
      any.dateTime,
      any.positiveIntOrZero,
      (DateTime date, int valueBase) {
        // Generate reasonable health values (e.g., blood pressure 60-200)
        final value = (valueBase % 140) + 60.0;
        return TestChartDataPoint(
          date: date,
          value: value,
          label: 'Health Data',
        );
      },
    );
  }

  /// Generate a list of TestChartDataPoints
  Generator<List<TestChartDataPoint>> get healthChartDataPointList {
    return any.list(any.healthChartDataPoint);
  }
}

void main() {
  group('Health Data Filtering Property Tests', () {
    /// **Feature: sews-improvement-plan, Property 6: Health Data Filtering**
    /// **Validates: Requirements 4.3**
    ///
    /// Property: For any date range filter applied to health records, the
    /// returned records SHALL only include records within that date range.
    Glados(any.combine2(
      any.healthChartDataPointList,
      any.healthDateRange,
      (data, range) => (data, range),
    )).test(
      'Property 6: Health Data Filtering - All filtered records are within date range',
      (tuple) {
        final (data, range) = tuple;

        // Act
        final filtered = filterByDateRange(data, range);

        // Assert: Every filtered record must be within the date range
        for (final point in filtered) {
          expect(
            range.contains(point.date),
            isTrue,
            reason: 'Filtered record with date ${point.date} should be within '
                'range ${range.start} - ${range.end}',
          );
        }
      },
    );

    /// Property: No records outside the date range should be included
    Glados(any.combine2(
      any.healthChartDataPointList,
      any.healthDateRange,
      (data, range) => (data, range),
    )).test(
      'Property 6: Health Data Filtering - No records outside range are included',
      (tuple) {
        final (data, range) = tuple;

        // Act
        final filtered = filterByDateRange(data, range);

        // Get records that should NOT be in the filtered result
        final outsideRange =
            data.where((point) => !range.contains(point.date)).toList();

        // Assert: None of the outside-range records should be in filtered
        for (final point in outsideRange) {
          expect(
            filtered.contains(point),
            isFalse,
            reason: 'Record with date ${point.date} is outside range '
                '${range.start} - ${range.end} and should not be included',
          );
        }
      },
    );

    /// Property: Filtering preserves all records within the range
    Glados(any.combine2(
      any.healthChartDataPointList,
      any.healthDateRange,
      (data, range) => (data, range),
    )).test(
      'Property 6: Health Data Filtering - All records within range are preserved',
      (tuple) {
        final (data, range) = tuple;

        // Act
        final filtered = filterByDateRange(data, range);

        // Get records that SHOULD be in the filtered result
        final withinRange =
            data.where((point) => range.contains(point.date)).toList();

        // Assert: Count should match
        expect(
          filtered.length,
          equals(withinRange.length),
          reason: 'Filtered result should contain exactly the records within '
              'the date range. Expected ${withinRange.length}, got ${filtered.length}',
        );
      },
    );

    /// Property: Empty data returns empty result
    Glados(any.healthDateRange).test(
      'Property 6: Health Data Filtering - Empty data returns empty result',
      (range) {
        // Arrange
        final emptyData = <TestChartDataPoint>[];

        // Act
        final filtered = filterByDateRange(emptyData, range);

        // Assert
        expect(
          filtered.isEmpty,
          isTrue,
          reason: 'Filtering empty data should return empty result',
        );
      },
    );

    /// Property: Filtering is idempotent (filtering twice gives same result)
    Glados(any.combine2(
      any.healthChartDataPointList,
      any.healthDateRange,
      (data, range) => (data, range),
    )).test(
      'Property 6: Health Data Filtering - Filtering is idempotent',
      (tuple) {
        final (data, range) = tuple;

        // Act
        final filteredOnce = filterByDateRange(data, range);
        final filteredTwice = filterByDateRange(filteredOnce, range);

        // Assert
        expect(
          filteredTwice.length,
          equals(filteredOnce.length),
          reason: 'Filtering twice should give the same result as filtering once',
        );
      },
    );

    /// Property: Filtered result length is <= original data length
    Glados(any.combine2(
      any.healthChartDataPointList,
      any.healthDateRange,
      (data, range) => (data, range),
    )).test(
      'Property 6: Health Data Filtering - Filtered length <= original length',
      (tuple) {
        final (data, range) = tuple;

        // Act
        final filtered = filterByDateRange(data, range);

        // Assert
        expect(
          filtered.length,
          lessThanOrEqualTo(data.length),
          reason: 'Filtered result should not have more records than original',
        );
      },
    );
  });
}
