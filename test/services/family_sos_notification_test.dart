import 'package:glados/glados.dart';

/// **Feature: sews-improvement-plan, Property 10: Family SOS Notification Broadcast**
/// **Validates: Requirements 6.2**
///
/// Property: For any SOS triggered by a monitored family member,
/// all family members SHALL receive a notification.

/// Test notification model for SOS alerts
class TestSOSNotification {
  final String notificationId;
  final String userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final int createdAt;
  final String priority;

  TestSOSNotification({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.createdAt,
    required this.priority,
  });

  @override
  String toString() =>
      'TestSOSNotification(id: $notificationId, userId: $userId, type: $type)';
}

/// SOS trigger event data
class SOSTriggerEvent {
  final String sosId;
  final String triggerUserId;
  final String triggerUserName;
  final String address;
  final List<String> familyMemberIds;

  SOSTriggerEvent({
    required this.sosId,
    required this.triggerUserId,
    required this.triggerUserName,
    required this.address,
    required this.familyMemberIds,
  });

  @override
  String toString() =>
      'SOSTriggerEvent(sosId: $sosId, triggerUserId: $triggerUserId, familyMembers: ${familyMemberIds.length})';
}

/// Pure function to broadcast SOS notifications to all family members
/// Mirrors the logic from SOSService.notifyFamilyMembersOnSOS
/// Validates: Requirements 6.2
List<TestSOSNotification> broadcastSOSToFamilyMembers(SOSTriggerEvent event) {
  if (event.sosId.isEmpty || event.triggerUserId.isEmpty) {
    return [];
  }

  // If no family members, return empty list
  if (event.familyMemberIds.isEmpty) {
    return [];
  }

  final notifications = <TestSOSNotification>[];
  final now = DateTime.now().millisecondsSinceEpoch;

  final title = '🚨 Cảnh báo SOS khẩn cấp!';
  final message = '${event.triggerUserName} đã kích hoạt SOS tại ${event.address}';

  // Send notification to each family member
  for (int i = 0; i < event.familyMemberIds.length; i++) {
    final memberId = event.familyMemberIds[i];
    if (memberId.isNotEmpty && memberId != event.triggerUserId) {
      notifications.add(TestSOSNotification(
        notificationId: 'notif_${event.sosId}_family_$i',
        userId: memberId,
        type: 'sos_alert',
        title: title,
        message: message,
        data: {
          'sosId': event.sosId,
          'userId': event.triggerUserId,
          'userName': event.triggerUserName,
          'address': event.address,
          'route': '/sos-status',
          'targetId': event.sosId,
        },
        createdAt: now,
        priority: 'high',
      ));
    }
  }

  return notifications;
}

/// Verify that all family members received notifications
bool allFamilyMembersNotified(
  SOSTriggerEvent event,
  List<TestSOSNotification> notifications,
) {
  // Get unique family member IDs (excluding the trigger user)
  final expectedRecipients = event.familyMemberIds
      .where((id) => id.isNotEmpty && id != event.triggerUserId)
      .toSet();

  // Get actual recipients from notifications
  final actualRecipients = notifications.map((n) => n.userId).toSet();

  // All expected recipients should have received notifications
  return expectedRecipients.every((id) => actualRecipients.contains(id));
}

/// Verify that all notifications have correct SOS data
bool allNotificationsHaveCorrectData(
  SOSTriggerEvent event,
  List<TestSOSNotification> notifications,
) {
  for (final notification in notifications) {
    if (notification.data == null) return false;
    if (notification.data!['sosId'] != event.sosId) return false;
    if (notification.data!['userId'] != event.triggerUserId) return false;
    if (notification.type != 'sos_alert') return false;
    if (notification.priority != 'high') return false;
  }
  return true;
}

/// Custom generators for test data
extension FamilySOSAny on Any {
  /// Generator for valid user IDs
  Generator<String> get validUserId {
    return any.letterOrDigits.map((s) => 'user_${s.isEmpty ? 'default' : s}');
  }

  /// Generator for valid SOS IDs
  Generator<String> get validSosId {
    return any.letterOrDigits.map((s) => 'sos_${s.isEmpty ? 'default' : s}');
  }

  /// Generator for user names
  Generator<String> get userName {
    return any.letterOrDigits.map((s) => 'User ${s.isEmpty ? 'John' : s}');
  }

  /// Generator for addresses
  Generator<String> get address {
    return any.letterOrDigits.map((s) => '${s.isEmpty ? '123' : s} Main Street, City');
  }

  /// Generator for list of family member IDs (1-10 members)
  Generator<List<String>> get familyMemberIdList {
    return any.list(any.validUserId).map((list) {
      // Ensure at least 1 member, max 10
      if (list.isEmpty) return ['user_family_1'];
      if (list.length > 10) return list.take(10).toList();
      // Remove duplicates
      return list.toSet().toList();
    });
  }

  /// Generator for SOSTriggerEvent with family members
  Generator<SOSTriggerEvent> get sosTriggerEventWithFamily {
    return any.combine5(
      any.validSosId,
      any.validUserId,
      any.userName,
      any.address,
      any.familyMemberIdList,
      (sosId, triggerUserId, triggerUserName, address, familyIds) {
        // Filter out family members that match trigger user ID
        final filteredFamilyIds = familyIds
            .where((id) => id != triggerUserId && id.isNotEmpty)
            .toSet()
            .toList();
        
        // Ensure at least one family member
        if (filteredFamilyIds.isEmpty) {
          filteredFamilyIds.add('user_family_default');
        }
        
        return SOSTriggerEvent(
          sosId: sosId,
          triggerUserId: triggerUserId,
          triggerUserName: triggerUserName,
          address: address,
          familyMemberIds: filteredFamilyIds,
        );
      },
    );
  }

  /// Generator for SOSTriggerEvent without family members (edge case)
  Generator<SOSTriggerEvent> get sosTriggerEventNoFamily {
    return any.combine4(
      any.validSosId,
      any.validUserId,
      any.userName,
      any.address,
      (sosId, triggerUserId, triggerUserName, address) {
        return SOSTriggerEvent(
          sosId: sosId,
          triggerUserId: triggerUserId,
          triggerUserName: triggerUserName,
          address: address,
          familyMemberIds: [], // No family members
        );
      },
    );
  }
}

void main() {
  group('Family SOS Notification Broadcast Property Tests', () {
    /// **Feature: sews-improvement-plan, Property 10: Family SOS Notification Broadcast**
    /// **Validates: Requirements 6.2**
    ///
    /// Property: For any SOS triggered by a monitored family member,
    /// all family members SHALL receive a notification.
    Glados(any.sosTriggerEventWithFamily).test(
      'Property 10.1: All family members receive SOS notification',
      (event) {
        // Act
        final notifications = broadcastSOSToFamilyMembers(event);

        // Get expected recipients (family members excluding trigger user)
        final expectedRecipients = event.familyMemberIds
            .where((id) => id.isNotEmpty && id != event.triggerUserId)
            .toSet();

        // Assert
        expect(notifications.length, equals(expectedRecipients.length),
            reason: 'Each family member should receive exactly one notification. '
                'Expected: ${expectedRecipients.length}, Got: ${notifications.length}');

        // Verify all family members are notified
        expect(allFamilyMembersNotified(event, notifications), isTrue,
            reason: 'All family members should receive a notification');
      },
    );

    /// Property: All SOS notifications contain correct data
    Glados(any.sosTriggerEventWithFamily).test(
      'Property 10.2: SOS notifications contain correct event data',
      (event) {
        // Act
        final notifications = broadcastSOSToFamilyMembers(event);

        // Assert
        expect(allNotificationsHaveCorrectData(event, notifications), isTrue,
            reason: 'All notifications should contain correct SOS data');

        // Verify each notification has the SOS ID
        for (final notification in notifications) {
          expect(notification.data?['sosId'], equals(event.sosId),
              reason: 'Notification should contain the SOS ID');
          expect(notification.data?['userId'], equals(event.triggerUserId),
              reason: 'Notification should contain the trigger user ID');
        }
      },
    );

    /// Property: SOS notifications have high priority
    Glados(any.sosTriggerEventWithFamily).test(
      'Property 10.3: SOS notifications have high priority',
      (event) {
        // Act
        final notifications = broadcastSOSToFamilyMembers(event);

        // Assert
        for (final notification in notifications) {
          expect(notification.priority, equals('high'),
              reason: 'SOS notifications should have high priority');
          expect(notification.type, equals('sos_alert'),
              reason: 'Notification type should be sos_alert');
        }
      },
    );

    /// Property: SOS notifications contain deep link route
    Glados(any.sosTriggerEventWithFamily).test(
      'Property 10.4: SOS notifications contain deep link route',
      (event) {
        // Act
        final notifications = broadcastSOSToFamilyMembers(event);

        // Assert
        for (final notification in notifications) {
          expect(notification.data?['route'], equals('/sos-status'),
              reason: 'Notification should contain route for deep linking');
          expect(notification.data?['targetId'], equals(event.sosId),
              reason: 'Notification should contain target ID for navigation');
        }
      },
    );

    /// Property: Trigger user does not receive their own SOS notification
    Glados(any.sosTriggerEventWithFamily).test(
      'Property 10.5: Trigger user does not receive their own notification',
      (event) {
        // Act
        final notifications = broadcastSOSToFamilyMembers(event);

        // Assert
        final triggerUserNotifications = notifications
            .where((n) => n.userId == event.triggerUserId)
            .toList();

        expect(triggerUserNotifications.isEmpty, isTrue,
            reason: 'Trigger user should not receive their own SOS notification');
      },
    );

    /// Property: No duplicate notifications for same family member
    Glados(any.sosTriggerEventWithFamily).test(
      'Property 10.6: No duplicate notifications for same family member',
      (event) {
        // Act
        final notifications = broadcastSOSToFamilyMembers(event);

        // Get all recipient user IDs
        final recipientIds = notifications.map((n) => n.userId).toList();
        final uniqueRecipientIds = recipientIds.toSet();

        // Assert
        expect(recipientIds.length, equals(uniqueRecipientIds.length),
            reason: 'Each family member should receive exactly one notification, no duplicates');
      },
    );

    /// Edge case: No family members results in no notifications
    Glados(any.sosTriggerEventNoFamily).test(
      'Property 10.7: No notifications when no family members exist',
      (event) {
        // Act
        final notifications = broadcastSOSToFamilyMembers(event);

        // Assert
        expect(notifications.isEmpty, isTrue,
            reason: 'No notifications should be created when there are no family members');
      },
    );

    /// Property: Notification message contains user name and address
    Glados(any.sosTriggerEventWithFamily).test(
      'Property 10.8: Notification message contains user name and address',
      (event) {
        // Act
        final notifications = broadcastSOSToFamilyMembers(event);

        // Assert
        for (final notification in notifications) {
          expect(notification.message.contains(event.triggerUserName), isTrue,
              reason: 'Notification message should contain the trigger user name');
          expect(notification.message.contains(event.address), isTrue,
              reason: 'Notification message should contain the address');
        }
      },
    );
  });
}
