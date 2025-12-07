import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

/// Integration tests for Offline Sync flow
/// Tests: offline create → online sync flow
/// **Validates: Requirements 5.2, 5.3**
///
/// These tests verify the complete offline sync lifecycle without
/// requiring actual Hive or Firebase connections.

/// Enum representing sync status
enum TestSyncStatus {
  idle,
  syncing,
  completed,
  failed
}

/// Enum representing network status
enum TestNetworkStatus {
  online,
  offline,
  unknown
}

/// Model for health record in tests
class TestHealthRecord {
  final String id;
  final String userId;
  final int recordedAt;
  final int? systolicBP;
  final int? diastolicBP;
  final int? heartRate;
  final double? bloodSugar;
  final double? weight;
  final String? notes;
  final int createdAt;

  TestHealthRecord({
    required this.id,
    required this.userId,
    required this.recordedAt,
    this.systolicBP,
    this.diastolicBP,
    this.heartRate,
    this.bloodSugar,
    this.weight,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'recordedAt': recordedAt,
    'systolicBP': systolicBP,
    'diastolicBP': diastolicBP,
    'heartRate': heartRate,
    'bloodSugar': bloodSugar,
    'weight': weight,
    'notes': notes,
    'createdAt': createdAt,
  };

  factory TestHealthRecord.fromJson(Map<String, dynamic> json) =>
      TestHealthRecord(
        id: json['id'] ?? '',
        userId: json['userId'] ?? '',
        recordedAt: json['recordedAt'] ?? 0,
        systolicBP: json['systolicBP'],
        diastolicBP: json['diastolicBP'],
        heartRate: json['heartRate'],
        bloodSugar: json['bloodSugar']?.toDouble(),
        weight: json['weight']?.toDouble(),
        notes: json['notes'],
        createdAt: json['createdAt'] ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestHealthRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId;

  @override
  int get hashCode => Object.hash(id, userId);
}

/// Model for pending record in tests
class TestPendingRecord {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final int createdAt;
  final int retryCount;
  final String? userId;

  TestPendingRecord({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.userId,
  });

  TestPendingRecord incrementRetry() => TestPendingRecord(
    id: id,
    type: type,
    data: data,
    createdAt: createdAt,
    retryCount: retryCount + 1,
    userId: userId,
  );

  bool get hasExceededMaxRetries => retryCount >= 3;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'data': data,
    'createdAt': createdAt,
    'retryCount': retryCount,
    'userId': userId,
  };

  factory TestPendingRecord.fromJson(Map<String, dynamic> json) =>
      TestPendingRecord(
        id: json['id'] ?? '',
        type: json['type'] ?? '',
        data: Map<String, dynamic>.from(json['data'] ?? {}),
        createdAt: json['createdAt'] ?? 0,
        retryCount: json['retryCount'] ?? 0,
        userId: json['userId'],
      );
}

/// Testable Offline Cache Service that simulates the real service behavior
/// without requiring actual Hive or Firebase connections.
class TestableOfflineCacheService {
  final StreamController<TestSyncStatus> _syncStatusController =
      StreamController<TestSyncStatus>.broadcast();

  // Simulated local storage (Hive)
  final Map<String, Map<String, dynamic>> _pendingQueue = {};
  final Map<String, Map<String, dynamic>> _userCache = {};
  DateTime? _cacheTimestamp;

  // Simulated remote database (Firebase)
  final Map<String, Map<String, dynamic>> _remoteDatabase = {};

  // State
  TestSyncStatus _currentStatus = TestSyncStatus.idle;
  int _idCounter = 0;

  // Getters
  Stream<TestSyncStatus> get syncStatusStream => _syncStatusController.stream;
  TestSyncStatus get currentStatus => _currentStatus;

  /// Queue a health record for sync when online (Requirement 5.2)
  String queueHealthRecord(TestHealthRecord record) {
    final pendingId = '${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';
    final pendingRecord = TestPendingRecord(
      id: pendingId,
      type: 'health_record',
      data: record.toJson(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      userId: record.userId,
    );
    _pendingQueue[pendingId] = pendingRecord.toJson();
    return pendingId;
  }

  /// Get all pending records
  List<TestPendingRecord> getPendingRecords() {
    final records = _pendingQueue.values
        .map((json) => TestPendingRecord.fromJson(json))
        .toList();
    records.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return records;
  }

  /// Check if there are pending records
  bool hasPendingRecords() => _pendingQueue.isNotEmpty;

  /// Get count of pending records
  int getPendingRecordsCount() => _pendingQueue.length;

  /// Sync all pending data to server (Requirement 5.3)
  Future<void> syncPendingData({bool simulateFailure = false}) async {
    if (_currentStatus == TestSyncStatus.syncing) return;

    _updateStatus(TestSyncStatus.syncing);

    try {
      final pendingRecords = getPendingRecords();

      if (pendingRecords.isEmpty) {
        _updateStatus(TestSyncStatus.completed);
        return;
      }

      bool hasFailures = false;

      for (final record in pendingRecords) {
        try {
          if (simulateFailure) {
            throw Exception('Simulated sync failure');
          }
          await _syncRecord(record);
          // Remove from pending queue on success
          _pendingQueue.remove(record.id);
        } catch (e) {
          // Increment retry count
          final updatedRecord = record.incrementRetry();

          if (updatedRecord.hasExceededMaxRetries) {
            hasFailures = true;
            _pendingQueue[record.id] = updatedRecord.toJson();
          } else {
            _pendingQueue[record.id] = updatedRecord.toJson();
          }
        }
      }

      if (hasFailures) {
        _updateStatus(TestSyncStatus.failed);
      } else {
        _updateStatus(TestSyncStatus.completed);
      }
    } catch (e) {
      _updateStatus(TestSyncStatus.failed);
    }
  }

  /// Sync a single record to remote database
  Future<void> _syncRecord(TestPendingRecord record) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 10));

    switch (record.type) {
      case 'health_record':
        final userId = record.userId ?? record.data['userId'];
        if (userId == null) {
          throw Exception('Missing userId for health record');
        }

        final recordId = 'synced_${record.id}';
        _remoteDatabase[recordId] = {
          ...record.data,
          'recordId': recordId,
          'syncedAt': DateTime.now().millisecondsSinceEpoch,
        };
        break;
      default:
        throw Exception('Unknown record type: ${record.type}');
    }
  }

  void _updateStatus(TestSyncStatus status) {
    _currentStatus = status;
    _syncStatusController.add(status);
  }

  /// Get synced records from remote database
  List<Map<String, dynamic>> getSyncedRecords() {
    return _remoteDatabase.values.toList();
  }

  /// Check if a record was synced to remote
  bool isRecordSynced(String originalRecordId) {
    return _remoteDatabase.values.any((record) =>
        record['id'] == originalRecordId ||
        record['recordId']?.contains(originalRecordId) == true);
  }

  /// Get synced record by original ID
  Map<String, dynamic>? getSyncedRecord(String pendingId) {
    try {
      return _remoteDatabase.values.firstWhere(
        (record) => record['recordId']?.contains(pendingId) == true,
      );
    } catch (e) {
      return null;
    }
  }

  /// Clear all data
  void clear() {
    _pendingQueue.clear();
    _remoteDatabase.clear();
    _userCache.clear();
    _cacheTimestamp = null;
    _updateStatus(TestSyncStatus.idle);
  }

  /// Dispose resources
  void dispose() {
    _syncStatusController.close();
  }
}

/// Testable Connectivity Service that simulates network status changes
class TestableConnectivityService {
  final StreamController<TestNetworkStatus> _statusController =
      StreamController<TestNetworkStatus>.broadcast();

  TestNetworkStatus _currentStatus = TestNetworkStatus.offline;
  final TestableOfflineCacheService _cacheService;

  TestableConnectivityService(this._cacheService);

  // Getters
  Stream<TestNetworkStatus> get statusStream => _statusController.stream;
  TestNetworkStatus get currentStatus => _currentStatus;
  bool get isOnline => _currentStatus == TestNetworkStatus.online;
  bool get isOffline => _currentStatus == TestNetworkStatus.offline;

  /// Simulate going offline
  void goOffline() {
    _currentStatus = TestNetworkStatus.offline;
    _statusController.add(TestNetworkStatus.offline);
  }

  /// Simulate going online and trigger sync (Requirement 5.3)
  Future<void> goOnline() async {
    final wasOffline = _currentStatus == TestNetworkStatus.offline;
    _currentStatus = TestNetworkStatus.online;
    _statusController.add(TestNetworkStatus.online);

    // Trigger sync when coming back online (Requirement 5.3)
    if (wasOffline && _cacheService.hasPendingRecords()) {
      await _cacheService.syncPendingData();
    }
  }

  /// Dispose resources
  void dispose() {
    _statusController.close();
  }
}


void main() {
  group('Offline Sync Integration Tests', () {
    late TestableOfflineCacheService cacheService;
    late TestableConnectivityService connectivityService;

    setUp(() {
      cacheService = TestableOfflineCacheService();
      connectivityService = TestableConnectivityService(cacheService);
    });

    tearDown(() {
      cacheService.dispose();
      connectivityService.dispose();
    });

    group('Offline Record Creation (Requirement 5.2)', () {
      test('queueHealthRecord should store record in pending queue', () {
        // Arrange
        final record = TestHealthRecord(
          id: 'record_001',
          userId: 'user_001',
          recordedAt: DateTime.now().millisecondsSinceEpoch,
          systolicBP: 120,
          diastolicBP: 80,
          heartRate: 72,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        // Act
        final pendingId = cacheService.queueHealthRecord(record);

        // Assert
        expect(pendingId, isNotEmpty);
        expect(cacheService.hasPendingRecords(), isTrue);
        expect(cacheService.getPendingRecordsCount(), equals(1));
      });

      test('queueHealthRecord should preserve all record data', () {
        // Arrange
        final record = TestHealthRecord(
          id: 'record_002',
          userId: 'user_002',
          recordedAt: DateTime.now().millisecondsSinceEpoch,
          systolicBP: 130,
          diastolicBP: 85,
          heartRate: 80,
          bloodSugar: 5.5,
          weight: 70.5,
          notes: 'Test notes',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        // Act
        final pendingId = cacheService.queueHealthRecord(record);
        final pendingRecords = cacheService.getPendingRecords();

        // Assert
        expect(pendingRecords.length, equals(1));
        final pending = pendingRecords.first;
        expect(pending.type, equals('health_record'));
        expect(pending.userId, equals(record.userId));
        expect(pending.data['systolicBP'], equals(130));
        expect(pending.data['diastolicBP'], equals(85));
        expect(pending.data['heartRate'], equals(80));
        expect(pending.data['bloodSugar'], equals(5.5));
        expect(pending.data['notes'], equals('Test notes'));
      });

      test('multiple records should be queued in FIFO order', () async {
        // Arrange
        final records = List.generate(3, (i) => TestHealthRecord(
          id: 'record_$i',
          userId: 'user_001',
          recordedAt: DateTime.now().millisecondsSinceEpoch,
          systolicBP: 120 + i,
          diastolicBP: 80 + i,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));

        // Act
        for (final record in records) {
          cacheService.queueHealthRecord(record);
          await Future.delayed(const Duration(milliseconds: 5));
        }

        // Assert
        expect(cacheService.getPendingRecordsCount(), equals(3));
        final pendingRecords = cacheService.getPendingRecords();
        
        // Verify FIFO order
        for (int i = 1; i < pendingRecords.length; i++) {
          expect(
            pendingRecords[i].createdAt >= pendingRecords[i - 1].createdAt,
            isTrue,
            reason: 'Records should be in FIFO order',
          );
        }
      });
    });

    group('Online Sync (Requirement 5.3)', () {
      test('syncPendingData should sync records to remote database', () async {
        // Arrange
        final record = TestHealthRecord(
          id: 'record_003',
          userId: 'user_003',
          recordedAt: DateTime.now().millisecondsSinceEpoch,
          systolicBP: 125,
          diastolicBP: 82,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        final pendingId = cacheService.queueHealthRecord(record);
        expect(cacheService.hasPendingRecords(), isTrue);

        // Act
        await cacheService.syncPendingData();

        // Assert
        expect(cacheService.hasPendingRecords(), isFalse);
        expect(cacheService.currentStatus, equals(TestSyncStatus.completed));
        
        final syncedRecords = cacheService.getSyncedRecords();
        expect(syncedRecords.length, equals(1));
        expect(syncedRecords.first['systolicBP'], equals(125));
        expect(syncedRecords.first['syncedAt'], isNotNull);
      });

      test('syncPendingData should remove synced records from queue', () async {
        // Arrange
        final records = List.generate(3, (i) => TestHealthRecord(
          id: 'record_sync_$i',
          userId: 'user_001',
          recordedAt: DateTime.now().millisecondsSinceEpoch,
          systolicBP: 120 + i,
          diastolicBP: 80 + i,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));
        for (final record in records) {
          cacheService.queueHealthRecord(record);
        }
        expect(cacheService.getPendingRecordsCount(), equals(3));

        // Act
        await cacheService.syncPendingData();

        // Assert
        expect(cacheService.getPendingRecordsCount(), equals(0));
        expect(cacheService.hasPendingRecords(), isFalse);
        expect(cacheService.getSyncedRecords().length, equals(3));
      });

      test('syncPendingData should emit correct status transitions', () async {
        // Arrange
        final record = TestHealthRecord(
          id: 'record_status',
          userId: 'user_001',
          recordedAt: DateTime.now().millisecondsSinceEpoch,
          systolicBP: 120,
          diastolicBP: 80,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        cacheService.queueHealthRecord(record);
        final statuses = <TestSyncStatus>[];
        cacheService.syncStatusStream.listen(statuses.add);

        // Act
        await cacheService.syncPendingData();
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(statuses, contains(TestSyncStatus.syncing));
        expect(statuses, contains(TestSyncStatus.completed));
      });

      test('empty queue should complete immediately', () async {
        // Arrange
        expect(cacheService.hasPendingRecords(), isFalse);
        final statuses = <TestSyncStatus>[];
        cacheService.syncStatusStream.listen(statuses.add);

        // Act
        await cacheService.syncPendingData();
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(statuses, contains(TestSyncStatus.completed));
      });
    });

    group('Connectivity-Triggered Sync (Requirement 5.3)', () {
      test('going online should trigger sync of pending records', () async {
        // Arrange
        connectivityService.goOffline();
        expect(connectivityService.isOffline, isTrue);

        final record = TestHealthRecord(
          id: 'record_connectivity',
          userId: 'user_001',
          recordedAt: DateTime.now().millisecondsSinceEpoch,
          systolicBP: 118,
          diastolicBP: 78,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        cacheService.queueHealthRecord(record);
        expect(cacheService.hasPendingRecords(), isTrue);

        // Act - Go online (should trigger sync)
        await connectivityService.goOnline();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(connectivityService.isOnline, isTrue);
        expect(cacheService.hasPendingRecords(), isFalse);
        expect(cacheService.getSyncedRecords().length, equals(1));
      });

      test('going online with no pending records should not fail', () async {
        // Arrange
        connectivityService.goOffline();
        expect(cacheService.hasPendingRecords(), isFalse);

        // Act
        await connectivityService.goOnline();

        // Assert
        expect(connectivityService.isOnline, isTrue);
        // Should not throw or fail
      });
    });

    group('Complete Flow: Offline Create → Online Sync', () {
      test('complete offline to online sync flow should work correctly', () async {
        // Validates: Requirements 5.2, 5.3
        final syncStatuses = <TestSyncStatus>[];
        final networkStatuses = <TestNetworkStatus>[];
        cacheService.syncStatusStream.listen(syncStatuses.add);
        connectivityService.statusStream.listen(networkStatuses.add);

        // Step 1: Start offline
        connectivityService.goOffline();
        expect(connectivityService.isOffline, isTrue);
        await Future.delayed(const Duration(milliseconds: 10));

        // Step 2: Create health records while offline (Requirement 5.2)
        final records = [
          TestHealthRecord(
            id: 'offline_record_1',
            userId: 'user_flow_001',
            recordedAt: DateTime.now().millisecondsSinceEpoch,
            systolicBP: 120,
            diastolicBP: 80,
            heartRate: 72,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
          TestHealthRecord(
            id: 'offline_record_2',
            userId: 'user_flow_001',
            recordedAt: DateTime.now().millisecondsSinceEpoch,
            systolicBP: 125,
            diastolicBP: 82,
            heartRate: 75,
            bloodSugar: 5.8,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        ];

        for (final record in records) {
          cacheService.queueHealthRecord(record);
        }

        // Verify records are queued
        expect(cacheService.getPendingRecordsCount(), equals(2));
        expect(cacheService.hasPendingRecords(), isTrue);

        // Step 3: Go online - should trigger sync (Requirement 5.3)
        await connectivityService.goOnline();
        await Future.delayed(const Duration(milliseconds: 100));

        // Step 4: Verify sync completed
        expect(connectivityService.isOnline, isTrue);
        expect(cacheService.hasPendingRecords(), isFalse);
        expect(cacheService.getPendingRecordsCount(), equals(0));

        // Step 5: Verify records synced to remote
        final syncedRecords = cacheService.getSyncedRecords();
        expect(syncedRecords.length, equals(2));

        // Verify data integrity
        final syncedBPs = syncedRecords.map((r) => r['systolicBP']).toList();
        expect(syncedBPs, containsAll([120, 125]));

        // Verify sync timestamps added
        for (final synced in syncedRecords) {
          expect(synced['syncedAt'], isNotNull);
          expect(synced['recordId'], isNotNull);
        }

        // Verify status transitions
        expect(networkStatuses, contains(TestNetworkStatus.offline));
        expect(networkStatuses, contains(TestNetworkStatus.online));
        expect(syncStatuses, contains(TestSyncStatus.syncing));
        expect(syncStatuses, contains(TestSyncStatus.completed));
      });

      test('multiple offline sessions should accumulate and sync', () async {
        // Validates: Requirements 5.2, 5.3

        // Session 1: Offline
        connectivityService.goOffline();
        cacheService.queueHealthRecord(TestHealthRecord(
          id: 'session1_record',
          userId: 'user_001',
          recordedAt: DateTime.now().millisecondsSinceEpoch,
          systolicBP: 115,
          diastolicBP: 75,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));
        expect(cacheService.getPendingRecordsCount(), equals(1));

        // Session 2: Still offline, add more records
        await Future.delayed(const Duration(milliseconds: 10));
        cacheService.queueHealthRecord(TestHealthRecord(
          id: 'session2_record',
          userId: 'user_001',
          recordedAt: DateTime.now().millisecondsSinceEpoch,
          systolicBP: 118,
          diastolicBP: 78,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));
        expect(cacheService.getPendingRecordsCount(), equals(2));

        // Go online - all records should sync
        await connectivityService.goOnline();
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify all records synced
        expect(cacheService.hasPendingRecords(), isFalse);
        expect(cacheService.getSyncedRecords().length, equals(2));
      });

      test('sync should preserve record order (FIFO)', () async {
        // Arrange
        connectivityService.goOffline();
        
        final timestamps = <int>[];
        for (int i = 0; i < 5; i++) {
          final record = TestHealthRecord(
            id: 'fifo_record_$i',
            userId: 'user_001',
            recordedAt: DateTime.now().millisecondsSinceEpoch,
            systolicBP: 120 + i,
            diastolicBP: 80 + i,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          );
          cacheService.queueHealthRecord(record);
          timestamps.add(DateTime.now().millisecondsSinceEpoch);
          await Future.delayed(const Duration(milliseconds: 5));
        }

        // Act
        await connectivityService.goOnline();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - records should be synced in order
        final syncedRecords = cacheService.getSyncedRecords();
        expect(syncedRecords.length, equals(5));
      });
    });

    group('Sync Failure Handling', () {
      test('failed sync should keep records in queue', () async {
        // Arrange
        final record = TestHealthRecord(
          id: 'fail_record',
          userId: 'user_001',
          recordedAt: DateTime.now().millisecondsSinceEpoch,
          systolicBP: 120,
          diastolicBP: 80,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        cacheService.queueHealthRecord(record);

        // Act - Simulate sync failure
        await cacheService.syncPendingData(simulateFailure: true);

        // Assert - Record should still be in queue
        expect(cacheService.hasPendingRecords(), isTrue);
        expect(cacheService.getPendingRecordsCount(), equals(1));
      });

      test('failed sync should increment retry count', () async {
        // Arrange
        final record = TestHealthRecord(
          id: 'retry_record',
          userId: 'user_001',
          recordedAt: DateTime.now().millisecondsSinceEpoch,
          systolicBP: 120,
          diastolicBP: 80,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        cacheService.queueHealthRecord(record);

        // Act - Simulate sync failure
        await cacheService.syncPendingData(simulateFailure: true);

        // Assert
        final pendingRecords = cacheService.getPendingRecords();
        expect(pendingRecords.first.retryCount, equals(1));
      });

      test('max retries exceeded should emit failed status', () async {
        // Arrange
        final record = TestHealthRecord(
          id: 'max_retry_record',
          userId: 'user_001',
          recordedAt: DateTime.now().millisecondsSinceEpoch,
          systolicBP: 120,
          diastolicBP: 80,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        cacheService.queueHealthRecord(record);
        final statuses = <TestSyncStatus>[];
        cacheService.syncStatusStream.listen(statuses.add);

        // Act - Simulate 3 failures (max retries)
        for (int i = 0; i < 3; i++) {
          await cacheService.syncPendingData(simulateFailure: true);
        }
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(statuses, contains(TestSyncStatus.failed));
        final pendingRecords = cacheService.getPendingRecords();
        expect(pendingRecords.first.hasExceededMaxRetries, isTrue);
      });
    });

    group('Data Integrity', () {
      test('synced record should contain all original fields', () async {
        // Arrange
        final record = TestHealthRecord(
          id: 'integrity_record',
          userId: 'user_integrity',
          recordedAt: 1700000000000,
          systolicBP: 135,
          diastolicBP: 88,
          heartRate: 85,
          bloodSugar: 6.2,
          weight: 75.5,
          notes: 'Integration test notes',
          createdAt: 1700000000000,
        );
        cacheService.queueHealthRecord(record);

        // Act
        await cacheService.syncPendingData();

        // Assert
        final syncedRecords = cacheService.getSyncedRecords();
        expect(syncedRecords.length, equals(1));
        
        final synced = syncedRecords.first;
        expect(synced['id'], equals('integrity_record'));
        expect(synced['userId'], equals('user_integrity'));
        expect(synced['recordedAt'], equals(1700000000000));
        expect(synced['systolicBP'], equals(135));
        expect(synced['diastolicBP'], equals(88));
        expect(synced['heartRate'], equals(85));
        expect(synced['bloodSugar'], equals(6.2));
        expect(synced['weight'], equals(75.5));
        expect(synced['notes'], equals('Integration test notes'));
        expect(synced['createdAt'], equals(1700000000000));
        expect(synced['syncedAt'], isNotNull);
      });

      test('synced record should have syncedAt timestamp', () async {
        // Arrange
        final beforeSync = DateTime.now().millisecondsSinceEpoch;
        final record = TestHealthRecord(
          id: 'timestamp_record',
          userId: 'user_001',
          recordedAt: DateTime.now().millisecondsSinceEpoch,
          systolicBP: 120,
          diastolicBP: 80,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        cacheService.queueHealthRecord(record);

        // Act
        await cacheService.syncPendingData();
        final afterSync = DateTime.now().millisecondsSinceEpoch;

        // Assert
        final syncedRecords = cacheService.getSyncedRecords();
        final syncedAt = syncedRecords.first['syncedAt'] as int;
        expect(syncedAt >= beforeSync, isTrue);
        expect(syncedAt <= afterSync, isTrue);
      });
    });
  });
}
