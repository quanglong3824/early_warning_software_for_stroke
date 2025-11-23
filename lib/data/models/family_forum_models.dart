class FamilyGroupModel {
  final String groupId;
  final String groupName;
  final String creatorId;
  final String? description;
  final int createdAt;
  final int memberCount;

  FamilyGroupModel({
    required this.groupId,
    required this.groupName,
    required this.creatorId,
    this.description,
    required this.createdAt,
    required this.memberCount,
  });

  factory FamilyGroupModel.fromJson(Map<String, dynamic> json) {
    return FamilyGroupModel(
      groupId: json['groupId'] ?? '',
      groupName: json['groupName'] ?? '',
      creatorId: json['creatorId'] ?? '',
      description: json['description'],
      createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      memberCount: json['memberCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'creatorId': creatorId,
      'description': description,
      'createdAt': createdAt,
      'memberCount': memberCount,
    };
  }
}

class FamilyMemberModel {
  final String userId;
  final String userName;
  final String role; // admin, member
  final int joinedAt;
  final String? addedBy;

  FamilyMemberModel({
    required this.userId,
    required this.userName,
    required this.role,
    required this.joinedAt,
    this.addedBy,
  });

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      role: json['role'] ?? 'member',
      joinedAt: json['joinedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      addedBy: json['addedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'role': role,
      'joinedAt': joinedAt,
      'addedBy': addedBy,
    };
  }
}

class ForumThreadModel {
  final String threadId;
  final String userId;
  final String userName;
  final String title;
  final String content;
  final String category;
  final int viewCount;
  final int replyCount;
  final int createdAt;
  final int? lastReplyAt;

  ForumThreadModel({
    required this.threadId,
    required this.userId,
    required this.userName,
    required this.title,
    required this.content,
    required this.category,
    required this.viewCount,
    required this.replyCount,
    required this.createdAt,
    this.lastReplyAt,
  });

  factory ForumThreadModel.fromJson(Map<String, dynamic> json) {
    return ForumThreadModel(
      threadId: json['threadId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'general',
      viewCount: json['viewCount'] ?? 0,
      replyCount: json['replyCount'] ?? 0,
      createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      lastReplyAt: json['lastReplyAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'threadId': threadId,
      'userId': userId,
      'userName': userName,
      'title': title,
      'content': content,
      'category': category,
      'viewCount': viewCount,
      'replyCount': replyCount,
      'createdAt': createdAt,
      'lastReplyAt': lastReplyAt,
    };
  }
}

class ForumPostModel {
  final String postId;
  final String threadId;
  final String userId;
  final String userName;
  final String content;
  final int createdAt;

  ForumPostModel({
    required this.postId,
    required this.threadId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory ForumPostModel.fromJson(Map<String, dynamic> json) {
    return ForumPostModel(
      postId: json['postId'] ?? '',
      threadId: json['threadId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'threadId': threadId,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': createdAt,
    };
  }
}
