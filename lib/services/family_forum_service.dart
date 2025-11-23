import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../data/models/family_forum_models.dart';

class EnhancedFamilyService {
  static final EnhancedFamilyService _instance = EnhancedFamilyService._internal();
  factory EnhancedFamilyService() => _instance;
  EnhancedFamilyService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Get user's family groups
  Stream<List<FamilyGroupModel>> getUserFamilyGroups(String userId) {
    return _db
        .child('user_family_groups')
        .child(userId)
        .onValue
        .asyncMap((event) async {
      final List<FamilyGroupModel> groups = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        for (var entry in data.entries) {
          final groupId = entry.key;
          final groupSnapshot = await _db.child('family_groups').child(groupId).get();
          if (groupSnapshot.exists) {
            final groupData = Map<String, dynamic>.from(groupSnapshot.value as Map);
            groups.add(FamilyGroupModel.fromJson(groupData));
          }
        }
      }
      return groups;
    });
  }

  /// Get family group members
  Stream<List<FamilyMemberModel>> getGroupMembers(String groupId) {
    return _db
        .child('family_group_members')
        .child(groupId)
        .onValue
        .map((event) {
      final List<FamilyMemberModel> members = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final memberData = Map<String, dynamic>.from(value as Map);
          members.add(FamilyMemberModel.fromJson(memberData));
        });
      }
      return members;
    });
  }

  /// Create family group
  Future<String?> createFamilyGroup({
    required String userId,
    required String userName,
    required String groupName,
    String? description,
  }) async {
    try {
      final groupRef = _db.child('family_groups').push();
      final groupId = groupRef.key!;
      final now = DateTime.now().millisecondsSinceEpoch;

      final group = FamilyGroupModel(
        groupId: groupId,
        groupName: groupName,
        creatorId: userId,
        description: description,
        createdAt: now,
        memberCount: 1,
      );

      await groupRef.set(group.toJson());

      // Add creator as admin member
      await _db.child('family_group_members').child(groupId).child(userId).set({
        'userId': userId,
        'userName': userName,
        'role': 'admin',
        'joinedAt': now,
        'addedBy': userId,
      });

      // Add to user's groups
      await _db.child('user_family_groups').child(userId).child(groupId).set({
        'groupId': groupId,
        'joinedAt': now,
      });

      return groupId;
    } catch (e) {
      print('Error creating family group: $e');
      return null;
    }
  }

  /// Add member to group
  Future<bool> addMember({
    required String groupId,
    required String userId,
    required String userName,
    required String addedBy,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      await _db.child('family_group_members').child(groupId).child(userId).set({
        'userId': userId,
        'userName': userName,
        'role': 'member',
        'joinedAt': now,
        'addedBy': addedBy,
      });

      await _db.child('user_family_groups').child(userId).child(groupId).set({
        'groupId': groupId,
        'joinedAt': now,
      });

      await _db.child('family_groups').child(groupId).update({
        'memberCount': ServerValue.increment(1),
      });

      return true;
    } catch (e) {
      print('Error adding member: $e');
      return false;
    }
  }

  /// Remove member from group
  Future<bool> removeMember(String groupId, String userId) async {
    try {
      await _db.child('family_group_members').child(groupId).child(userId).remove();
      await _db.child('user_family_groups').child(userId).child(groupId).remove();
      await _db.child('family_groups').child(groupId).update({
        'memberCount': ServerValue.increment(-1),
      });
      return true;
    } catch (e) {
      print('Error removing member: $e');
      return false;
    }
  }
}

class ForumService {
  static final ForumService _instance = ForumService._internal();
  factory ForumService() => _instance;
  ForumService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Get all forum threads
  Stream<List<ForumThreadModel>> getForumThreads({String? category}) {
    var query = _db.child('forum_threads').orderByChild('createdAt');
    
    return query.onValue.map((event) {
      final List<ForumThreadModel> threads = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final threadData = Map<String, dynamic>.from(value as Map);
          final thread = ForumThreadModel.fromJson(threadData);
          if (category == null || thread.category == category) {
            threads.add(thread);
          }
        });
      }
      threads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return threads;
    });
  }

  /// Get thread posts
  Stream<List<ForumPostModel>> getThreadPosts(String threadId) {
    return _db
        .child('forum_posts')
        .child(threadId)
        .orderByChild('createdAt')
        .onValue
        .map((event) {
      final List<ForumPostModel> posts = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final postData = Map<String, dynamic>.from(value as Map);
          posts.add(ForumPostModel.fromJson(postData));
        });
      }
      posts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return posts;
    });
  }

  /// Create forum thread
  Future<String?> createThread({
    required String userId,
    required String userName,
    required String title,
    required String content,
    required String category,
  }) async {
    try {
      final threadRef = _db.child('forum_threads').push();
      final threadId = threadRef.key!;
      final now = DateTime.now().millisecondsSinceEpoch;

      final thread = ForumThreadModel(
        threadId: threadId,
        userId: userId,
        userName: userName,
        title: title,
        content: content,
        category: category,
        viewCount: 0,
        replyCount: 0,
        createdAt: now,
      );

      await threadRef.set(thread.toJson());
      return threadId;
    } catch (e) {
      print('Error creating thread: $e');
      return null;
    }
  }

  /// Create forum post (reply)
  Future<String?> createPost({
    required String threadId,
    required String userId,
    required String userName,
    required String content,
  }) async {
    try {
      final postRef = _db.child('forum_posts').child(threadId).push();
      final postId = postRef.key!;
      final now = DateTime.now().millisecondsSinceEpoch;

      final post = ForumPostModel(
        postId: postId,
        threadId: threadId,
        userId: userId,
        userName: userName,
        content: content,
        createdAt: now,
      );

      await postRef.set(post.toJson());

      // Update thread reply count and last reply time
      await _db.child('forum_threads').child(threadId).update({
        'replyCount': ServerValue.increment(1),
        'lastReplyAt': now,
      });

      return postId;
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  /// Increment view count
  Future<void> incrementViewCount(String threadId) async {
    try {
      await _db.child('forum_threads').child(threadId).update({
        'viewCount': ServerValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }
}
