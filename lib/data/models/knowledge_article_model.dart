class KnowledgeArticleModel {
  final String id;
  final String type; // 'article', 'video'
  final String title;
  final String description;
  final String imageUrl;
  final String meta; // e.g., 'Bài viết • 5 phút đọc'
  final String? videoUrl;
  final List<String> categories;
  final DateTime publishedAt;

  KnowledgeArticleModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.meta,
    this.videoUrl,
    required this.categories,
    required this.publishedAt,
  });

  factory KnowledgeArticleModel.fromJson(Map<String, dynamic> json) {
    return KnowledgeArticleModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      meta: json['meta'] as String,
      videoUrl: json['videoUrl'] as String?,
      categories: List<String>.from(json['categories'] as List),
      publishedAt: DateTime.parse(json['publishedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'meta': meta,
      'videoUrl': videoUrl,
      'categories': categories,
      'publishedAt': publishedAt.toIso8601String(),
    };
  }
}
