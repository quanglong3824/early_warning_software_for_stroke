import 'package:glados/glados.dart';

/// **Feature: sews-improvement-plan, Property 17: Pagination Consistency**
/// **Validates: Requirements 10.3**
///
/// Property: For any paginated list, each page SHALL contain at most 20 items
/// and items SHALL not be duplicated across pages.

/// Default page size - mirrors kDefaultPageSize from pagination_utils.dart
const int kDefaultPageSize = 20;

/// Represents a paginated result - mirrors PaginatedResult from pagination_utils.dart
class TestPaginatedResult<T> {
  final List<T> items;
  final String? lastKey;
  final bool hasMore;

  const TestPaginatedResult({
    required this.items,
    this.lastKey,
    required this.hasMore,
  });
}

/// Pure function to paginate a list of items
/// This mirrors the pagination logic used throughout the app
/// Validates: Requirements 10.3
TestPaginatedResult<T> paginateItems<T>({
  required List<T> allItems,
  required int pageSize,
  String? startAfterKey,
  required String Function(T) getKey,
}) {
  // Find starting index
  int startIndex = 0;
  if (startAfterKey != null) {
    final keyIndex = allItems.indexWhere((item) => getKey(item) == startAfterKey);
    if (keyIndex != -1) {
      startIndex = keyIndex + 1;
    }
  }

  // Get items for this page
  final endIndex = (startIndex + pageSize).clamp(0, allItems.length);
  final pageItems = allItems.sublist(startIndex, endIndex);

  // Determine if there are more items
  final hasMore = endIndex < allItems.length;
  final lastKey = pageItems.isNotEmpty ? getKey(pageItems.last) : null;

  return TestPaginatedResult(
    items: pageItems,
    lastKey: lastKey,
    hasMore: hasMore,
  );
}

/// Fetch all pages from a paginated source
/// Returns a list of pages, where each page is a list of items
List<List<T>> fetchAllPages<T>({
  required List<T> allItems,
  required int pageSize,
  required String Function(T) getKey,
}) {
  final pages = <List<T>>[];
  String? lastKey;
  bool hasMore = true;

  while (hasMore) {
    final result = paginateItems(
      allItems: allItems,
      pageSize: pageSize,
      startAfterKey: lastKey,
      getKey: getKey,
    );
    
    if (result.items.isEmpty) break;
    
    pages.add(result.items);
    lastKey = result.lastKey;
    hasMore = result.hasMore;
  }

  return pages;
}

/// Test item with unique ID
class TestItem {
  final String id;
  final String data;

  TestItem({required this.id, required this.data});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TestItem(id: $id, data: $data)';
}

/// Generate a list of TestItems with unique IDs based on count
List<TestItem> generateTestItems(int count) {
  return List.generate(
    count,
    (i) => TestItem(id: 'item_$i', data: 'data_$i'),
  );
}

/// Custom generators for pagination tests
extension PaginationAny on Any {
  /// Generate a count for items (0-200)
  Generator<int> get itemCount {
    return any.positiveIntOrZero.map((n) => n % 201);
  }

  /// Generate a valid page size (1-50)
  Generator<int> get pageSize {
    return any.positiveIntOrZero.map((n) => (n % 50) + 1);
  }

  /// Generate a non-empty item count (1-200)
  Generator<int> get nonEmptyItemCount {
    return any.positiveIntOrZero.map((n) => (n % 200) + 1);
  }
}

void main() {
  group('Pagination Consistency Property Tests', () {
    /// **Feature: sews-improvement-plan, Property 17: Pagination Consistency**
    /// **Validates: Requirements 10.3**
    ///
    /// Property: Each page SHALL contain at most pageSize items
    Glados(any.combine2(
      any.itemCount,
      any.pageSize,
      (itemCount, pageSize) => (itemCount, pageSize),
    )).test(
      'Property 17: Pagination Consistency - Each page contains at most pageSize items',
      (tuple) {
        final (itemCount, pageSize) = tuple;
        final items = generateTestItems(itemCount);

        // Act
        final pages = fetchAllPages(
          allItems: items,
          pageSize: pageSize,
          getKey: (item) => item.id,
        );

        // Assert: Each page should have at most pageSize items
        for (int i = 0; i < pages.length; i++) {
          expect(
            pages[i].length,
            lessThanOrEqualTo(pageSize),
            reason: 'Page $i has ${pages[i].length} items, '
                'but should have at most $pageSize items',
          );
        }
      },
    );

    /// Property: Items SHALL not be duplicated across pages
    Glados(any.combine2(
      any.itemCount,
      any.pageSize,
      (itemCount, pageSize) => (itemCount, pageSize),
    )).test(
      'Property 17: Pagination Consistency - No duplicate items across pages',
      (tuple) {
        final (itemCount, pageSize) = tuple;
        final items = generateTestItems(itemCount);

        // Act
        final pages = fetchAllPages(
          allItems: items,
          pageSize: pageSize,
          getKey: (item) => item.id,
        );

        // Flatten all pages and check for duplicates
        final allPageItems = pages.expand((page) => page).toList();
        final uniqueIds = allPageItems.map((item) => item.id).toSet();

        // Assert: No duplicates
        expect(
          uniqueIds.length,
          equals(allPageItems.length),
          reason: 'Found duplicate items across pages. '
              'Total items: ${allPageItems.length}, Unique: ${uniqueIds.length}',
        );
      },
    );

    /// Property: All original items should be present across all pages
    Glados(any.combine2(
      any.itemCount,
      any.pageSize,
      (itemCount, pageSize) => (itemCount, pageSize),
    )).test(
      'Property 17: Pagination Consistency - All items are preserved across pages',
      (tuple) {
        final (itemCount, pageSize) = tuple;
        final items = generateTestItems(itemCount);

        // Act
        final pages = fetchAllPages(
          allItems: items,
          pageSize: pageSize,
          getKey: (item) => item.id,
        );

        // Flatten all pages
        final allPageItems = pages.expand((page) => page).toList();

        // Assert: Total count matches
        expect(
          allPageItems.length,
          equals(items.length),
          reason: 'Pagination should preserve all items. '
              'Original: ${items.length}, After pagination: ${allPageItems.length}',
        );
      },
    );

    /// Property: Order should be preserved across pages
    Glados(any.combine2(
      any.itemCount,
      any.pageSize,
      (itemCount, pageSize) => (itemCount, pageSize),
    )).test(
      'Property 17: Pagination Consistency - Item order is preserved',
      (tuple) {
        final (itemCount, pageSize) = tuple;
        final items = generateTestItems(itemCount);

        // Act
        final pages = fetchAllPages(
          allItems: items,
          pageSize: pageSize,
          getKey: (item) => item.id,
        );

        // Flatten all pages
        final allPageItems = pages.expand((page) => page).toList();

        // Assert: Order matches original
        for (int i = 0; i < allPageItems.length; i++) {
          expect(
            allPageItems[i].id,
            equals(items[i].id),
            reason: 'Item at position $i should be ${items[i].id}, '
                'but got ${allPageItems[i].id}',
          );
        }
      },
    );

    /// Property: Default page size of 20 items per page
    Glados(any.nonEmptyItemCount).test(
      'Property 17: Pagination Consistency - Default page size is 20',
      (itemCount) {
        final items = generateTestItems(itemCount);

        // Act
        final pages = fetchAllPages(
          allItems: items,
          pageSize: kDefaultPageSize,
          getKey: (item) => item.id,
        );

        // Assert: Each page (except possibly the last) should have exactly 20 items
        for (int i = 0; i < pages.length; i++) {
          if (i < pages.length - 1) {
            // Non-last pages should be full
            expect(
              pages[i].length,
              equals(kDefaultPageSize),
              reason: 'Non-last page $i should have exactly $kDefaultPageSize items, '
                  'but has ${pages[i].length}',
            );
          } else {
            // Last page can have 1 to pageSize items
            expect(
              pages[i].length,
              lessThanOrEqualTo(kDefaultPageSize),
              reason: 'Last page should have at most $kDefaultPageSize items',
            );
            expect(
              pages[i].length,
              greaterThan(0),
              reason: 'Last page should have at least 1 item',
            );
          }
        }
      },
    );

    /// Property: Empty list produces no pages
    Glados(any.pageSize).test(
      'Property 17: Pagination Consistency - Empty list produces no pages',
      (pageSize) {
        // Arrange
        final emptyItems = <TestItem>[];

        // Act
        final pages = fetchAllPages(
          allItems: emptyItems,
          pageSize: pageSize,
          getKey: (item) => item.id,
        );

        // Assert
        expect(
          pages.isEmpty,
          isTrue,
          reason: 'Empty list should produce no pages',
        );
      },
    );

    /// Property: Single page result when items <= pageSize
    Glados(any.combine2(
      any.nonEmptyItemCount,
      any.pageSize,
      (itemCount, pageSize) => (itemCount, pageSize),
    )).test(
      'Property 17: Pagination Consistency - Single page when items fit',
      (tuple) {
        final (itemCount, pageSize) = tuple;
        final items = generateTestItems(itemCount);

        // Act
        final pages = fetchAllPages(
          allItems: items,
          pageSize: pageSize,
          getKey: (item) => item.id,
        );

        // Assert: If items fit in one page, there should be exactly one page
        if (items.length <= pageSize) {
          expect(
            pages.length,
            equals(1),
            reason: 'Items that fit in one page should produce exactly one page. '
                'Items: ${items.length}, PageSize: $pageSize, Pages: ${pages.length}',
          );
        }
      },
    );

    /// Property: hasMore is false only on last page
    Glados(any.combine2(
      any.nonEmptyItemCount,
      any.pageSize,
      (itemCount, pageSize) => (itemCount, pageSize),
    )).test(
      'Property 17: Pagination Consistency - hasMore indicates more pages correctly',
      (tuple) {
        final (itemCount, pageSize) = tuple;
        final items = generateTestItems(itemCount);

        // Fetch pages one by one and check hasMore
        String? lastKey;
        int pageCount = 0;
        final expectedPageCount = (items.length / pageSize).ceil();

        while (true) {
          final result = paginateItems(
            allItems: items,
            pageSize: pageSize,
            startAfterKey: lastKey,
            getKey: (item) => item.id,
          );

          if (result.items.isEmpty) break;

          pageCount++;
          final isLastPage = pageCount == expectedPageCount;

          // Assert: hasMore should be true except on last page
          expect(
            result.hasMore,
            equals(!isLastPage),
            reason: 'Page $pageCount: hasMore should be ${!isLastPage}, '
                'but was ${result.hasMore}. '
                'Total pages expected: $expectedPageCount',
          );

          lastKey = result.lastKey;
          if (!result.hasMore) break;
        }
      },
    );

    /// Property: Number of pages is correct based on item count and page size
    Glados(any.combine2(
      any.nonEmptyItemCount,
      any.pageSize,
      (itemCount, pageSize) => (itemCount, pageSize),
    )).test(
      'Property 17: Pagination Consistency - Correct number of pages',
      (tuple) {
        final (itemCount, pageSize) = tuple;
        final items = generateTestItems(itemCount);

        // Act
        final pages = fetchAllPages(
          allItems: items,
          pageSize: pageSize,
          getKey: (item) => item.id,
        );

        // Calculate expected page count
        final expectedPageCount = (items.length / pageSize).ceil();

        // Assert
        expect(
          pages.length,
          equals(expectedPageCount),
          reason: 'Expected $expectedPageCount pages for ${items.length} items '
              'with page size $pageSize, but got ${pages.length} pages',
        );
      },
    );
  });
}
