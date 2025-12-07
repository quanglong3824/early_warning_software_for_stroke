import 'package:glados/glados.dart';

/// **Feature: sews-improvement-plan, Property 15: Article Visibility**
/// **Validates: Requirements 9.2**
///
/// Property: For any published article, the article SHALL be visible to all
/// users immediately after publication.

/// Test article model - mirrors KnowledgeArticleExtended from knowledge_service.dart
/// This is a pure data class that doesn't require Firebase
class TestArticle {
  final String id;
  final String title;
  final String description;
  final String content;
  final List<String> categories;
  final bool isPublished;
  final DateTime publishedAt;

  TestArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.categories,
    required this.isPublished,
    required this.publishedAt,
  });

  /// Create a published copy of this article
  TestArticle publish() {
    return TestArticle(
      id: id,
      title: title,
      description: description,
      content: content,
      categories: categories,
      isPublished: true,
      publishedAt: DateTime.now(),
    );
  }

  /// Create an unpublished copy of this article
  TestArticle unpublish() {
    return TestArticle(
      id: id,
      title: title,
      description: description,
      content: content,
      categories: categories,
      isPublished: false,
      publishedAt: publishedAt,
    );
  }

  @override
  String toString() =>
      'TestArticle(id: $id, title: $title, isPublished: $isPublished)';
}

/// Pure function for getting visible articles (published only)
/// Mirrors the getArticles logic from KnowledgeService
/// Validates: Requirements 9.2
List<TestArticle> getVisibleArticles(List<TestArticle> allArticles) {
  return allArticles.where((article) => article.isPublished).toList();
}

/// Pure function for publishing an article
/// Mirrors the publishArticle logic from KnowledgeService
/// Validates: Requirements 9.2
List<TestArticle> publishArticle(List<TestArticle> allArticles, String articleId) {
  return allArticles.map((article) {
    if (article.id == articleId) {
      return article.publish();
    }
    return article;
  }).toList();
}

/// Pure function for unpublishing an article
/// Mirrors the unpublishArticle logic from KnowledgeService
List<TestArticle> unpublishArticle(List<TestArticle> allArticles, String articleId) {
  return allArticles.map((article) {
    if (article.id == articleId) {
      return article.unpublish();
    }
    return article;
  }).toList();
}

/// Custom generator for article visibility tests
extension ArticleVisibilityAny on Any {
  /// Generate a TestArticle with random published state
  Generator<TestArticle> get testArticle {
    return any.combine5(
      any.positiveInt,
      any.lowercaseLetters,
      any.lowercaseLetters,
      any.bool,
      any.dateTime,
      (int id, String title, String desc, bool isPublished, DateTime publishedAt) {
        return TestArticle(
          id: 'article_$id',
          title: 'Title $title',
          description: 'Description $desc',
          content: 'Content for $title',
          categories: ['Health'],
          isPublished: isPublished,
          publishedAt: publishedAt,
        );
      },
    );
  }

  /// Generate a list of TestArticles with unique IDs
  Generator<List<TestArticle>> get testArticleList {
    return any.list(any.testArticle).map((articles) {
      // Ensure unique IDs by adding index suffix
      return articles.asMap().entries.map((entry) {
        final article = entry.value;
        return TestArticle(
          id: '${article.id}_${entry.key}',
          title: article.title,
          description: article.description,
          content: article.content,
          categories: article.categories,
          isPublished: article.isPublished,
          publishedAt: article.publishedAt,
        );
      }).toList();
    });
  }

  /// Generate a TestArticle that is always unpublished (for publish testing)
  Generator<TestArticle> get unpublishedArticle {
    return any.combine3(
      any.positiveInt,
      any.lowercaseLetters,
      any.dateTime,
      (int id, String title, DateTime publishedAt) {
        return TestArticle(
          id: 'article_$id',
          title: 'Title $title',
          description: 'Description for $title',
          content: 'Content for $title',
          categories: ['Health'],
          isPublished: false,
          publishedAt: publishedAt,
        );
      },
    );
  }
}

void main() {
  group('Article Visibility Property Tests', () {
    /// **Feature: sews-improvement-plan, Property 15: Article Visibility**
    /// **Validates: Requirements 9.2**
    ///
    /// Property: For any published article, the article SHALL be visible to
    /// all users immediately after publication.
    Glados(any.testArticleList).test(
      'Property 15: Article Visibility - Published articles are visible',
      (articles) {
        // Act
        final visibleArticles = getVisibleArticles(articles);

        // Assert: All visible articles must be published
        for (final article in visibleArticles) {
          expect(
            article.isPublished,
            isTrue,
            reason: 'Visible article "${article.title}" should be published',
          );
        }
      },
    );

    /// Property: Unpublished articles are NOT visible
    Glados(any.testArticleList).test(
      'Property 15: Article Visibility - Unpublished articles are not visible',
      (articles) {
        // Act
        final visibleArticles = getVisibleArticles(articles);

        // Get unpublished articles
        final unpublishedArticles =
            articles.where((a) => !a.isPublished).toList();

        // Assert: None of the unpublished articles should be visible
        for (final unpublished in unpublishedArticles) {
          final isVisible =
              visibleArticles.any((v) => v.id == unpublished.id);
          expect(
            isVisible,
            isFalse,
            reason: 'Unpublished article "${unpublished.title}" should not be visible',
          );
        }
      },
    );

    /// Property: Publishing an article makes it immediately visible
    Glados(any.unpublishedArticle).test(
      'Property 15: Article Visibility - Publishing makes article immediately visible',
      (article) {
        // Arrange: Start with a list containing the unpublished article
        final articles = [article];

        // Verify article is not visible before publishing
        final visibleBefore = getVisibleArticles(articles);
        expect(
          visibleBefore.any((a) => a.id == article.id),
          isFalse,
          reason: 'Article should not be visible before publishing',
        );

        // Act: Publish the article
        final articlesAfterPublish = publishArticle(articles, article.id);
        final visibleAfter = getVisibleArticles(articlesAfterPublish);

        // Assert: Article should now be visible
        expect(
          visibleAfter.any((a) => a.id == article.id),
          isTrue,
          reason: 'Article should be visible immediately after publishing',
        );
      },
    );

    /// Property: All published articles are included in visible list
    Glados(any.testArticleList).test(
      'Property 15: Article Visibility - All published articles are included',
      (articles) {
        // Act
        final visibleArticles = getVisibleArticles(articles);

        // Get all published articles from original list
        final publishedArticles = articles.where((a) => a.isPublished).toList();

        // Assert: Count should match
        expect(
          visibleArticles.length,
          equals(publishedArticles.length),
          reason: 'Visible articles count should equal published articles count. '
              'Expected ${publishedArticles.length}, got ${visibleArticles.length}',
        );

        // Assert: All published articles should be in visible list
        for (final published in publishedArticles) {
          final isVisible = visibleArticles.any((v) => v.id == published.id);
          expect(
            isVisible,
            isTrue,
            reason: 'Published article "${published.title}" should be visible',
          );
        }
      },
    );

    /// Property: Unpublishing an article removes it from visible list
    Glados(any.testArticle).test(
      'Property 15: Article Visibility - Unpublishing removes article from visible list',
      (article) {
        // Arrange: Ensure article is published first
        final publishedArticle = article.publish();
        final articles = [publishedArticle];

        // Verify article is visible when published
        final visibleBefore = getVisibleArticles(articles);
        expect(
          visibleBefore.any((a) => a.id == publishedArticle.id),
          isTrue,
          reason: 'Published article should be visible',
        );

        // Act: Unpublish the article
        final articlesAfterUnpublish = unpublishArticle(articles, publishedArticle.id);
        final visibleAfter = getVisibleArticles(articlesAfterUnpublish);

        // Assert: Article should no longer be visible
        expect(
          visibleAfter.any((a) => a.id == publishedArticle.id),
          isFalse,
          reason: 'Article should not be visible after unpublishing',
        );
      },
    );

    /// Property: Visibility filtering is idempotent
    Glados(any.testArticleList).test(
      'Property 15: Article Visibility - Filtering is idempotent',
      (articles) {
        // Act
        final filteredOnce = getVisibleArticles(articles);
        final filteredTwice = getVisibleArticles(filteredOnce);

        // Assert
        expect(
          filteredTwice.length,
          equals(filteredOnce.length),
          reason: 'Filtering twice should give the same result as filtering once',
        );
      },
    );

    /// Property: Empty article list returns empty visible list
    Glados(any.int).test(
      'Property 15: Article Visibility - Empty list returns empty result',
      (_) {
        // Arrange
        final emptyArticles = <TestArticle>[];

        // Act
        final visibleArticles = getVisibleArticles(emptyArticles);

        // Assert
        expect(
          visibleArticles.isEmpty,
          isTrue,
          reason: 'Empty article list should return empty visible list',
        );
      },
    );
  });
}
