import 'package:glados/glados.dart';

/// **Feature: sews-improvement-plan, Property 14: Leave Period Blocking**
/// **Validates: Requirements 8.4**
///
/// Property: For any doctor leave period, no appointments SHALL be bookable
/// during that period. This means isOnLeave should return true for any date
/// within the leave period.

/// Test leave record - mirrors LeaveRecord from doctor_schedule_service.dart
/// This is a pure data class that doesn't require Firebase
class TestLeaveRecord {
  final String leaveId;
  final String doctorId;
  final int startDate; // milliseconds since epoch
  final int endDate; // milliseconds since epoch
  final String? reason;

  TestLeaveRecord({
    required this.leaveId,
    required this.doctorId,
    required this.startDate,
    required this.endDate,
    this.reason,
  });

  @override
  String toString() =>
      'TestLeaveRecord(start: ${DateTime.fromMillisecondsSinceEpoch(startDate)}, '
      'end: ${DateTime.fromMillisecondsSinceEpoch(endDate)})';
}

/// Pure function for checking if a date is within a leave period
/// Mirrors the isOnLeave logic from DoctorScheduleService
/// Validates: Requirements 8.4
bool isOnLeave(DateTime date, List<TestLeaveRecord> leaves) {
  for (final leave in leaves) {
    final startDate = DateTime.fromMillisecondsSinceEpoch(leave.startDate);
    final endDate = DateTime.fromMillisecondsSinceEpoch(leave.endDate);

    if (date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        date.isBefore(endDate.add(const Duration(days: 1)))) {
      return true;
    }
  }
  return false;
}

/// Custom generator for DateTime values
extension DateTimeAny on Any {
  /// Generator for valid DateTime values within a reasonable range
  Generator<DateTime> get validDateTime {
    return any.positiveIntOrZero.bind((yearOffset) {
      return any.positiveIntOrZero.bind((monthOffset) {
        return any.positiveIntOrZero.bind((dayOffset) {
          return any.positiveIntOrZero.bind((hourOffset) {
            return any.positiveIntOrZero.map((minuteOffset) {
              // Generate dates between 2020 and 2030
              final year = 2020 + (yearOffset % 11);
              final month = 1 + (monthOffset % 12);
              final day = 1 + (dayOffset % 28); // Safe for all months
              final hour = hourOffset % 24;
              final minute = minuteOffset % 60;

              return DateTime(year, month, day, hour, minute);
            });
          });
        });
      });
    });
  }
}

/// Generator for leave duration in days (1-30 days)
extension LeaveDurationAny on Any {
  Generator<int> get leaveDurationDays {
    return any.positiveIntOrZero.map((value) => 1 + (value % 30));
  }
}

/// Generator for offset within leave period (0.0 to 1.0)
extension OffsetAny on Any {
  Generator<double> get offsetFraction {
    return any.positiveIntOrZero.map((value) => (value % 101) / 100.0);
  }
}

void main() {
  group('Leave Period Blocking Property Tests', () {
    /// **Feature: sews-improvement-plan, Property 14: Leave Period Blocking**
    /// **Validates: Requirements 8.4**
    ///
    /// Property: For any date within a leave period, isOnLeave should return true.
    Glados3(any.validDateTime, any.leaveDurationDays, any.offsetFraction).test(
      'Property 14: Any date within leave period is blocked',
      (leaveStartDate, durationDays, offsetFraction) {
        // Arrange: Create a leave period
        final leaveEndDate = leaveStartDate.add(Duration(days: durationDays));

        final leave = TestLeaveRecord(
          leaveId: 'test-leave-1',
          doctorId: 'doctor-1',
          startDate: leaveStartDate.millisecondsSinceEpoch,
          endDate: leaveEndDate.millisecondsSinceEpoch,
          reason: 'Test leave',
        );

        // Generate a date within the leave period using the offset fraction
        final totalDuration = leaveEndDate.difference(leaveStartDate);
        final offsetDuration = Duration(
          milliseconds: (totalDuration.inMilliseconds * offsetFraction).round(),
        );
        final dateWithinLeave = leaveStartDate.add(offsetDuration);

        // Act
        final result = isOnLeave(dateWithinLeave, [leave]);

        // Assert: Date within leave period should be blocked
        expect(
          result,
          isTrue,
          reason: 'Date $dateWithinLeave should be blocked because it falls within '
              'leave period from $leaveStartDate to $leaveEndDate',
        );
      },
    );


    /// Property: Date before leave period should not be blocked
    Glados2(any.validDateTime, any.leaveDurationDays).test(
      'Property 14: Date before leave period is not blocked',
      (leaveStartDate, durationDays) {
        // Arrange: Create a leave period
        final leaveEndDate = leaveStartDate.add(Duration(days: durationDays));

        final leave = TestLeaveRecord(
          leaveId: 'test-leave-1',
          doctorId: 'doctor-1',
          startDate: leaveStartDate.millisecondsSinceEpoch,
          endDate: leaveEndDate.millisecondsSinceEpoch,
          reason: 'Test leave',
        );

        // Generate a date clearly before the leave period (at least 2 days before)
        final dateBeforeLeave = leaveStartDate.subtract(const Duration(days: 2));

        // Act
        final result = isOnLeave(dateBeforeLeave, [leave]);

        // Assert: Date before leave period should not be blocked
        expect(
          result,
          isFalse,
          reason: 'Date $dateBeforeLeave should NOT be blocked because it is before '
              'leave period starting at $leaveStartDate',
        );
      },
    );

    /// Property: Date after leave period should not be blocked
    Glados2(any.validDateTime, any.leaveDurationDays).test(
      'Property 14: Date after leave period is not blocked',
      (leaveStartDate, durationDays) {
        // Arrange: Create a leave period
        final leaveEndDate = leaveStartDate.add(Duration(days: durationDays));

        final leave = TestLeaveRecord(
          leaveId: 'test-leave-1',
          doctorId: 'doctor-1',
          startDate: leaveStartDate.millisecondsSinceEpoch,
          endDate: leaveEndDate.millisecondsSinceEpoch,
          reason: 'Test leave',
        );

        // Generate a date clearly after the leave period (at least 2 days after)
        final dateAfterLeave = leaveEndDate.add(const Duration(days: 2));

        // Act
        final result = isOnLeave(dateAfterLeave, [leave]);

        // Assert: Date after leave period should not be blocked
        expect(
          result,
          isFalse,
          reason: 'Date $dateAfterLeave should NOT be blocked because it is after '
              'leave period ending at $leaveEndDate',
        );
      },
    );

    /// Property: Leave start date itself should be blocked
    Glados2(any.validDateTime, any.leaveDurationDays).test(
      'Property 14: Leave start date is blocked',
      (leaveStartDate, durationDays) {
        // Arrange: Create a leave period
        final leaveEndDate = leaveStartDate.add(Duration(days: durationDays));

        final leave = TestLeaveRecord(
          leaveId: 'test-leave-1',
          doctorId: 'doctor-1',
          startDate: leaveStartDate.millisecondsSinceEpoch,
          endDate: leaveEndDate.millisecondsSinceEpoch,
          reason: 'Test leave',
        );

        // Act: Check the start date itself
        final result = isOnLeave(leaveStartDate, [leave]);

        // Assert: Start date should be blocked
        expect(result, isTrue, reason: 'Leave start date $leaveStartDate should be blocked');
      },
    );

    /// Property: Leave end date itself should be blocked
    Glados2(any.validDateTime, any.leaveDurationDays).test(
      'Property 14: Leave end date is blocked',
      (leaveStartDate, durationDays) {
        // Arrange: Create a leave period
        final leaveEndDate = leaveStartDate.add(Duration(days: durationDays));

        final leave = TestLeaveRecord(
          leaveId: 'test-leave-1',
          doctorId: 'doctor-1',
          startDate: leaveStartDate.millisecondsSinceEpoch,
          endDate: leaveEndDate.millisecondsSinceEpoch,
          reason: 'Test leave',
        );

        // Act: Check the end date itself
        final result = isOnLeave(leaveEndDate, [leave]);

        // Assert: End date should be blocked
        expect(result, isTrue, reason: 'Leave end date $leaveEndDate should be blocked');
      },
    );

    /// Property: Empty leave list means no dates are blocked
    Glados(any.validDateTime).test(
      'Property 14: No leaves means no dates are blocked',
      (anyDate) {
        // Act: Check any date with empty leave list
        final result = isOnLeave(anyDate, []);

        // Assert: No dates should be blocked when there are no leaves
        expect(
          result,
          isFalse,
          reason: 'Date $anyDate should NOT be blocked when there are no leave records',
        );
      },
    );
  });
}
