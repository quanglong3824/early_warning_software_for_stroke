import 'package:flutter/material.dart';
import 'package:glados/glados.dart';

/// **Feature: sews-improvement-plan, Property 13: Time Slot Availability**
/// **Validates: Requirements 8.3**
///
/// Property: For any booked appointment slot, that slot SHALL not appear
/// in available slots for other patients.

/// Test time slot - mirrors TimeSlot from doctor_schedule_service.dart
/// This is a pure data class that doesn't require Firebase
class TestTimeSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isBooked;
  final String? patientId;
  final String? appointmentId;

  TestTimeSlot({
    required this.startTime,
    required this.endTime,
    this.isBooked = false,
    this.patientId,
    this.appointmentId,
  });

  /// Creates a unique key for this time slot based on start time
  String get slotKey => '${startTime.hour}:${startTime.minute}';

  @override
  String toString() =>
      'TestTimeSlot(${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} - '
      '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}, '
      'booked: $isBooked)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestTimeSlot &&
        other.startTime.hour == startTime.hour &&
        other.startTime.minute == startTime.minute;
  }

  @override
  int get hashCode => startTime.hour.hashCode ^ startTime.minute.hashCode;
}

/// Test day schedule - mirrors DaySchedule from doctor_schedule_service.dart
class TestDaySchedule {
  final bool isWorking;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final int slotDurationMinutes;
  final List<TestTimeSlot> bookedSlots;

  TestDaySchedule({
    this.isWorking = false,
    this.startTime,
    this.endTime,
    this.slotDurationMinutes = 30,
    this.bookedSlots = const [],
  });
}


/// Pure function for generating time slots from a day schedule
/// Mirrors the generateTimeSlots logic from DoctorScheduleService
List<TestTimeSlot> generateTimeSlots(TestDaySchedule daySchedule) {
  if (!daySchedule.isWorking ||
      daySchedule.startTime == null ||
      daySchedule.endTime == null) {
    return [];
  }

  final slots = <TestTimeSlot>[];
  var currentMinutes =
      daySchedule.startTime!.hour * 60 + daySchedule.startTime!.minute;
  final endMinutes =
      daySchedule.endTime!.hour * 60 + daySchedule.endTime!.minute;

  while (currentMinutes + daySchedule.slotDurationMinutes <= endMinutes) {
    final startHour = currentMinutes ~/ 60;
    final startMinute = currentMinutes % 60;
    final endHour = (currentMinutes + daySchedule.slotDurationMinutes) ~/ 60;
    final endMinute = (currentMinutes + daySchedule.slotDurationMinutes) % 60;

    slots.add(TestTimeSlot(
      startTime: TimeOfDay(hour: startHour, minute: startMinute),
      endTime: TimeOfDay(hour: endHour, minute: endMinute),
    ));

    currentMinutes += daySchedule.slotDurationMinutes;
  }

  return slots;
}

/// Pure function for getting available slots (excluding booked ones)
/// Mirrors the getAvailableSlots logic from DoctorScheduleService
/// Validates: Requirements 8.3
List<TestTimeSlot> getAvailableSlots(TestDaySchedule daySchedule) {
  // Generate all possible slots
  final allSlots = generateTimeSlots(daySchedule);

  // Get set of booked slot keys
  final bookedTimes = daySchedule.bookedSlots.map((s) => s.slotKey).toSet();

  // Filter out booked slots
  return allSlots.where((slot) => !bookedTimes.contains(slot.slotKey)).toList();
}

/// Custom generator for TimeOfDay values
extension TimeOfDayAny on Any {
  /// Generator for valid TimeOfDay values (working hours: 8:00 - 18:00)
  Generator<TimeOfDay> get workingHourTime {
    return any.positiveIntOrZero.bind((hourOffset) {
      return any.positiveIntOrZero.map((minuteOffset) {
        // Generate times between 8:00 and 17:30 (last slot start)
        final hour = 8 + (hourOffset % 10); // 8-17
        final minute = (minuteOffset % 2) * 30; // 0 or 30
        return TimeOfDay(hour: hour, minute: minute);
      });
    });
  }

  /// Generator for slot duration in minutes (15, 30, 45, or 60)
  Generator<int> get slotDuration {
    return any.positiveIntOrZero.map((value) {
      final durations = [15, 30, 45, 60];
      return durations[value % durations.length];
    });
  }
}

/// Generator for number of slots to book (0 to maxSlots)
extension BookingCountAny on Any {
  Generator<int> get bookingCount {
    return any.positiveIntOrZero.map((value) => value % 10); // 0-9 bookings
  }
}


void main() {
  group('Time Slot Availability Property Tests', () {
    /// **Feature: sews-improvement-plan, Property 13: Time Slot Availability**
    /// **Validates: Requirements 8.3**
    ///
    /// Property: For any booked appointment slot, that slot SHALL not appear
    /// in available slots for other patients.
    Glados2(any.slotDuration, any.bookingCount).test(
      'Property 13: Booked slots do not appear in available slots',
      (slotDuration, numBookings) {
        // Arrange: Create a working day schedule (8:00 - 18:00)
        final startTime = const TimeOfDay(hour: 8, minute: 0);
        final endTime = const TimeOfDay(hour: 18, minute: 0);

        // Generate all possible slots first
        final baseSchedule = TestDaySchedule(
          isWorking: true,
          startTime: startTime,
          endTime: endTime,
          slotDurationMinutes: slotDuration,
          bookedSlots: [],
        );

        final allSlots = generateTimeSlots(baseSchedule);
        if (allSlots.isEmpty) return; // Skip if no slots generated

        // Book some random slots (up to numBookings or available slots)
        final slotsToBook = numBookings.clamp(0, allSlots.length);
        final bookedSlots = <TestTimeSlot>[];

        for (var i = 0; i < slotsToBook; i++) {
          final slotIndex = (i * 3) % allSlots.length; // Spread bookings
          final slot = allSlots[slotIndex];
          bookedSlots.add(TestTimeSlot(
            startTime: slot.startTime,
            endTime: slot.endTime,
            isBooked: true,
            patientId: 'patient-$i',
            appointmentId: 'appointment-$i',
          ));
        }

        // Create schedule with booked slots
        final scheduleWithBookings = TestDaySchedule(
          isWorking: true,
          startTime: startTime,
          endTime: endTime,
          slotDurationMinutes: slotDuration,
          bookedSlots: bookedSlots,
        );

        // Act: Get available slots
        final availableSlots = getAvailableSlots(scheduleWithBookings);

        // Assert: No booked slot should appear in available slots
        final bookedSlotKeys = bookedSlots.map((s) => s.slotKey).toSet();
        final availableSlotKeys = availableSlots.map((s) => s.slotKey).toSet();

        final intersection = bookedSlotKeys.intersection(availableSlotKeys);

        expect(
          intersection,
          isEmpty,
          reason: 'Booked slots $bookedSlotKeys should not appear in '
              'available slots $availableSlotKeys. Found overlap: $intersection',
        );
      },
    );

    /// Property: Available slots + booked slots = all slots
    Glados2(any.slotDuration, any.bookingCount).test(
      'Property 13: Available slots and booked slots partition all slots',
      (slotDuration, numBookings) {
        // Arrange: Create a working day schedule
        final startTime = const TimeOfDay(hour: 8, minute: 0);
        final endTime = const TimeOfDay(hour: 18, minute: 0);

        final baseSchedule = TestDaySchedule(
          isWorking: true,
          startTime: startTime,
          endTime: endTime,
          slotDurationMinutes: slotDuration,
          bookedSlots: [],
        );

        final allSlots = generateTimeSlots(baseSchedule);
        if (allSlots.isEmpty) return;

        // Book some slots
        final slotsToBook = numBookings.clamp(0, allSlots.length);
        final bookedSlots = <TestTimeSlot>[];

        for (var i = 0; i < slotsToBook; i++) {
          final slotIndex = (i * 2) % allSlots.length;
          final slot = allSlots[slotIndex];
          bookedSlots.add(TestTimeSlot(
            startTime: slot.startTime,
            endTime: slot.endTime,
            isBooked: true,
            patientId: 'patient-$i',
          ));
        }

        final scheduleWithBookings = TestDaySchedule(
          isWorking: true,
          startTime: startTime,
          endTime: endTime,
          slotDurationMinutes: slotDuration,
          bookedSlots: bookedSlots,
        );

        // Act
        final availableSlots = getAvailableSlots(scheduleWithBookings);

        // Assert: available + booked = all (accounting for unique slots)
        final uniqueBookedKeys = bookedSlots.map((s) => s.slotKey).toSet();
        final availableKeys = availableSlots.map((s) => s.slotKey).toSet();
        final allKeys = allSlots.map((s) => s.slotKey).toSet();

        final combinedKeys = {...uniqueBookedKeys, ...availableKeys};

        expect(
          combinedKeys,
          equals(allKeys),
          reason: 'Available slots ($availableKeys) + booked slots '
              '($uniqueBookedKeys) should equal all slots ($allKeys)',
        );
      },
    );

    /// Property: Non-working day has no available slots
    Glados(any.slotDuration).test(
      'Property 13: Non-working day has no available slots',
      (slotDuration) {
        // Arrange: Create a non-working day schedule
        final schedule = TestDaySchedule(
          isWorking: false,
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          slotDurationMinutes: slotDuration,
          bookedSlots: [],
        );

        // Act
        final availableSlots = getAvailableSlots(schedule);

        // Assert: No slots should be available on non-working day
        expect(
          availableSlots,
          isEmpty,
          reason: 'Non-working day should have no available slots',
        );
      },
    );

    /// Property: All slots booked means no available slots
    Glados(any.slotDuration).test(
      'Property 13: All slots booked means no available slots',
      (slotDuration) {
        // Arrange: Create a working day schedule
        final startTime = const TimeOfDay(hour: 8, minute: 0);
        final endTime = const TimeOfDay(hour: 18, minute: 0);

        final baseSchedule = TestDaySchedule(
          isWorking: true,
          startTime: startTime,
          endTime: endTime,
          slotDurationMinutes: slotDuration,
          bookedSlots: [],
        );

        final allSlots = generateTimeSlots(baseSchedule);
        if (allSlots.isEmpty) return;

        // Book ALL slots
        final bookedSlots = allSlots
            .map((slot) => TestTimeSlot(
                  startTime: slot.startTime,
                  endTime: slot.endTime,
                  isBooked: true,
                  patientId: 'patient-${slot.slotKey}',
                ))
            .toList();

        final fullyBookedSchedule = TestDaySchedule(
          isWorking: true,
          startTime: startTime,
          endTime: endTime,
          slotDurationMinutes: slotDuration,
          bookedSlots: bookedSlots,
        );

        // Act
        final availableSlots = getAvailableSlots(fullyBookedSchedule);

        // Assert: No slots should be available when all are booked
        expect(
          availableSlots,
          isEmpty,
          reason: 'When all ${allSlots.length} slots are booked, '
              'no slots should be available',
        );
      },
    );

    /// Property: No bookings means all slots are available
    Glados(any.slotDuration).test(
      'Property 13: No bookings means all slots are available',
      (slotDuration) {
        // Arrange: Create a working day schedule with no bookings
        final schedule = TestDaySchedule(
          isWorking: true,
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          slotDurationMinutes: slotDuration,
          bookedSlots: [],
        );

        // Act
        final allSlots = generateTimeSlots(schedule);
        final availableSlots = getAvailableSlots(schedule);

        // Assert: All slots should be available when none are booked
        expect(
          availableSlots.length,
          equals(allSlots.length),
          reason: 'When no slots are booked, all ${allSlots.length} slots '
              'should be available, but got ${availableSlots.length}',
        );
      },
    );
  });
}
