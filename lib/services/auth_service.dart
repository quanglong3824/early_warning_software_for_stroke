import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service quản lý authentication và session
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '484558690842-o8paac719fa5qbe1pispm4ji2ocn06aj.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/userinfo.profile',
      'https://www.googleapis.com/auth/userinfo.email',
    ],
  );

  // Session keys
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserRole = 'user_role';
  static const String _keyLoginMethod = 'login_method'; // 'email', 'google', 'guest'

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
    return RegExp(r'^(0|\+84)(\s|\.)?((3[2-9])|(5[689])|(7[06-9])|(8[1-689])|(9[0-46-9]))(\d)(\s|\.)?(\d{3})(\s|\.)?(\d{3})$')
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
        return {'success': false, 'message': 'Vui lòng nhập email hoặc số điện thoại'};
      }
      if (!isValidEmail(account) && !isValidPhone(account)) {
        return {'success': false, 'message': 'Email hoặc số điện thoại không hợp lệ'};
      }
      if (password.length < 6) {
        return {'success': false, 'message': 'Mật khẩu phải có ít nhất 6 ký tự'};
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
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
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
        return {'success': false, 'message': 'Vui lòng nhập email hoặc số điện thoại'};
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
      final snapshot = await _database.child('users').child(userCredential.user!.uid).get();

      if (!snapshot.exists) {
        await _auth.signOut();
        return {'success': false, 'message': 'Dữ liệu người dùng không tồn tại'};
      }

      final userData = Map<String, dynamic>.from(snapshot.value as Map);

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
      // Trigger Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Đăng nhập Google bị hủy'};
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Check if tokens are available
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        await _googleSignIn.signOut();
        return {
          'success': false,
          'message': 'Không thể lấy thông tin xác thực từ Google. Vui lòng thử lại.',
        };
      }

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Kiểm tra xem user đã tồn tại chưa
      final snapshot = await _database.child('users').child(userCredential.user!.uid).get();

      if (!snapshot.exists) {
        // Tạo user mới
        await _database.child('users').child(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': userCredential.user!.displayName ?? 'User',
          'email': userCredential.user!.email,
          'phone': null,
          'password': null, // Google login không cần password
          'role': 'user',
          'loginMethod': 'google',
          'photoURL': userCredential.user!.photoURL,
          'createdAt': ServerValue.timestamp,
          'updatedAt': ServerValue.timestamp,
        });
      }

      // Lưu session
      await _saveSession(
        userId: userCredential.user!.uid,
        userName: userCredential.user!.displayName ?? 'User',
        userEmail: userCredential.user!.email,
        userRole: 'user',
        loginMethod: 'google',
      );

      return {
        'success': true,
        'message': 'Đăng nhập Google thành công!',
        'userId': userCredential.user!.uid,
        'userName': userCredential.user!.displayName,
      };
    } on FirebaseAuthException catch (e) {
      await _googleSignIn.signOut();
      String message;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          message = 'Email này đã được sử dụng với phương thức đăng nhập khác';
          break;
        case 'invalid-credential':
          message = 'Thông tin xác thực không hợp lệ';
          break;
        case 'operation-not-allowed':
          message = 'Đăng nhập Google chưa được kích hoạt';
          break;
        case 'user-disabled':
          message = 'Tài khoản đã bị vô hiệu hóa';
          break;
        default:
          message = 'Lỗi đăng nhập Google: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      await _googleSignIn.signOut();
      // Check for specific People API error
      if (e.toString().contains('PERMISSION_DENIED') || 
          e.toString().contains('People API')) {
        return {
          'success': false,
          'message': 'Vui lòng bật People API trong Google Cloud Console.\n'
              'Truy cập: console.developers.google.com/apis/api/people.googleapis.com',
        };
      }
      return {'success': false, 'message': 'Lỗi đăng nhập Google: $e'};
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
        'message': 'Đã gửi email hướng dẫn đặt lại mật khẩu. Vui lòng kiểm tra hộp thư của bạn.',
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
        return {'success': false, 'message': 'Mật khẩu mới phải có ít nhất 6 ký tự'};
      }

      // Lấy thông tin user từ database
      final snapshot = await _database.child('users').child(user.uid).get();
      if (!snapshot.exists) {
        return {'success': false, 'message': 'Không tìm thấy thông tin người dùng'};
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
      if (newPassword.length < 6) {
        return {'success': false, 'message': 'Mật khẩu phải có ít nhất 6 ký tự'};
      }

      // Verify code trước để lấy email
      final email = await _auth.verifyPasswordResetCode(code);
      
      // Xác nhận reset password với Firebase Auth
      await _auth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );

      // Mã hóa mật khẩu mới
      final hashedPassword = hashPassword(newPassword);

      // Tìm user trong database bằng email
      final usersSnapshot = await _database.child('users')
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
        });
      }

      return {
        'success': true,
        'message': 'Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại.',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'expired-action-code':
          message = 'Link đặt lại mật khẩu đã hết hạn';
          break;
        case 'invalid-action-code':
          message = 'Link đặt lại mật khẩu không hợp lệ';
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
}
