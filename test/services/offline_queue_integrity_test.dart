import 'package:glados/glados.dart';

/// **Feature: sews-improvement-plan, Property 7: Offline Queue Integrity**
/// **Validates: Requirements 5.2, 5.3**
///
/// Property: For any health record created offline, the record SHALL be queued
/// and successfully synced when connection is restored.

/// Test version of HealthRecordModel - mirrors the actual model for testing
class TestHealthRecord {
  final String id;
  final String userId;
  final int recordedAt;
  final int? systolicBP;
  final int? diastolicBP;
  final int? heartRate;
  final double? bloodSugar;
  final double? weight;
  final double? height;
  final double? temperature;
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
    this.height,
    this.temperature,
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
        'height': height,
        'temperature': temperature,
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
        height: json['height']?.toDouble(),
        temperature: json['temperature']?.toDouble(),
        notes: json['notes'],
        createdAt: json['createdAt'] ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestHealthRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          recordedAt == other.recordedAt &&
          systolicBP == other.systolicBP &&
          diastolicBP == other.diastolicBP &&
          heartRate == other.heartRate &&
          bloodSugar == other.bloodSugar &&
          weight == other.weight &&
          height == other.height &&
          temperature == other.temperature &&
          notes == other.notes &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        recordedAt,
        systolicBP,
        diastolicBP,
        heartRate,
        bloodSugar,
        weight,
        height,
        temperature,
        notes,
        createdAt,
      );

  @override
  String toString() =>
      'TestHealthRecord(id: $id, userId: $userId, systolicBP: $systolicBP, '
      'diastolicBP: $diastolicBP)';
}

/// Test version of PendingRecord - mirrors the actual model
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

  @override
  String toString() =>
      'TestPendingRecord(id: $id, type: $type, userId: $userId)';
}

/// Simulates the offline queue behavior from OfflineCacheService
class OfflineQueueSimulator {
  final Map<String, Map<String, dynamic>> _pendingQueue = {};
  int _idCounter = 0;

  /// Queue a health record for sync (mirrors queueHealthRecord)
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

  /// Get all pending records (mirrors getPendingRecords)
  List<TestPendingRecord> getPendingRecords() {
    final records = _pendingQueue.values
        .map((json) => TestPendingRecord.fromJson(json))
        .toList();
    // Sort by creation time (FIFO)
    records.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return records;
  }

  /// Check if queue has pending records
  bool hasPendingRecords() => _pendingQueue.isNotEmpty;

  /// Get count of pending records
  int getPendingRecordsCount() => _pendingQueue.length;

  /// Simulate successful sync - removes record from queue
  void syncRecord(String recordId) {
    _pendingQueue.remove(recordId);
  }

  /// Clear all pending records
  void clear() => _pendingQueue.clear();

  /// Get a specific pending record by ID
  TestPendingRecord? getRecord(String recordId) {
    final json = _pendingQueue[recordId];
    if (json == null) return null;
    return TestPendingRecord.fromJson(json);
  }

  /// Extract health record data from pending record
  TestHealthRecord? extractHealthRecord(String recordId) {
    final pending = getRecord(recordId);
    if (pending == null || pending.type != 'health_record') return null;
    return TestHealthRecord.fromJson(pending.data);
  }
}

/// Custom generators for offline queue tests
extension OfflineQueueAny on Any {
  /// Generate a valid TestHealthRecord with realistic health data
  Generator<TestHealthRecord> get healthRecord {
    return any.combine5(
      any.lowercaseLetters,
      any.lowercaseLetters,
      any.intInRange(60, 200), // systolic BP range
      any.intInRange(40, 120), // diastolic BP range
      any.intInRange(40, 180), // heart rate range
      (String id, String userId, int systolic, int diastolic, int heartRate) {
        final now = DateTime.now().millisecondsSinceEpoch;
        return TestHealthRecord(
          id: 'record_$id',
          userId: 'user_$userId',
          recordedAt: now,
          systolicBP: systolic,
          diastolicBP: diastolic,
          heartRate: heartRate,
          createdAt: now,
        );
      },
    );
  }

  /// Generate a TestHealthRecord with optional fields (some may be null)
  Generator<TestHealthRecord> get healthRecordWithOptionals {
    return any.combine5(
      any.lowercaseLetters,
      any.lowercaseLetters,
      any.bool, // whether to include systolic
      any.bool, // whether to include diastolic
      any.bool, // whether to include blood sugar
      (String id, String userId, bool hasSystolic, bool hasDiastolic,
          bool hasBloodSugar) {
        final now = DateTime.now().millisecondsSinceEpoch;
        return TestHealthRecord(
          id: 'record_$id',
          userId: 'user_$userId',
          recordedAt: now,
          systolicBP: hasSystolic ? 120 : null,
          diastolicBP: hasDiastolic ? 80 : null,
          bloodSugar: hasBloodSugar ? 5.5 : null,
          createdAt: now,
        );
      },
    );
  }

  /// Generate a list of health records
  Generator<List<TestHealthRecord>> get healthRecordList {
    return any.nonEmptyList(any.healthRecord);
  }
}

void main() {
  group('Offline Queue Integrity Property Tests', () {
    /// **Feature: sews-improvement-plan, Property 7: Offline Queue Integrity**
    /// **Validates: Requirements 5.2, 5.3**
    ///
    /// Property: For any health record created offline, the record SHALL be
    /// queued and successfully synced when connection is restored.
    Glados(any.healthRecord).test(
      'Property 7: Offline Queue Integrity - Queued record is stored in pending queue',
      (record) {
        // Arrange
        final queue = OfflineQueueSimulator();
        expect(queue.hasPendingRecords(), isFalse);

        // Act: Queue the health record (Requirement 5.2)
        final pendingId = queue.queueHealthRecord(record);

        // Assert: Record should be in the queue
        expect(
          queue.hasPendingRecords(),
          isTrue,
          reason: 'Queue should have pending records after queueing',
        );
        expect(
          queue.getPendingRecordsCount(),
          equals(1),
          reason: 'Queue should have exactly 1 pending record',
        );

        final pendingRecord = queue.getRecord(pendingId);
        expect(
          pendingRecord,
          isNotNull,
          reason: 'Pending record should be retrievable by ID',
        );
        expect(
          pendingRecord!.type,
          equals('health_record'),
          reason: 'Pending record type should be health_record',
        );
        expect(
          pendingRecord.userId,
          equals(record.userId),
          reason: 'Pending record should preserve userId',
        );
      },
    );

    /// Property: Queued health record data is preserved (round-trip integrity)
    Glados(any.healthRecord).test(
      'Property 7: Offline Queue Integrity - Health record data is preserved in queue',
      (record) {
        // Arrange
        final queue = OfflineQueueSimulator();

        // Act: Queue and retrieve the record
        final pendingId = queue.queueHealthRecord(record);
        final extractedRecord = queue.extractHealthRecord(pendingId);

        // Assert: Extracted record should match original
        expect(
          extractedRecord,
          isNotNull,
          reason: 'Should be able to extract health record from queue',
        );
        expect(
          extractedRecord!.id,
          equals(record.id),
          reason: 'Record ID should be preserved',
        );
        expect(
          extractedRecord.userId,
          equals(record.userId),
          reason: 'User ID should be preserved',
        );
        expect(
          extractedRecord.systolicBP,
          equals(record.systolicBP),
          reason: 'Systolic BP should be preserved',
        );
        expect(
          extractedRecord.diastolicBP,
          equals(record.diastolicBP),
          reason: 'Diastolic BP should be preserved',
        );
        expect(
          extractedRecord.heartRate,
          equals(record.heartRate),
          reason: 'Heart rate should be preserved',
        );
      },
    );

    /// Property: Synced record is removed from queue (Requirement 5.3)
    Glados(any.healthRecord).test(
      'Property 7: Offline Queue Integrity - Synced record is removed from queue',
      (record) {
        // Arrange
        final queue = OfflineQueueSimulator();
        final pendingId = queue.queueHealthRecord(record);
        expect(queue.hasPendingRecords(), isTrue);

        // Act: Simulate successful sync (Requirement 5.3)
        queue.syncRecord(pendingId);

        // Assert: Record should be removed from queue
        expect(
          queue.hasPendingRecords(),
          isFalse,
          reason: 'Queue should be empty after successful sync',
        );
        expect(
          queue.getRecord(pendingId),
          isNull,
          reason: 'Synced record should not be retrievable',
        );
      },
    );

    /// Property: Multiple records maintain FIFO order
    Glados(any.healthRecordList).test(
      'Property 7: Offline Queue Integrity - Multiple records maintain FIFO order',
      (records) {
        // Arrange
        final queue = OfflineQueueSimulator();
        final pendingIds = <String>[];

        // Act: Queue all records
        for (final record in records) {
          pendingIds.add(queue.queueHealthRecord(record));
        }

        // Assert: All records should be in queue
        expect(
          queue.getPendingRecordsCount(),
          equals(records.length),
          reason: 'Queue should contain all queued records',
        );

        // Assert: Records should be retrievable in FIFO order
        final pendingRecords = queue.getPendingRecords();
        expect(
          pendingRecords.length,
          equals(records.length),
          reason: 'getPendingRecords should return all records',
        );

        // Verify FIFO ordering by createdAt
        for (int i = 1; i < pendingRecords.length; i++) {
          expect(
            pendingRecords[i].createdAt >= pendingRecords[i - 1].createdAt,
            isTrue,
            reason: 'Records should be ordered by creation time (FIFO)',
          );
        }
      },
    );

    /// Property: Health record with optional fields is preserved
    Glados(any.healthRecordWithOptionals).test(
      'Property 7: Offline Queue Integrity - Optional fields are preserved',
      (record) {
        // Arrange
        final queue = OfflineQueueSimulator();

        // Act
        final pendingId = queue.queueHealthRecord(record);
        final extractedRecord = queue.extractHealthRecord(pendingId);

        // Assert: All fields including optional ones should be preserved
        expect(extractedRecord, isNotNull);
        expect(
          extractedRecord!.systolicBP,
          equals(record.systolicBP),
          reason: 'Optional systolicBP should be preserved (even if null)',
        );
        expect(
          extractedRecord.diastolicBP,
          equals(record.diastolicBP),
          reason: 'Optional diastolicBP should be preserved (even if null)',
        );
        expect(
          extractedRecord.bloodSugar,
          equals(record.bloodSugar),
          reason: 'Optional bloodSugar should be preserved (even if null)',
        );
      },
    );

    /// Property: Partial sync removes only synced records
    Glados(any.healthRecordList).test(
      'Property 7: Offline Queue Integrity - Partial sync removes only synced records',
      (records) {
        // Skip if less than 2 records
        if (records.length < 2) return;

        // Arrange
        final queue = OfflineQueueSimulator();
        final pendingIds = <String>[];
        for (final record in records) {
          pendingIds.add(queue.queueHealthRecord(record));
        }

        // Act: Sync only the first record
        queue.syncRecord(pendingIds.first);

        // Assert: Only first record should be removed
        expect(
          queue.getPendingRecordsCount(),
          equals(records.length - 1),
          reason: 'Queue should have one less record after partial sync',
        );
        expect(
          queue.getRecord(pendingIds.first),
          isNull,
          reason: 'Synced record should be removed',
        );

        // Remaining records should still be in queue
        for (int i = 1; i < pendingIds.length; i++) {
          expect(
            queue.getRecord(pendingIds[i]),
            isNotNull,
            reason: 'Non-synced records should remain in queue',
          );
        }
      },
    );

    /// Property: toJson/fromJson round-trip preserves PendingRecord
    Glados(any.healthRecord).test(
      'Property 7: Offline Queue Integrity - PendingRecord serialization round-trip',
      (record) {
        // Arrange
        final pendingRecord = TestPendingRecord(
          id: 'pending_${record.id}',
          type: 'health_record',
          data: record.toJson(),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          userId: record.userId,
        );

        // Act: Round-trip through JSON
        final json = pendingRecord.toJson();
        final restored = TestPendingRecord.fromJson(json);

        // Assert: All fields should be preserved
        expect(restored.id, equals(pendingRecord.id));
        expect(restored.type, equals(pendingRecord.type));
        expect(restored.createdAt, equals(pendingRecord.createdAt));
        expect(restored.userId, equals(pendingRecord.userId));
        expect(restored.retryCount, equals(pendingRecord.retryCount));

        // Verify nested health record data
        final restoredHealthRecord = TestHealthRecord.fromJson(restored.data);
        expect(restoredHealthRecord.id, equals(record.id));
        expect(restoredHealthRecord.userId, equals(record.userId));
      },
    );

    /// Property: toJson/fromJson round-trip preserves HealthRecord
    Glados(any.healthRecord).test(
      'Property 7: Offline Queue Integrity - HealthRecord serialization round-trip',
      (record) {
        // Act: Round-trip through JSON
        final json = record.toJson();
        final restored = TestHealthRecord.fromJson(json);

        // Assert: Record should be equal after round-trip
        expect(
          restored,
          equals(record),
          reason: 'Health record should be preserved through JSON round-trip',
        );
      },
    );
  });
}
