import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../data/models/knowledge_article_model.dart';
import '../utils/pagination_utils.dart';

/// Interface for Knowledge Service
/// Implements Requirements 9.1, 9.2, 9.3, 9.4, 10.3
abstract class IKnowledgeService {
  /// Create a new article
  Future<String> createArticle(KnowledgeArticleModel article);
  
  /// Update an existing article
  Future<void> updateArticle(String articleId, KnowledgeArticleModel article);
  
  /// Delete an article
  Future<void> deleteArticle(String articleId);
  
  /// Get article by ID
  Future<KnowledgeArticleModel?> getArticle(String articleId);
  
  /// Get all articles (with optional category filter)
  Future<List<KnowledgeArticleModel>> getArticles({String? category});
  
  /// Get paginated articles
  /// Requirements: 10.3
  Future<PaginatedResult<KnowledgeArticleModel>> getArticlesPaginated({
    String? category,
    String? lastKey,
    int pageSize = kDefaultPageSize,
  });
  
  /// Search articles with full-text search
  Future<List<KnowledgeArticleModel>> searchArticles(String query);
  
  /// Track article view
  Future<void> trackView(String articleId, String userId);
  
  /// Get view count for an article
  Future<int> getViewCount(String articleId);
  
  /// Get reading time tracking
  Future<void> trackReadingTime(String articleId, String userId, int seconds);
  
  /// Stream of articles for real-time updates
  Stream<List<KnowledgeArticleModel>> articlesStream({String? category});
  
  /// Publish an article (make it visible to users)
  Future<void> publishArticle(String articleId);
  
  /// Unpublish an article
  Future<void> unpublishArticle(String articleId);
}

/// Extended KnowledgeArticleModel with additional fields for CMS
class KnowledgeArticleExtended extends KnowledgeArticleModel {
  final String? content; // Full article content (HTML or markdown)
  final String authorId;
  final bool isPublished;
  final int viewCount;
  final int totalReadingTimeSeconds;
  final DateTime? updatedAt;
  final List<String> mediaUrls;

  KnowledgeArticleExtended({
    required super.id,
    required super.type,
    required super.title,
    required super.description,
    required super.imageUrl,
    required super.meta,
    super.videoUrl,
    required super.categories,
    required super.publishedAt,
    this.content,
    required this.authorId,
    this.isPublished = false,
    this.viewCount = 0,
    this.totalReadingTimeSeconds = 0,
    this.updatedAt,
    this.mediaUrls = const [],
  });

  factory KnowledgeArticleExtended.fromJson(Map<String, dynamic> json) {
    return KnowledgeArticleExtended(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'article',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      meta: json['meta'] as String? ?? '',
      videoUrl: json['videoUrl'] as String?,
      categories: json['categories'] != null 
          ? List<String>.from(json['categories'] as List)
          : [],
      publishedAt: json['publishedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['publishedAt'] as int)
          : DateTime.now(),
      content: json['content'] as String?,
      authorId: json['authorId'] as String? ?? '',
      isPublished: json['isPublished'] as bool? ?? false,
      viewCount: json['viewCount'] as int? ?? 0,
      totalReadingTimeSeconds: json['totalReadingTimeSeconds'] as int? ?? 0,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : null,
      mediaUrls: json['mediaUrls'] != null 
          ? List<String>.from(json['mediaUrls'] as List)
          : [],
    );
  }

  @override
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
      'publishedAt': publishedAt.millisecondsSinceEpoch,
      'content': content,
      'authorId': authorId,
      'isPublished': isPublished,
      'viewCount': viewCount,
      'totalReadingTimeSeconds': totalReadingTimeSeconds,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'mediaUrls': mediaUrls,
    };
  }

  KnowledgeArticleExtended copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    String? imageUrl,
    String? meta,
    String? videoUrl,
    List<String>? categories,
    DateTime? publishedAt,
    String? content,
    String? authorId,
    bool? isPublished,
    int? viewCount,
    int? totalReadingTimeSeconds,
    DateTime? updatedAt,
    List<String>? mediaUrls,
  }) {
    return KnowledgeArticleExtended(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      meta: meta ?? this.meta,
      videoUrl: videoUrl ?? this.videoUrl,
      categories: categories ?? this.categories,
      publishedAt: publishedAt ?? this.publishedAt,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      isPublished: isPublished ?? this.isPublished,
      viewCount: viewCount ?? this.viewCount,
      totalReadingTimeSeconds: totalReadingTimeSeconds ?? this.totalReadingTimeSeconds,
      updatedAt: updatedAt ?? this.updatedAt,
      mediaUrls: mediaUrls ?? this.mediaUrls,
    );
  }
}

/// Article view record for tracking
class ArticleViewRecord {
  final String articleId;
  final String userId;
  final DateTime viewedAt;
  final int readingTimeSeconds;

  ArticleViewRecord({
    required this.articleId,
    required this.userId,
    required this.viewedAt,
    this.readingTimeSeconds = 0,
  });

  factory ArticleViewRecord.fromJson(Map<String, dynamic> json) {
    return ArticleViewRecord(
      articleId: json['articleId'] as String,
      userId: json['userId'] as String,
      viewedAt: DateTime.fromMillisecondsSinceEpoch(json['viewedAt'] as int),
      readingTimeSeconds: json['readingTimeSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'articleId': articleId,
      'userId': userId,
      'viewedAt': viewedAt.millisecondsSinceEpoch,
      'readingTimeSeconds': readingTimeSeconds,
    };
  }
}


/// Implementation of Knowledge Service
/// Implements Requirements 9.1, 9.2, 9.3, 9.4
class KnowledgeService implements IKnowledgeService {
  // Singleton pattern
  static final KnowledgeService _instance = KnowledgeService._internal();
  factory KnowledgeService() => _instance;
  KnowledgeService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Create a new article
  /// Requirements: 9.1
  @override
  Future<String> createArticle(KnowledgeArticleModel article) async {
    final ref = _database.child('knowledge_articles').push();
    final articleId = ref.key!;
    
    final extendedArticle = article is KnowledgeArticleExtended 
        ? article.copyWith(id: articleId)
        : KnowledgeArticleExtended(
            id: articleId,
            type: article.type,
            title: article.title,
            description: article.description,
            imageUrl: article.imageUrl,
            meta: article.meta,
            videoUrl: article.videoUrl,
            categories: article.categories,
            publishedAt: article.publishedAt,
            authorId: '',
            isPublished: false,
          );
    
    await ref.set(extendedArticle.toJson());
    return articleId;
  }

  /// Update an existing article
  /// Requirements: 9.1, 9.5
  @override
  Future<void> updateArticle(String articleId, KnowledgeArticleModel article) async {
    final data = article is KnowledgeArticleExtended 
        ? article.copyWith(updatedAt: DateTime.now()).toJson()
        : {
            ...article.toJson(),
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          };
    
    await _database.child('knowledge_articles/$articleId').update(data);
  }

  /// Delete an article
  /// Requirements: 9.1
  @override
  Future<void> deleteArticle(String articleId) async {
    await _database.child('knowledge_articles/$articleId').remove();
    // Also remove view records
    await _database.child('article_views/$articleId').remove();
  }

  /// Get article by ID
  @override
  Future<KnowledgeArticleModel?> getArticle(String articleId) async {
    final snapshot = await _database.child('knowledge_articles/$articleId').get();
    if (!snapshot.exists) return null;
    
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return KnowledgeArticleExtended.fromJson(data);
  }

  /// Get all articles (with optional category filter)
  /// Requirements: 9.2
  @override
  Future<List<KnowledgeArticleModel>> getArticles({String? category}) async {
    final snapshot = await _database
        .child('knowledge_articles')
        .orderByChild('isPublished')
        .equalTo(true)
        .get();
    
    if (!snapshot.exists) return [];
    
    final articles = <KnowledgeArticleExtended>[];
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    
    for (final entry in data.entries) {
      final articleData = Map<String, dynamic>.from(entry.value as Map);
      articleData['id'] = entry.key;
      final article = KnowledgeArticleExtended.fromJson(articleData);
      
      if (category == null || category == 'Tất cả' || article.categories.contains(category)) {
        articles.add(article);
      }
    }
    
    // Sort by publishedAt descending
    articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return articles;
  }

  /// Get paginated articles
  /// Requirements: 10.3 - Implement pagination with 20 items per page
  @override
  Future<PaginatedResult<KnowledgeArticleModel>> getArticlesPaginated({
    String? category,
    String? lastKey,
    int pageSize = kDefaultPageSize,
  }) async {
    Query query = _database
        .child('knowledge_articles')
        .orderByChild('publishedAt');
    
    // If we have a lastKey, start after it
    if (lastKey != null) {
      final lastArticle = await _database.child('knowledge_articles/$lastKey').get();
      if (lastArticle.exists) {
        final lastData = Map<String, dynamic>.from(lastArticle.value as Map);
        final lastPublishedAt = lastData['publishedAt'] as int?;
        if (lastPublishedAt != null) {
          query = query.endBefore(lastPublishedAt);
        }
      }
    }
    
    // Fetch one extra to check if there are more
    query = query.limitToLast(pageSize + 1);
    
    final snapshot = await query.get();
    
    if (!snapshot.exists) {
      return const PaginatedResult(items: [], hasMore: false);
    }
    
    final articles = <KnowledgeArticleExtended>[];
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    
    for (final entry in data.entries) {
      final articleData = Map<String, dynamic>.from(entry.value as Map);
      articleData['id'] = entry.key;
      final article = KnowledgeArticleExtended.fromJson(articleData);
      
      // Only include published articles
      if (!article.isPublished) continue;
      
      // Filter by category if specified
      if (category == null || category == 'Tất cả' || article.categories.contains(category)) {
        articles.add(article);
      }
    }
    
    // Sort by publishedAt descending
    articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    
    // Check if there are more items
    final hasMore = articles.length > pageSize;
    
    // Remove the extra item if present
    if (hasMore && articles.isNotEmpty) {
      articles.removeLast();
    }
    
    // Get the last key for next page
    final newLastKey = articles.isNotEmpty ? articles.last.id : null;
    
    return PaginatedResult(
      items: articles,
      lastKey: newLastKey,
      hasMore: hasMore,
    );
  }

  /// Search articles with full-text search
  /// Requirements: 9.4
  @override
  Future<List<KnowledgeArticleModel>> searchArticles(String query) async {
    if (query.trim().isEmpty) return [];
    
    final normalizedQuery = query.toLowerCase().trim();
    final queryWords = normalizedQuery.split(RegExp(r'\s+'));
    
    final snapshot = await _database
        .child('knowledge_articles')
        .orderByChild('isPublished')
        .equalTo(true)
        .get();
    
    if (!snapshot.exists) return [];
    
    final articles = <KnowledgeArticleExtended>[];
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    
    for (final entry in data.entries) {
      final articleData = Map<String, dynamic>.from(entry.value as Map);
      articleData['id'] = entry.key;
      final article = KnowledgeArticleExtended.fromJson(articleData);
      
      // Search in title, description, content, and categories
      final searchableText = [
        article.title.toLowerCase(),
        article.description.toLowerCase(),
        (article.content ?? '').toLowerCase(),
        article.categories.join(' ').toLowerCase(),
      ].join(' ');
      
      // Check if all query words are found
      final matchesAll = queryWords.every((word) => searchableText.contains(word));
      if (matchesAll) {
        articles.add(article);
      }
    }
    
    // Sort by relevance (title matches first, then by date)
    articles.sort((a, b) {
      final aInTitle = a.title.toLowerCase().contains(normalizedQuery);
      final bInTitle = b.title.toLowerCase().contains(normalizedQuery);
      if (aInTitle && !bInTitle) return -1;
      if (!aInTitle && bInTitle) return 1;
      return b.publishedAt.compareTo(a.publishedAt);
    });
    
    return articles;
  }

  /// Track article view
  /// Requirements: 9.3
  @override
  Future<void> trackView(String articleId, String userId) async {
    final viewRef = _database.child('article_views/$articleId/$userId');
    final existingView = await viewRef.get();
    
    if (!existingView.exists) {
      // First view - create record and increment count
      await viewRef.set({
        'articleId': articleId,
        'userId': userId,
        'viewedAt': DateTime.now().millisecondsSinceEpoch,
        'readingTimeSeconds': 0,
      });
      
      // Increment view count on article
      await _database.child('knowledge_articles/$articleId/viewCount')
          .set(ServerValue.increment(1));
    } else {
      // Update last viewed time
      await viewRef.update({
        'viewedAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  /// Get view count for an article
  /// Requirements: 9.3
  @override
  Future<int> getViewCount(String articleId) async {
    final snapshot = await _database
        .child('knowledge_articles/$articleId/viewCount')
        .get();
    
    if (!snapshot.exists) return 0;
    return snapshot.value as int? ?? 0;
  }

  /// Track reading time
  /// Requirements: 9.3
  @override
  Future<void> trackReadingTime(String articleId, String userId, int seconds) async {
    final viewRef = _database.child('article_views/$articleId/$userId');
    
    await viewRef.update({
      'readingTimeSeconds': ServerValue.increment(seconds),
    });
    
    // Also update total reading time on article
    await _database.child('knowledge_articles/$articleId/totalReadingTimeSeconds')
        .set(ServerValue.increment(seconds));
  }

  /// Stream of articles for real-time updates
  /// Requirements: 9.2
  @override
  Stream<List<KnowledgeArticleModel>> articlesStream({String? category}) {
    return _database
        .child('knowledge_articles')
        .orderByChild('isPublished')
        .equalTo(true)
        .onValue
        .map((event) {
          if (!event.snapshot.exists) return <KnowledgeArticleExtended>[];
          
          final articles = <KnowledgeArticleExtended>[];
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          
          for (final entry in data.entries) {
            final articleData = Map<String, dynamic>.from(entry.value as Map);
            articleData['id'] = entry.key;
            final article = KnowledgeArticleExtended.fromJson(articleData);
            
            if (category == null || category == 'Tất cả' || article.categories.contains(category)) {
              articles.add(article);
            }
          }
          
          articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
          return articles;
        });
  }

  /// Publish an article (make it visible to users)
  /// Requirements: 9.2
  @override
  Future<void> publishArticle(String articleId) async {
    await _database.child('knowledge_articles/$articleId').update({
      'isPublished': true,
      'publishedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Unpublish an article
  @override
  Future<void> unpublishArticle(String articleId) async {
    await _database.child('knowledge_articles/$articleId').update({
      'isPublished': false,
    });
  }

  /// Get all articles for admin (including unpublished)
  Future<List<KnowledgeArticleExtended>> getAllArticlesForAdmin() async {
    final snapshot = await _database.child('knowledge_articles').get();
    
    if (!snapshot.exists) return [];
    
    final articles = <KnowledgeArticleExtended>[];
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    
    for (final entry in data.entries) {
      final articleData = Map<String, dynamic>.from(entry.value as Map);
      articleData['id'] = entry.key;
      articles.add(KnowledgeArticleExtended.fromJson(articleData));
    }
    
    articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return articles;
  }

  /// Stream of all articles for admin
  Stream<List<KnowledgeArticleExtended>> allArticlesStreamForAdmin() {
    return _database.child('knowledge_articles').onValue.map((event) {
      if (!event.snapshot.exists) return <KnowledgeArticleExtended>[];
      
      final articles = <KnowledgeArticleExtended>[];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      
      for (final entry in data.entries) {
        final articleData = Map<String, dynamic>.from(entry.value as Map);
        articleData['id'] = entry.key;
        articles.add(KnowledgeArticleExtended.fromJson(articleData));
      }
      
      articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      return articles;
    });
  }

  /// Get article statistics
  Future<Map<String, dynamic>> getArticleStats() async {
    final snapshot = await _database.child('knowledge_articles').get();
    
    if (!snapshot.exists) {
      return {
        'totalArticles': 0,
        'publishedArticles': 0,
        'totalVideos': 0,
        'totalViews': 0,
      };
    }
    
    int totalArticles = 0;
    int publishedArticles = 0;
    int totalVideos = 0;
    int totalViews = 0;
    
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    for (final entry in data.entries) {
      final articleData = Map<String, dynamic>.from(entry.value as Map);
      totalArticles++;
      
      if (articleData['isPublished'] == true) publishedArticles++;
      if (articleData['type'] == 'video') totalVideos++;
      totalViews += (articleData['viewCount'] as int?) ?? 0;
    }
    
    return {
      'totalArticles': totalArticles,
      'publishedArticles': publishedArticles,
      'totalVideos': totalVideos,
      'totalViews': totalViews,
    };
  }
}
