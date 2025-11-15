class ForumPostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String content;
  final int likes;
  final int comments;
  final DateTime createdAt;
  final List<String> tags;

  ForumPostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    required this.likes,
    required this.comments,
    required this.createdAt,
    required this.tags,
  });

  factory ForumPostModel.fromJson(Map<String, dynamic> json) {
    return ForumPostModel(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      likes: json['likes'] as int,
      comments: json['comments'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      tags: List<String>.from(json['tags'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'title': title,
      'content': content,
      'likes': likes,
      'comments': comments,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
    };
  }
}
