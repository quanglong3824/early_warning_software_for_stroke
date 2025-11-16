import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AdminUserService {
  static final AdminUserService _instance = AdminUserService._internal();
  factory AdminUserService() => _instance;
  AdminUserService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Lấy danh sách tất cả users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _database.child('users').get();
      
      if (!snapshot.exists) {
        return [];
      }

      final usersMap = Map<String, dynamic>.from(snapshot.value as Map);
      final usersList = <Map<String, dynamic>>[];

      usersMap.forEach((key, value) {
        final userData = Map<String, dynamic>.from(value as Map);
        userData['uid'] = key;
        usersList.add(userData);
      });

      // Sắp xếp theo thời gian tạo (mới nhất trước)
      usersList.sort((a, b) {
        final aTime = a['createdAt'] ?? 0;
        final bTime = b['createdAt'] ?? 0;
        return bTime.compareTo(aTime);
      });

      return usersList;
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  /// Lấy danh sách users theo role
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      print('🔍 Fetching users with role: $role');
      
      final snapshot = await _database
          .child('users')
          .orderByChild('role')
          .equalTo(role)
          .get();
      
      print('📊 Snapshot exists: ${snapshot.exists}');
      
      if (!snapshot.exists) {
        print('⚠️ No users found with role: $role');
        return [];
      }

      final usersMap = Map<String, dynamic>.from(snapshot.value as Map);
      print('📦 Found ${usersMap.length} users in database');
      
      final usersList = <Map<String, dynamic>>[];

      usersMap.forEach((key, value) {
        final userData = Map<String, dynamic>.from(value as Map);
        userData['uid'] = key;
        usersList.add(userData);
        print('👤 User: ${userData['name']} (${userData['email']})');
      });

      print('✅ Returning ${usersList.length} users');
      return usersList;
    } catch (e) {
      print('❌ Error getting users by role: $e');
      return [];
    }
  }

  /// Đếm số lượng users theo role
  Future<int> countUsersByRole(String role) async {
    try {
      final users = await getUsersByRole(role);
      return users.length;
    } catch (e) {
      print('Error counting users: $e');
      return 0;
    }
  }

  /// Đếm tổng số users
  Future<int> countAllUsers() async {
    try {
      final snapshot = await _database.child('users').get();
      if (!snapshot.exists) return 0;
      
      final usersMap = Map<String, dynamic>.from(snapshot.value as Map);
      return usersMap.length;
    } catch (e) {
      print('Error counting all users: $e');
      return 0;
    }
  }

  /// Lấy thông tin chi tiết user
  Future<Map<String, dynamic>?> getUserDetail(String userId) async {
    try {
      final snapshot = await _database.child('users').child(userId).get();
      
      if (!snapshot.exists) {
        return null;
      }

      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      userData['uid'] = userId;
      return userData;
    } catch (e) {
      print('Error getting user detail: $e');
      return null;
    }
  }

  /// Chặn/Mở chặn user
  Future<Map<String, dynamic>> toggleUserStatus(String userId, bool isBlocked) async {
    try {
      await _database.child('users').child(userId).update({
        'isBlocked': isBlocked,
        'blockedAt': isBlocked ? ServerValue.timestamp : null,
        'updatedAt': ServerValue.timestamp,
      });

      return {
        'success': true,
        'message': isBlocked ? 'Đã chặn người dùng' : 'Đã mở chặn người dùng',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: $e',
      };
    }
  }

  /// Xóa user (soft delete - chỉ đánh dấu)
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      await _database.child('users').child(userId).update({
        'isDeleted': true,
        'deletedAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      return {
        'success': true,
        'message': 'Đã xóa người dùng',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: $e',
      };
    }
  }

  /// Xóa user vĩnh viễn (hard delete)
  Future<Map<String, dynamic>> permanentDeleteUser(String userId) async {
    try {
      // Xóa trong Realtime Database
      await _database.child('users').child(userId).remove();

      // Note: Không thể xóa user trong Firebase Auth từ admin
      // Cần sử dụng Firebase Admin SDK hoặc Cloud Functions

      return {
        'success': true,
        'message': 'Đã xóa người dùng vĩnh viễn khỏi database',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: $e',
      };
    }
  }

  /// Tìm kiếm users
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final allUsers = await getAllUsers();
      
      if (query.isEmpty) {
        return allUsers;
      }

      final lowerQuery = query.toLowerCase();
      
      return allUsers.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final phone = (user['phone'] ?? '').toString().toLowerCase();
        
        return name.contains(lowerQuery) ||
               email.contains(lowerQuery) ||
               phone.contains(lowerQuery);
      }).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// Lọc users theo trạng thái
  Future<List<Map<String, dynamic>>> filterUsersByStatus(String status) async {
    try {
      final allUsers = await getAllUsers();
      
      if (status == 'all') {
        return allUsers;
      } else if (status == 'active') {
        return allUsers.where((user) => 
          (user['isBlocked'] ?? false) == false &&
          (user['isDeleted'] ?? false) == false
        ).toList();
      } else if (status == 'blocked') {
        return allUsers.where((user) => 
          (user['isBlocked'] ?? false) == true
        ).toList();
      } else if (status == 'deleted') {
        return allUsers.where((user) => 
          (user['isDeleted'] ?? false) == true
        ).toList();
      }
      
      return allUsers;
    } catch (e) {
      print('Error filtering users: $e');
      return [];
    }
  }

  /// Tạo user mới
  Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    String? phone,
    required String password,
    String role = 'user',
  }) async {
    try {
      // Validate
      if (name.trim().isEmpty) {
        return {'success': false, 'message': 'Vui lòng nhập họ tên'};
      }
      if (email.trim().isEmpty) {
        return {'success': false, 'message': 'Vui lòng nhập email'};
      }
      if (password.length < 6) {
        return {'success': false, 'message': 'Mật khẩu phải có ít nhất 6 ký tự'};
      }

      // Tạo tài khoản Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);

      // Mã hóa mật khẩu
      final hashedPassword = _hashPassword(password);

      // Lưu vào Realtime Database
      await _database.child('users').child(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'password': hashedPassword,
        'role': role,
        'loginMethod': 'email',
        'isBlocked': false,
        'isDeleted': false,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      // Đăng xuất sau khi tạo
      await _auth.signOut();

      return {
        'success': true,
        'message': 'Tạo user thành công',
        'userId': userCredential.user!.uid,
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email đã được sử dụng';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ';
          break;
        case 'weak-password':
          message = 'Mật khẩu quá yếu';
          break;
        default:
          message = 'Lỗi: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Cập nhật thông tin user
  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      // Validate
      if (data.containsKey('name') && (data['name'] as String).trim().isEmpty) {
        return {'success': false, 'message': 'Vui lòng nhập họ tên'};
      }
      if (data.containsKey('email') && (data['email'] as String).trim().isEmpty) {
        return {'success': false, 'message': 'Vui lòng nhập email'};
      }

      data['updatedAt'] = ServerValue.timestamp;
      
      await _database.child('users').child(userId).update(data);

      return {
        'success': true,
        'message': 'Đã cập nhật thông tin người dùng',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: $e',
      };
    }
  }

  /// Helper: Hash password (same as AuthService)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Lấy thống kê users
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      print('📊 Getting user stats...');
      final allUsers = await getAllUsers();
      print('📦 Total users in database: ${allUsers.length}');
      
      final totalUsers = allUsers.length;
      final activeUsers = allUsers.where((u) => 
        (u['isBlocked'] ?? false) == false &&
        (u['isDeleted'] ?? false) == false
      ).length;
      final blockedUsers = allUsers.where((u) => 
        (u['isBlocked'] ?? false) == true
      ).length;
      final deletedUsers = allUsers.where((u) => 
        (u['isDeleted'] ?? false) == true
      ).length;

      // Đếm theo role
      final userRole = allUsers.where((u) => u['role'] == 'user').length;
      final doctorRole = allUsers.where((u) => u['role'] == 'doctor').length;
      final adminRole = allUsers.where((u) => u['role'] == 'admin').length;

      print('👥 Users by role: user=$userRole, doctor=$doctorRole, admin=$adminRole');

      // Users mới trong 7 ngày
      final now = DateTime.now().millisecondsSinceEpoch;
      final sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000);
      final newUsers = allUsers.where((u) {
        final createdAt = u['createdAt'] ?? 0;
        return createdAt > sevenDaysAgo;
      }).length;

      final stats = {
        'total': totalUsers,
        'active': activeUsers,
        'blocked': blockedUsers,
        'deleted': deletedUsers,
        'users': userRole,
        'doctors': doctorRole,
        'admins': adminRole,
        'newThisWeek': newUsers,
      };
      
      print('✅ Stats calculated: $stats');
      return stats;
    } catch (e) {
      print('❌ Error getting user stats: $e');
      return {
        'total': 0,
        'active': 0,
        'blocked': 0,
        'deleted': 0,
        'users': 0,
        'doctors': 0,
        'admins': 0,
        'newThisWeek': 0,
      };
    }
  }

  /// Format timestamp thành string
  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  /// Format timestamp thành relative time
  String formatRelativeTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} năm trước';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} tháng trước';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} ngày trước';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} phút trước';
      } else {
        return 'Vừa xong';
      }
    } catch (e) {
      return 'N/A';
    }
  }
}
