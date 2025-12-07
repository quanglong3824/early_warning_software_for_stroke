import 'package:glados/glados.dart';
import 'package:early_warning_software_for_stroke/services/medication_reminder_service.dart';

/// **Feature: sews-improvement-plan, Property 11: Medication Adherence Calculation**
/// **Validates: Requirements 7.5**
///
/// Property: For any user with medication logs, the adherence percentage
/// SHALL equal (taken doses / scheduled doses) × 100.

/// Custom generator for adherence calculation inputs
extension AdherenceAny on Any {
  /// Generator for valid adherence inputs (takenDoses, scheduledDoses)
  /// where takenDoses <= scheduledDoses and scheduledDoses > 0
  Generator<(int, int)> get validAdherenceInput {
    return any.positiveIntOrZero.bind((scheduledBase) {
      // Ensure scheduledDoses is at least 1 (avoid division by zero)
      final scheduledDoses = (scheduledBase % 1000) + 1;
      
      return any.positiveIntOrZero.map((takenBase) {
        // Ensure takenDoses is between 0 and scheduledDoses
        final takenDoses = takenBase % (scheduledDoses + 1);
        return (takenDoses, scheduledDoses);
      });
    });
  }
}

void main() {
  group('Medication Adherence Calculation Property Tests', () {
    /// **Feature: sews-improvement-plan, Property 11: Medication Adherence Calculation**
    /// **Validates: Requirements 7.5**
    ///
    /// Property: For any user with medication logs, the adherence percentage
    /// SHALL equal (taken doses / scheduled doses) × 100.
    Glados(any.validAdherenceInput).test(
      'Property 11: Adherence equals (takenDoses / scheduledDoses) × 100',
      (input) {
        final (takenDoses, scheduledDoses) = input;

        // Calculate expected adherence manually
        final expectedAdherence = (takenDoses / scheduledDoses) * 100;

        // Act
        final actualAdherence = MedicationReminderService.calculateAdherence(
          takenDoses,
          scheduledDoses,
        );

        // Assert
        expect(actualAdherence, closeTo(expectedAdherence, 0.0001),
            reason: 'Adherence should equal (takenDoses / scheduledDoses) × 100. '
                'takenDoses: $takenDoses, scheduledDoses: $scheduledDoses');
      },
    );

    /// Property: Zero scheduled doses returns 0% adherence
    Glados(any.positiveIntOrZero).test(
      'Property 11: Zero scheduled doses returns 0% adherence',
      (takenDoses) {
        // Act
        final adherence = MedicationReminderService.calculateAdherence(
          takenDoses,
          0, // zero scheduled doses
        );

        // Assert
        expect(adherence, equals(0.0),
            reason: 'Zero scheduled doses should return 0% adherence');
      },
    );

    /// Property: Adherence is always between 0% and 100% for valid inputs
    Glados(any.validAdherenceInput).test(
      'Property 11: Adherence is between 0% and 100%',
      (input) {
        final (takenDoses, scheduledDoses) = input;

        // Act
        final adherence = MedicationReminderService.calculateAdherence(
          takenDoses,
          scheduledDoses,
        );

        // Assert
        expect(adherence, greaterThanOrEqualTo(0.0),
            reason: 'Adherence should never be negative');
        expect(adherence, lessThanOrEqualTo(100.0),
            reason: 'Adherence should never exceed 100%');
      },
    );

    /// Property: Perfect adherence (all doses taken) equals 100%
    Glados(any.positiveIntOrZero).test(
      'Property 11: Perfect adherence equals 100%',
      (scheduledBase) {
        // Ensure at least 1 scheduled dose
        final scheduledDoses = (scheduledBase % 1000) + 1;
        final takenDoses = scheduledDoses; // All doses taken

        // Act
        final adherence = MedicationReminderService.calculateAdherence(
          takenDoses,
          scheduledDoses,
        );

        // Assert
        expect(adherence, equals(100.0),
            reason: 'Taking all scheduled doses should result in 100% adherence');
      },
    );

    /// Property: Zero doses taken equals 0% adherence
    Glados(any.positiveIntOrZero).test(
      'Property 11: Zero doses taken equals 0% adherence',
      (scheduledBase) {
        // Ensure at least 1 scheduled dose
        final scheduledDoses = (scheduledBase % 1000) + 1;
        final takenDoses = 0; // No doses taken

        // Act
        final adherence = MedicationReminderService.calculateAdherence(
          takenDoses,
          scheduledDoses,
        );

        // Assert
        expect(adherence, equals(0.0),
            reason: 'Taking zero doses should result in 0% adherence');
      },
    );
  });
}
