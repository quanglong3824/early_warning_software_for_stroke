import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

/// Model for review statistics
class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> distribution; // star -> count

  const ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    final dist = <int, int>{};
    if (json['distribution'] != null) {
      final distData = json['distribution'];
      if (distData is Map) {
        distData.forEach((key, value) {
          final star = int.tryParse(key.toString());
          if (star != null && value is int) {
            dist[star] = value;
          }
        });
      }
    }
    // Ensure all star levels exist
    for (int i = 1; i <= 5; i++) {
      dist.putIfAbsent(i, () => 0);
    }

    return ReviewStats(
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] as int? ?? 0,
      distribution: dist,
    );
  }

  Map<String, dynamic> toJson() => {
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'distribution': distribution.map((k, v) => MapEntry(k.toString(), v)),
      };

  /// Create empty stats
  factory ReviewStats.empty() {
    return ReviewStats(
      averageRating: 0.0,
      totalReviews: 0,
      distribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
    );
  }
}


/// Model for a single review
class ReviewModel {
  final String reviewId;
  final String doctorId;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final int rating;
  final String? comment;
  final String? doctorResponse;
  final int? responseAt;
  final bool isAnonymous;
  final int createdAt;

  const ReviewModel({
    required this.reviewId,
    required this.doctorId,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.rating,
    this.comment,
    this.doctorResponse,
    this.responseAt,
    required this.isAnonymous,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(String id, Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: id,
      doctorId: json['doctorId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String?,
      userAvatar: json['userAvatar'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String?,
      doctorResponse: json['doctorResponse'] as String?,
      responseAt: json['responseAt'] as int?,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      createdAt: json['createdAt'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'reviewId': reviewId,
        'doctorId': doctorId,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'rating': rating,
        'comment': comment,
        'doctorResponse': doctorResponse,
        'responseAt': responseAt,
        'isAnonymous': isAnonymous,
        'createdAt': createdAt,
      };

  /// Get display name (anonymous or actual name)
  String get displayName {
    if (isAnonymous) return 'Ẩn danh';
    return userName ?? 'Bệnh nhân';
  }

  /// Check if review has doctor response
  bool get hasResponse => doctorResponse != null && doctorResponse!.isNotEmpty;

  /// Create a copy with doctor response
  ReviewModel copyWithResponse(String response, int responseTime) {
    return ReviewModel(
      reviewId: reviewId,
      doctorId: doctorId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      rating: rating,
      comment: comment,
      doctorResponse: response,
      responseAt: responseTime,
      isAnonymous: isAnonymous,
      createdAt: createdAt,
    );
  }
}


/// Service quản lý đánh giá bác sĩ
/// Implements Requirements: 7.1, 7.2, 7.3, 7.4, 7.5
class DoctorReviewService {
  static final DoctorReviewService _instance = DoctorReviewService._internal();
  factory DoctorReviewService() => _instance;
  DoctorReviewService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Lấy thống kê đánh giá theo thời gian thực
  /// Requirements: 7.1, 7.3
  Stream<ReviewStats> getReviewStats(String doctorId) {
    return _db.child('doctor_reviews').child(doctorId).onValue.asyncMap((event) async {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return ReviewStats.empty();
      }

      final dynamic value = event.snapshot.value;
      Map<dynamic, dynamic> data = {};

      if (value is Map) {
        data = value;
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          if (value[i] != null) {
            data[i.toString()] = value[i];
          }
        }
      }

      // Calculate stats from reviews
      final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      double totalRating = 0;
      int count = 0;

      for (var entry in data.entries) {
        if (entry.value == null) continue;
        final reviewData = Map<String, dynamic>.from(entry.value as Map);
        final rating = (reviewData['rating'] as num?)?.toInt() ?? 0;

        if (rating >= 1 && rating <= 5) {
          distribution[rating] = (distribution[rating] ?? 0) + 1;
          totalRating += rating;
          count++;
        }
      }

      final averageRating = count > 0 ? totalRating / count : 0.0;

      return ReviewStats(
        averageRating: averageRating,
        totalReviews: count,
        distribution: distribution,
      );
    });
  }

  /// Lấy danh sách đánh giá với sorting theo ngày
  /// Requirements: 7.2
  Stream<List<ReviewModel>> getReviews(String doctorId) {
    return _db
        .child('doctor_reviews')
        .child(doctorId)
        .orderByChild('createdAt')
        .onValue
        .asyncMap((event) async {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <ReviewModel>[];
      }

      final dynamic value = event.snapshot.value;
      Map<dynamic, dynamic> data = {};

      if (value is Map) {
        data = value;
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          if (value[i] != null) {
            data[i.toString()] = value[i];
          }
        }
      }

      final List<ReviewModel> reviews = [];

      for (var entry in data.entries) {
        if (entry.value == null) continue;
        final reviewData = Map<String, dynamic>.from(entry.value as Map);
        reviewData['doctorId'] = doctorId;

        // Fetch user name if not anonymous
        final isAnonymous = reviewData['isAnonymous'] as bool? ?? false;
        if (!isAnonymous) {
          final userId = reviewData['userId'] as String?;
          if (userId != null && reviewData['userName'] == null) {
            try {
              final userSnapshot = await _db.child('users').child(userId).get();
              if (userSnapshot.exists && userSnapshot.value != null) {
                final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
                reviewData['userName'] = userData['name'];
                reviewData['userAvatar'] = userData['avatarUrl'] ?? userData['photoURL'];
              }
            } catch (e) {
              print('Error fetching user $userId: $e');
            }
          }
        }

        reviews.add(ReviewModel.fromJson(entry.key.toString(), reviewData));
      }

      // Sort by createdAt descending (newest first)
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return reviews;
    });
  }


  /// Lấy phân bố đánh giá theo sao
  /// Requirements: 7.4
  Stream<Map<int, int>> getRatingDistribution(String doctorId) {
    return getReviewStats(doctorId).map((stats) => stats.distribution);
  }

  /// Phản hồi đánh giá
  /// Requirements: 7.5
  Future<bool> respondToReview(String doctorId, String reviewId, String response) async {
    try {
      final responseTime = DateTime.now().millisecondsSinceEpoch;
      
      await _db.child('doctor_reviews').child(doctorId).child(reviewId).update({
        'doctorResponse': response,
        'responseAt': responseTime,
      });

      // Optionally notify the patient about the response
      final reviewSnapshot = await _db.child('doctor_reviews').child(doctorId).child(reviewId).get();
      if (reviewSnapshot.exists && reviewSnapshot.value != null) {
        final reviewData = Map<String, dynamic>.from(reviewSnapshot.value as Map);
        final userId = reviewData['userId'] as String?;
        
        if (userId != null) {
          // Create notification for the patient
          await _db.child('notifications').push().set({
            'userId': userId,
            'type': 'review_response',
            'title': 'Bác sĩ đã phản hồi đánh giá của bạn',
            'message': response.length > 100 ? '${response.substring(0, 100)}...' : response,
            'data': {
              'doctorId': doctorId,
              'reviewId': reviewId,
            },
            'isRead': false,
            'createdAt': ServerValue.timestamp,
          });
        }
      }

      return true;
    } catch (e) {
      print('Error responding to review: $e');
      return false;
    }
  }

  /// Tính toán rating trung bình từ danh sách reviews
  /// Utility function for Requirements: 7.1, 7.3
  double calculateAverageRating(List<ReviewModel> reviews) {
    if (reviews.isEmpty) return 0.0;
    
    final totalRating = reviews.fold<int>(0, (sum, review) => sum + review.rating);
    return totalRating / reviews.length;
  }

  /// Tính toán phân bố rating từ danh sách reviews
  /// Utility function for Requirements: 7.4
  Map<int, int> calculateRatingDistribution(List<ReviewModel> reviews) {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    
    for (final review in reviews) {
      if (review.rating >= 1 && review.rating <= 5) {
        distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
      }
    }
    
    return distribution;
  }

  /// Lấy một review cụ thể
  Future<ReviewModel?> getReview(String doctorId, String reviewId) async {
    try {
      final snapshot = await _db.child('doctor_reviews').child(doctorId).child(reviewId).get();
      
      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }

      final reviewData = Map<String, dynamic>.from(snapshot.value as Map);
      reviewData['doctorId'] = doctorId;

      // Fetch user name if not anonymous
      final isAnonymous = reviewData['isAnonymous'] as bool? ?? false;
      if (!isAnonymous) {
        final userId = reviewData['userId'] as String?;
        if (userId != null) {
          try {
            final userSnapshot = await _db.child('users').child(userId).get();
            if (userSnapshot.exists && userSnapshot.value != null) {
              final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
              reviewData['userName'] = userData['name'];
              reviewData['userAvatar'] = userData['avatarUrl'] ?? userData['photoURL'];
            }
          } catch (e) {
            print('Error fetching user $userId: $e');
          }
        }
      }

      return ReviewModel.fromJson(reviewId, reviewData);
    } catch (e) {
      print('Error getting review: $e');
      return null;
    }
  }

  /// Lấy số lượng đánh giá chưa phản hồi
  Stream<int> getUnrespondedReviewCount(String doctorId) {
    return _db.child('doctor_reviews').child(doctorId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return 0;
      }

      final dynamic value = event.snapshot.value;
      Map<dynamic, dynamic> data = {};

      if (value is Map) {
        data = value;
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          if (value[i] != null) {
            data[i.toString()] = value[i];
          }
        }
      }

      int count = 0;
      for (var entry in data.entries) {
        if (entry.value == null) continue;
        final reviewData = Map<String, dynamic>.from(entry.value as Map);
        final doctorResponse = reviewData['doctorResponse'] as String?;
        
        if (doctorResponse == null || doctorResponse.isEmpty) {
          count++;
        }
      }
      return count;
    });
  }
}
