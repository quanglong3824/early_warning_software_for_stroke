import 'package:flutter/material.dart';

/// Navigation utilities for optimized route transitions
/// Requirements: 10.2 - Complete transition within 300ms

/// Default transition duration (300ms as per requirements)
const Duration kDefaultTransitionDuration = Duration(milliseconds: 300);

/// Fast transition duration for quick navigations
const Duration kFastTransitionDuration = Duration(milliseconds: 200);

/// Optimized page route with fast transitions
class OptimizedPageRoute<T> extends MaterialPageRoute<T> {
  OptimizedPageRoute({
    required super.builder,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
  });

  @override
  Duration get transitionDuration => kDefaultTransitionDuration;

  @override
  Duration get reverseTransitionDuration => kDefaultTransitionDuration;
}

/// Fade transition route for smoother animations
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: kDefaultTransitionDuration,
          reverseTransitionDuration: kDefaultTransitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

/// Slide transition route (from right)
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlidePageRoute({required this.page, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: kDefaultTransitionDuration,
          reverseTransitionDuration: kDefaultTransitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

/// Slide up transition route (for modals/dialogs)
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpPageRoute({required this.page, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: kDefaultTransitionDuration,
          reverseTransitionDuration: kDefaultTransitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

/// No animation route for instant transitions
class NoAnimationPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  NoAnimationPageRoute({required this.page, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
}

/// Route cache for frequently accessed screens
class RouteCache {
  static final RouteCache _instance = RouteCache._internal();
  factory RouteCache() => _instance;
  RouteCache._internal();

  final Map<String, Widget> _cache = {};
  final Set<String> _cacheableRoutes = {
    '/dashboard',
    '/profile',
    '/settings',
    '/knowledge',
    '/pharmacy',
    '/health-hub',
    '/doctors-hub',
    '/prediction-hub',
  };

  /// Check if a route should be cached
  bool shouldCache(String routeName) {
    return _cacheableRoutes.contains(routeName);
  }

  /// Get cached widget or null
  Widget? get(String routeName) {
    return _cache[routeName];
  }

  /// Cache a widget
  void put(String routeName, Widget widget) {
    if (shouldCache(routeName)) {
      _cache[routeName] = widget;
    }
  }

  /// Remove from cache
  void remove(String routeName) {
    _cache.remove(routeName);
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
  }

  /// Clear cache for routes matching a pattern
  void clearPattern(String pattern) {
    _cache.removeWhere((key, _) => key.contains(pattern));
  }
}

/// Navigation helper with optimized transitions
class AppNavigator {
  /// Push with optimized slide transition
  static Future<T?> push<T>(BuildContext context, Widget page, {String? routeName}) {
    return Navigator.of(context).push<T>(
      SlidePageRoute(
        page: page,
        settings: routeName != null ? RouteSettings(name: routeName) : null,
      ),
    );
  }

  /// Push with fade transition
  static Future<T?> pushFade<T>(BuildContext context, Widget page, {String? routeName}) {
    return Navigator.of(context).push<T>(
      FadePageRoute(
        page: page,
        settings: routeName != null ? RouteSettings(name: routeName) : null,
      ),
    );
  }

  /// Push with slide up transition (for modals)
  static Future<T?> pushModal<T>(BuildContext context, Widget page, {String? routeName}) {
    return Navigator.of(context).push<T>(
      SlideUpPageRoute(
        page: page,
        settings: routeName != null ? RouteSettings(name: routeName) : null,
      ),
    );
  }

  /// Push replacement with optimized transition
  static Future<T?> pushReplacement<T, TO>(BuildContext context, Widget page, {String? routeName}) {
    return Navigator.of(context).pushReplacement<T, TO>(
      SlidePageRoute(
        page: page,
        settings: routeName != null ? RouteSettings(name: routeName) : null,
      ),
    );
  }

  /// Push and remove until with optimized transition
  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context,
    Widget page,
    RoutePredicate predicate, {
    String? routeName,
  }) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      SlidePageRoute(
        page: page,
        settings: routeName != null ? RouteSettings(name: routeName) : null,
      ),
      predicate,
    );
  }

  /// Pop with result
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }

  /// Pop until a specific route
  static void popUntil(BuildContext context, RoutePredicate predicate) {
    Navigator.of(context).popUntil(predicate);
  }

  /// Pop to root
  static void popToRoot(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

/// Extension for easier navigation
extension NavigationExtension on BuildContext {
  /// Push with optimized transition
  Future<T?> pushPage<T>(Widget page, {String? routeName}) {
    return AppNavigator.push<T>(this, page, routeName: routeName);
  }

  /// Push with fade transition
  Future<T?> pushPageFade<T>(Widget page, {String? routeName}) {
    return AppNavigator.pushFade<T>(this, page, routeName: routeName);
  }

  /// Push modal with slide up transition
  Future<T?> pushModal<T>(Widget page, {String? routeName}) {
    return AppNavigator.pushModal<T>(this, page, routeName: routeName);
  }

  /// Pop current page
  void popPage<T>([T? result]) {
    AppNavigator.pop<T>(this, result);
  }

  /// Pop to root
  void popToRoot() {
    AppNavigator.popToRoot(this);
  }
}
