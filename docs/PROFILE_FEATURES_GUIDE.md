# Hướng dẫn Tính năng Quản lý Thông tin Cá nhân

## 📋 Tổng quan

Đã hoàn thiện các tính năng quản lý thông tin cá nhân và mật khẩu:

### **1. ✅ Chỉnh sửa thông tin cá nhân**
### **2. ✅ Đổi mật khẩu (với timestamp)**
### **3. ✅ Quên mật khẩu (gửi email)**
### **4. ✅ Reset mật khẩu từ email link**

---

## 🎯 Chi tiết tính năng

### **1. Chỉnh sửa thông tin cá nhân**

**File:** `lib/features/user/profile/screen_edit_profile.dart`

**Truy cập:**
- Settings → Thông tin cá nhân
- Profile → Chỉnh sửa thông tin

**Tính năng:**
- ✅ Chỉnh sửa họ tên (bắt buộc)
- ✅ Chỉnh sửa email (tùy chọn)
- ✅ Chỉnh sửa số điện thoại (tùy chọn)
- ✅ Validation real-time
- ✅ Cập nhật vào Realtime Database
- ✅ Cập nhật session tự động
- ✅ Reload data sau khi lưu

**Validation:**
```dart
- Họ tên: Không được trống, ít nhất 2 ký tự
- Email: Phải hợp lệ (nếu nhập)
- SĐT: Phải hợp lệ theo format VN (nếu nhập)
```

---

### **2. Đổi mật khẩu**

**File:** `lib/features/user/settings/screen_change_password.dart`

**Truy cập:**
- Settings → Thay đổi mật khẩu

**Tính năng:**
- ✅ Nhập mật khẩu hiện tại
- ✅ Nhập mật khẩu mới
- ✅ Xác nhận mật khẩu mới
- ✅ Validation đầy đủ
- ✅ **Hiển thị lần cuối đổi mật khẩu**
- ✅ Cập nhật timestamp `lastPasswordChange`
- ✅ Mã hóa SHA256

**Hiển thị timestamp:**
```
Lần cuối đổi: Hôm nay
Lần cuối đổi: Hôm qua
Lần cuối đổi: 3 ngày trước
Lần cuối đổi: 2 tuần trước
Lần cuối đổi: 1 tháng trước
Lần cuối đổi: 15/11/2024
```

**Database Structure:**
```json
users/{uid}/
  - password: "hashed_password"
  - lastPasswordChange: 1700000000000
  - updatedAt: 1700000000000
```

---

### **3. Quên mật khẩu**

**File:** `lib/features/user/auth/screen_forgot_password.dart`

**Truy cập:**
- Login → Quên mật khẩu?

**Quy trình:**
1. Nhập email đã đăng ký
2. Click "Gửi Hướng Dẫn"
3. Firebase gửi email với link reset
4. Email chứa link dạng: `https://yourapp.com/__/auth/action?mode=resetPassword&oobCode=ABC123`

**Email Template:**
Firebase tự động gửi email với:
- Link reset password
- Thời hạn: 1 giờ
- Ngôn ngữ: Tiếng Việt (có thể config)

---

### **4. Reset mật khẩu từ Email**

**File:** `lib/features/user/auth/screen_reset_password.dart`

**Route:** `/reset-password`

**Quy trình:**
1. User click link trong email
2. App nhận `oobCode` từ URL
3. Hiển thị form nhập mật khẩu mới
4. Xác nhận với Firebase Auth
5. **Cập nhật mật khẩu đã mã hóa vào Realtime Database**
6. **Cập nhật timestamp `lastPasswordChange`**
7. Chuyển về màn hình login

**Xử lý Deep Link:**
Cần cấu hình deep link để app nhận được `oobCode`:

**Web:**
```dart
// URL: https://yourapp.com/__/auth/action?mode=resetPassword&oobCode=ABC123
Navigator.pushNamed(
  context,
  '/reset-password',
  arguments: {'code': 'ABC123'},
);
```

**Mobile (Android/iOS):**
Cần config deep link trong `AndroidManifest.xml` và `Info.plist`

---

## 🔐 Bảo mật

### **Mã hóa mật khẩu:**
```dart
// SHA256 hash
String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
```

### **Lưu trữ:**
```
Firebase Auth: Mật khẩu gốc (Firebase tự quản lý)
Realtime DB: Mật khẩu đã hash SHA256
```

### **Đồng bộ:**
- Đổi mật khẩu: Cập nhật cả Auth và DB
- Reset từ email: Cập nhật cả Auth và DB
- Timestamp được lưu mỗi lần thay đổi

---

## 📱 Routes

```dart
'/edit-profile'      → ScreenEditProfile
'/change-password'   → ScreenChangePassword
'/forgot-password'   → ScreenForgotPassword
'/reset-password'    → ScreenResetPassword (với code parameter)
```

---

## 🎨 UI/UX

### **Màu sắc:**
- Primary: `#135BEC` (Blue)
- Background: `#F6F6F8` (Light Gray)
- Error: `#EF4444` (Red)
- Success: `#10B981` (Green)

### **Components:**
- Input fields với border radius 12px
- Error messages màu đỏ
- Loading indicators
- Success/Error snackbars
- Info boxes với icon

### **Validation:**
- Real-time validation khi nhập
- Border đỏ khi có lỗi
- Text lỗi hiển thị dưới input
- Disable button khi đang loading

---

## 🔄 Session Management

### **Cập nhật session:**
```dart
// Sau khi edit profile
await _authService.updateUserSession(
  userName: newName,
  userEmail: newEmail,
);
```

### **Session keys:**
```
- is_logged_in: bool
- user_id: string
- user_name: string
- user_email: string
- user_role: string
- login_method: string
```

---

## 🧪 Testing

### **Test Edit Profile:**
1. Login → Settings → Thông tin cá nhân
2. Thay đổi tên, email, SĐT
3. Click "Lưu thay đổi"
4. Kiểm tra data đã cập nhật
5. Kiểm tra tên hiển thị ở Dashboard

### **Test Change Password:**
1. Login → Settings → Thay đổi mật khẩu
2. Nhập mật khẩu hiện tại
3. Nhập mật khẩu mới
4. Click "Đổi mật khẩu"
5. Kiểm tra "Lần cuối đổi" hiển thị
6. Logout và login lại với mật khẩu mới

### **Test Forgot Password:**
1. Logout → Login → Quên mật khẩu
2. Nhập email
3. Click "Gửi Hướng Dẫn"
4. Kiểm tra email
5. Click link trong email
6. Nhập mật khẩu mới
7. Login với mật khẩu mới

---

## ⚠️ Lưu ý

### **Email Configuration:**
Cần cấu hình email template trong Firebase Console:
1. Firebase Console → Authentication
2. Templates → Password reset
3. Customize email template
4. Set action URL

### **Deep Link (Mobile):**
Để reset password hoạt động trên mobile, cần:
1. Config deep link
2. Handle URL scheme
3. Parse `oobCode` từ URL

### **Error Handling:**
- Link hết hạn: "Link đặt lại mật khẩu đã hết hạn"
- Link không hợp lệ: "Link đặt lại mật khẩu không hợp lệ"
- Mật khẩu yếu: "Mật khẩu quá yếu"

---

## 📊 Database Schema

```json
users/{uid}/
  - uid: string
  - name: string
  - email: string (nullable)
  - phone: string (nullable)
  - password: string (SHA256 hashed)
  - role: "user" | "doctor" | "admin"
  - loginMethod: "email" | "google" | "guest"
  - lastPasswordChange: timestamp (milliseconds)
  - createdAt: timestamp
  - updatedAt: timestamp
```

---

## ✨ Tính năng nổi bật

1. ✅ **Real-time validation** - Kiểm tra ngay khi nhập
2. ✅ **Timestamp tracking** - Theo dõi lần cuối đổi mật khẩu
3. ✅ **Session sync** - Tự động cập nhật session
4. ✅ **Email integration** - Gửi email reset password
5. ✅ **Security** - Mã hóa SHA256, đồng bộ Auth & DB
6. ✅ **UX friendly** - Loading states, error messages, success feedback

Hệ thống quản lý thông tin cá nhân đã hoàn chỉnh! 🎉
