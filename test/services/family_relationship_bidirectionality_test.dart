import 'package:glados/glados.dart';

/// **Feature: sews-improvement-plan, Property 9: Family Relationship Bidirectionality**
/// **Validates: Requirements 6.1**
///
/// Property: For any family member addition, both users SHALL have the
/// relationship recorded in their family lists.

/// Test model for family member relationship
class TestFamilyMember {
  final String id;
  final String memberId;
  final String memberName;
  final String relationship;
  final int addedAt;

  TestFamilyMember({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.relationship,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'memberName': memberName,
        'relationship': relationship,
        'addedAt': addedAt,
      };

  factory TestFamilyMember.fromJson(Map<String, dynamic> json) =>
      TestFamilyMember(
        id: json['id'] ?? '',
        memberId: json['memberId'] ?? '',
        memberName: json['memberName'] ?? '',
        relationship: json['relationship'] ?? '',
        addedAt: json['addedAt'] ?? 0,
      );

  @override
  String toString() =>
      'TestFamilyMember(id: $id, memberId: $memberId, relationship: $relationship)';
}

/// Family relationship request data
class FamilyRelationshipRequest {
  final String userId;
  final String userName;
  final String memberId;
  final String memberName;
  final String relationship;

  FamilyRelationshipRequest({
    required this.userId,
    required this.userName,
    required this.memberId,
    required this.memberName,
    required this.relationship,
  });

  @override
  String toString() =>
      'FamilyRelationshipRequest(userId: $userId, memberId: $memberId, relationship: $relationship)';
}


/// Simulates the family service behavior for bidirectional relationships
/// Mirrors the logic from FamilyService.addFamilyMemberBidirectional
class FamilyServiceSimulator {
  /// Storage: userId -> Map<memberId, FamilyMember>
  final Map<String, Map<String, TestFamilyMember>> _familyMembers = {};
  int _idCounter = 0;

  /// Add a family member with bidirectional relationship
  /// Mirrors FamilyService.addFamilyMemberBidirectional
  /// Validates: Requirements 6.1
  bool addFamilyMemberBidirectional(FamilyRelationshipRequest request) {
    // Validate input
    if (request.userId.isEmpty || request.memberId.isEmpty) {
      return false;
    }

    // Cannot add self as family member
    if (request.userId == request.memberId) {
      return false;
    }

    // Check if already connected
    if (isAlreadyFamilyMember(request.userId, request.memberId)) {
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final memberId1 = 'member_${_idCounter++}';
    final memberId2 = 'member_${_idCounter++}';

    // Initialize user's family list if not exists
    _familyMembers[request.userId] ??= {};
    _familyMembers[request.memberId] ??= {};

    // Add member to user's family list
    _familyMembers[request.userId]![memberId1] = TestFamilyMember(
      id: memberId1,
      memberId: request.memberId,
      memberName: request.memberName,
      relationship: request.relationship,
      addedAt: now,
    );

    // Add user to member's family list (reverse relationship)
    _familyMembers[request.memberId]![memberId2] = TestFamilyMember(
      id: memberId2,
      memberId: request.userId,
      memberName: request.userName,
      relationship: _reverseRelationship(request.relationship),
      addedAt: now,
    );

    return true;
  }

  /// Check if two users are already family members
  bool isAlreadyFamilyMember(String userId, String memberId) {
    final userFamily = _familyMembers[userId];
    if (userFamily == null) return false;

    return userFamily.values.any((member) => member.memberId == memberId);
  }

  /// Get family members for a user
  List<TestFamilyMember> getFamilyMembers(String userId) {
    final userFamily = _familyMembers[userId];
    if (userFamily == null) return [];
    return userFamily.values.toList();
  }

  /// Get family member IDs for a user
  List<String> getFamilyMemberIds(String userId) {
    return getFamilyMembers(userId).map((m) => m.memberId).toList();
  }

  /// Check if user has a specific family member
  bool hasFamilyMember(String userId, String memberId) {
    return getFamilyMemberIds(userId).contains(memberId);
  }

  /// Get the relationship from user to member
  String? getRelationship(String userId, String memberId) {
    final userFamily = _familyMembers[userId];
    if (userFamily == null) return null;

    final member = userFamily.values
        .where((m) => m.memberId == memberId)
        .firstOrNull;
    return member?.relationship;
  }

  /// Remove family member (bidirectional)
  bool removeFamilyMember(String userId, String memberId) {
    final userFamily = _familyMembers[userId];
    if (userFamily == null) return false;

    // Find and remove from user's list
    String? keyToRemove;
    for (var entry in userFamily.entries) {
      if (entry.value.memberId == memberId) {
        keyToRemove = entry.key;
        break;
      }
    }

    if (keyToRemove == null) return false;
    userFamily.remove(keyToRemove);

    // Remove from member's list (reverse)
    final memberFamily = _familyMembers[memberId];
    if (memberFamily != null) {
      String? reverseKeyToRemove;
      for (var entry in memberFamily.entries) {
        if (entry.value.memberId == userId) {
          reverseKeyToRemove = entry.key;
          break;
        }
      }
      if (reverseKeyToRemove != null) {
        memberFamily.remove(reverseKeyToRemove);
      }
    }

    return true;
  }

  /// Clear all data
  void clear() => _familyMembers.clear();

  /// Reverse relationship mapping (mirrors FamilyService._reverseRelationship)
  String _reverseRelationship(String relationship) {
    const map = {
      'Bố/Mẹ': 'Con',
      'Con': 'Bố/Mẹ',
      'Anh/Chị': 'Em',
      'Em': 'Anh/Chị',
      'Vợ/Chồng': 'Vợ/Chồng',
      'Người thân': 'Người thân',
    };
    return map[relationship] ?? 'Người thân';
  }
}

/// Pure function to get the reverse relationship
/// Mirrors FamilyService._reverseRelationship
String reverseRelationship(String relationship) {
  const map = {
    'Bố/Mẹ': 'Con',
    'Con': 'Bố/Mẹ',
    'Anh/Chị': 'Em',
    'Em': 'Anh/Chị',
    'Vợ/Chồng': 'Vợ/Chồng',
    'Người thân': 'Người thân',
  };
  return map[relationship] ?? 'Người thân';
}


/// Custom generators for family relationship tests
extension FamilyRelationshipAny on Any {
  /// Generator for valid user IDs
  Generator<String> get validUserId {
    return any.letterOrDigits.map((s) => 'user_${s.isEmpty ? 'default' : s}');
  }

  /// Generator for user names
  Generator<String> get userName {
    return any.letterOrDigits.map((s) => 'User ${s.isEmpty ? 'John' : s}');
  }

  /// Generator for valid relationship types
  Generator<String> get validRelationship {
    return any.choose([
      'Bố/Mẹ',
      'Con',
      'Anh/Chị',
      'Em',
      'Vợ/Chồng',
      'Người thân',
    ]);
  }

  /// Generator for FamilyRelationshipRequest with distinct user and member IDs
  Generator<FamilyRelationshipRequest> get familyRelationshipRequest {
    return any.combine5(
      any.validUserId,
      any.userName,
      any.validUserId,
      any.userName,
      any.validRelationship,
      (userId, userName, memberId, memberName, relationship) {
        // Ensure userId and memberId are different
        final actualMemberId = userId == memberId 
            ? '${memberId}_other' 
            : memberId;
        final actualMemberName = userId == memberId 
            ? '${memberName} Other' 
            : memberName;
        
        return FamilyRelationshipRequest(
          userId: userId,
          userName: userName,
          memberId: actualMemberId,
          memberName: actualMemberName,
          relationship: relationship,
        );
      },
    );
  }

  /// Generator for list of family relationship requests
  Generator<List<FamilyRelationshipRequest>> get familyRelationshipRequestList {
    return any.list(any.familyRelationshipRequest).map((list) {
      // Ensure at least 1 request
      if (list.isEmpty) {
        return [
          FamilyRelationshipRequest(
            userId: 'user_default',
            userName: 'User Default',
            memberId: 'user_member',
            memberName: 'User Member',
            relationship: 'Người thân',
          )
        ];
      }
      // Limit to 5 for performance
      return list.take(5).toList();
    });
  }
}

void main() {
  group('Family Relationship Bidirectionality Property Tests', () {
    /// **Feature: sews-improvement-plan, Property 9: Family Relationship Bidirectionality**
    /// **Validates: Requirements 6.1**
    ///
    /// Property: For any family member addition, both users SHALL have the
    /// relationship recorded in their family lists.
    Glados(any.familyRelationshipRequest).test(
      'Property 9.1: Adding family member creates bidirectional relationship',
      (request) {
        // Arrange
        final service = FamilyServiceSimulator();

        // Act
        final result = service.addFamilyMemberBidirectional(request);

        // Assert: Addition should succeed
        expect(result, isTrue,
            reason: 'Adding family member should succeed');

        // Assert: User should have member in their family list
        expect(service.hasFamilyMember(request.userId, request.memberId), isTrue,
            reason: 'User should have member in their family list');

        // Assert: Member should have user in their family list (bidirectional)
        expect(service.hasFamilyMember(request.memberId, request.userId), isTrue,
            reason: 'Member should have user in their family list (bidirectional)');
      },
    );

    /// Property: Relationship types are correctly reversed
    Glados(any.familyRelationshipRequest).test(
      'Property 9.2: Relationship types are correctly reversed',
      (request) {
        // Arrange
        final service = FamilyServiceSimulator();

        // Act
        service.addFamilyMemberBidirectional(request);

        // Assert: User's relationship to member
        final userToMemberRelation = service.getRelationship(
          request.userId,
          request.memberId,
        );
        expect(userToMemberRelation, equals(request.relationship),
            reason: 'User should have the original relationship to member');

        // Assert: Member's relationship to user (reversed)
        final memberToUserRelation = service.getRelationship(
          request.memberId,
          request.userId,
        );
        final expectedReverse = reverseRelationship(request.relationship);
        expect(memberToUserRelation, equals(expectedReverse),
            reason: 'Member should have the reversed relationship to user');
      },
    );

    /// Property: Reverse relationship is symmetric for symmetric relationships
    Glados(any.choose(['Vợ/Chồng', 'Người thân'])).test(
      'Property 9.3: Symmetric relationships remain the same when reversed',
      (relationship) {
        // Act
        final reversed = reverseRelationship(relationship);

        // Assert: Symmetric relationships should remain the same
        expect(reversed, equals(relationship),
            reason: 'Symmetric relationships should remain the same when reversed');
      },
    );

    /// Property: Reverse relationship is inverse for asymmetric relationships
    Glados(any.choose(['Bố/Mẹ', 'Con', 'Anh/Chị', 'Em'])).test(
      'Property 9.4: Asymmetric relationships are properly inverted',
      (relationship) {
        // Act
        final reversed = reverseRelationship(relationship);
        final doubleReversed = reverseRelationship(reversed);

        // Assert: Double reverse should return to original
        expect(doubleReversed, equals(relationship),
            reason: 'Double reverse should return to original relationship');
      },
    );

    /// Property: Cannot add self as family member
    Glados(any.validUserId).test(
      'Property 9.5: Cannot add self as family member',
      (userId) {
        // Arrange
        final service = FamilyServiceSimulator();
        final request = FamilyRelationshipRequest(
          userId: userId,
          userName: 'User Name',
          memberId: userId, // Same as userId
          memberName: 'User Name',
          relationship: 'Người thân',
        );

        // Act
        final result = service.addFamilyMemberBidirectional(request);

        // Assert: Should fail
        expect(result, isFalse,
            reason: 'Should not be able to add self as family member');
      },
    );

    /// Property: Cannot add duplicate family member
    Glados(any.familyRelationshipRequest).test(
      'Property 9.6: Cannot add duplicate family member',
      (request) {
        // Arrange
        final service = FamilyServiceSimulator();

        // Act: Add first time
        final firstResult = service.addFamilyMemberBidirectional(request);
        expect(firstResult, isTrue);

        // Act: Try to add again
        final secondResult = service.addFamilyMemberBidirectional(request);

        // Assert: Second addition should fail
        expect(secondResult, isFalse,
            reason: 'Should not be able to add duplicate family member');

        // Assert: Should still have exactly one relationship each way
        final userFamilyMembers = service.getFamilyMembers(request.userId);
        final memberFamilyMembers = service.getFamilyMembers(request.memberId);

        final userToMemberCount = userFamilyMembers
            .where((m) => m.memberId == request.memberId)
            .length;
        final memberToUserCount = memberFamilyMembers
            .where((m) => m.memberId == request.userId)
            .length;

        expect(userToMemberCount, equals(1),
            reason: 'User should have exactly one relationship to member');
        expect(memberToUserCount, equals(1),
            reason: 'Member should have exactly one relationship to user');
      },
    );

    /// Property: Removing family member removes bidirectional relationship
    Glados(any.familyRelationshipRequest).test(
      'Property 9.7: Removing family member removes bidirectional relationship',
      (request) {
        // Arrange
        final service = FamilyServiceSimulator();
        service.addFamilyMemberBidirectional(request);

        // Verify both relationships exist
        expect(service.hasFamilyMember(request.userId, request.memberId), isTrue);
        expect(service.hasFamilyMember(request.memberId, request.userId), isTrue);

        // Act: Remove family member
        final result = service.removeFamilyMember(request.userId, request.memberId);

        // Assert: Removal should succeed
        expect(result, isTrue,
            reason: 'Removing family member should succeed');

        // Assert: Both relationships should be removed
        expect(service.hasFamilyMember(request.userId, request.memberId), isFalse,
            reason: 'User should no longer have member in family list');
        expect(service.hasFamilyMember(request.memberId, request.userId), isFalse,
            reason: 'Member should no longer have user in family list');
      },
    );

    /// Property: Multiple family relationships are independent
    Glados(any.familyRelationshipRequestList).test(
      'Property 9.8: Multiple family relationships are independent',
      (requests) {
        // Arrange
        final service = FamilyServiceSimulator();
        final successfulRequests = <FamilyRelationshipRequest>[];

        // Act: Add all relationships
        for (final request in requests) {
          if (service.addFamilyMemberBidirectional(request)) {
            successfulRequests.add(request);
          }
        }

        // Assert: Each successful relationship should be bidirectional
        for (final request in successfulRequests) {
          expect(service.hasFamilyMember(request.userId, request.memberId), isTrue,
              reason: 'User ${request.userId} should have member ${request.memberId}');
          expect(service.hasFamilyMember(request.memberId, request.userId), isTrue,
              reason: 'Member ${request.memberId} should have user ${request.userId}');
        }
      },
    );

    /// Property: Family member data is preserved correctly
    Glados(any.familyRelationshipRequest).test(
      'Property 9.9: Family member data is preserved correctly',
      (request) {
        // Arrange
        final service = FamilyServiceSimulator();

        // Act
        service.addFamilyMemberBidirectional(request);

        // Assert: User's family member data
        final userFamilyMembers = service.getFamilyMembers(request.userId);
        final memberInUserList = userFamilyMembers
            .where((m) => m.memberId == request.memberId)
            .first;

        expect(memberInUserList.memberName, equals(request.memberName),
            reason: 'Member name should be preserved');
        expect(memberInUserList.relationship, equals(request.relationship),
            reason: 'Relationship should be preserved');

        // Assert: Member's family member data
        final memberFamilyMembers = service.getFamilyMembers(request.memberId);
        final userInMemberList = memberFamilyMembers
            .where((m) => m.memberId == request.userId)
            .first;

        expect(userInMemberList.memberName, equals(request.userName),
            reason: 'User name should be preserved in member list');
      },
    );
  });
}
