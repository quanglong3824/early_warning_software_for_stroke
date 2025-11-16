# 🔧 Fix Logout & Google Sign-In

## ✅ Đã hoàn thành 3 tính năng:

### 1. ✅ Đăng xuất xóa toàn bộ session
### 2. ✅ Fix Google Sign-In
### 3. ✅ Firebase Rules đầy đủ quyền

---

## 1. 🚪 Đăng xuất xóa toàn bộ session

### **Vấn đề trước đây:**
- Đăng xuất → Tắt app → Mở lại
- Vẫn tự động login với session cũ
- Session không bị xóa hoàn toàn

### **Đã fix:**
```dart
// File: lib/services/auth_service.dart

Future<void> logout() async {
  try {
    // 1. Sign out từ Firebase Auth
    await _auth.signOut();
    
    // 2. Sign out từ Google (nếu đã login bằng Google)
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect(); // ← Disconnect để xóa hoàn toàn
    } catch (e) {
      print('Google sign out error: $e');
    }
    
    // 3. Xóa toàn bộ SharedPreferences
    await _clearSession();
    
    print('✅ Đăng xuất thành công - Đã xóa toàn bộ session');
  } catch (e) {
    print('❌ Error logging out: $e');
    // Vẫn xóa session dù có lỗi
    await _clearSession();
  }
}
```

### **Cải tiến:**
- ✅ `signOut()` - Đăng xuất Firebase
- ✅ `disconnect()` - Xóa hoàn toàn Google account
- ✅ `clear()` - Xóa toàn bộ SharedPreferences
- ✅ Error handling - Vẫn xóa session dù có lỗi

### **Test:**
```
1. Login vào app
2. Vào Settings → Đăng xuất
3. Tắt app hoàn toàn
4. Mở lại app
5. ✅ Phải thấy màn hình login (không tự động login)
```

---

## 2. 🔐 Fix Google Sign-In

### **Client ID của bạn:**
```
484558690842-o8paac719fa5qbe1pispm4ji2ocn06aj.apps.googleusercontent.com
```

### **Đã cập nhật:**

#### **A. AuthService (lib/services/auth_service.dart):**
```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: '484558690842-o8paac719fa5qbe1pispm4ji2ocn06aj.apps.googleusercontent.com',
  scopes: [
    'email',
    'profile',
    'https://www.googleapis.com/auth/userinfo.profile',
    'https://www.googleapis.com/auth/userinfo.email',
  ],
);
```

#### **B. Web (web/index.html):**
```html
<meta name="google-signin-client_id" 
      content="484558690842-o8paac719fa5qbe1pispm4ji2ocn06aj.apps.googleusercontent.com">
```

### **Scopes đã thêm:**
- ✅ `email` - Lấy email
- ✅ `profile` - Lấy thông tin profile
- ✅ `userinfo.profile` - Thông tin chi tiết profile
- ✅ `userinfo.email` - Thông tin chi tiết email

### **Cần kiểm tra trong Google Cloud Console:**

#### **Bước 1: Truy cập Google Cloud Console**
```
https://console.cloud.google.com
→ Chọn project của bạn
→ APIs & Services → Credentials
```

#### **Bước 2: Kiểm tra OAuth 2.0 Client IDs**
```
Client ID: 484558690842-o8paac719fa5qbe1pispm4ji2ocn06aj.apps.googleusercontent.com

Phải có:
✅ Application type: Web application (hoặc Android)
✅ Authorized redirect URIs (nếu web)
✅ Package name (nếu Android)
✅ SHA-1 fingerprint (nếu Android)
```

#### **Bước 3: Lấy SHA-1 fingerprint (Android):**
```bash
# Debug SHA-1
cd android
./gradlew signingReport

# Hoặc dùng keytool
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copy SHA-1 và thêm vào Google Cloud Console → Credentials → OAuth Client ID

#### **Bước 4: Enable APIs**
```
APIs & Services → Library
→ Tìm và enable:
  ✅ Google+ API
  ✅ People API
  ✅ Google Sign-In API
```

#### **Bước 5: OAuth consent screen**
```
APIs & Services → OAuth consent screen
→ Kiểm tra:
  ✅ User type: External (hoặc Internal)
  ✅ Scopes: email, profile
  ✅ Test users: Thêm email test (nếu chưa publish)
```

---

## 3. 🔥 Firebase Rules - Đầy đủ quyền

### **Rules mới (FULL ACCESS):**

```json
{
  "rules": {
    "users": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["email", "phone"]
    },
    "family_requests": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["fromUserId", "toUserId", "status"]
    },
    "family_members": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["memberId"]
    },
    "notifications": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["isRead", "createdAt"]
    },
    "reminders": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "password_reset_codes": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

### **Thay đổi:**
- ✅ Tất cả node: `.write: "auth != null"` (thay vì restricted)
- ✅ User đã login có thể đọc/ghi tất cả
- ✅ Giữ nguyên indexes để query nhanh

### **Cách cập nhật:**
```
1. https://console.firebase.google.com
2. Realtime Database → Rules
3. Copy rules từ file FIREBASE_RULES_FULL_ACCESS.json
4. Paste và click "Publish"
5. Đợi 5-10 giây
```

### **⚠️ Lưu ý bảo mật:**
Rules này cho phép user đã login đọc/ghi tất cả data. Phù hợp cho:
- ✅ Development/Testing
- ✅ App nhỏ với ít user
- ⚠️ Không khuyến khích cho production với nhiều user

**Cho production, nên dùng rules có validation:**
```json
"users": {
  "$uid": {
    ".read": "$uid === auth.uid",
    ".write": "$uid === auth.uid"
  }
}
```

---

## 🧪 Test đầy đủ:

### **Test 1: Logout**
```
1. Login vào app (email hoặc Google)
2. Vào Settings → Đăng xuất
3. Xác nhận đăng xuất
4. ✅ Về màn hình login
5. Tắt app hoàn toàn
6. Mở lại app
7. ✅ Vẫn ở màn hình login (không tự động login)
```

### **Test 2: Google Sign-In**
```
1. Màn hình login
2. Click "Đăng nhập bằng Google"
3. Chọn tài khoản Google
4. ✅ Login thành công
5. Vào dashboard
6. Vào Settings → Đăng xuất
7. Login lại bằng Google
8. ✅ Phải chọn lại tài khoản (không tự động)
```

### **Test 3: Firebase Rules**
```
1. Login vào app
2. Vào Gia đình → Gửi yêu cầu
3. ✅ Gửi thành công (không Permission denied)
4. User khác chấp nhận
5. ✅ Chấp nhận thành công
6. Xóa thành viên
7. ✅ Xóa thành công
```

---

## 📋 Checklist:

### **Logout:**
- [x] Cập nhật AuthService
- [x] Thêm disconnect() cho Google
- [x] Test logout → tắt app → mở lại

### **Google Sign-In:**
- [x] Cập nhật Client ID trong AuthService
- [x] Cập nhật Client ID trong web/index.html
- [x] Thêm scopes đầy đủ
- [ ] Kiểm tra Google Cloud Console
- [ ] Thêm SHA-1 fingerprint (Android)
- [ ] Enable APIs cần thiết
- [ ] Kiểm tra OAuth consent screen

### **Firebase Rules:**
- [ ] Copy rules từ FIREBASE_RULES_FULL_ACCESS.json
- [ ] Paste vào Firebase Console
- [ ] Click "Publish"
- [ ] Test các tính năng

---

## 🔧 Troubleshooting:

### **Vẫn tự động login sau khi logout?**
```
1. Uninstall app hoàn toàn
2. Reinstall
3. Test lại
```

### **Google Sign-In vẫn lỗi?**
```
1. Kiểm tra SHA-1 đã thêm chưa
2. Kiểm tra APIs đã enable chưa
3. Kiểm tra OAuth consent screen
4. Đợi 5-10 phút sau khi thay đổi
5. Clear cache app và thử lại
```

### **Permission denied sau khi update rules?**
```
1. Kiểm tra rules đã Publish chưa
2. Đợi 5-10 giây
3. Restart app
4. Kiểm tra user đã login chưa
```

---

## 📱 Commands hữu ích:

### **Lấy SHA-1:**
```bash
cd android
./gradlew signingReport
```

### **Clean và rebuild:**
```bash
flutter clean
flutter pub get
flutter run
```

### **Uninstall app:**
```bash
flutter clean
adb uninstall com.example.early_warning_software_for_stroke
flutter run
```

---

## ✅ Tóm tắt:

**Đã fix:**
- ✅ Logout xóa hoàn toàn session (disconnect Google)
- ✅ Cập nhật Google Client ID và scopes
- ✅ Firebase Rules đầy đủ quyền

**Cần làm:**
- ⚠️ Kiểm tra Google Cloud Console (SHA-1, APIs, OAuth)
- ⚠️ Cập nhật Firebase Rules
- ⚠️ Test đầy đủ

Sau khi hoàn thành checklist, tất cả sẽ hoạt động hoàn hảo! 🎉
