import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../data/models/family_forum_models.dart';

class FamilyService {
  static final FamilyService _instance = FamilyService._internal();
  factory FamilyService() => _instance;
  FamilyService._internal();

  final _database = FirebaseDatabase.instance.ref();
  
  // Cache for better performance
  final Map<String, List<Map<String, dynamic>>> _familyMembersCache = {};
  final Map<String, List<Map<String, dynamic>>> _familyGroupsCache = {};

  // Stream controllers for real-time updates
  final Map<String, StreamController<List<FamilyMemberHealth>>> _healthStatusControllers = {};

  /// Add a family member with bidirectional relationship
  /// This ensures both users have each other in their family lists
  /// Requirements: 6.1
  Future<bool> addFamilyMemberBidirectional({
    required String userId,
    required String userName,
    required String memberId,
    required String memberName,
    required String relationship,
  }) async {
    try {
      // Check if already connected
      final existingConnection = await _checkExistingConnection(userId, memberId);
      if (existingConnection == 'already_member') {
        print('⚠️ Already family members');
        return false;
      }

      // Create bidirectional relationship
      final memberId1 = _database.child('family_members').child(userId).push().key!;
      final memberId2 = _database.child('family_members').child(memberId).push().key!;

      // Add member to user's family list
      await _database
          .child('family_members')
          .child(userId)
          .child(memberId1)
          .set({
        'id': memberId1,
        'memberId': memberId,
        'memberName': memberName,
        'relationship': relationship,
        'addedAt': ServerValue.timestamp,
      });

      // Add user to member's family list (reverse relationship)
      await _database
          .child('family_members')
          .child(memberId)
          .child(memberId2)
          .set({
        'id': memberId2,
        'memberId': userId,
        'memberName': userName,
        'relationship': _reverseRelationship(relationship),
        'addedAt': ServerValue.timestamp,
      });

      print('✅ Bidirectional family relationship created');
      return true;
    } catch (e) {
      print('❌ Error creating bidirectional relationship: $e');
      return false;
    }
  }

  /// Get real-time stream of family members' health status
  /// Requirements: 6.3
  Stream<List<FamilyMemberHealth>> getFamilyHealthStatus(String userId) {
    // Create or reuse stream controller
    if (!_healthStatusControllers.containsKey(userId)) {
      _healthStatusControllers[userId] = StreamController<List<FamilyMemberHealth>>.broadcast();
      _startHealthStatusListener(userId);
    }
    return _healthStatusControllers[userId]!.stream;
  }

  /// Start listening to family members' health status
  void _startHealthStatusListener(String userId) async {
    // Listen to family members changes
    _database.child('family_members').child(userId).onValue.listen((event) async {
      if (!event.snapshot.exists) {
        _healthStatusControllers[userId]?.add([]);
        return;
      }

      final membersData = Map<String, dynamic>.from(event.snapshot.value as Map);
      final healthStatuses = <FamilyMemberHealth>[];

      for (var entry in membersData.entries) {
        final memberData = Map<String, dynamic>.from(entry.value as Map);
        final memberId = memberData['memberId'] as String;
        final memberName = memberData['memberName'] as String? ?? 'Không rõ';
        final relationship = memberData['relationship'] as String? ?? 'Người thân';

        // Get latest prediction for this member
        final healthStatus = await _getMemberHealthStatus(
          memberId: memberId,
          name: memberName,
          relationship: relationship,
        );
        healthStatuses.add(healthStatus);
      }

      // Sort by risk level (high first)
      healthStatuses.sort((a, b) {
        final riskOrder = {'high': 0, 'medium': 1, 'low': 2, null: 3};
        return (riskOrder[a.latestRiskLevel] ?? 3)
            .compareTo(riskOrder[b.latestRiskLevel] ?? 3);
      });

      _healthStatusControllers[userId]?.add(healthStatuses);
    });
  }

  /// Get health status for a single family member
  Future<FamilyMemberHealth> _getMemberHealthStatus({
    required String memberId,
    required String name,
    required String relationship,
  }) async {
    try {
      // Get latest stroke prediction
      final strokeSnapshot = await _database
          .child('predictions')
          .orderByChild('userId')
          .equalTo(memberId)
          .limitToLast(1)
          .get();

      String? latestRiskLevel;
      int? latestRiskScore;
      String? predictionType;
      DateTime? lastUpdate;

      if (strokeSnapshot.exists) {
        final data = Map<String, dynamic>.from(strokeSnapshot.value as Map);
        if (data.isNotEmpty) {
          final latestPrediction = Map<String, dynamic>.from(data.values.first as Map);
          latestRiskLevel = latestPrediction['riskLevel'] as String?;
          latestRiskScore = latestPrediction['riskScore'] as int?;
          predictionType = latestPrediction['type'] as String?;
          final createdAt = latestPrediction['createdAt'];
          if (createdAt != null) {
            lastUpdate = DateTime.fromMillisecondsSinceEpoch(createdAt as int);
          }
        }
      }

      // Get latest health record
      Map<String, dynamic>? latestHealthRecord;
      final healthSnapshot = await _database
          .child('health_records')
          .child(memberId)
          .orderByChild('recordedAt')
          .limitToLast(1)
          .get();

      if (healthSnapshot.exists) {
        final data = Map<String, dynamic>.from(healthSnapshot.value as Map);
        if (data.isNotEmpty) {
          latestHealthRecord = Map<String, dynamic>.from(data.values.first as Map);
          // Update lastUpdate if health record is more recent
          final recordedAt = latestHealthRecord['recordedAt'];
          if (recordedAt != null) {
            final recordDate = DateTime.fromMillisecondsSinceEpoch(recordedAt as int);
            if (lastUpdate == null || recordDate.isAfter(lastUpdate)) {
              lastUpdate = recordDate;
            }
          }
        }
      }

      return FamilyMemberHealth(
        memberId: memberId,
        name: name,
        relationship: relationship,
        latestRiskLevel: latestRiskLevel,
        lastUpdate: lastUpdate,
        latestRiskScore: latestRiskScore,
        predictionType: predictionType,
        latestHealthRecord: latestHealthRecord,
      );
    } catch (e) {
      print('Error getting member health status: $e');
      return FamilyMemberHealth(
        memberId: memberId,
        name: name,
        relationship: relationship,
      );
    }
  }

  /// Get all family member IDs for a user
  Future<List<String>> getFamilyMemberIds(String userId) async {
    try {
      final snapshot = await _database
          .child('family_members')
          .child(userId)
          .get();

      if (!snapshot.exists) return [];

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final memberIds = <String>[];

      data.forEach((key, value) {
        final member = Map<String, dynamic>.from(value as Map);
        final memberId = member['memberId'] as String?;
        if (memberId != null) {
          memberIds.add(memberId);
        }
      });

      return memberIds;
    } catch (e) {
      print('Error getting family member IDs: $e');
      return [];
    }
  }

  /// Dispose stream controllers
  void dispose() {
    for (var controller in _healthStatusControllers.values) {
      controller.close();
    }
    _healthStatusControllers.clear();
  }

  // Tìm user bằng email hoặc phone
  Future<Map<String, dynamic>?> findUserByEmailOrPhone(String query) async {
    try {
      print('🔍 Searching for user: $query');
      
      final normalizedQuery = query.trim().toLowerCase();
      final normalizedPhone = query.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
      
      // Search all users (most reliable method)
      final allUsersSnapshot = await _database.child('users').get();
      
      if (!allUsersSnapshot.exists) {
        print('❌ No users in database');
        return null;
      }

      final allUsers = Map<String, dynamic>.from(allUsersSnapshot.value as Map);
      
      for (var entry in allUsers.entries) {
        final userData = Map<String, dynamic>.from(entry.value as Map);
        final email = (userData['email'] as String?)?.toLowerCase().trim() ?? '';
        final phone = (userData['phone'] as String?)?.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '') ?? '';
        
        // Match by email or phone
        if (email == normalizedQuery || 
            phone == normalizedPhone ||
            email.contains(normalizedQuery) ||
            phone.contains(normalizedPhone)) {
          print('✅ Found user: ${userData['name']} ($email)');
          userData['id'] = entry.key;
          return userData;
        }
      }

      print('❌ User not found');
      return null;
    } catch (e) {
      print('❌ Error finding user: $e');
      return null;
    }
  }

  // Gửi yêu cầu kết nối gia đình
  Future<bool> sendFamilyRequest({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    required String relationship,
  }) async {
    try {
      // Kiểm tra đã tồn tại chưa
      final existingRequest = await _checkExistingConnection(fromUserId, toUserId);
      if (existingRequest != null) {
        return false; // Đã tồn tại
      }

      final requestId = _database.child('family_requests').push().key!;
      
      await _database.child('family_requests').child(requestId).set({
        'id': requestId,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'toUserId': toUserId,
        'toUserName': toUserName,
        'relationship': relationship,
        'status': 'pending', // pending, accepted, rejected
        'createdAt': ServerValue.timestamp,
      });

      // Tạo thông báo cho người nhận
      await _createNotification(
        userId: toUserId,
        type: 'family_request',
        title: 'Yêu cầu kết nối gia đình',
        message: '$fromUserName muốn thêm bạn vào danh sách gia đình',
        data: {'requestId': requestId},
      );

      return true;
    } catch (e) {
      print('Error sending family request: $e');
      return false;
    }
  }

  // Kiểm tra kết nối đã tồn tại
  Future<String?> _checkExistingConnection(String userId1, String userId2) async {
    try {
      // Kiểm tra yêu cầu đang chờ
      final requestsSnapshot = await _database
          .child('family_requests')
          .orderByChild('fromUserId')
          .equalTo(userId1)
          .get();

      if (requestsSnapshot.exists) {
        final data = Map<String, dynamic>.from(requestsSnapshot.value as Map);
        for (var entry in data.entries) {
          final request = Map<String, dynamic>.from(entry.value as Map);
          if (request['toUserId'] == userId2 && request['status'] == 'pending') {
            return 'pending_sent';
          }
        }
      }

      // Kiểm tra đã là thành viên
      final familySnapshot = await _database
          .child('family_members')
          .child(userId1)
          .orderByChild('memberId')
          .equalTo(userId2)
          .get();

      if (familySnapshot.exists) {
        return 'already_member';
      }

      return null;
    } catch (e) {
      print('Error checking existing connection: $e');
      return null;
    }
  }

  // Chấp nhận yêu cầu
  Future<bool> acceptFamilyRequest(String requestId) async {
    try {
      final requestSnapshot = await _database
          .child('family_requests')
          .child(requestId)
          .get();

      if (!requestSnapshot.exists) return false;

      final request = Map<String, dynamic>.from(requestSnapshot.value as Map);
      
      // Cập nhật status
      await _database
          .child('family_requests')
          .child(requestId)
          .update({'status': 'accepted', 'updatedAt': ServerValue.timestamp});

      // Thêm vào family_members (2 chiều)
      final memberId1 = _database.child('family_members').child(request['fromUserId']).push().key!;
      final memberId2 = _database.child('family_members').child(request['toUserId']).push().key!;

      await _database
          .child('family_members')
          .child(request['fromUserId'])
          .child(memberId1)
          .set({
        'id': memberId1,
        'memberId': request['toUserId'],
        'memberName': request['toUserName'],
        'relationship': request['relationship'],
        'addedAt': ServerValue.timestamp,
      });

      await _database
          .child('family_members')
          .child(request['toUserId'])
          .child(memberId2)
          .set({
        'id': memberId2,
        'memberId': request['fromUserId'],
        'memberName': request['fromUserName'],
        'relationship': _reverseRelationship(request['relationship']),
        'addedAt': ServerValue.timestamp,
      });

      // Tạo thông báo
      await _createNotification(
        userId: request['fromUserId'],
        type: 'family_accepted',
        title: 'Yêu cầu được chấp nhận',
        message: '${request['toUserName']} đã chấp nhận yêu cầu kết nối gia đình',
        data: {'memberId': memberId1},
      );

      return true;
    } catch (e) {
      print('Error accepting request: $e');
      return false;
    }
  }

  // Từ chối yêu cầu
  Future<bool> rejectFamilyRequest(String requestId) async {
    try {
      final requestSnapshot = await _database
          .child('family_requests')
          .child(requestId)
          .get();

      if (!requestSnapshot.exists) return false;

      final request = Map<String, dynamic>.from(requestSnapshot.value as Map);

      await _database
          .child('family_requests')
          .child(requestId)
          .update({'status': 'rejected', 'updatedAt': ServerValue.timestamp});

      // Tạo thông báo
      await _createNotification(
        userId: request['fromUserId'],
        type: 'family_rejected',
        title: 'Yêu cầu bị từ chối',
        message: '${request['toUserName']} đã từ chối yêu cầu kết nối gia đình',
        data: {'requestId': requestId},
      );

      return true;
    } catch (e) {
      print('Error rejecting request: $e');
      return false;
    }
  }

  // Xóa thành viên gia đình
  Future<bool> removeFamilyMember(String userId, String memberId) async {
    try {
      // Xóa từ cả 2 phía
      final memberSnapshot = await _database
          .child('family_members')
          .child(userId)
          .child(memberId)
          .get();

      if (!memberSnapshot.exists) return false;

      final member = Map<String, dynamic>.from(memberSnapshot.value as Map);
      final otherUserId = member['memberId'];

      // Xóa từ phía user hiện tại
      await _database
          .child('family_members')
          .child(userId)
          .child(memberId)
          .remove();

      // Tìm và xóa từ phía user kia
      final otherSideSnapshot = await _database
          .child('family_members')
          .child(otherUserId)
          .orderByChild('memberId')
          .equalTo(userId)
          .get();

      if (otherSideSnapshot.exists) {
        final data = Map<String, dynamic>.from(otherSideSnapshot.value as Map);
        final otherMemberId = data.keys.first;
        await _database
            .child('family_members')
            .child(otherUserId)
            .child(otherMemberId)
            .remove();
      }

      return true;
    } catch (e) {
      print('Error removing family member: $e');
      return false;
    }
  }

  // Lấy danh sách gia đình
  Future<List<Map<String, dynamic>>> getFamilyMembers(String userId) async {
    try {
      final snapshot = await _database
          .child('family_members')
          .child(userId)
          .get();

      if (!snapshot.exists) return [];

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final members = <Map<String, dynamic>>[];

      data.forEach((key, value) {
        final member = Map<String, dynamic>.from(value as Map);
        member['id'] = key;
        members.add(member);
      });

      return members;
    } catch (e) {
      print('Error getting family members: $e');
      return [];
    }
  }

  // Lấy yêu cầu đang chờ (nhận được)
  Future<List<Map<String, dynamic>>> getPendingRequests(String userId) async {
    try {
      final snapshot = await _database
          .child('family_requests')
          .orderByChild('toUserId')
          .equalTo(userId)
          .get();

      if (!snapshot.exists) return [];

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final requests = <Map<String, dynamic>>[];

      data.forEach((key, value) {
        final request = Map<String, dynamic>.from(value as Map);
        if (request['status'] == 'pending') {
          request['id'] = key;
          requests.add(request);
        }
      });

      return requests;
    } catch (e) {
      print('Error getting pending requests: $e');
      return [];
    }
  }

  // Lấy yêu cầu đã gửi đi
  Future<List<Map<String, dynamic>>> getSentRequests(String userId) async {
    try {
      final snapshot = await _database
          .child('family_requests')
          .orderByChild('fromUserId')
          .equalTo(userId)
          .get();

      if (!snapshot.exists) return [];

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final requests = <Map<String, dynamic>>[];

      data.forEach((key, value) {
        final request = Map<String, dynamic>.from(value as Map);
        if (request['status'] == 'pending') {
          request['id'] = key;
          requests.add(request);
        }
      });

      return requests;
    } catch (e) {
      print('Error getting sent requests: $e');
      return [];
    }
  }

  // Hủy yêu cầu đã gửi
  Future<bool> cancelSentRequest(String requestId) async {
    try {
      await _database
          .child('family_requests')
          .child(requestId)
          .remove();
      return true;
    } catch (e) {
      print('Error canceling request: $e');
      return false;
    }
  }

  // Tạo thông báo
  Future<void> _createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationId = _database.child('notifications').child(userId).push().key!;
      
      await _database
          .child('notifications')
          .child(userId)
          .child(notificationId)
          .set({
        'id': notificationId,
        'type': type,
        'title': title,
        'message': message,
        'data': data ?? {},
        'isRead': false,
        'createdAt': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Đảo ngược mối quan hệ
  String _reverseRelationship(String relationship) {
    final map = {
      'Bố/Mẹ': 'Con',
      'Con': 'Bố/Mẹ',
      'Anh/Chị': 'Em',
      'Em': 'Anh/Chị',
      'Vợ/Chồng': 'Vợ/Chồng',
      'Người thân': 'Người thân',
    };
    return map[relationship] ?? 'Người thân';
  }

  // Lấy số lượng thông báo chưa đọc
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final snapshot = await _database
          .child('notifications')
          .child(userId)
          .orderByChild('isRead')
          .equalTo(false)
          .get();

      if (!snapshot.exists) return 0;

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Lấy danh sách thông báo
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final snapshot = await _database
          .child('notifications')
          .child(userId)
          .get();

      if (!snapshot.exists) return [];

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final notifications = <Map<String, dynamic>>[];

      data.forEach((key, value) {
        final notification = Map<String, dynamic>.from(value as Map);
        notification['id'] = key;
        notifications.add(notification);
      });

      // Sắp xếp theo thời gian mới nhất
      notifications.sort((a, b) {
        final timeA = a['createdAt'] ?? 0;
        final timeB = b['createdAt'] ?? 0;
        return timeB.compareTo(timeA);
      });

      return notifications;
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  // Đánh dấu đã đọc
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _database
          .child('notifications')
          .child(userId)
          .child(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  // Đánh dấu tất cả đã đọc
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _database
          .child('notifications')
          .child(userId)
          .get();

      if (!snapshot.exists) return;

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      
      for (var key in data.keys) {
        await _database
            .child('notifications')
            .child(userId)
            .child(key)
            .update({'isRead': true});
      }
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }
}
