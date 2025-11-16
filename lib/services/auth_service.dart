import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service quản lý authentication và session
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? "484558690842-o8paac719fa5qbe1pispm4ji2ocn06aj.apps.googleusercontent.com"
        : null, // Android để null, sẽ dùng google-services.json
    scopes: [
      'email',
      'profile',
    ],
  );
  
  // Session keys
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserRole = 'user_role';
  static const String _keyLoginMethod = 'login_method';
  static const String _keyLastActivity = 'last_activity';
  
  // Session timeout (30 minutes)
  static const int _sessionTimeoutMinutes = 30;

  /// Mã hóa mật khẩu bằng SHA256
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Kiểm tra email hợp lệ
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Kiểm tra số điện thoại Việt Nam hợp lệ
  bool isValidPhone(String phone) {
    return RegExp(
            r'^(0|\+84)(\s|\.)?((3[2-9])|(5[689])|(7[06-9])|(8[1-689])|(9[0-46-9]))(\d)(\s|\.)?(\d{3})(\s|\.)?(\d{3})$')
        .hasMatch(phone);
  }

  /// Đăng ký tài khoản mới
  Future<Map<String, dynamic>> register({
    required String name,
    required String account, // email hoặc phone
    required String password,
  }) async {
    try {
      // Validate
      if (name.trim().isEmpty) {
        return {'success': false, 'message': 'Vui lòng nhập họ và tên'};
      }
      if (account.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Vui lòng nhập email hoặc số điện thoại'
        };
      }
      if (!isValidEmail(account) && !isValidPhone(account)) {
        return {
          'success': false,
          'message': 'Email hoặc số điện thoại không hợp lệ'
        };
      }
      if (password.length < 6) {
        return {
          'success': false,
          'message': 'Mật khẩu phải có ít nhất 6 ký tự'
        };
      }

      String email;
      String? phone;

      if (isValidEmail(account)) {
        email = account;
      } else {
        phone = account;
        email = '${account.replaceAll(RegExp(r'[^0-9]'), '')}@sews.app';
      }

      // Mã hóa mật khẩu
      final hashedPassword = hashPassword(password);

      // Tạo tài khoản Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);

      // Lưu vào Realtime Database
      await _database.child('users').child(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': isValidEmail(account) ? account : null,
        'phone': phone,
        'password': hashedPassword, // Lưu mật khẩu đã mã hóa
        'role': 'user',
        'loginMethod': 'email',
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      // Lưu session
      await _saveSession(
        userId: userCredential.user!.uid,
        userName: name,
        userEmail: isValidEmail(account) ? account : null,
        userRole: 'user',
        loginMethod: 'email',
      );

      return {
        'success': true,
        'message': 'Đăng ký thành công!',
        'userId': userCredential.user!.uid,
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email này đã được sử dụng';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ';
          break;
        case 'weak-password':
          message = 'Mật khẩu quá yếu';
          break;
        default:
          message = 'Đăng ký thất bại: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Đăng nhập bằng email/phone và mật khẩu
  Future<Map<String, dynamic>> login({
    required String account,
    required String password,
  }) async {
    try {
      // Validate
      if (account.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Vui lòng nhập email hoặc số điện thoại'
        };
      }
      if (password.isEmpty) {
        return {'success': false, 'message': 'Vui lòng nhập mật khẩu'};
      }

      String email;
      if (isValidEmail(account)) {
        email = account;
      } else {
        email = '${account.replaceAll(RegExp(r'[^0-9]'), '')}@sews.app';
      }

      // Mã hóa mật khẩu để so sánh
      final hashedPassword = hashPassword(password);

      // Đăng nhập Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Lấy thông tin từ Realtime Database
      final snapshot =
          await _database.child('users').child(userCredential.user!.uid).get();

      if (!snapshot.exists) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Dữ liệu người dùng không tồn tại'
        };
      }

      final userData = Map<String, dynamic>.from(snapshot.value as Map);

      // Kiểm tra tài khoản bị xóa
      if (userData['isDeleted'] == true) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Tài khoản đã bị xóa. Vui lòng liên hệ quản trị viên.'
        };
      }

      // Kiểm tra tài khoản bị chặn
      if (userData['isBlocked'] == true) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Tài khoản đã bị chặn. Vui lòng liên hệ quản trị viên.'
        };
      }

      // Kiểm tra mật khẩu
      if (userData['password'] != hashedPassword) {
        await _auth.signOut();
        return {'success': false, 'message': 'Mật khẩu không đúng'};
      }

      // Kiểm tra role
      final role = userData['role'] as String?;
      if (role != 'user') {
        await _auth.signOut();
        return {
          'success': false,
          'message': role == 'doctor'
              ? 'Tài khoản bác sĩ không thể đăng nhập ở đây'
              : 'Tài khoản quản trị không thể đăng nhập ở đây'
        };
      }

      // Lưu session
      await _saveSession(
        userId: userCredential.user!.uid,
        userName: userData['name'],
        userEmail: userData['email'],
        userRole: role!,
        
        loginMethod: 'email',
      );

      return {
        'success': true,
        'message': 'Đăng nhập thành công!',
        'userId': userCredential.user!.uid,
        'userName': userData['name'],
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Tài khoản không tồn tại';
          break;
        case 'wrong-password':
          message = 'Mật khẩu không đúng';
          break;
        case 'invalid-credential':
          message = 'Thông tin đăng nhập không đúng';
          break;
        case 'user-disabled':
          message = 'Tài khoản đã bị vô hiệu hóa';
          break;
        default:
          message = 'Đăng nhập thất bại: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Đăng nhập bằng Google
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      // Sign out trước để clear cache
      await _googleSignIn.signOut();
      
      // Trigger Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Đăng nhập Google bị hủy'};
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Check if tokens are available
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        await _googleSignIn.signOut();
        return {
          'success': false,
          'message': 'Không thể lấy thông tin xác thực từ Google',
        };
      }

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        await _googleSignIn.signOut();
        return {
          'success': false,
          'message': 'Không thể xác thực với Firebase',
        };
      }

      // Kiểm tra xem user đã tồn tại chưa
      final snapshot =
          await _database.child('users').child(userCredential.user!.uid).get();

      String userName = userCredential.user!.displayName ?? 'User';
      String? userEmail = userCredential.user!.email;

      if (!snapshot.exists) {
        // Tạo user mới
        await _database.child('users').child(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': userName,
          'email': userEmail,
          'phone': null,
          'password': null, // Google login không cần password
          'role': 'user',
          'loginMethod': 'google',
          'photoURL': userCredential.user!.photoURL,
          'createdAt': ServerValue.timestamp,
          'updatedAt': ServerValue.timestamp,
        });
      } else {
        // Cập nhật thông tin nếu đã tồn tại
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        
        // Kiểm tra tài khoản bị xóa
        if (userData['isDeleted'] == true) {
          await _auth.signOut();
          await _googleSignIn.signOut();
          return {
            'success': false,
            'message': 'Tài khoản đã bị xóa. Vui lòng liên hệ quản trị viên.'
          };
        }

        // Kiểm tra tài khoản bị chặn
        if (userData['isBlocked'] == true) {
          await _auth.signOut();
          await _googleSignIn.signOut();
          return {
            'success': false,
            'message': 'Tài khoản đã bị chặn. Vui lòng liên hệ quản trị viên.'
          };
        }
        
        userName = userData['name'] ?? userName;
        
        // Cập nhật last login
        await _database.child('users').child(userCredential.user!.uid).update({
          'lastLogin': ServerValue.timestamp,
          'updatedAt': ServerValue.timestamp,
        });
      }

      // Lưu session
      await _saveSession(
        userId: userCredential.user!.uid,
        userName: userName,
        userEmail: userEmail,
        userRole: 'user',
        loginMethod: 'google',
      );

      return {
        'success': true,
        'message': 'Đăng nhập Google thành công!',
        'userId': userCredential.user!.uid,
        'userName': userName,
      };
    } on FirebaseAuthException catch (e) {
      await _googleSignIn.signOut();
      String message;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          message = 'Email này đã được đăng ký bằng phương thức khác. Vui lòng đăng nhập bằng email/mật khẩu.';
          break;
        case 'invalid-credential':
          message = 'Thông tin xác thực không hợp lệ. Vui lòng thử lại.';
          break;
        case 'operation-not-allowed':
          message = 'Đăng nhập Google chưa được kích hoạt. Vui lòng liên hệ quản trị viên.';
          break;
        case 'user-disabled':
          message = 'Tài khoản đã bị vô hiệu hóa. Vui lòng liên hệ hỗ trợ.';
          break;
        case 'user-not-found':
          message = 'Không tìm thấy tài khoản. Vui lòng đăng ký.';
          break;
        case 'network-request-failed':
          message = 'Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.';
          break;
        default:
          message = 'Lỗi đăng nhập: ${e.message ?? "Không xác định"}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      await _googleSignIn.signOut();
      
      final errorMessage = e.toString();
      
      // Check for specific errors
      if (errorMessage.contains('PERMISSION_DENIED') ||
          errorMessage.contains('People API')) {
        return {
          'success': false,
          'message': 'Lỗi cấu hình Google Sign-In.\n'
              'Vui lòng bật People API trong Google Cloud Console.',
        };
      }
      
      if (errorMessage.contains('PlatformException')) {
        return {
          'success': false,
          'message': 'Lỗi nền tảng. Vui lòng cập nhật ứng dụng hoặc thử lại sau.',
        };
      }
      
      if (errorMessage.contains('sign_in_canceled')) {
        return {
          'success': false,
          'message': 'Đăng nhập bị hủy',
        };
      }
      
      return {
        'success': false,
        'message': 'Lỗi không xác định. Vui lòng thử lại sau.',
      };
    }
  }

  /// Đăng nhập khách (Guest)
  Future<Map<String, dynamic>> loginAsGuest() async {
    try {
      // Tạo ID ngẫu nhiên cho guest
      final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';

      // Lưu session
      await _saveSession(
        userId: guestId,
        userName: 'Khách',
        userEmail: null,
        userRole: 'guest',
        loginMethod: 'guest',
      );

      return {
        'success': true,
        'message': 'Đăng nhập với tư cách khách',
        'userId': guestId,
        'userName': 'Khách',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Đăng nhập Admin
  Future<Map<String, dynamic>> loginAdmin({
    required String email,
    required String password,
  }) async {
    return _loginWithRole(
      email: email,
      password: password,
      requiredRole: 'admin',
      roleDisplayName: 'Admin',
    );
  }

  /// Đăng nhập Doctor
  Future<Map<String, dynamic>> loginDoctor({
    required String email,
    required String password,
  }) async {
    return _loginWithRole(
      email: email,
      password: password,
      requiredRole: 'doctor',
      roleDisplayName: 'Bác sĩ',
    );
  }

  /// Helper method để đăng nhập với role cụ thể
  Future<Map<String, dynamic>> _loginWithRole({
    required String email,
    required String password,
    required String requiredRole,
    required String roleDisplayName,
  }) async {
    try {
      // Validate
      if (email.trim().isEmpty) {
        return {'success': false, 'message': 'Vui lòng nhập email'};
      }
      if (!isValidEmail(email)) {
        return {'success': false, 'message': 'Email không hợp lệ'};
      }
      if (password.isEmpty) {
        return {'success': false, 'message': 'Vui lòng nhập mật khẩu'};
      }

      // Mã hóa mật khẩu
      final hashedPassword = hashPassword(password);

      // Đăng nhập Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Lấy thông tin từ Realtime Database
      final snapshot =
          await _database.child('users').child(userCredential.user!.uid).get();

      if (!snapshot.exists) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Dữ liệu người dùng không tồn tại'
        };
      }

      final userData = Map<String, dynamic>.from(snapshot.value as Map);

      // Kiểm tra tài khoản bị xóa
      if (userData['isDeleted'] == true) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Tài khoản đã bị xóa. Vui lòng liên hệ quản trị viên.'
        };
      }

      // Kiểm tra tài khoản bị chặn
      if (userData['isBlocked'] == true) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Tài khoản đã bị chặn. Vui lòng liên hệ quản trị viên.'
        };
      }

      // Kiểm tra mật khẩu
      if (userData['password'] != hashedPassword) {
        await _auth.signOut();
        return {'success': false, 'message': 'Mật khẩu không đúng'};
      }

      // Kiểm tra role
      final role = userData['role'] as String?;
      if (role != requiredRole) {
        await _auth.signOut();
        
        // Thông báo lỗi cụ thể theo role
        String errorMessage;
        if (role == 'user') {
          errorMessage = 'Đây là tài khoản người dùng. Vui lòng đăng nhập ở màn hình người dùng.';
        } else if (role == 'doctor') {
          errorMessage = 'Đây là tài khoản bác sĩ. Vui lòng đăng nhập ở màn hình bác sĩ.';
        } else if (role == 'admin') {
          errorMessage = 'Đây là tài khoản quản trị. Vui lòng đăng nhập ở màn hình admin.';
        } else {
          errorMessage = 'Tài khoản không có quyền truy cập vào $roleDisplayName.';
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }

      // Lưu session
      await _saveSession(
        userId: userCredential.user!.uid,
        userName: userData['name'] ?? roleDisplayName,
        userEmail: userData['email'],
        userRole: requiredRole,
        loginMethod: 'email',
      );

      return {
        'success': true,
        'message': 'Đăng nhập $roleDisplayName thành công!',
        'userId': userCredential.user!.uid,
        'userName': userData['name'] ?? roleDisplayName,
        'userRole': requiredRole,
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Tài khoản không tồn tại';
          break;
        case 'wrong-password':
          message = 'Mật khẩu không đúng';
          break;
        case 'invalid-credential':
          message = 'Thông tin đăng nhập không đúng';
          break;
        case 'user-disabled':
          message = 'Tài khoản đã bị vô hiệu hóa';
          break;
        default:
          message = 'Đăng nhập thất bại: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Quên mật khẩu - Gửi email reset
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      if (email.trim().isEmpty) {
        return {'success': false, 'message': 'Vui lòng nhập email'};
      }
      if (!isValidEmail(email)) {
        return {'success': false, 'message': 'Email không hợp lệ'};
      }

      // Gửi email reset password
      await _auth.sendPasswordResetEmail(email: email);

      return {
        'success': true,
        'message':
            'Đã gửi email hướng dẫn đặt lại mật khẩu. Vui lòng kiểm tra hộp thư của bạn.',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Email này chưa được đăng ký';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ';
          break;
        default:
          message = 'Lỗi: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Đổi mật khẩu
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Vui lòng đăng nhập lại'};
      }

      if (currentPassword.isEmpty || newPassword.isEmpty) {
        return {'success': false, 'message': 'Vui lòng nhập đầy đủ thông tin'};
      }

      if (newPassword.length < 6) {
        return {
          'success': false,
          'message': 'Mật khẩu mới phải có ít nhất 6 ký tự'
        };
      }

      // Lấy thông tin user từ database
      final snapshot = await _database.child('users').child(user.uid).get();
      if (!snapshot.exists) {
        return {
          'success': false,
          'message': 'Không tìm thấy thông tin người dùng'
        };
      }

      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      final hashedCurrentPassword = hashPassword(currentPassword);

      // Kiểm tra mật khẩu hiện tại
      if (userData['password'] != hashedCurrentPassword) {
        return {'success': false, 'message': 'Mật khẩu hiện tại không đúng'};
      }

      // Mã hóa mật khẩu mới
      final hashedNewPassword = hashPassword(newPassword);

      // Cập nhật mật khẩu trong Firebase Auth
      await user.updatePassword(newPassword);

      // Cập nhật mật khẩu trong Realtime Database với timestamp
      await _database.child('users').child(user.uid).update({
        'password': hashedNewPassword,
        'lastPasswordChange': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      return {
        'success': true,
        'message': 'Đổi mật khẩu thành công!',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'Mật khẩu quá yếu';
          break;
        case 'requires-recent-login':
          message = 'Vui lòng đăng nhập lại để thực hiện thao tác này';
          break;
        default:
          message = 'Lỗi: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Reset mật khẩu từ email (sau khi click link)
  Future<Map<String, dynamic>> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      if (newPassword.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Vui lòng nhập mật khẩu mới'
        };
      }
      
      if (newPassword.length < 6) {
        return {
          'success': false,
          'message': 'Mật khẩu phải có ít nhất 6 ký tự'
        };
      }

      // Verify code trước để lấy email
      String email;
      try {
        email = await _auth.verifyPasswordResetCode(code);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'expired-action-code') {
          return {
            'success': false,
            'message': 'Link đặt lại mật khẩu đã hết hạn. Vui lòng yêu cầu link mới.',
          };
        } else if (e.code == 'invalid-action-code') {
          return {
            'success': false,
            'message': 'Link đặt lại mật khẩu không hợp lệ hoặc đã được sử dụng.',
          };
        }
        rethrow;
      }

      // Xác nhận reset password với Firebase Auth
      await _auth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );

      // Mã hóa mật khẩu mới
      final hashedPassword = hashPassword(newPassword);

      // Tìm user trong database bằng email với retry
      int retries = 3;
      bool updated = false;
      
      while (retries > 0 && !updated) {
        try {
          final usersSnapshot = await _database
              .child('users')
              .orderByChild('email')
              .equalTo(email)
              .get();

          if (usersSnapshot.exists) {
            final users = Map<String, dynamic>.from(usersSnapshot.value as Map);
            final userId = users.keys.first;

            // Cập nhật mật khẩu đã mã hóa vào Realtime Database
            await _database.child('users').child(userId).update({
              'password': hashedPassword,
              'lastPasswordChange': ServerValue.timestamp,
              'updatedAt': ServerValue.timestamp,
              'passwordResetAt': ServerValue.timestamp,
            });
            
            updated = true;
            
            print('✅ Password updated in Realtime Database for user: $userId');
          } else {
            print('⚠️ User not found in database with email: $email');
            // Vẫn coi là thành công vì Firebase Auth đã update
            updated = true;
          }
        } catch (e) {
          retries--;
          if (retries == 0) {
            print('❌ Failed to update password in database after retries: $e');
            // Vẫn return success vì Firebase Auth đã update
            updated = true;
          } else {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }

      return {
        'success': true,
        'message': 'Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại.',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'expired-action-code':
          message = 'Link đặt lại mật khẩu đã hết hạn. Vui lòng yêu cầu link mới.';
          break;
        case 'invalid-action-code':
          message = 'Link đặt lại mật khẩu không hợp lệ hoặc đã được sử dụng.';
          break;
        case 'weak-password':
          message = 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
          break;
        case 'user-disabled':
          message = 'Tài khoản đã bị vô hiệu hóa.';
          break;
        case 'user-not-found':
          message = 'Không tìm thấy tài khoản.';
          break;
        default:
          message = 'Lỗi: ${e.message ?? "Không xác định"}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi không xác định. Vui lòng thử lại sau.',
      };
    }
  }

  /// Đăng xuất - Xóa toàn bộ session và cache
  Future<void> logout() async {
    try {
      // Sign out từ Firebase Auth
      await _auth.signOut();

      // Sign out từ Google (nếu đã login bằng Google)
      try {
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect(); // Disconnect để xóa hoàn toàn
      } catch (e) {
        print('Google sign out error (có thể chưa login Google): $e');
      }

      // Xóa toàn bộ SharedPreferences
      await _clearSession();

      print('✅ Đăng xuất thành công - Đã xóa toàn bộ session');
    } catch (e) {
      print('❌ Error logging out: $e');
      // Vẫn xóa session dù có lỗi
      await _clearSession();
    }
  }

  /// Lưu session
  Future<void> _saveSession({
    required String userId,
    required String userName,
    String? userEmail,
    required String userRole,
    required String loginMethod,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserName, userName);
    if (userEmail != null) {
      await prefs.setString(_keyUserEmail, userEmail);
    }
    await prefs.setString(_keyUserRole, userRole);
    await prefs.setString(_keyLoginMethod, loginMethod);
    await prefs.setInt(_keyLastActivity, DateTime.now().millisecondsSinceEpoch);
  }

  /// Cập nhật session (dùng khi edit profile)
  Future<void> updateUserSession({
    String? userName,
    String? userEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (userName != null) {
      await prefs.setString(_keyUserName, userName);
    }
    if (userEmail != null) {
      await prefs.setString(_keyUserEmail, userEmail);
    }
  }

  /// Xóa session
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Kiểm tra có session không
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Lấy thông tin user từ session
  Future<Map<String, String?>> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(_keyUserId),
      'userName': prefs.getString(_keyUserName),
      'userEmail': prefs.getString(_keyUserEmail),
      'userRole': prefs.getString(_keyUserRole),
      'loginMethod': prefs.getString(_keyLoginMethod),
    };
  }

  /// Lấy tên user
  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName) ?? 'User';
  }

  /// Lấy user ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// Kiểm tra session còn hợp lệ không (timeout 30 phút)
  Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      
      if (!isLoggedIn) return false;
      
      final lastActivity = prefs.getInt(_keyLastActivity) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final difference = now - lastActivity;
      
      // Check if session expired (30 minutes)
      if (difference > _sessionTimeoutMinutes * 60 * 1000) {
        print('⚠️ Session expired. Logging out...');
        await logout();
        return false;
      }
      
      // Update last activity
      await prefs.setInt(_keyLastActivity, now);
      return true;
    } catch (e) {
      print('Error checking session: $e');
      return false;
    }
  }

  /// Cập nhật last activity (gọi khi user tương tác)
  Future<void> updateLastActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastActivity, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error updating last activity: $e');
    }
  }

  /// Retry logic cho network operations
  Future<T> _retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    int retries = maxRetries;
    while (retries > 0) {
      try {
        return await operation();
      } catch (e) {
        retries--;
        if (retries == 0) rethrow;
        print('⚠️ Operation failed, retrying... ($retries attempts left)');
        await Future.delayed(delay);
      }
    }
    throw Exception('Operation failed after $maxRetries retries');
  }

  /// Kiểm tra kết nối internet (basic check)
  Future<bool> hasInternetConnection() async {
    try {
      // Try to get current user from Firebase Auth
      // If it works, we have internet
      await _auth.currentUser?.reload();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate và sanitize input
  String _sanitizeInput(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Log authentication events (for debugging)
  void _logAuthEvent(String event, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      print('🔐 Auth Event: $event');
      if (data != null) {
        print('   Data: $data');
      }
    }
  }

  /// Get user data from database với retry
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      return await _retryOperation(() async {
        final snapshot = await _database.child('users').child(userId).get();
        if (snapshot.exists) {
          return Map<String, dynamic>.from(snapshot.value as Map);
        }
        return null;
      });
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Update user data
  Future<bool> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _retryOperation(() async {
        await _database.child('users').child(userId).update({
          ...data,
          'updatedAt': ServerValue.timestamp,
        });
      });
      
      // Update session if name or email changed
      if (data.containsKey('name') || data.containsKey('email')) {
        await updateUserSession(
          userName: data['name'],
          userEmail: data['email'],
        );
      }
      
      return true;
    } catch (e) {
      print('Error updating user data: $e');
      return false;
    }
  }

  /// Verify email
  Future<Map<String, dynamic>> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Vui lòng đăng nhập'};
      }

      if (user.emailVerified) {
        return {'success': false, 'message': 'Email đã được xác thực'};
      }

      await user.sendEmailVerification();
      
      return {
        'success': true,
        'message': 'Đã gửi email xác thực. Vui lòng kiểm tra hộp thư.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      await user.reload();
      return user.emailVerified;
    } catch (e) {
      return false;
    }
  }

  /// Re-authenticate user (for sensitive operations)
  Future<bool> reauthenticate(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      print('Re-authentication failed: $e');
      return false;
    }
  }

  /// Kiểm tra trạng thái tài khoản (bị chặn hoặc xóa)
  /// Trả về Map với 'isValid' và 'message'
  Future<Map<String, dynamic>> checkAccountStatus() async {
    try {
      final userId = await getUserId();
      
      // Guest account luôn valid
      if (userId == null || userId.startsWith('guest_')) {
        return {'isValid': true};
      }

      final userData = await getUserData(userId);
      
      if (userData == null) {
        return {
          'isValid': false,
          'message': 'Không tìm thấy thông tin tài khoản.',
        };
      }

      // Kiểm tra tài khoản bị xóa
      if (userData['isDeleted'] == true) {
        await logout();
        return {
          'isValid': false,
          'message': 'Tài khoản đã bị xóa. Vui lòng liên hệ quản trị viên.',
        };
      }

      // Kiểm tra tài khoản bị chặn
      if (userData['isBlocked'] == true) {
        await logout();
        return {
          'isValid': false,
          'message': 'Tài khoản đã bị chặn. Vui lòng liên hệ quản trị viên.',
        };
      }

      return {'isValid': true};
    } catch (e) {
      print('Error checking account status: $e');
      return {
        'isValid': false,
        'message': 'Lỗi kiểm tra trạng thái tài khoản.',
      };
    }
  }
}
