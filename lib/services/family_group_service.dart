import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

/// Service quản lý Family Groups (1:N relationships)
/// Cho phép tạo nhóm gia đình với nhiều thành viên
class FamilyGroupService {
  static final FamilyGroupService _instance = FamilyGroupService._internal();
  factory FamilyGroupService() => _instance;
  FamilyGroupService._internal();

  final _database = FirebaseDatabase.instance.ref();

  /// Tạo nhóm gia đình mới
  Future<String?> createFamilyGroup({
    required String creatorId,
    required String creatorName,
    required String groupName,
    String? description,
  }) async {
    try {
      final groupId = _database.child('family_groups').push().key!;
      
      await _database.child('family_groups').child(groupId).set({
        'id': groupId,
        'name': groupName,
        'description': description ?? '',
        'creatorId': creatorId,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
        'memberCount': 1,
      });

      // Thêm creator vào nhóm
      await addMemberToGroup(
        groupId: groupId,
        userId: creatorId,
        userName: creatorName,
        role: 'admin', // Creator là admin
        addedBy: creatorId,
      );

      print('✅ Created family group: $groupId');
      return groupId;
    } catch (e) {
      print('❌ Error creating family group: $e');
      return null;
    }
  }

  /// Thêm thành viên vào nhóm
  Future<bool> addMemberToGroup({
    required String groupId,
    required String userId,
    required String userName,
    String role = 'member', // admin, member
    required String addedBy,
  }) async {
    try {
      // Check if already member
      final existingMember = await _database
          .child('family_group_members')
          .child(groupId)
          .child(userId)
          .get();

      if (existingMember.exists) {
        print('⚠️ User already in group');
        return false;
      }

      // Add to group members
      await _database
          .child('family_group_members')
          .child(groupId)
          .child(userId)
          .set({
        'userId': userId,
        'userName': userName,
        'role': role,
        'addedBy': addedBy,
        'joinedAt': ServerValue.timestamp,
      });

      // Add to user's groups
      await _database
          .child('user_family_groups')
          .child(userId)
          .child(groupId)
          .set({
        'groupId': groupId,
        'role': role,
        'joinedAt': ServerValue.timestamp,
      });

      // Update member count
      final groupSnapshot = await _database
          .child('family_groups')
          .child(groupId)
          .get();

      if (groupSnapshot.exists) {
        final groupData = Map<String, dynamic>.from(groupSnapshot.value as Map);
        final currentCount = groupData['memberCount'] ?? 0;
        
        await _database
            .child('family_groups')
            .child(groupId)
            .update({
          'memberCount': currentCount + 1,
          'updatedAt': ServerValue.timestamp,
        });
      }

      // Create notification for new member
      await _createNotification(
        userId: userId,
        type: 'added_to_group',
        title: 'Thêm vào nhóm gia đình',
        message: 'Bạn đã được thêm vào nhóm gia đình',
        data: {'groupId': groupId},
      );

      print('✅ Added member to group: $userId → $groupId');
      return true;
    } catch (e) {
      print('❌ Error adding member to group: $e');
      return false;
    }
  }

  /// Gửi lời mời vào nhóm
  Future<bool> sendGroupInvitation({
    required String groupId,
    required String groupName,
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
  }) async {
    try {
      // Check if already member
      final existingMember = await _database
          .child('family_group_members')
          .child(groupId)
          .child(toUserId)
          .get();

      if (existingMember.exists) {
        return false; // Already member
      }

      // Check if invitation already sent
      final existingInvitation = await _database
          .child('family_group_invitations')
          .orderByChild('groupId')
          .equalTo(groupId)
          .get();

      if (existingInvitation.exists) {
        final invitations = Map<String, dynamic>.from(existingInvitation.value as Map);
        for (var entry in invitations.entries) {
          final invitation = Map<String, dynamic>.from(entry.value as Map);
          if (invitation['toUserId'] == toUserId && invitation['status'] == 'pending') {
            return false; // Already invited
          }
        }
      }

      final invitationId = _database.child('family_group_invitations').push().key!;

      await _database
          .child('family_group_invitations')
          .child(invitationId)
          .set({
        'id': invitationId,
        'groupId': groupId,
        'groupName': groupName,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'toUserId': toUserId,
        'toUserName': toUserName,
        'status': 'pending', // pending, accepted, rejected
        'createdAt': ServerValue.timestamp,
      });

      // Create notification
      await _createNotification(
        userId: toUserId,
        type: 'group_invitation',
        title: 'Lời mời vào nhóm gia đình',
        message: '$fromUserName mời bạn tham gia nhóm "$groupName"',
        data: {'invitationId': invitationId, 'groupId': groupId},
      );

      print('✅ Sent group invitation: $invitationId');
      return true;
    } catch (e) {
      print('❌ Error sending group invitation: $e');
      return false;
    }
  }

  /// Chấp nhận lời mời
  Future<bool> acceptGroupInvitation(String invitationId) async {
    try {
      final invitationSnapshot = await _database
          .child('family_group_invitations')
          .child(invitationId)
          .get();

      if (!invitationSnapshot.exists) return false;

      final invitation = Map<String, dynamic>.from(invitationSnapshot.value as Map);

      // Update invitation status
      await _database
          .child('family_group_invitations')
          .child(invitationId)
          .update({
        'status': 'accepted',
        'acceptedAt': ServerValue.timestamp,
      });

      // Add member to group
      await addMemberToGroup(
        groupId: invitation['groupId'],
        userId: invitation['toUserId'],
        userName: invitation['toUserName'],
        role: 'member',
        addedBy: invitation['fromUserId'],
      );

      // Notify sender
      await _createNotification(
        userId: invitation['fromUserId'],
        type: 'invitation_accepted',
        title: 'Lời mời được chấp nhận',
        message: '${invitation['toUserName']} đã tham gia nhóm "${invitation['groupName']}"',
        data: {'groupId': invitation['groupId']},
      );

      // Notify all group members
      await _notifyGroupMembers(
        groupId: invitation['groupId'],
        excludeUserId: invitation['toUserId'],
        title: 'Thành viên mới',
        message: '${invitation['toUserName']} đã tham gia nhóm',
      );

      print('✅ Accepted group invitation: $invitationId');
      return true;
    } catch (e) {
      print('❌ Error accepting invitation: $e');
      return false;
    }
  }

  /// Từ chối lời mời
  Future<bool> rejectGroupInvitation(String invitationId) async {
    try {
      final invitationSnapshot = await _database
          .child('family_group_invitations')
          .child(invitationId)
          .get();

      if (!invitationSnapshot.exists) return false;

      final invitation = Map<String, dynamic>.from(invitationSnapshot.value as Map);

      await _database
          .child('family_group_invitations')
          .child(invitationId)
          .update({
        'status': 'rejected',
        'rejectedAt': ServerValue.timestamp,
      });

      // Notify sender
      await _createNotification(
        userId: invitation['fromUserId'],
        type: 'invitation_rejected',
        title: 'Lời mời bị từ chối',
        message: '${invitation['toUserName']} đã từ chối lời mời vào nhóm',
        data: {'groupId': invitation['groupId']},
      );

      print('✅ Rejected group invitation: $invitationId');
      return true;
    } catch (e) {
      print('❌ Error rejecting invitation: $e');
      return false;
    }
  }

  /// Rời khỏi nhóm
  Future<bool> leaveGroup(String groupId, String userId) async {
    try {
      // Check if user is admin
      final memberSnapshot = await _database
          .child('family_group_members')
          .child(groupId)
          .child(userId)
          .get();

      if (!memberSnapshot.exists) return false;

      final member = Map<String, dynamic>.from(memberSnapshot.value as Map);

      // If admin, check if there are other members
      if (member['role'] == 'admin') {
        final membersSnapshot = await _database
            .child('family_group_members')
            .child(groupId)
            .get();

        if (membersSnapshot.exists) {
          final members = Map<String, dynamic>.from(membersSnapshot.value as Map);
          if (members.length > 1) {
            // Transfer admin to another member
            final otherMemberId = members.keys.firstWhere((key) => key != userId);
            await _database
                .child('family_group_members')
                .child(groupId)
                .child(otherMemberId)
                .update({'role': 'admin'});
          } else {
            // Last member, delete group
            await deleteGroup(groupId);
            return true;
          }
        }
      }

      // Remove from group members
      await _database
          .child('family_group_members')
          .child(groupId)
          .child(userId)
          .remove();

      // Remove from user's groups
      await _database
          .child('user_family_groups')
          .child(userId)
          .child(groupId)
          .remove();

      // Update member count
      final groupSnapshot = await _database
          .child('family_groups')
          .child(groupId)
          .get();

      if (groupSnapshot.exists) {
        final groupData = Map<String, dynamic>.from(groupSnapshot.value as Map);
        final currentCount = groupData['memberCount'] ?? 1;
        
        await _database
            .child('family_groups')
            .child(groupId)
            .update({
          'memberCount': currentCount - 1,
          'updatedAt': ServerValue.timestamp,
        });
      }

      // Notify group members
      await _notifyGroupMembers(
        groupId: groupId,
        excludeUserId: userId,
        title: 'Thành viên rời nhóm',
        message: '${member['userName']} đã rời khỏi nhóm',
      );

      print('✅ User left group: $userId → $groupId');
      return true;
    } catch (e) {
      print('❌ Error leaving group: $e');
      return false;
    }
  }

  /// Xóa thành viên khỏi nhóm (chỉ admin)
  Future<bool> removeMemberFromGroup({
    required String groupId,
    required String userId,
    required String removedBy,
  }) async {
    try {
      // Check if remover is admin
      final removerSnapshot = await _database
          .child('family_group_members')
          .child(groupId)
          .child(removedBy)
          .get();

      if (!removerSnapshot.exists) return false;

      final remover = Map<String, dynamic>.from(removerSnapshot.value as Map);
      if (remover['role'] != 'admin') {
        print('⚠️ Only admin can remove members');
        return false;
      }

      // Cannot remove yourself
      if (userId == removedBy) {
        print('⚠️ Cannot remove yourself, use leaveGroup instead');
        return false;
      }

      // Get member info before removing
      final memberSnapshot = await _database
          .child('family_group_members')
          .child(groupId)
          .child(userId)
          .get();

      if (!memberSnapshot.exists) return false;

      final member = Map<String, dynamic>.from(memberSnapshot.value as Map);

      // Remove from group
      await _database
          .child('family_group_members')
          .child(groupId)
          .child(userId)
          .remove();

      // Remove from user's groups
      await _database
          .child('user_family_groups')
          .child(userId)
          .child(groupId)
          .remove();

      // Update member count
      final groupSnapshot = await _database
          .child('family_groups')
          .child(groupId)
          .get();

      if (groupSnapshot.exists) {
        final groupData = Map<String, dynamic>.from(groupSnapshot.value as Map);
        final currentCount = groupData['memberCount'] ?? 1;
        
        await _database
            .child('family_groups')
            .child(groupId)
            .update({
          'memberCount': currentCount - 1,
          'updatedAt': ServerValue.timestamp,
        });
      }

      // Notify removed member
      await _createNotification(
        userId: userId,
        type: 'removed_from_group',
        title: 'Bị xóa khỏi nhóm',
        message: 'Bạn đã bị xóa khỏi nhóm gia đình',
        data: {'groupId': groupId},
      );

      // Notify other members
      await _notifyGroupMembers(
        groupId: groupId,
        excludeUserId: userId,
        title: 'Thành viên bị xóa',
        message: '${member['userName']} đã bị xóa khỏi nhóm',
      );

      print('✅ Removed member from group: $userId → $groupId');
      return true;
    } catch (e) {
      print('❌ Error removing member: $e');
      return false;
    }
  }

  /// Xóa nhóm (chỉ admin)
  Future<bool> deleteGroup(String groupId) async {
    try {
      // Get all members
      final membersSnapshot = await _database
          .child('family_group_members')
          .child(groupId)
          .get();

      if (membersSnapshot.exists) {
        final members = Map<String, dynamic>.from(membersSnapshot.value as Map);
        
        // Remove from each user's groups
        for (var userId in members.keys) {
          await _database
              .child('user_family_groups')
              .child(userId)
              .child(groupId)
              .remove();

          // Notify member
          await _createNotification(
            userId: userId,
            type: 'group_deleted',
            title: 'Nhóm đã bị xóa',
            message: 'Nhóm gia đình đã bị xóa',
            data: {'groupId': groupId},
          );
        }
      }

      // Delete group members
      await _database
          .child('family_group_members')
          .child(groupId)
          .remove();

      // Delete group
      await _database
          .child('family_groups')
          .child(groupId)
          .remove();

      print('✅ Deleted group: $groupId');
      return true;
    } catch (e) {
      print('❌ Error deleting group: $e');
      return false;
    }
  }

  /// Lấy danh sách nhóm của user
  Future<List<Map<String, dynamic>>> getUserGroups(String userId) async {
    try {
      final userGroupsSnapshot = await _database
          .child('user_family_groups')
          .child(userId)
          .get();

      if (!userGroupsSnapshot.exists) return [];

      final userGroups = Map<String, dynamic>.from(userGroupsSnapshot.value as Map);
      final groups = <Map<String, dynamic>>[];

      for (var entry in userGroups.entries) {
        final groupId = entry.key;
        final groupSnapshot = await _database
            .child('family_groups')
            .child(groupId)
            .get();

        if (groupSnapshot.exists) {
          final groupData = Map<String, dynamic>.from(groupSnapshot.value as Map);
          final userGroupData = Map<String, dynamic>.from(entry.value as Map);
          
          groupData['userRole'] = userGroupData['role'];
          groupData['joinedAt'] = userGroupData['joinedAt'];
          groups.add(groupData);
        }
      }

      // Sort by joinedAt
      groups.sort((a, b) {
        final timeA = a['joinedAt'] ?? 0;
        final timeB = b['joinedAt'] ?? 0;
        return timeB.compareTo(timeA);
      });

      return groups;
    } catch (e) {
      print('❌ Error getting user groups: $e');
      return [];
    }
  }

  /// Lấy thành viên của nhóm
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    try {
      final membersSnapshot = await _database
          .child('family_group_members')
          .child(groupId)
          .get();

      if (!membersSnapshot.exists) return [];

      final membersData = Map<String, dynamic>.from(membersSnapshot.value as Map);
      final members = <Map<String, dynamic>>[];

      membersData.forEach((userId, value) {
        final member = Map<String, dynamic>.from(value as Map);
        member['userId'] = userId;
        members.add(member);
      });

      // Sort: admin first, then by joinedAt
      members.sort((a, b) {
        if (a['role'] == 'admin' && b['role'] != 'admin') return -1;
        if (a['role'] != 'admin' && b['role'] == 'admin') return 1;
        
        final timeA = a['joinedAt'] ?? 0;
        final timeB = b['joinedAt'] ?? 0;
        return timeA.compareTo(timeB);
      });

      return members;
    } catch (e) {
      print('❌ Error getting group members: $e');
      return [];
    }
  }

  /// Lấy lời mời đang chờ
  Future<List<Map<String, dynamic>>> getPendingInvitations(String userId) async {
    try {
      final invitationsSnapshot = await _database
          .child('family_group_invitations')
          .orderByChild('toUserId')
          .equalTo(userId)
          .get();

      if (!invitationsSnapshot.exists) return [];

      final invitationsData = Map<String, dynamic>.from(invitationsSnapshot.value as Map);
      final invitations = <Map<String, dynamic>>[];

      invitationsData.forEach((key, value) {
        final invitation = Map<String, dynamic>.from(value as Map);
        if (invitation['status'] == 'pending') {
          invitations.add(invitation);
        }
      });

      // Sort by createdAt
      invitations.sort((a, b) {
        final timeA = a['createdAt'] ?? 0;
        final timeB = b['createdAt'] ?? 0;
        return timeB.compareTo(timeA);
      });

      return invitations;
    } catch (e) {
      print('❌ Error getting pending invitations: $e');
      return [];
    }
  }

  /// Stream để listen real-time changes
  Stream<List<Map<String, dynamic>>> streamUserGroups(String userId) {
    return _database
        .child('user_family_groups')
        .child(userId)
        .onValue
        .asyncMap((event) async {
      if (!event.snapshot.exists) return [];

      final userGroups = Map<String, dynamic>.from(event.snapshot.value as Map);
      final groups = <Map<String, dynamic>>[];

      for (var entry in userGroups.entries) {
        final groupId = entry.key;
        final groupSnapshot = await _database
            .child('family_groups')
            .child(groupId)
            .get();

        if (groupSnapshot.exists) {
          final groupData = Map<String, dynamic>.from(groupSnapshot.value as Map);
          final userGroupData = Map<String, dynamic>.from(entry.value as Map);
          
          groupData['userRole'] = userGroupData['role'];
          groupData['joinedAt'] = userGroupData['joinedAt'];
          groups.add(groupData);
        }
      }

      return groups;
    });
  }

  /// Stream group members
  Stream<List<Map<String, dynamic>>> streamGroupMembers(String groupId) {
    return _database
        .child('family_group_members')
        .child(groupId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return [];

      final membersData = Map<String, dynamic>.from(event.snapshot.value as Map);
      final members = <Map<String, dynamic>>[];

      membersData.forEach((userId, value) {
        final member = Map<String, dynamic>.from(value as Map);
        member['userId'] = userId;
        members.add(member);
      });

      members.sort((a, b) {
        if (a['role'] == 'admin' && b['role'] != 'admin') return -1;
        if (a['role'] != 'admin' && b['role'] == 'admin') return 1;
        
        final timeA = a['joinedAt'] ?? 0;
        final timeB = b['joinedAt'] ?? 0;
        return timeA.compareTo(timeB);
      });

      return members;
    });
  }

  /// Notify all group members
  Future<void> _notifyGroupMembers({
    required String groupId,
    String? excludeUserId,
    required String title,
    required String message,
  }) async {
    try {
      final membersSnapshot = await _database
          .child('family_group_members')
          .child(groupId)
          .get();

      if (!membersSnapshot.exists) return;

      final members = Map<String, dynamic>.from(membersSnapshot.value as Map);

      for (var userId in members.keys) {
        if (userId != excludeUserId) {
          await _createNotification(
            userId: userId,
            type: 'group_update',
            title: title,
            message: message,
            data: {'groupId': groupId},
          );
        }
      }
    } catch (e) {
      print('❌ Error notifying group members: $e');
    }
  }

  /// Create notification
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
      print('❌ Error creating notification: $e');
    }
  }
}
