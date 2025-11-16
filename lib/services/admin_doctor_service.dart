import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AdminDoctorService {
  static final AdminDoctorService _instance = AdminDoctorService._internal();
  factory AdminDoctorService() => _instance;
  AdminDoctorService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Lấy danh sách tất cả doctors
  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    try {
      final snapshot = await _database.child('users').get();
      
      if (!snapshot.exists) {
        return [];
      }

      final usersMap = Map<String, dynamic>.from(snapshot.value as Map);
      final doctorsList = <Map<String, dynamic>>[];

      usersMap.forEach((key, value) {
        final userData = Map<String, dynamic>.from(value as Map);
        if (userData['role'] == 'doctor') {
          userData['uid'] = key;
          doctorsList.add(userData);
        }
      });

      // Sắp xếp theo thời gian tạo (mới nhất trước)
      doctorsList.sort((a, b) {
        final aTime = a['createdAt'] ?? 0;
        final bTime = b['createdAt'] ?? 0;
        return bTime.compareTo(aTime);
      });

      return doctorsList;
    } catch (e) {
      print('Error getting all doctors: $e');
      return [];
    }
  }

  /// Lấy danh sách doctors theo role
  Future<List<Map<String, dynamic>>> getDoctorsByRole(String role) async {
    try {
      print('🔍 Fetching doctors with role: $role');
      
      final snapshot = await _database
          .child('users')
          .orderByChild('role')
          .equalTo(role)
          .get();
      
      print('📊 Snapshot exists: ${snapshot.exists}');
      
      if (!snapshot.exists) {
        print('⚠️ No doctors found with role: $role');
        return [];
      }

      final usersMap = Map<String, dynamic>.from(snapshot.value as Map);
      print('📦 Found ${usersMap.length} doctors in database');
      
      final doctorsList = <Map<String, dynamic>>[];

      usersMap.forEach((key, value) {
        final userData = Map<String, dynamic>.from(value as Map);
        userData['uid'] = key;
        doctorsList.add(userData);
        print('👨‍⚕️ Doctor: ${userData['name']} (${userData['email']})');
      });

      print('✅ Returning ${doctorsList.length} doctors');
      return doctorsList;
    } catch (e) {
      print('❌ Error getting doctors by role: $e');
      return [];
    }
  }

  /// Đếm số lượng doctors
  Future<int> countDoctors() async {
    try {
      final doctors = await getDoctorsByRole('doctor');
      return doctors.length;
    } catch (e) {
      print('Error counting doctors: $e');
      return 0;
    }
  }

  /// Lấy thông tin chi tiết doctor
  Future<Map<String, dynamic>?> getDoctorDetail(String doctorId) async {
    try {
      final snapshot = await _database.child('users').child(doctorId).get();
      
      if (!snapshot.exists) {
        return null;
      }

      final doctorData = Map<String, dynamic>.from(snapshot.value as Map);
      doctorData['uid'] = doctorId;
      return doctorData;
    } catch (e) {
      print('Error getting doctor detail: $e');
      return null;
    }
  }

  /// Chặn/Mở chặn doctor
  Future<Map<String, dynamic>> toggleDoctorStatus(String doctorId, bool isBlocked) async {
    try {
      await _database.child('users').child(doctorId).update({
        'isBlocked': isBlocked,
        'blockedAt': isBlocked ? ServerValue.timestamp : null,
        'updatedAt': ServerValue.timestamp,
      });

      return {
        'success': true,
        'message': isBlocked ? 'Đã chặn bác sĩ' : 'Đã mở chặn bác sĩ',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: $e',
      };
    }
  }

  /// Xóa doctor (soft delete)
  Future<Map<String, dynamic>> deleteDoctor(String doctorId) async {
    try {
      await _database.child('users').child(doctorId).update({
        'isDeleted': true,
        'deletedAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      return {
        'success': true,
        'message': 'Đã xóa bác sĩ',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: $e',
      };
    }
  }

  /// Tạo doctor mới
  Future<Map<String, dynamic>> createDoctor({
    required String name,
    required String email,
    String? phone,
    required String password,
    String? specialty,
    String? hospitalId,
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
        'role': 'doctor',
        'specialty': specialty,
        'hospitalId': hospitalId,
        'loginMethod': 'email',
        'isBlocked': false,
        'isDeleted': false,
        'rating': 0.0,
        'totalReviews': 0,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      // Đăng xuất sau khi tạo
      await _auth.signOut();

      return {
        'success': true,
        'message': 'Tạo bác sĩ thành công',
        'doctorId': userCredential.user!.uid,
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

  /// Cập nhật thông tin doctor
  Future<Map<String, dynamic>> updateDoctor(String doctorId, Map<String, dynamic> data) async {
    try {
      // Validate
      if (data.containsKey('name') && (data['name'] as String).trim().isEmpty) {
        return {'success': false, 'message': 'Vui lòng nhập họ tên'};
      }
      if (data.containsKey('email') && (data['email'] as String).trim().isEmpty) {
        return {'success': false, 'message': 'Vui lòng nhập email'};
      }

      data['updatedAt'] = ServerValue.timestamp;
      
      await _database.child('users').child(doctorId).update(data);

      return {
        'success': true,
        'message': 'Đã cập nhật thông tin bác sĩ',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: $e',
      };
    }
  }

  /// Tìm kiếm doctors
  Future<List<Map<String, dynamic>>> searchDoctors(String query) async {
    try {
      final allDoctors = await getAllDoctors();
      
      if (query.isEmpty) {
        return allDoctors;
      }

      final lowerQuery = query.toLowerCase();
      
      return allDoctors.where((doctor) {
        final name = (doctor['name'] ?? '').toString().toLowerCase();
        final email = (doctor['email'] ?? '').toString().toLowerCase();
        final phone = (doctor['phone'] ?? '').toString().toLowerCase();
        final specialty = (doctor['specialty'] ?? '').toString().toLowerCase();
        
        return name.contains(lowerQuery) ||
               email.contains(lowerQuery) ||
               phone.contains(lowerQuery) ||
               specialty.contains(lowerQuery);
      }).toList();
    } catch (e) {
      print('Error searching doctors: $e');
      return [];
    }
  }

  /// Lọc doctors theo trạng thái
  Future<List<Map<String, dynamic>>> filterDoctorsByStatus(String status) async {
    try {
      final allDoctors = await getAllDoctors();
      
      if (status == 'all') {
        return allDoctors;
      } else if (status == 'active') {
        return allDoctors.where((doctor) => 
          (doctor['isBlocked'] ?? false) == false &&
          (doctor['isDeleted'] ?? false) == false
        ).toList();
      } else if (status == 'blocked') {
        return allDoctors.where((doctor) => 
          (doctor['isBlocked'] ?? false) == true
        ).toList();
      } else if (status == 'deleted') {
        return allDoctors.where((doctor) => 
          (doctor['isDeleted'] ?? false) == true
        ).toList();
      }
      
      return allDoctors;
    } catch (e) {
      print('Error filtering doctors: $e');
      return [];
    }
  }

  /// Lấy thống kê doctors
  Future<Map<String, dynamic>> getDoctorStats() async {
    try {
      print('📊 Getting doctor stats...');
      final allDoctors = await getAllDoctors();
      print('📦 Total doctors in database: ${allDoctors.length}');
      
      final totalDoctors = allDoctors.length;
      final activeDoctors = allDoctors.where((d) => 
        (d['isBlocked'] ?? false) == false &&
        (d['isDeleted'] ?? false) == false
      ).length;
      final blockedDoctors = allDoctors.where((d) => 
        (d['isBlocked'] ?? false) == true
      ).length;
      final deletedDoctors = allDoctors.where((d) => 
        (d['isDeleted'] ?? false) == true
      ).length;

      // Doctors mới trong 7 ngày
      final now = DateTime.now().millisecondsSinceEpoch;
      final sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000);
      final newDoctors = allDoctors.where((d) {
        final createdAt = d['createdAt'] ?? 0;
        return createdAt > sevenDaysAgo;
      }).length;

      final stats = {
        'total': totalDoctors,
        'active': activeDoctors,
        'blocked': blockedDoctors,
        'deleted': deletedDoctors,
        'newThisWeek': newDoctors,
      };
      
      print('✅ Stats calculated: $stats');
      return stats;
    } catch (e) {
      print('❌ Error getting doctor stats: $e');
      return {
        'total': 0,
        'active': 0,
        'blocked': 0,
        'deleted': 0,
        'newThisWeek': 0,
      };
    }
  }

  /// Helper: Hash password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
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
