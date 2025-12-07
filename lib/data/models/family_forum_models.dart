/// Model for family member health status
/// Used for real-time family health monitoring
class FamilyMemberHealth {
  final String memberId;
  final String name;
  final String relationship;
  final String? latestRiskLevel; // 'low', 'medium', 'high', or null
  final DateTime? lastUpdate;
  final int? latestRiskScore;
  final String? predictionType; // 'stroke' or 'diabetes'
  final Map<String, dynamic>? latestHealthRecord;

  FamilyMemberHealth({
    required this.memberId,
    required this.name,
    required this.relationship,
    this.latestRiskLevel,
    this.lastUpdate,
    this.latestRiskScore,
    this.predictionType,
    this.latestHealthRecord,
  });

  factory FamilyMemberHealth.fromJson(Map<String, dynamic> json) {
    return FamilyMemberHealth(
      memberId: json['memberId'] ?? '',
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? 'Người thân',
      latestRiskLevel: json['latestRiskLevel'],
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastUpdate'] as int)
          : null,
      latestRiskScore: json['latestRiskScore'],
      predictionType: json['predictionType'],
      latestHealthRecord: json['latestHealthRecord'] != null
          ? Map<String, dynamic>.from(json['latestHealthRecord'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'name': name,
      'relationship': relationship,
      'latestRiskLevel': latestRiskLevel,
      'lastUpdate': lastUpdate?.millisecondsSinceEpoch,
      'latestRiskScore': latestRiskScore,
      'predictionType': predictionType,
      'latestHealthRecord': latestHealthRecord,
    };
  }

  /// Check if this member has high risk
  bool get isHighRisk => latestRiskLevel == 'high';

  /// Check if this member has medium risk
  bool get isMediumRisk => latestRiskLevel == 'medium';

  /// Get risk level in Vietnamese
  String get riskLevelVi {
    switch (latestRiskLevel) {
      case 'high':
        return 'Nguy cơ cao';
      case 'medium':
        return 'Nguy cơ trung bình';
      case 'low':
        return 'Nguy cơ thấp';
      default:
        return 'Chưa có dữ liệu';
    }
  }

  /// Copy with new values
  FamilyMemberHealth copyWith({
    String? memberId,
    String? name,
    String? relationship,
    String? latestRiskLevel,
    DateTime? lastUpdate,
    int? latestRiskScore,
    String? predictionType,
    Map<String, dynamic>? latestHealthRecord,
  }) {
    return FamilyMemberHealth(
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      latestRiskLevel: latestRiskLevel ?? this.latestRiskLevel,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      latestRiskScore: latestRiskScore ?? this.latestRiskScore,
      predictionType: predictionType ?? this.predictionType,
      latestHealthRecord: latestHealthRecord ?? this.latestHealthRecord,
    );
  }
}

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
