import 'package:flutter/material.dart';
import '../utils/pagination_utils.dart';

/// A reusable paginated list view widget with infinite scroll
/// Requirements: 10.3 - Implement pagination with 20 items per page
class PaginatedListView<T> extends StatefulWidget {
  /// The pagination state containing items and loading status
  final PaginationState<T> state;

  /// Callback to load more items
  final VoidCallback onLoadMore;

  /// Builder for each item
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Optional separator builder
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Widget to show when list is empty
  final Widget? emptyWidget;

  /// Widget to show at the bottom when loading more
  final Widget? loadingWidget;

  /// Widget to show when there's an error
  final Widget Function(String error)? errorWidget;

  /// Padding for the list
  final EdgeInsetsGeometry? padding;

  /// Physics for the scroll view
  final ScrollPhysics? physics;

  /// Whether to shrink wrap the list
  final bool shrinkWrap;

  const PaginatedListView({
    super.key,
    required this.state,
    required this.onLoadMore,
    required this.itemBuilder,
    this.separatorBuilder,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.isNearBottom &&
        !widget.state.isLoading &&
        widget.state.hasMore) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    // Show error if present
    if (state.error != null && state.items.isEmpty) {
      return widget.errorWidget?.call(state.error!) ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  state.error!,
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: widget.onLoadMore,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
    }

    // Show empty state
    if (state.items.isEmpty && !state.isLoading) {
      return widget.emptyWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Không có dữ liệu',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
    }

    // Show initial loading
    if (state.items.isEmpty && state.isLoading) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    // Build the list
    final itemCount = state.items.length + (state.hasMore ? 1 : 0);

    if (widget.separatorBuilder != null) {
      return ListView.separated(
        controller: _scrollController,
        padding: widget.padding,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        itemCount: itemCount,
        separatorBuilder: widget.separatorBuilder!,
        itemBuilder: (context, index) => _buildItem(context, index),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      itemCount: itemCount,
      itemBuilder: (context, index) => _buildItem(context, index),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    // Show loading indicator at the bottom
    if (index >= widget.state.items.length) {
      return _buildLoadingIndicator();
    }

    return widget.itemBuilder(context, widget.state.items[index], index);
  }

  Widget _buildLoadingIndicator() {
    if (!widget.state.isLoading) {
      return const SizedBox.shrink();
    }

    return widget.loadingWidget ??
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
  }
}

/// A simpler infinite scroll wrapper for existing list views
class InfiniteScrollWrapper extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final ScrollController? scrollController;

  const InfiniteScrollWrapper({
    super.key,
    required this.child,
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
    this.scrollController,
  });

  @override
  State<InfiniteScrollWrapper> createState() => _InfiniteScrollWrapperState();
}

class _InfiniteScrollWrapperState extends State<InfiniteScrollWrapper> {
  late ScrollController _scrollController;
  bool _usingInternalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _usingInternalController = true;
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (_usingInternalController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.isNearBottom && !widget.isLoading && widget.hasMore) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
