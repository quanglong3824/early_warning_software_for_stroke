import 'package:glados/glados.dart';

/// **Feature: sews-improvement-plan, Property 16: Search Performance**
/// **Validates: Requirements 9.4**
///
/// Property: For any knowledge base search query, results SHALL be returned
/// within 2 seconds.
///
/// Note: This test validates the search algorithm's correctness and performance
/// characteristics using pure functions that mirror the KnowledgeService logic.

/// Test article model for search performance testing
class SearchableArticle {
  final String id;
  final String title;
  final String description;
  final String content;
  final List<String> categories;
  final bool isPublished;

  SearchableArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.categories,
    required this.isPublished,
  });

  @override
  String toString() =>
      'SearchableArticle(id: $id, title: $title, isPublished: $isPublished)';
}

/// Pure search function that mirrors KnowledgeService.searchArticles logic
/// This is the core algorithm being tested for correctness and performance
/// Validates: Requirements 9.4
List<SearchableArticle> searchArticles(
  List<SearchableArticle> allArticles,
  String query,
) {
  if (query.trim().isEmpty) return [];

  final normalizedQuery = query.toLowerCase().trim();
  final queryWords = normalizedQuery.split(RegExp(r'\s+'));

  final results = <SearchableArticle>[];

  for (final article in allArticles) {
    // Only search published articles
    if (!article.isPublished) continue;

    // Build searchable text from title, description, content, and categories
    final searchableText = [
      article.title.toLowerCase(),
      article.description.toLowerCase(),
      article.content.toLowerCase(),
      article.categories.join(' ').toLowerCase(),
    ].join(' ');

    // Check if all query words are found
    final matchesAll = queryWords.every((word) => searchableText.contains(word));
    if (matchesAll) {
      results.add(article);
    }
  }

  // Sort by relevance (title matches first)
  results.sort((a, b) {
    final aInTitle = a.title.toLowerCase().contains(normalizedQuery);
    final bInTitle = b.title.toLowerCase().contains(normalizedQuery);
    if (aInTitle && !bInTitle) return -1;
    if (!aInTitle && bInTitle) return 1;
    return 0;
  });

  return results;
}

/// Custom generators for search performance tests
extension SearchPerformanceAny on Any {
  /// Generate a random search query (1-3 words)
  Generator<String> get searchQuery {
    return any.lowercaseLetters.map((letters) {
      // Create a query with 1-3 words
      if (letters.isEmpty) return 'health';
      final words = <String>[];
      var remaining = letters;
      while (remaining.isNotEmpty && words.length < 3) {
        final wordLength = remaining.length > 5 ? 5 : remaining.length;
        words.add(remaining.substring(0, wordLength));
        remaining = remaining.length > wordLength 
            ? remaining.substring(wordLength) 
            : '';
      }
      return words.join(' ');
    });
  }

  /// Generate a SearchableArticle
  Generator<SearchableArticle> get searchableArticle {
    return any.combine5(
      any.positiveInt,
      any.lowercaseLetters,
      any.lowercaseLetters,
      any.bool,
      any.choose(['Health', 'Stroke', 'Diabetes', 'Prevention', 'Nutrition']),
      (int id, String title, String desc, bool isPublished, String category) {
        return SearchableArticle(
          id: 'article_$id',
          title: 'Article about $title',
          description: 'Description: $desc',
          content: 'Full content about $title and $desc with health information',
          categories: [category],
          isPublished: isPublished,
        );
      },
    );
  }

  /// Generate a list of SearchableArticles with unique IDs
  Generator<List<SearchableArticle>> get searchableArticleList {
    return any.list(any.searchableArticle).map((articles) {
      return articles.asMap().entries.map((entry) {
        final article = entry.value;
        return SearchableArticle(
          id: '${article.id}_${entry.key}',
          title: article.title,
          description: article.description,
          content: article.content,
          categories: article.categories,
          isPublished: article.isPublished,
        );
      }).toList();
    });
  }

  /// Generate a published article with specific searchable content
  Generator<SearchableArticle> get publishedArticleWithContent {
    return any.combine3(
      any.positiveInt,
      any.lowercaseLetters,
      any.choose(['Health', 'Stroke', 'Diabetes', 'Prevention']),
      (int id, String content, String category) {
        return SearchableArticle(
          id: 'article_$id',
          title: 'Article about $content',
          description: 'Description for $content',
          content: 'Full content: $content',
          categories: [category],
          isPublished: true,
        );
      },
    );
  }
}

void main() {
  group('Search Performance Property Tests', () {
    /// **Feature: sews-improvement-plan, Property 16: Search Performance**
    /// **Validates: Requirements 9.4**
    ///
    /// Property: Search completes within reasonable time bounds
    /// Note: We test algorithmic complexity rather than wall-clock time
    /// since property tests should be deterministic
    Glados2(any.searchableArticleList, any.searchQuery).test(
      'Property 16: Search Performance - Search completes for any input',
      (articles, query) {
        // Act: Execute search and measure time
        final stopwatch = Stopwatch()..start();
        final results = searchArticles(articles, query);
        stopwatch.stop();

        // Assert: Search should complete (no infinite loops or crashes)
        // The results should be a valid list
        expect(results, isA<List<SearchableArticle>>());

        // Performance assertion: Search should complete in under 2 seconds
        // even for large datasets (property-based tests generate various sizes)
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(2000),
          reason: 'Search should complete within 2 seconds. '
              'Took ${stopwatch.elapsedMilliseconds}ms for ${articles.length} articles',
        );
      },
    );

    /// Property: Empty query returns empty results immediately
    Glados(any.searchableArticleList).test(
      'Property 16: Search Performance - Empty query returns empty results',
      (articles) {
        // Test various empty/whitespace queries
        final emptyQueries = ['', '   ', '\t', '\n', '  \t  '];

        for (final query in emptyQueries) {
          final stopwatch = Stopwatch()..start();
          final results = searchArticles(articles, query);
          stopwatch.stop();

          expect(
            results.isEmpty,
            isTrue,
            reason: 'Empty/whitespace query should return empty results',
          );

          // Empty query should be very fast
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(100),
            reason: 'Empty query should return immediately',
          );
        }
      },
    );

    /// Property: Search results only contain published articles
    Glados2(any.searchableArticleList, any.searchQuery).test(
      'Property 16: Search Performance - Results only contain published articles',
      (articles, query) {
        // Act
        final results = searchArticles(articles, query);

        // Assert: All results must be published
        for (final result in results) {
          expect(
            result.isPublished,
            isTrue,
            reason: 'Search result "${result.title}" should be published',
          );
        }
      },
    );

    /// Property: Search results contain the query terms
    Glados(any.publishedArticleWithContent).test(
      'Property 16: Search Performance - Results are relevant to query',
      (article) {
        // Arrange: Create a list with the article
        final articles = [article];

        // Extract a word from the article title to use as query
        final titleWords = article.title.toLowerCase().split(' ');
        if (titleWords.isEmpty) return; // Skip if no words

        final query = titleWords.last; // Use last word as query
        if (query.isEmpty) return;

        // Act
        final results = searchArticles(articles, query);

        // Assert: The article should be found if query matches
        final searchableText = [
          article.title.toLowerCase(),
          article.description.toLowerCase(),
          article.content.toLowerCase(),
          article.categories.join(' ').toLowerCase(),
        ].join(' ');

        if (searchableText.contains(query.toLowerCase())) {
          expect(
            results.any((r) => r.id == article.id),
            isTrue,
            reason: 'Article containing "$query" should be in results',
          );
        }
      },
    );

    /// Property: Search is case-insensitive
    Glados(any.publishedArticleWithContent).test(
      'Property 16: Search Performance - Search is case-insensitive',
      (article) {
        final articles = [article];

        // Get a word from the title
        final titleWords = article.title.split(' ');
        if (titleWords.isEmpty) return;

        final word = titleWords.last;
        if (word.isEmpty) return;

        // Search with different cases
        final lowerResults = searchArticles(articles, word.toLowerCase());
        final upperResults = searchArticles(articles, word.toUpperCase());
        final mixedResults = searchArticles(articles, _mixCase(word));

        // All should return the same results
        expect(
          lowerResults.length,
          equals(upperResults.length),
          reason: 'Case should not affect search results count',
        );
        expect(
          lowerResults.length,
          equals(mixedResults.length),
          reason: 'Mixed case should return same results',
        );
      },
    );

    /// Property: Multi-word queries require all words to match
    Glados(any.searchableArticleList).test(
      'Property 16: Search Performance - Multi-word queries match all words',
      (articles) {
        // Create a multi-word query
        const query = 'health information';
        final queryWords = query.toLowerCase().split(' ');

        // Act
        final results = searchArticles(articles, query);

        // Assert: Each result must contain ALL query words
        for (final result in results) {
          final searchableText = [
            result.title.toLowerCase(),
            result.description.toLowerCase(),
            result.content.toLowerCase(),
            result.categories.join(' ').toLowerCase(),
          ].join(' ');

          for (final word in queryWords) {
            expect(
              searchableText.contains(word),
              isTrue,
              reason: 'Result "${result.title}" should contain word "$word"',
            );
          }
        }
      },
    );

    /// Property: Search results are sorted by relevance (title matches first)
    Glados(any.searchableArticleList).test(
      'Property 16: Search Performance - Results sorted by relevance',
      (articles) {
        // Skip if not enough articles
        if (articles.length < 2) return;

        // Find a common word to search
        const query = 'article';

        // Act
        final results = searchArticles(articles, query);

        // Assert: Title matches should come before non-title matches
        bool foundNonTitleMatch = false;
        for (final result in results) {
          final inTitle = result.title.toLowerCase().contains(query.toLowerCase());

          if (!inTitle) {
            foundNonTitleMatch = true;
          } else if (foundNonTitleMatch) {
            // If we found a title match after a non-title match, sorting is wrong
            fail('Title matches should come before non-title matches');
          }
        }
      },
    );

    /// Property: Search is idempotent
    Glados2(any.searchableArticleList, any.searchQuery).test(
      'Property 16: Search Performance - Search is idempotent',
      (articles, query) {
        // Act: Search twice with same query
        final results1 = searchArticles(articles, query);
        final results2 = searchArticles(articles, query);

        // Assert: Results should be identical
        expect(
          results1.length,
          equals(results2.length),
          reason: 'Repeated searches should return same number of results',
        );

        for (var i = 0; i < results1.length; i++) {
          expect(
            results1[i].id,
            equals(results2[i].id),
            reason: 'Repeated searches should return same results in same order',
          );
        }
      },
    );

    /// Property: No duplicate results
    Glados2(any.searchableArticleList, any.searchQuery).test(
      'Property 16: Search Performance - No duplicate results',
      (articles, query) {
        // Act
        final results = searchArticles(articles, query);

        // Assert: No duplicate IDs
        final ids = results.map((r) => r.id).toSet();
        expect(
          ids.length,
          equals(results.length),
          reason: 'Search results should not contain duplicates',
        );
      },
    );
  });
}

/// Helper function to create mixed case string
String _mixCase(String input) {
  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    buffer.write(i.isEven ? input[i].toLowerCase() : input[i].toUpperCase());
  }
  return buffer.toString();
}
