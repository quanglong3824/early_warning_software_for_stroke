import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class HealthPlanService {
  static final HealthPlanService _instance = HealthPlanService._internal();
  factory HealthPlanService() => _instance;
  HealthPlanService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  String _getDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// Get daily checklist status
  Stream<Map<String, bool>> getDailyChecklist(String userId) {
    final dateKey = _getDateKey();
    return _db
        .child('health_plans')
        .child(userId)
        .child(dateKey)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return data.map((key, value) => MapEntry(key, value as bool));
      }
      return {};
    });
  }

  /// Toggle checklist item
  Future<void> toggleItem(String userId, String itemId, bool isChecked) async {
    final dateKey = _getDateKey();
    try {
      await _db
          .child('health_plans')
          .child(userId)
          .child(dateKey)
          .update({itemId: isChecked});
    } catch (e) {
      print('Error toggling health plan item: $e');
    }
  }
}
