import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'auth_service.dart';

/// Script tạo tài khoản admin test
/// Chạy một lần để tạo tài khoản admin trong Firebase
class AdminTestAccount {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static final AuthService _authService = AuthService();

  /// Tài khoản admin test
  static const String adminEmail = 'admin@sews.app';
  static const String adminPassword = 'admin123456';
  static const String adminName = 'Admin SEWS';

  /// Tạo tài khoản admin test
  static Future<Map<String, dynamic>> createAdminAccount() async {
    try {
      print('🔧 Đang tạo tài khoản admin test...');

      UserCredential? userCredential;
      String? userId;

      // Kiểm tra xem tài khoản đã tồn tại chưa
      try {
        // Thử đăng nhập để kiểm tra tài khoản có tồn tại không
        userCredential = await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        
        userId = userCredential.user!.uid;
        print('✅ Tài khoản admin đã tồn tại trong Firebase Auth');
        
        // Kiểm tra xem có trong database không
        final snapshot = await _database.child('users').child(userId).get();
        
        if (!snapshot.exists) {
          // Tài khoản có trong Auth nhưng không có trong Database
          // Tạo lại data trong Database
          print('⚠️ Tài khoản không có trong Database, đang tạo lại...');
          
          final hashedPassword = _authService.hashPassword(adminPassword);
          
          await _database.child('users').child(userId).set({
            'uid': userId,
            'name': adminName,
            'email': adminEmail,
            'phone': null,
            'password': hashedPassword,
            'role': 'admin',
            'loginMethod': 'email',
            'createdAt': ServerValue.timestamp,
            'updatedAt': ServerValue.timestamp,
          });
          
          print('✅ Đã tạo lại data trong Database');
        }
        
        // Đăng xuất sau khi kiểm tra
        await _auth.signOut();
        
        return {
          'success': true,
          'message': 'Tài khoản admin đã sẵn sàng',
          'email': adminEmail,
          'password': adminPassword,
          'userId': userId,
        };
      } on FirebaseAuthException catch (e) {
        // Nếu user-not-found hoặc wrong-password, tài khoản chưa tồn tại
        if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          print('⚠️ Tài khoản chưa tồn tại, đang tạo mới...');
          // Tiếp tục tạo tài khoản mới bên dưới
        } else if (e.code == 'email-already-in-use') {
          // Email đã được dùng nhưng sai mật khẩu
          // Thử tạo lại với mật khẩu mới
          print('⚠️ Email đã tồn tại nhưng mật khẩu không khớp');
          return {
            'success': false,
            'message': 'Email đã được sử dụng với mật khẩu khác. Vui lòng xóa tài khoản trong Firebase Console.',
          };
        } else {
          // Lỗi khác
          rethrow;
        }
      }

      // Tạo tài khoản Firebase Auth mới
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      await userCredential.user?.updateDisplayName(adminName);
      userId = userCredential.user!.uid;

      // Mã hóa mật khẩu
      final hashedPassword = _authService.hashPassword(adminPassword);

      // Lưu vào Realtime Database
      await _database.child('users').child(userId).set({
        'uid': userId,
        'name': adminName,
        'email': adminEmail,
        'phone': null,
        'password': hashedPassword,
        'role': 'admin',
        'loginMethod': 'email',
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      print('✅ Tạo tài khoản admin thành công!');
      print('📧 Email: $adminEmail');
      print('🔑 Password: $adminPassword');

      // Đăng xuất sau khi tạo
      await _auth.signOut();

      return {
        'success': true,
        'message': 'Tạo tài khoản admin thành công',
        'email': adminEmail,
        'password': adminPassword,
        'userId': userId,
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email đã được sử dụng. Tài khoản có thể đã tồn tại trong Firebase Auth.';
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
      print('❌ Lỗi tạo tài khoản: $message');
      return {'success': false, 'message': message};
    } catch (e) {
      print('❌ Lỗi: $e');
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Tạo thêm tài khoản admin với thông tin tùy chỉnh
  static Future<Map<String, dynamic>> createCustomAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('🔧 Đang tạo tài khoản admin: $email');

      // Tạo tài khoản Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);

      // Mã hóa mật khẩu
      final hashedPassword = _authService.hashPassword(password);

      // Lưu vào Realtime Database
      await _database.child('users').child(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'phone': null,
        'password': hashedPassword,
        'role': 'admin',
        'loginMethod': 'email',
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      print('✅ Tạo tài khoản admin thành công!');
      print('📧 Email: $email');
      print('🔑 Password: $password');

      // Đăng xuất sau khi tạo
      await _auth.signOut();

      return {
        'success': true,
        'message': 'Tạo tài khoản admin thành công',
        'email': email,
        'password': password,
        'userId': userCredential.user!.uid,
      };
    } catch (e) {
      print('❌ Lỗi: $e');
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Xóa tài khoản admin test (cả Auth và Database)
  static Future<Map<String, dynamic>> deleteAdminAccount() async {
    try {
      print('�H️ Đang xóa tài khoản admin test...');

      // Đăng nhập để lấy user
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      final userId = userCredential.user!.uid;

      // Xóa trong Database
      await _database.child('users').child(userId).remove();
      print('✅ Đã xóa data trong Database');

      // Xóa user trong Auth
      await userCredential.user!.delete();
      print('✅ Đã xóa tài khoản trong Firebase Auth');

      return {
        'success': true,
        'message': 'Đã xóa tài khoản admin thành công',
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
        case 'requires-recent-login':
          message = 'Cần đăng nhập lại để xóa tài khoản';
          break;
        default:
          message = 'Lỗi: ${e.message}';
      }
      print('❌ Lỗi xóa tài khoản: $message');
      return {'success': false, 'message': message};
    } catch (e) {
      print('❌ Lỗi: $e');
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Hiển thị thông tin tài khoản admin test
  static void showAdminCredentials() {
    print('═══════════════════════════════════════');
    print('🔐 THÔNG TIN TÀI KHOẢN ADMIN TEST');
    print('═══════════════════════════════════════');
    print('📧 Email:    $adminEmail');
    print('🔑 Password: $adminPassword');
    print('👤 Name:     $adminName');
    print('═══════════════════════════════════════');
  }
}
