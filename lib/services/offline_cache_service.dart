import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:early_warning_software_for_stroke/data/models/user_model.dart';
import 'package:early_warning_software_for_stroke/data/models/health_record_model.dart';

/// Sync status enumeration
enum SyncStatus {
  idle,
  syncing,
  completed,
  failed
}

/// Pending record wrapper for offline queue
class PendingRecord {
  final String id;
  final String type; // 'health_record', 'appointment', etc.
  final Map<String, dynamic> data;
  final int createdAt;
  final int retryCount;
  final String? userId;

  PendingRecord({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.userId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'data': data,
    'createdAt': createdAt,
    'retryCount': retryCount,
    'userId': userId,
  };

  factory PendingRecord.fromJson(Map<String, dynamic> json) => PendingRecord(
    id: json['id'] ?? '',
    type: json['type'] ?? '',
    data: Map<String, dynamic>.from(json['data'] ?? {}),
    createdAt: json['createdAt'] ?? 0,
    retryCount: json['retryCount'] ?? 0,
    userId: json['userId'],
  );

  PendingRecord incrementRetry() => PendingRecord(
    id: id,
    type: type,
    data: data,
    createdAt: createdAt,
    retryCount: retryCount + 1,
    userId: userId,
  );
  
  /// Check if max retries exceeded
  bool get hasExceededMaxRetries => retryCount >= 3;
}


/// Abstract interface for Offline Cache Service
/// Implements Requirements 5.1, 5.2, 5.3, 5.5
abstract class IOfflineCacheService {
  /// Initialize Hive boxes
  Future<void> initialize();
  
  /// Cache user profile for offline access (Requirement 5.1)
  Future<void> cacheUserProfile(UserModel user);
  
  /// Get cached user profile (Requirement 5.1)
  Future<UserModel?> getCachedUserProfile();
  
  /// Queue health record for sync when online (Requirement 5.2)
  Future<void> queueHealthRecord(HealthRecordModel record);
  
  /// Get all pending records waiting for sync (Requirement 5.2)
  Future<List<PendingRecord>> getPendingRecords();
  
  /// Sync all pending data to server (Requirement 5.3)
  Future<void> syncPendingData();
  
  /// Stream of sync status changes
  Stream<SyncStatus> get syncStatusStream;
  
  /// Clear all cached data
  Future<void> clearCache();
  
  /// Check if there are pending records
  Future<bool> hasPendingRecords();
  
  /// Get count of pending records
  Future<int> getPendingRecordsCount();
  
  /// Cache timestamp for "data may be outdated" indicator (Requirement 5.4)
  Future<void> setCacheTimestamp();
  
  /// Get cache timestamp
  Future<DateTime?> getCacheTimestamp();
  
  /// Check if cached data is stale (older than threshold)
  Future<bool> isCacheStale({Duration threshold = const Duration(hours: 1)});
}

/// Implementation of Offline Cache Service using Hive
/// Implements Requirements 5.1, 5.2, 5.3, 5.4, 5.5
class OfflineCacheService implements IOfflineCacheService {
  static const String _userBoxName = 'user_cache';
  static const String _pendingBoxName = 'pending_records';
  static const String _metadataBoxName = 'cache_metadata';
  static const int _maxRetries = 3;
  
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final StreamController<SyncStatus> _syncStatusController = 
      StreamController<SyncStatus>.broadcast();
  
  Box? _userBox;
  Box? _pendingBox;
  Box? _metadataBox;
  
  SyncStatus _currentStatus = SyncStatus.idle;
  
  @override
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  
  /// Get current sync status
  SyncStatus get currentStatus => _currentStatus;
  
  @override
  Future<void> initialize() async {
    await Hive.initFlutter();
    _userBox = await Hive.openBox(_userBoxName);
    _pendingBox = await Hive.openBox(_pendingBoxName);
    _metadataBox = await Hive.openBox(_metadataBoxName);
  }
  
  // ============================================
  // User Profile Caching (Requirement 5.1)
  // ============================================
  
  @override
  Future<void> cacheUserProfile(UserModel user) async {
    await _userBox?.put('current_user', user.toJson());
    await setCacheTimestamp();
  }
  
  @override
  Future<UserModel?> getCachedUserProfile() async {
    final data = _userBox?.get('current_user');
    if (data == null) return null;
    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }

  // ============================================
  // Health Record Queue (Requirement 5.2)
  // ============================================

  @override
  Future<void> queueHealthRecord(HealthRecordModel record) async {
    final pendingRecord = PendingRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'health_record',
      data: record.toJson(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      userId: record.userId,
    );
    
    await _pendingBox?.put(pendingRecord.id, pendingRecord.toJson());
  }
  
  @override
  Future<List<PendingRecord>> getPendingRecords() async {
    final records = <PendingRecord>[];
    
    _pendingBox?.toMap().forEach((key, value) {
      records.add(PendingRecord.fromJson(Map<String, dynamic>.from(value)));
    });
    
    // Sort by creation time (oldest first for FIFO processing)
    records.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    return records;
  }
  
  @override
  Future<bool> hasPendingRecords() async {
    return (_pendingBox?.length ?? 0) > 0;
  }
  
  @override
  Future<int> getPendingRecordsCount() async {
    return _pendingBox?.length ?? 0;
  }
  
  // ============================================
  // Sync Mechanism (Requirements 5.3, 5.5)
  // ============================================
  
  @override
  Future<void> syncPendingData() async {
    if (_currentStatus == SyncStatus.syncing) {
      return; // Already syncing
    }
    
    _updateStatus(SyncStatus.syncing);
    
    try {
      final pendingRecords = await getPendingRecords();
      
      if (pendingRecords.isEmpty) {
        _updateStatus(SyncStatus.completed);
        return;
      }
      
      bool hasFailures = false;
      
      for (final record in pendingRecords) {
        try {
          await _syncRecord(record);
          // Remove from pending queue on success
          await _pendingBox?.delete(record.id);
        } catch (e) {
          // Increment retry count
          final updatedRecord = record.incrementRetry();
          
          if (updatedRecord.hasExceededMaxRetries) {
            // Max retries reached (Requirement 5.5)
            hasFailures = true;
            // Keep in queue for manual retry
            await _pendingBox?.put(record.id, updatedRecord.toJson());
          } else {
            // Update retry count in queue
            await _pendingBox?.put(record.id, updatedRecord.toJson());
          }
        }
      }
      
      if (hasFailures) {
        _updateStatus(SyncStatus.failed);
      } else {
        _updateStatus(SyncStatus.completed);
      }
    } catch (e) {
      _updateStatus(SyncStatus.failed);
    }
  }
  
  /// Sync with retry logic (Requirement 5.5)
  /// Retries up to 3 times before notifying user
  Future<bool> syncWithRetry() async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        await syncPendingData();
        if (_currentStatus == SyncStatus.completed) {
          return true;
        }
      } catch (e) {
        // Continue to next attempt
      }
      
      // Wait before retry with exponential backoff
      if (attempt < _maxRetries - 1) {
        await Future.delayed(Duration(seconds: (attempt + 1) * 2));
      }
    }
    
    return false;
  }
  
  Future<void> _syncRecord(PendingRecord record) async {
    switch (record.type) {
      case 'health_record':
        final userId = record.userId ?? record.data['userId'];
        if (userId == null) {
          throw Exception('Missing userId for health record');
        }
        
        final ref = _database.child('health_records').child(userId).push();
        await ref.set({
          ...record.data,
          'recordId': ref.key,
          'syncedAt': DateTime.now().millisecondsSinceEpoch,
        });
        break;
      default:
        throw Exception('Unknown record type: ${record.type}');
    }
  }
  
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _syncStatusController.add(status);
  }
  
  // ============================================
  // Cache Metadata (Requirement 5.4)
  // ============================================
  
  @override
  Future<void> setCacheTimestamp() async {
    await _metadataBox?.put('last_cache_time', DateTime.now().millisecondsSinceEpoch);
  }
  
  @override
  Future<DateTime?> getCacheTimestamp() async {
    final timestamp = _metadataBox?.get('last_cache_time');
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp as int);
  }
  
  @override
  Future<bool> isCacheStale({Duration threshold = const Duration(hours: 1)}) async {
    final cacheTime = await getCacheTimestamp();
    if (cacheTime == null) return true;
    
    return DateTime.now().difference(cacheTime) > threshold;
  }
  
  // ============================================
  // Cache Management
  // ============================================
  
  @override
  Future<void> clearCache() async {
    await _userBox?.clear();
    await _pendingBox?.clear();
    await _metadataBox?.clear();
    _updateStatus(SyncStatus.idle);
  }
  
  /// Clear only pending records (for manual retry reset)
  Future<void> clearPendingRecords() async {
    await _pendingBox?.clear();
  }
  
  /// Remove a specific pending record
  Future<void> removePendingRecord(String recordId) async {
    await _pendingBox?.delete(recordId);
  }
  
  /// Reset retry count for all failed records (for manual retry)
  Future<void> resetFailedRecords() async {
    final records = await getPendingRecords();
    for (final record in records) {
      if (record.hasExceededMaxRetries) {
        final resetRecord = PendingRecord(
          id: record.id,
          type: record.type,
          data: record.data,
          createdAt: record.createdAt,
          retryCount: 0,
          userId: record.userId,
        );
        await _pendingBox?.put(record.id, resetRecord.toJson());
      }
    }
  }
  
  /// Dispose resources
  void dispose() {
    _syncStatusController.close();
  }
}
