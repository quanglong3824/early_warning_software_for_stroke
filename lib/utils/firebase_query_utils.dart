import 'package:firebase_database/firebase_database.dart';

/// Firebase query optimization utilities
/// Requirements: 10.5 - Use indexed queries for optimal performance

/// Query builder for optimized Firebase queries
class FirebaseQueryBuilder {
  final DatabaseReference _ref;
  Query? _query;

  FirebaseQueryBuilder(this._ref) {
    _query = _ref;
  }

  /// Order by a specific child key (should be indexed)
  FirebaseQueryBuilder orderByChild(String key) {
    _query = _query!.orderByChild(key);
    return this;
  }

  /// Order by key
  FirebaseQueryBuilder orderByKey() {
    _query = _query!.orderByKey();
    return this;
  }

  /// Order by value
  FirebaseQueryBuilder orderByValue() {
    _query = _query!.orderByValue();
    return this;
  }

  /// Filter to items equal to a value
  FirebaseQueryBuilder equalTo(Object? value, {String? key}) {
    _query = _query!.equalTo(value, key: key);
    return this;
  }

  /// Filter to items starting at a value
  FirebaseQueryBuilder startAt(Object? value, {String? key}) {
    _query = _query!.startAt(value, key: key);
    return this;
  }

  /// Filter to items ending at a value
  FirebaseQueryBuilder endAt(Object? value, {String? key}) {
    _query = _query!.endAt(value, key: key);
    return this;
  }

  /// Limit to first N items
  FirebaseQueryBuilder limitToFirst(int limit) {
    _query = _query!.limitToFirst(limit);
    return this;
  }

  /// Limit to last N items
  FirebaseQueryBuilder limitToLast(int limit) {
    _query = _query!.limitToLast(limit);
    return this;
  }

  /// Build and return the query
  Query build() => _query!;

  /// Execute the query and get snapshot
  Future<DataSnapshot> get() => _query!.get();

  /// Listen to query changes
  Stream<DatabaseEvent> onValue() => _query!.onValue;
}

/// Extension methods for DatabaseReference
extension DatabaseReferenceExtension on DatabaseReference {
  /// Create a query builder for this reference
  FirebaseQueryBuilder queryBuilder() => FirebaseQueryBuilder(this);
}

/// Optimized query patterns for common use cases
class OptimizedQueries {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Get user's appointments with pagination
  /// Uses index: appointments/.indexOn: ["userId", "appointmentDate"]
  static Query getUserAppointments(String userId, {int limit = 20, int? startAfter}) {
    Query query = _database
        .child('appointments')
        .orderByChild('userId')
        .equalTo(userId);
    
    if (limit > 0) {
      query = query.limitToLast(limit);
    }
    
    return query;
  }

  /// Get user's prescriptions with pagination
  /// Uses index: prescriptions/.indexOn: ["userId", "createdAt"]
  static Query getUserPrescriptions(String userId, {int limit = 20}) {
    return _database
        .child('prescriptions')
        .orderByChild('userId')
        .equalTo(userId)
        .limitToLast(limit);
  }

  /// Get published articles with pagination
  /// Uses index: knowledge_articles/.indexOn: ["isPublished", "publishedAt"]
  static Query getPublishedArticles({int limit = 20, int? endBefore}) {
    Query query = _database
        .child('knowledge_articles')
        .orderByChild('publishedAt');
    
    if (endBefore != null) {
      query = query.endBefore(endBefore);
    }
    
    return query.limitToLast(limit);
  }

  /// Get user's health records with date range
  /// Uses index: health_records/.indexOn: ["userId", "recordDate"]
  static Query getUserHealthRecords(
    String userId, {
    int? startDate,
    int? endDate,
    int limit = 50,
  }) {
    Query query = _database
        .child('health_records')
        .orderByChild('userId')
        .equalTo(userId);
    
    return query.limitToLast(limit);
  }

  /// Get active SOS requests for doctor
  /// Uses index: sos_requests/.indexOn: ["status", "createdAt"]
  static Query getActiveSosRequests({int limit = 20}) {
    return _database
        .child('sos_requests')
        .orderByChild('status')
        .equalTo('pending')
        .limitToLast(limit);
  }

  /// Get doctor's patients
  /// Uses index: appointments/.indexOn: ["doctorId"]
  static Query getDoctorPatients(String doctorId, {int limit = 50}) {
    return _database
        .child('appointments')
        .orderByChild('doctorId')
        .equalTo(doctorId)
        .limitToLast(limit);
  }

  /// Get user's notifications
  /// Uses index: notifications/.indexOn: ["userId", "createdAt"]
  static Query getUserNotifications(String userId, {int limit = 30}) {
    return _database
        .child('notifications')
        .orderByChild('userId')
        .equalTo(userId)
        .limitToLast(limit);
  }

  /// Get unread notifications count
  /// Uses index: notifications/.indexOn: ["userId", "isRead"]
  static Query getUnreadNotifications(String userId) {
    return _database
        .child('notifications')
        .orderByChild('userId')
        .equalTo(userId);
  }

  /// Get user's pharmacy orders
  /// Uses index: pharmacy_orders/.indexOn: ["userId", "createdAt"]
  static Query getUserOrders(String userId, {int limit = 20}) {
    return _database
        .child('pharmacy_orders')
        .orderByChild('userId')
        .equalTo(userId)
        .limitToLast(limit);
  }

  /// Get active medications
  /// Uses index: medications/.indexOn: ["isActive"]
  static Query getActiveMedications({int limit = 100}) {
    return _database
        .child('medications')
        .orderByChild('isActive')
        .equalTo(true)
        .limitToLast(limit);
  }

  /// Get user's reminders
  /// Uses index: reminders/.indexOn: ["userId", "isActive"]
  static Query getUserReminders(String userId) {
    return _database
        .child('reminders')
        .orderByChild('userId')
        .equalTo(userId);
  }

  /// Get family members
  /// Uses index: family_members/.indexOn: ["userId"]
  static Query getFamilyMembers(String userId) {
    return _database
        .child('family_members')
        .orderByChild('userId')
        .equalTo(userId);
  }

  /// Get user's predictions
  /// Uses index: predictions/.indexOn: ["userId", "createdAt"]
  static Query getUserPredictions(String userId, {int limit = 20}) {
    return _database
        .child('predictions')
        .orderByChild('userId')
        .equalTo(userId)
        .limitToLast(limit);
  }

  /// Get doctor's schedule for a date
  /// Uses index: doctor_schedules/.indexOn: ["doctorId", "date"]
  static Query getDoctorSchedule(String doctorId, String date) {
    return _database
        .child('doctor_schedules')
        .orderByChild('doctorId')
        .equalTo(doctorId);
  }

  /// Get forum threads by category
  /// Uses index: forum_threads/.indexOn: ["category", "createdAt"]
  static Query getForumThreads(String category, {int limit = 20}) {
    return _database
        .child('forum_threads')
        .orderByChild('category')
        .equalTo(category)
        .limitToLast(limit);
  }

  /// Get thread comments
  /// Uses index: forum_comments/.indexOn: ["threadId", "createdAt"]
  static Query getThreadComments(String threadId, {int limit = 50}) {
    return _database
        .child('forum_comments')
        .orderByChild('threadId')
        .equalTo(threadId)
        .limitToLast(limit);
  }
}

/// Query result caching for frequently accessed data
class QueryCache {
  static final Map<String, _CacheEntry> _cache = {};
  static const Duration _defaultTtl = Duration(minutes: 5);

  /// Get cached data or fetch from query
  static Future<DataSnapshot?> getOrFetch(
    String cacheKey,
    Query query, {
    Duration? ttl,
  }) async {
    final entry = _cache[cacheKey];
    final now = DateTime.now();

    if (entry != null && now.isBefore(entry.expiresAt)) {
      return entry.snapshot;
    }

    try {
      final snapshot = await query.get();
      _cache[cacheKey] = _CacheEntry(
        snapshot: snapshot,
        expiresAt: now.add(ttl ?? _defaultTtl),
      );
      return snapshot;
    } catch (e) {
      // Return cached data if available, even if expired
      return entry?.snapshot;
    }
  }

  /// Invalidate a specific cache entry
  static void invalidate(String cacheKey) {
    _cache.remove(cacheKey);
  }

  /// Invalidate all cache entries matching a prefix
  static void invalidatePrefix(String prefix) {
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Clear all cache
  static void clearAll() {
    _cache.clear();
  }
}

class _CacheEntry {
  final DataSnapshot snapshot;
  final DateTime expiresAt;

  _CacheEntry({required this.snapshot, required this.expiresAt});
}
