import 'package:flutter/material.dart';

/// Pagination utilities for list screens
/// Requirements: 10.3 - Implement pagination with 20 items per page

/// Default page size for pagination
const int kDefaultPageSize = 20;

/// Pagination state for managing paginated data
class PaginationState<T> {
  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final String? lastKey;
  final String? error;

  const PaginationState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastKey,
    this.error,
  });

  PaginationState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? hasMore,
    String? lastKey,
    String? error,
  }) {
    return PaginationState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastKey: lastKey ?? this.lastKey,
      error: error,
    );
  }

  /// Initial state
  factory PaginationState.initial() => const PaginationState();

  /// Loading state
  PaginationState<T> loading() => copyWith(isLoading: true, error: null);

  /// Success state with new items
  PaginationState<T> success(List<T> newItems, {String? newLastKey, bool? hasMoreItems}) {
    return copyWith(
      items: [...items, ...newItems],
      isLoading: false,
      hasMore: hasMoreItems ?? newItems.length >= kDefaultPageSize,
      lastKey: newLastKey,
      error: null,
    );
  }

  /// Error state
  PaginationState<T> failure(String errorMessage) {
    return copyWith(
      isLoading: false,
      error: errorMessage,
    );
  }

  /// Reset state
  PaginationState<T> reset() => PaginationState<T>.initial();
}

/// Paginated result from Firebase queries
class PaginatedResult<T> {
  final List<T> items;
  final String? lastKey;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    this.lastKey,
    required this.hasMore,
  });
}

/// Extension for ScrollController to detect when user reaches bottom
extension ScrollControllerExtension on ScrollController {
  /// Check if scroll position is near the bottom
  bool get isNearBottom {
    if (!hasClients) return false;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;
    // Trigger when 80% scrolled
    return currentScroll >= maxScroll * 0.8;
  }

  /// Check if at the very bottom
  bool get isAtBottom {
    if (!hasClients) return false;
    return position.pixels >= position.maxScrollExtent;
  }
}
