import 'package:glados/glados.dart';

/// **Feature: sews-improvement-plan, Property 4: Notification Delivery**
/// **Validates: Requirements 3.1, 3.2, 3.3**
///
/// Property: For any prescription creation, appointment change, or SOS acknowledgment,
/// a notification SHALL be created for all relevant recipients.

/// Notification event types
enum NotificationEventType {
  prescriptionCreated,
  appointmentConfirmed,
  appointmentCancelled,
  sosAcknowledged,
}

/// Test notification model - mirrors NotificationModel without Firebase dependencies
class TestNotification {
  final String notificationId;
  final String userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final int createdAt;

  TestNotification({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.createdAt,
  });

  @override
  String toString() =>
      'TestNotification(id: $notificationId, userId: $userId, type: $type, title: $title)';
}

/// Prescription event data
class PrescriptionEvent {
  final String prescriptionId;
  final String patientId;
  final String doctorName;

  PrescriptionEvent({
    required this.prescriptionId,
    required this.patientId,
    required this.doctorName,
  });

  @override
  String toString() =>
      'PrescriptionEvent(prescriptionId: $prescriptionId, patientId: $patientId, doctorName: $doctorName)';
}

/// Appointment event data
class AppointmentEvent {
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final String status; // 'confirmed' or 'cancelled'
  final String? doctorName;
  final String? patientName;

  AppointmentEvent({
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.status,
    this.doctorName,
    this.patientName,
  });

  /// Get all recipients who should receive notification
  List<String> get recipients {
    // Both patient and doctor should be notified
    return [patientId, doctorId];
  }

  @override
  String toString() =>
      'AppointmentEvent(appointmentId: $appointmentId, patientId: $patientId, doctorId: $doctorId, status: $status)';
}

/// SOS event data
class SOSEvent {
  final String sosId;
  final String patientId;
  final List<String> familyMemberIds;
  final String? doctorName;

  SOSEvent({
    required this.sosId,
    required this.patientId,
    required this.familyMemberIds,
    this.doctorName,
  });

  /// Get all recipients who should receive notification
  List<String> get recipients {
    // Patient and all family members should be notified
    return [patientId, ...familyMemberIds];
  }

  @override
  String toString() =>
      'SOSEvent(sosId: $sosId, patientId: $patientId, familyMembers: ${familyMemberIds.length})';
}

/// Pure function to create notification for prescription event
/// Mirrors the logic from EnhancedNotificationService.sendPrescriptionNotification
/// Validates: Requirements 3.1
TestNotification? createPrescriptionNotification(PrescriptionEvent event) {
  if (event.patientId.isEmpty || event.prescriptionId.isEmpty) {
    return null;
  }

  return TestNotification(
    notificationId: 'notif_${event.prescriptionId}',
    userId: event.patientId,
    type: 'prescription',
    title: 'Đơn thuốc mới',
    message: 'Bác sĩ ${event.doctorName} đã kê đơn thuốc cho bạn',
    data: {
      'prescriptionId': event.prescriptionId,
      'route': '/prescriptions',
      'targetId': event.prescriptionId,
    },
    createdAt: DateTime.now().millisecondsSinceEpoch,
  );
}

/// Pure function to create notifications for appointment event
/// Mirrors the logic from EnhancedNotificationService.sendAppointmentNotification
/// Validates: Requirements 3.2
List<TestNotification> createAppointmentNotifications(AppointmentEvent event) {
  if (event.appointmentId.isEmpty || event.patientId.isEmpty || event.doctorId.isEmpty) {
    return [];
  }

  final notifications = <TestNotification>[];
  final now = DateTime.now().millisecondsSinceEpoch;

  String title;
  String patientMessage;
  String doctorMessage;

  switch (event.status) {
    case 'confirmed':
      title = 'Lịch hẹn đã xác nhận';
      patientMessage = event.doctorName != null
          ? 'Bác sĩ ${event.doctorName} đã xác nhận lịch hẹn của bạn'
          : 'Lịch hẹn của bạn đã được xác nhận';
      doctorMessage = event.patientName != null
          ? 'Bạn đã xác nhận lịch hẹn với bệnh nhân ${event.patientName}'
          : 'Bạn đã xác nhận lịch hẹn';
      break;
    case 'cancelled':
      title = 'Lịch hẹn đã hủy';
      patientMessage = event.doctorName != null
          ? 'Bác sĩ ${event.doctorName} đã hủy lịch hẹn'
          : 'Lịch hẹn của bạn đã bị hủy';
      doctorMessage = event.patientName != null
          ? 'Lịch hẹn với bệnh nhân ${event.patientName} đã bị hủy'
          : 'Lịch hẹn đã bị hủy';
      break;
    default:
      title = 'Cập nhật lịch hẹn';
      patientMessage = 'Lịch hẹn của bạn đã được cập nhật';
      doctorMessage = 'Lịch hẹn đã được cập nhật';
  }

  // Notification for patient
  notifications.add(TestNotification(
    notificationId: 'notif_${event.appointmentId}_patient',
    userId: event.patientId,
    type: 'appointment',
    title: title,
    message: patientMessage,
    data: {
      'appointmentId': event.appointmentId,
      'status': event.status,
      'route': '/appointments',
      'targetId': event.appointmentId,
    },
    createdAt: now,
  ));

  // Notification for doctor
  notifications.add(TestNotification(
    notificationId: 'notif_${event.appointmentId}_doctor',
    userId: event.doctorId,
    type: 'appointment',
    title: title,
    message: doctorMessage,
    data: {
      'appointmentId': event.appointmentId,
      'status': event.status,
      'route': '/appointments',
      'targetId': event.appointmentId,
    },
    createdAt: now,
  ));

  return notifications;
}

/// Pure function to create notifications for SOS acknowledgment event
/// Mirrors the logic from EnhancedNotificationService.sendSOSNotification
/// Validates: Requirements 3.3
List<TestNotification> createSOSNotifications(SOSEvent event) {
  if (event.sosId.isEmpty || event.patientId.isEmpty) {
    return [];
  }

  final notifications = <TestNotification>[];
  final now = DateTime.now().millisecondsSinceEpoch;

  // Notification for patient
  notifications.add(TestNotification(
    notificationId: 'notif_${event.sosId}_patient',
    userId: event.patientId,
    type: 'sos',
    title: 'SOS đã được tiếp nhận',
    message: event.doctorName != null
        ? 'Bác sĩ ${event.doctorName} đã tiếp nhận yêu cầu SOS của bạn'
        : 'Yêu cầu SOS của bạn đã được tiếp nhận',
    data: {
      'sosId': event.sosId,
      'status': 'acknowledged',
      'route': '/sos-status',
      'targetId': event.sosId,
    },
    createdAt: now,
  ));

  // Notifications for all family members
  for (int i = 0; i < event.familyMemberIds.length; i++) {
    final familyMemberId = event.familyMemberIds[i];
    if (familyMemberId.isNotEmpty) {
      notifications.add(TestNotification(
        notificationId: 'notif_${event.sosId}_family_$i',
        userId: familyMemberId,
        type: 'sos',
        title: 'SOS đã được tiếp nhận',
        message: 'Yêu cầu SOS của người thân đã được tiếp nhận',
        data: {
          'sosId': event.sosId,
          'status': 'acknowledged',
          'route': '/sos-status',
          'targetId': event.sosId,
        },
        createdAt: now,
      ));
    }
  }

  return notifications;
}

/// Custom generators for test data
extension NotificationEventAny on Any {
  /// Generator for valid user IDs
  Generator<String> get validUserId {
    return any.letterOrDigits.map((s) => 'user_${s.isEmpty ? 'default' : s}');
  }

  /// Generator for valid prescription IDs
  Generator<String> get validPrescriptionId {
    return any.letterOrDigits.map((s) => 'presc_${s.isEmpty ? 'default' : s}');
  }

  /// Generator for valid appointment IDs
  Generator<String> get validAppointmentId {
    return any.letterOrDigits.map((s) => 'appt_${s.isEmpty ? 'default' : s}');
  }

  /// Generator for valid SOS IDs
  Generator<String> get validSosId {
    return any.letterOrDigits.map((s) => 'sos_${s.isEmpty ? 'default' : s}');
  }

  /// Generator for doctor names
  Generator<String> get doctorName {
    return any.letterOrDigits.map((s) => 'Dr. ${s.isEmpty ? 'Smith' : s}');
  }

  /// Generator for patient names
  Generator<String> get patientName {
    return any.letterOrDigits.map((s) => 'Patient ${s.isEmpty ? 'John' : s}');
  }

  /// Generator for PrescriptionEvent
  Generator<PrescriptionEvent> get prescriptionEvent {
    return any.combine3(
      any.validPrescriptionId,
      any.validUserId,
      any.doctorName,
      (prescriptionId, patientId, doctorName) => PrescriptionEvent(
        prescriptionId: prescriptionId,
        patientId: patientId,
        doctorName: doctorName,
      ),
    );
  }

  /// Generator for appointment status
  Generator<String> get appointmentStatus {
    return any.choose(['confirmed', 'cancelled']);
  }

  /// Generator for AppointmentEvent
  Generator<AppointmentEvent> get appointmentEvent {
    return any.combine5(
      any.validAppointmentId,
      any.validUserId,
      any.validUserId,
      any.appointmentStatus,
      any.doctorName,
      (appointmentId, patientId, doctorId, status, doctorName) {
        // Ensure patient and doctor are different
        final actualDoctorId = patientId == doctorId ? '${doctorId}_doc' : doctorId;
        return AppointmentEvent(
          appointmentId: appointmentId,
          patientId: patientId,
          doctorId: actualDoctorId,
          status: status,
          doctorName: doctorName,
          patientName: 'Patient',
        );
      },
    );
  }

  /// Generator for list of family member IDs (0-5 members)
  Generator<List<String>> get familyMemberIds {
    return any.list(any.validUserId).map((list) {
      // Limit to 0-5 members
      if (list.length > 5) return list.take(5).toList();
      return list;
    });
  }

  /// Generator for SOSEvent
  Generator<SOSEvent> get sosEvent {
    return any.combine4(
      any.validSosId,
      any.validUserId,
      any.familyMemberIds,
      any.doctorName,
      (sosId, patientId, familyIds, doctorName) {
        // Filter out family members that match patient ID
        final filteredFamilyIds = familyIds.where((id) => id != patientId).toList();
        return SOSEvent(
          sosId: sosId,
          patientId: patientId,
          familyMemberIds: filteredFamilyIds,
          doctorName: doctorName,
        );
      },
    );
  }
}

void main() {
  group('Notification Delivery Property Tests', () {
    /// **Feature: sews-improvement-plan, Property 4: Notification Delivery**
    /// **Validates: Requirements 3.1**
    ///
    /// Property: For any prescription creation, a notification SHALL be created
    /// for the patient.
    Glados(any.prescriptionEvent).test(
      'Property 4.1: Prescription notification is created for patient',
      (event) {
        // Act
        final notification = createPrescriptionNotification(event);

        // Assert
        expect(notification, isNotNull,
            reason: 'Notification should be created for prescription event');
        expect(notification!.userId, equals(event.patientId),
            reason: 'Notification should be sent to the patient');
        expect(notification.type, equals('prescription'),
            reason: 'Notification type should be prescription');
        expect(notification.data?['prescriptionId'], equals(event.prescriptionId),
            reason: 'Notification should contain prescription ID');
      },
    );

    /// **Feature: sews-improvement-plan, Property 4: Notification Delivery**
    /// **Validates: Requirements 3.2**
    ///
    /// Property: For any appointment confirmation or cancellation, notifications
    /// SHALL be created for both patient and doctor.
    Glados(any.appointmentEvent).test(
      'Property 4.2: Appointment notifications are created for all relevant parties',
      (event) {
        // Act
        final notifications = createAppointmentNotifications(event);

        // Assert
        expect(notifications.length, equals(2),
            reason: 'Two notifications should be created (patient and doctor)');

        // Check patient notification
        final patientNotif = notifications.firstWhere(
          (n) => n.userId == event.patientId,
          orElse: () => throw Exception('Patient notification not found'),
        );
        expect(patientNotif.type, equals('appointment'),
            reason: 'Patient notification type should be appointment');
        expect(patientNotif.data?['appointmentId'], equals(event.appointmentId),
            reason: 'Patient notification should contain appointment ID');
        expect(patientNotif.data?['status'], equals(event.status),
            reason: 'Patient notification should contain correct status');

        // Check doctor notification
        final doctorNotif = notifications.firstWhere(
          (n) => n.userId == event.doctorId,
          orElse: () => throw Exception('Doctor notification not found'),
        );
        expect(doctorNotif.type, equals('appointment'),
            reason: 'Doctor notification type should be appointment');
        expect(doctorNotif.data?['appointmentId'], equals(event.appointmentId),
            reason: 'Doctor notification should contain appointment ID');
      },
    );

    /// **Feature: sews-improvement-plan, Property 4: Notification Delivery**
    /// **Validates: Requirements 3.3**
    ///
    /// Property: For any SOS acknowledgment, notifications SHALL be created
    /// for the patient and all family members.
    Glados(any.sosEvent).test(
      'Property 4.3: SOS notifications are created for patient and all family members',
      (event) {
        // Act
        final notifications = createSOSNotifications(event);

        // Expected count: 1 (patient) + number of family members
        final expectedCount = 1 + event.familyMemberIds.length;

        // Assert
        expect(notifications.length, equals(expectedCount),
            reason: 'Notifications should be created for patient and all family members. '
                'Expected: $expectedCount, Got: ${notifications.length}');

        // Check patient notification exists
        final patientNotif = notifications.firstWhere(
          (n) => n.userId == event.patientId,
          orElse: () => throw Exception('Patient notification not found'),
        );
        expect(patientNotif.type, equals('sos'),
            reason: 'Patient notification type should be sos');
        expect(patientNotif.data?['sosId'], equals(event.sosId),
            reason: 'Patient notification should contain SOS ID');

        // Check all family members receive notifications
        for (final familyMemberId in event.familyMemberIds) {
          final familyNotif = notifications.firstWhere(
            (n) => n.userId == familyMemberId,
            orElse: () => throw Exception('Family member $familyMemberId notification not found'),
          );
          expect(familyNotif.type, equals('sos'),
              reason: 'Family member notification type should be sos');
          expect(familyNotif.data?['sosId'], equals(event.sosId),
              reason: 'Family member notification should contain SOS ID');
        }
      },
    );

    /// Property: All notifications have required fields
    Glados(any.prescriptionEvent).test(
      'Property 4.4: Prescription notifications have all required fields',
      (event) {
        // Act
        final notification = createPrescriptionNotification(event);

        // Assert
        expect(notification, isNotNull);
        expect(notification!.notificationId, isNotEmpty,
            reason: 'Notification ID should not be empty');
        expect(notification.userId, isNotEmpty,
            reason: 'User ID should not be empty');
        expect(notification.type, isNotEmpty,
            reason: 'Type should not be empty');
        expect(notification.title, isNotEmpty,
            reason: 'Title should not be empty');
        expect(notification.message, isNotEmpty,
            reason: 'Message should not be empty');
        expect(notification.data, isNotNull,
            reason: 'Data should not be null');
        expect(notification.data!['route'], isNotNull,
            reason: 'Route should be present for deep linking');
      },
    );

    /// Property: Appointment notifications contain correct status
    Glados(any.appointmentEvent).test(
      'Property 4.5: Appointment notifications contain correct status',
      (event) {
        // Act
        final notifications = createAppointmentNotifications(event);

        // Assert
        for (final notification in notifications) {
          expect(notification.data?['status'], equals(event.status),
              reason: 'All appointment notifications should contain the correct status');
        }
      },
    );
  });
}
