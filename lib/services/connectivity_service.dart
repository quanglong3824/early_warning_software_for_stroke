import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:early_warning_software_for_stroke/services/offline_cache_service.dart';

/// Network connectivity status
enum NetworkStatus {
  online,
  offline,
  unknown
}

/// Connectivity Service for monitoring network status
/// Implements Requirement 5.3 - Trigger sync when online
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final OfflineCacheService _offlineCacheService;
  
  final StreamController<NetworkStatus> _statusController = 
      StreamController<NetworkStatus>.broadcast();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  NetworkStatus _currentStatus = NetworkStatus.unknown;
  bool _wasOffline = false;
  
  ConnectivityService({OfflineCacheService? offlineCacheService})
      : _offlineCacheService = offlineCacheService ?? OfflineCacheService();
  
  /// Stream of network status changes
  Stream<NetworkStatus> get statusStream => _statusController.stream;
  
  /// Current network status
  NetworkStatus get currentStatus => _currentStatus;
  
  /// Check if currently online
  bool get isOnline => _currentStatus == NetworkStatus.online;
  
  /// Check if currently offline
  bool get isOffline => _currentStatus == NetworkStatus.offline;
  
  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial status
    await _checkConnectivity();
    
    // Listen for changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
  }
  
  /// Check current connectivity status
  Future<NetworkStatus> checkConnectivity() async {
    return await _checkConnectivity();
  }
  
  Future<NetworkStatus> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final status = _mapConnectivityResults(results);
      _updateStatus(status);
      return status;
    } catch (e) {
      _updateStatus(NetworkStatus.unknown);
      return NetworkStatus.unknown;
    }
  }
  
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final newStatus = _mapConnectivityResults(results);
    
    // Track if we were offline before
    if (_currentStatus == NetworkStatus.offline) {
      _wasOffline = true;
    }
    
    _updateStatus(newStatus);
    
    // Trigger sync when coming back online (Requirement 5.3)
    if (newStatus == NetworkStatus.online && _wasOffline) {
      _wasOffline = false;
      _triggerSync();
    }
  }
  
  NetworkStatus _mapConnectivityResults(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return NetworkStatus.offline;
    }
    
    // Check for any active connection
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.ethernet)) {
      return NetworkStatus.online;
    }
    
    return NetworkStatus.unknown;
  }
  
  void _updateStatus(NetworkStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);
    }
  }
  
  /// Trigger sync when connection is restored (Requirement 5.3)
  Future<void> _triggerSync() async {
    try {
      final hasPending = await _offlineCacheService.hasPendingRecords();
      if (hasPending) {
        // Sync within 30 seconds as per Requirement 5.3
        await _offlineCacheService.syncPendingData();
      }
    } catch (e) {
      // Sync failed, will retry on next connectivity change
    }
  }
  
  /// Manually trigger sync (for manual retry option - Requirement 5.5)
  Future<bool> manualSync() async {
    if (!isOnline) {
      return false;
    }
    
    return await _offlineCacheService.syncWithRetry();
  }
  
  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
  }
}

/// Singleton instance for global access
class ConnectivityServiceSingleton {
  static ConnectivityService? _instance;
  
  static ConnectivityService get instance {
    _instance ??= ConnectivityService();
    return _instance!;
  }
  
  static Future<void> initialize() async {
    await instance.initialize();
  }
  
  static void dispose() {
    _instance?.dispose();
    _instance = null;
  }
}
