import 'package:flutter/material.dart';
import 'dart:async';
import '../services/connectivity_service.dart';
import '../services/offline_cache_service.dart';

/// Offline Banner Widget - Shows when device is offline
/// Implements Requirement 5.4 - Display indicator showing data may be outdated
class OfflineBanner extends StatefulWidget {
  final Widget child;
  final bool showSyncStatus;
  
  const OfflineBanner({
    super.key,
    required this.child,
    this.showSyncStatus = true,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  final ConnectivityService _connectivityService = ConnectivityServiceSingleton.instance;
  final OfflineCacheService _offlineCacheService = OfflineCacheService();
  
  StreamSubscription<NetworkStatus>? _networkSubscription;
  StreamSubscription<SyncStatus>? _syncSubscription;
  
  NetworkStatus _networkStatus = NetworkStatus.unknown;
  SyncStatus _syncStatus = SyncStatus.idle;
  int _pendingCount = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeListeners();
  }
  
  Future<void> _initializeListeners() async {
    // Initialize services if needed
    try {
      await _offlineCacheService.initialize();
    } catch (e) {
      // Already initialized
    }
    
    // Get initial status
    _networkStatus = _connectivityService.currentStatus;
    _syncStatus = _offlineCacheService.currentStatus;
    await _updatePendingCount();
    
    // Listen for network changes
    _networkSubscription = _connectivityService.statusStream.listen((status) {
      if (mounted) {
        setState(() => _networkStatus = status);
        _updatePendingCount();
      }
    });
    
    // Listen for sync status changes
    if (widget.showSyncStatus) {
      _syncSubscription = _offlineCacheService.syncStatusStream.listen((status) {
        if (mounted) {
          setState(() => _syncStatus = status);
          if (status == SyncStatus.completed) {
            _updatePendingCount();
          }
        }
      });
    }
    
    if (mounted) setState(() {});
  }
  
  Future<void> _updatePendingCount() async {
    final count = await _offlineCacheService.getPendingRecordsCount();
    if (mounted) {
      setState(() => _pendingCount = count);
    }
  }
  
  @override
  void dispose() {
    _networkSubscription?.cancel();
    _syncSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Offline Banner
        if (_networkStatus == NetworkStatus.offline)
          _buildOfflineBanner(),
        
        // Syncing Banner
        if (_networkStatus == NetworkStatus.online && 
            _syncStatus == SyncStatus.syncing)
          _buildSyncingBanner(),
        
        // Pending Records Banner
        if (_networkStatus == NetworkStatus.online && 
            _pendingCount > 0 &&
            _syncStatus != SyncStatus.syncing)
          _buildPendingBanner(),
        
        // Sync Failed Banner
        if (_syncStatus == SyncStatus.failed)
          _buildSyncFailedBanner(),
        
        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
  
  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.grey[800],
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Bạn đang offline. Dữ liệu có thể không được cập nhật.',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSyncingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.blue[600],
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Đang đồng bộ dữ liệu...',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPendingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.orange[600],
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.sync_problem, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$_pendingCount bản ghi đang chờ đồng bộ',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _manualSync,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
              ),
              child: const Text(
                'Đồng bộ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSyncFailedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.red[600],
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Đồng bộ thất bại sau 3 lần thử',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _retrySync,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
              ),
              child: const Text(
                'Thử lại',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _manualSync() async {
    await _connectivityService.manualSync();
  }
  
  Future<void> _retrySync() async {
    await _offlineCacheService.resetFailedRecords();
    await _connectivityService.manualSync();
  }
}

/// Cached Data Indicator - Shows when viewing cached data
/// Implements Requirement 5.4
class CachedDataIndicator extends StatelessWidget {
  final DateTime? cacheTime;
  final VoidCallback? onRefresh;
  
  const CachedDataIndicator({
    super.key,
    this.cacheTime,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (cacheTime == null) return const SizedBox.shrink();
    
    final timeDiff = DateTime.now().difference(cacheTime!);
    final timeText = _formatTimeDifference(timeDiff);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 14, color: Colors.amber[800]),
          const SizedBox(width: 6),
          Text(
            'Dữ liệu cache từ $timeText trước',
            style: TextStyle(
              fontSize: 12,
              color: Colors.amber[900],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onRefresh != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRefresh,
              child: Icon(Icons.refresh, size: 16, color: Colors.amber[800]),
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatTimeDifference(Duration diff) {
    if (diff.inDays > 0) {
      return '${diff.inDays} ngày';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} giờ';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} phút';
    } else {
      return 'vài giây';
    }
  }
}

/// Network Status Icon - Small indicator for app bar
class NetworkStatusIcon extends StatefulWidget {
  const NetworkStatusIcon({super.key});

  @override
  State<NetworkStatusIcon> createState() => _NetworkStatusIconState();
}

class _NetworkStatusIconState extends State<NetworkStatusIcon> {
  final ConnectivityService _connectivityService = ConnectivityServiceSingleton.instance;
  StreamSubscription<NetworkStatus>? _subscription;
  NetworkStatus _status = NetworkStatus.unknown;

  @override
  void initState() {
    super.initState();
    _status = _connectivityService.currentStatus;
    _subscription = _connectivityService.statusStream.listen((status) {
      if (mounted) setState(() => _status = status);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_status == NetworkStatus.online) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Icon(
        _status == NetworkStatus.offline ? Icons.cloud_off : Icons.cloud_queue,
        color: _status == NetworkStatus.offline ? Colors.red : Colors.grey,
        size: 20,
      ),
    );
  }
}
