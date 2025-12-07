import 'dart:async';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'offline_cache_service.dart';
import 'connectivity_service.dart';

/// Service initializer for optimized app startup
/// Requirements: 10.1 - Display main dashboard within 3 seconds
/// 
/// This class manages lazy loading of non-critical services to improve
/// app startup time. Critical services are initialized immediately,
/// while non-critical services are loaded in the background.
class ServiceInitializer {
  static final ServiceInitializer _instance = ServiceInitializer._internal();
  factory ServiceInitializer() => _instance;
  ServiceInitializer._internal();

  bool _criticalServicesInitialized = false;
  bool _allServicesInitialized = false;
  
  final Completer<void> _criticalCompleter = Completer<void>();
  final Completer<void> _allCompleter = Completer<void>();

  /// Stream to track initialization progress
  final _progressController = StreamController<InitializationProgress>.broadcast();
  Stream<InitializationProgress> get progressStream => _progressController.stream;

  /// Check if critical services are ready
  bool get isCriticalReady => _criticalServicesInitialized;
  
  /// Check if all services are ready
  bool get isFullyReady => _allServicesInitialized;

  /// Wait for critical services to be ready
  Future<void> waitForCritical() => _criticalCompleter.future;
  
  /// Wait for all services to be ready
  Future<void> waitForAll() => _allCompleter.future;

  /// Initialize all services with priority ordering
  /// Critical services are initialized first, then non-critical in background
  Future<void> initialize() async {
    if (_criticalServicesInitialized) return;

    try {
      // Phase 1: Critical services (required for app to function)
      _emitProgress('Đang khởi tạo...', 0.1);
      await _initializeCriticalServices();
      
      _criticalServicesInitialized = true;
      if (!_criticalCompleter.isCompleted) {
        _criticalCompleter.complete();
      }
      
      // Phase 2: Non-critical services (can be loaded in background)
      _initializeNonCriticalServices();
      
    } catch (e) {
      debugPrint('ServiceInitializer error: $e');
      if (!_criticalCompleter.isCompleted) {
        _criticalCompleter.completeError(e);
      }
    }
  }

  /// Initialize critical services required for app startup
  Future<void> _initializeCriticalServices() async {
    _emitProgress('Đang kết nối...', 0.3);
    
    // Initialize connectivity service first (needed for offline detection)
    await ConnectivityServiceSingleton.initialize();
    
    _emitProgress('Đang tải dữ liệu...', 0.5);
    
    // Initialize offline cache (needed for cached data display)
    final offlineCacheService = OfflineCacheService();
    await offlineCacheService.initialize();
    
    _emitProgress('Hoàn tất', 0.8);
  }

  /// Initialize non-critical services in background
  void _initializeNonCriticalServices() {
    // Run in background without blocking
    Future.microtask(() async {
      try {
        _emitProgress('Đang tải thêm...', 0.9);
        
        // Initialize notification service (can be delayed)
        final notificationService = NotificationService();
        await notificationService.initialize();
        
        _allServicesInitialized = true;
        if (!_allCompleter.isCompleted) {
          _allCompleter.complete();
        }
        
        _emitProgress('Hoàn tất', 1.0);
        
      } catch (e) {
        debugPrint('Non-critical service initialization error: $e');
        // Don't fail the app for non-critical services
        _allServicesInitialized = true;
        if (!_allCompleter.isCompleted) {
          _allCompleter.complete();
        }
      }
    });
  }

  void _emitProgress(String message, double progress) {
    _progressController.add(InitializationProgress(
      message: message,
      progress: progress,
    ));
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
  }
}

/// Progress information for initialization
class InitializationProgress {
  final String message;
  final double progress; // 0.0 to 1.0

  InitializationProgress({
    required this.message,
    required this.progress,
  });
}

/// Lazy service loader for on-demand service initialization
class LazyServiceLoader<T> {
  final Future<T> Function() _factory;
  T? _instance;
  bool _isLoading = false;
  final Completer<T> _completer = Completer<T>();

  LazyServiceLoader(this._factory);

  /// Get the service instance, initializing if needed
  Future<T> get() async {
    if (_instance != null) return _instance!;
    
    if (_isLoading) {
      return _completer.future;
    }
    
    _isLoading = true;
    try {
      _instance = await _factory();
      _completer.complete(_instance);
      return _instance!;
    } catch (e) {
      _completer.completeError(e);
      rethrow;
    }
  }

  /// Check if service is already loaded
  bool get isLoaded => _instance != null;

  /// Get instance if already loaded, null otherwise
  T? get instanceOrNull => _instance;
}
