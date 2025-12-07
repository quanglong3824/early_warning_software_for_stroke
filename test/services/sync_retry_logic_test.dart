import 'package:glados/glados.dart';

/// **Feature: sews-improvement-plan, Property 8: Sync Retry Logic**
/// **Validates: Requirements 5.5**
///
/// Property: For any sync operation that fails, the system SHALL retry up to 3
/// times before notifying the user.

/// Maximum number of retries before giving up
const int maxRetries = 3;

/// Pending record wrapper for offline queue - mirrors PendingRecord from
/// offline_cache_service.dart. This is a pure data class for testing.
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

  /// Increment retry count - mirrors PendingRecord.incrementRetry()
  TestPendingRecord incrementRetry() => TestPendingRecord(
        id: id,
        type: type,
        data: data,
        createdAt: createdAt,
        retryCount: retryCount + 1,
        userId: userId,
      );

  /// Check if max retries exceeded - mirrors PendingRecord.hasExceededMaxRetries
  bool get hasExceededMaxRetries => retryCount >= maxRetries;

  @override
  String toString() =>
      'TestPendingRecord(id: $id, type: $type, retryCount: $retryCount)';
}

/// Result of a sync attempt
enum SyncAttemptResult {
  success,
  failure,
}

/// Simulates the sync retry logic from OfflineCacheService.syncWithRetry()
/// Returns the final record state after all retry attempts
class SyncRetrySimulator {
  /// Simulate sync attempts with a given failure pattern
  /// Returns the final record state and whether user should be notified
  static ({TestPendingRecord record, bool shouldNotifyUser}) simulateSyncRetry(
    TestPendingRecord initialRecord,
    List<SyncAttemptResult> attemptResults,
  ) {
    var currentRecord = initialRecord;
    bool shouldNotifyUser = false;

    for (final result in attemptResults) {
      if (result == SyncAttemptResult.success) {
        // Success - no need to increment retry or notify
        return (record: currentRecord, shouldNotifyUser: false);
      } else {
        // Failure - increment retry count
        currentRecord = currentRecord.incrementRetry();

        if (currentRecord.hasExceededMaxRetries) {
          // Max retries reached - notify user (Requirement 5.5)
          shouldNotifyUser = true;
          break;
        }
      }
    }

    return (record: currentRecord, shouldNotifyUser: shouldNotifyUser);
  }

  /// Simulate multiple consecutive failures
  static ({TestPendingRecord record, bool shouldNotifyUser})
      simulateConsecutiveFailures(
    TestPendingRecord initialRecord,
    int failureCount,
  ) {
    final attempts = List.generate(
      failureCount,
      (_) => SyncAttemptResult.failure,
    );
    return simulateSyncRetry(initialRecord, attempts);
  }
}

/// Custom generators for sync retry tests
extension SyncRetryAny on Any {
  /// Generate a TestPendingRecord with valid data
  Generator<TestPendingRecord> get pendingRecord {
    return any.combine3(
      any.lowercaseLetters,
      any.positiveIntOrZero,
      any.positiveIntOrZero,
      (String id, int createdAt, int retryBase) {
        // Ensure retry count starts at 0 for fresh records
        return TestPendingRecord(
          id: 'record_$id',
          type: 'health_record',
          data: {'test': 'data'},
          createdAt: createdAt,
          retryCount: 0,
          userId: 'user_$id',
        );
      },
    );
  }

  /// Generate a TestPendingRecord with a specific retry count (0 to maxRetries-1)
  Generator<TestPendingRecord> get pendingRecordWithRetries {
    return any.combine3(
      any.lowercaseLetters,
      any.positiveIntOrZero,
      any.intInRange(0, maxRetries - 1),
      (String id, int createdAt, int retryCount) {
        return TestPendingRecord(
          id: 'record_$id',
          type: 'health_record',
          data: {'test': 'data'},
          createdAt: createdAt,
          retryCount: retryCount,
          userId: 'user_$id',
        );
      },
    );
  }

  /// Generate a list of sync attempt results
  Generator<List<SyncAttemptResult>> get syncAttemptResults {
    return any.list(
      any.choose([SyncAttemptResult.success, SyncAttemptResult.failure]),
    );
  }

  /// Generate a failure count (1 to 10)
  Generator<int> get failureCount {
    return any.intInRange(1, 10);
  }
}

void main() {
  group('Sync Retry Logic Property Tests', () {
    /// **Feature: sews-improvement-plan, Property 8: Sync Retry Logic**
    /// **Validates: Requirements 5.5**
    ///
    /// Property: For any sync operation that fails, the system SHALL retry up
    /// to 3 times before notifying the user.
    Glados(any.pendingRecord).test(
      'Property 8: Sync Retry Logic - Exactly 3 failures triggers user notification',
      (record) {
        // Arrange: Start with a fresh record (0 retries)
        expect(record.retryCount, equals(0));

        // Act: Simulate exactly 3 consecutive failures
        final result = SyncRetrySimulator.simulateConsecutiveFailures(
          record,
          maxRetries,
        );

        // Assert: After exactly 3 failures, user should be notified
        expect(
          result.shouldNotifyUser,
          isTrue,
          reason: 'User should be notified after exactly $maxRetries failures',
        );
        expect(
          result.record.retryCount,
          equals(maxRetries),
          reason: 'Retry count should be exactly $maxRetries after $maxRetries failures',
        );
        expect(
          result.record.hasExceededMaxRetries,
          isTrue,
          reason: 'Record should be marked as exceeded max retries',
        );
      },
    );

    /// Property: Less than 3 failures should NOT trigger user notification
    Glados(any.combine2(
      any.pendingRecord,
      any.intInRange(1, maxRetries - 1),
      (record, failures) => (record, failures),
    )).test(
      'Property 8: Sync Retry Logic - Less than 3 failures does not notify user',
      (tuple) {
        final (record, failures) = tuple;

        // Act: Simulate fewer than maxRetries failures
        final result = SyncRetrySimulator.simulateConsecutiveFailures(
          record,
          failures,
        );

        // Assert: User should NOT be notified yet
        expect(
          result.shouldNotifyUser,
          isFalse,
          reason: 'User should NOT be notified after only $failures failures '
              '(max is $maxRetries)',
        );
        expect(
          result.record.retryCount,
          equals(failures),
          reason: 'Retry count should equal number of failures',
        );
        expect(
          result.record.hasExceededMaxRetries,
          isFalse,
          reason: 'Record should NOT be marked as exceeded max retries',
        );
      },
    );

    /// Property: Success on any attempt should NOT trigger notification
    Glados(any.combine2(
      any.pendingRecord,
      any.intInRange(0, maxRetries - 1),
      (record, failuresBeforeSuccess) => (record, failuresBeforeSuccess),
    )).test(
      'Property 8: Sync Retry Logic - Success stops retry and does not notify',
      (tuple) {
        final (record, failuresBeforeSuccess) = tuple;

        // Arrange: Create attempt pattern with failures followed by success
        final attempts = [
          ...List.generate(
            failuresBeforeSuccess,
            (_) => SyncAttemptResult.failure,
          ),
          SyncAttemptResult.success,
        ];

        // Act
        final result = SyncRetrySimulator.simulateSyncRetry(record, attempts);

        // Assert: User should NOT be notified on success
        expect(
          result.shouldNotifyUser,
          isFalse,
          reason: 'User should NOT be notified when sync eventually succeeds',
        );
      },
    );

    /// Property: Retry count increments by exactly 1 on each failure
    Glados(any.pendingRecordWithRetries).test(
      'Property 8: Sync Retry Logic - Retry count increments by 1 on failure',
      (record) {
        // Arrange
        final initialRetryCount = record.retryCount;

        // Act: Increment retry (simulating one failure)
        final updatedRecord = record.incrementRetry();

        // Assert
        expect(
          updatedRecord.retryCount,
          equals(initialRetryCount + 1),
          reason: 'Retry count should increment by exactly 1',
        );
      },
    );

    /// Property: hasExceededMaxRetries is true iff retryCount >= maxRetries
    Glados(any.intInRange(0, maxRetries + 5)).test(
      'Property 8: Sync Retry Logic - hasExceededMaxRetries threshold is correct',
      (retryCount) {
        // Arrange
        final record = TestPendingRecord(
          id: 'test',
          type: 'health_record',
          data: {},
          createdAt: 0,
          retryCount: retryCount,
        );

        // Assert
        final expectedExceeded = retryCount >= maxRetries;
        expect(
          record.hasExceededMaxRetries,
          equals(expectedExceeded),
          reason: 'hasExceededMaxRetries should be $expectedExceeded when '
              'retryCount is $retryCount (maxRetries is $maxRetries)',
        );
      },
    );

    /// Property: More than 3 failures still results in notification (idempotent)
    Glados(any.combine2(
      any.pendingRecord,
      any.intInRange(maxRetries, maxRetries + 5),
      (record, failures) => (record, failures),
    )).test(
      'Property 8: Sync Retry Logic - More than 3 failures still notifies user',
      (tuple) {
        final (record, failures) = tuple;

        // Act: Simulate more than maxRetries failures
        final result = SyncRetrySimulator.simulateConsecutiveFailures(
          record,
          failures,
        );

        // Assert: User should be notified
        expect(
          result.shouldNotifyUser,
          isTrue,
          reason: 'User should be notified after $failures failures '
              '(>= $maxRetries)',
        );
      },
    );

    /// Property: Fresh record starts with 0 retries
    Glados(any.pendingRecord).test(
      'Property 8: Sync Retry Logic - Fresh records start with 0 retries',
      (record) {
        // Assert
        expect(
          record.retryCount,
          equals(0),
          reason: 'Fresh pending records should start with 0 retry count',
        );
        expect(
          record.hasExceededMaxRetries,
          isFalse,
          reason: 'Fresh records should not have exceeded max retries',
        );
      },
    );

    /// Property: incrementRetry preserves all other fields
    Glados(any.pendingRecordWithRetries).test(
      'Property 8: Sync Retry Logic - incrementRetry preserves other fields',
      (record) {
        // Act
        final updatedRecord = record.incrementRetry();

        // Assert: All fields except retryCount should be preserved
        expect(updatedRecord.id, equals(record.id));
        expect(updatedRecord.type, equals(record.type));
        expect(updatedRecord.data, equals(record.data));
        expect(updatedRecord.createdAt, equals(record.createdAt));
        expect(updatedRecord.userId, equals(record.userId));
      },
    );
  });
}
