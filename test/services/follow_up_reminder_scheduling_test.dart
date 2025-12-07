import 'package:glados/glados.dart';
import 'package:early_warning_software_for_stroke/services/medication_reminder_service.dart';

/// **Feature: sews-improvement-plan, Property 12: Follow-up Reminder Scheduling**
/// **Validates: Requirements 7.4**
///
/// Property: For any missed medication dose, a follow-up reminder
/// SHALL be scheduled 30 minutes after the original time.

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

void main() {
  group('Follow-up Reminder Scheduling Property Tests', () {
    /// **Feature: sews-improvement-plan, Property 12: Follow-up Reminder Scheduling**
    /// **Validates: Requirements 7.4**
    ///
    /// Property: For any missed medication dose, a follow-up reminder
    /// SHALL be scheduled exactly 30 minutes after the original time.
    Glados(any.validDateTime).test(
      'Property 12: Follow-up reminder is scheduled 30 minutes after original time',
      (originalTime) {
        // Act
        final followUpTime = MedicationReminderService.calculateFollowUpTime(originalTime);

        // Assert: Follow-up time should be exactly 30 minutes after original
        final expectedFollowUpTime = originalTime.add(const Duration(minutes: 30));
        
        expect(followUpTime, equals(expectedFollowUpTime),
            reason: 'Follow-up reminder should be scheduled exactly 30 minutes after '
                'original time. Original: $originalTime, Expected: $expectedFollowUpTime, '
                'Actual: $followUpTime');
      },
    );

    /// Property: Follow-up time difference is always exactly 30 minutes
    Glados(any.validDateTime).test(
      'Property 12: Follow-up time difference is exactly 30 minutes',
      (originalTime) {
        // Act
        final followUpTime = MedicationReminderService.calculateFollowUpTime(originalTime);

        // Assert: Difference should be exactly 30 minutes (1800 seconds)
        final difference = followUpTime.difference(originalTime);
        
        expect(difference.inMinutes, equals(30),
            reason: 'Follow-up reminder should be exactly 30 minutes after original time. '
                'Actual difference: ${difference.inMinutes} minutes');
        expect(difference.inSeconds, equals(1800),
            reason: 'Follow-up reminder should be exactly 1800 seconds after original time. '
                'Actual difference: ${difference.inSeconds} seconds');
      },
    );

    /// Property: Follow-up time is always in the future relative to original time
    Glados(any.validDateTime).test(
      'Property 12: Follow-up time is always after original time',
      (originalTime) {
        // Act
        final followUpTime = MedicationReminderService.calculateFollowUpTime(originalTime);

        // Assert: Follow-up time should always be after original time
        expect(followUpTime.isAfter(originalTime), isTrue,
            reason: 'Follow-up time should always be after original time. '
                'Original: $originalTime, Follow-up: $followUpTime');
      },
    );

    /// Property: Follow-up calculation preserves date components correctly
    /// (handles day/month/year boundaries)
    Glados(any.validDateTime).test(
      'Property 12: Follow-up calculation handles time boundaries correctly',
      (originalTime) {
        // Act
        final followUpTime = MedicationReminderService.calculateFollowUpTime(originalTime);

        // Assert: The follow-up time should be a valid DateTime
        // and the difference should be exactly 30 minutes regardless of boundaries
        expect(followUpTime.millisecondsSinceEpoch, 
            equals(originalTime.millisecondsSinceEpoch + (30 * 60 * 1000)),
            reason: 'Follow-up time should be exactly 30 minutes (in milliseconds) '
                'after original time, even across day/month/year boundaries');
      },
    );

    /// Property: Follow-up calculation is deterministic
    Glados(any.validDateTime).test(
      'Property 12: Follow-up calculation is deterministic',
      (originalTime) {
        // Act: Calculate follow-up time twice
        final followUpTime1 = MedicationReminderService.calculateFollowUpTime(originalTime);
        final followUpTime2 = MedicationReminderService.calculateFollowUpTime(originalTime);

        // Assert: Both calculations should produce the same result
        expect(followUpTime1, equals(followUpTime2),
            reason: 'Follow-up calculation should be deterministic - '
                'same input should always produce same output');
      },
    );
  });
}
