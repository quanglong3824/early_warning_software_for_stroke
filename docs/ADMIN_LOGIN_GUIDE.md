# Hướng dẫn đăng nhập Admin/Test

## Tách biệt hệ thống đăng nhập

Dự án hiện có **2 hệ thống đăng nhập riêng biệt**:

### 1. Đăng nhập User (Firebase Authentication)
**Route:** `/login`

**Phương thức:**
- Email/Password (với Realtime Database)
- Google Sign-In
- Guest (Khách)

**Tính năng:**
- Đăng ký tài khoản mới
- Quên mật khẩu (gửi email)
- Đổi mật khẩu
- Session management
- Mã hóa mật khẩu SHA256

---

### 2. Đăng nhập Admin/Test (Hardcoded)
**Route:** `/admin/login`

**Tài khoản:**
```
Username: admin
Password: admin123

Username: test
Password: 123456
```

**Đặc điểm:**
- ✅ Không dùng Firebase Authentication
- ✅ Không ảnh hưởng đến hệ thống User
- ✅ Credentials được hardcode trong code
- ✅ Dùng để test Firebase Realtime Database
- ✅ Truy cập Admin Test Panel

---

## Cách truy cập

### Từ màn hình Login User:
1. Mở app → Màn hình Login User
2. Cuộn xuống dưới cùng
3. Click vào **"Đăng nhập Admin/Test"**
4. Nhập username và password
5. Truy cập Admin Test Panel

### Trực tiếp:
```dart
Navigator.of(context).pushNamed('/admin/login');
```

---

## Admin Test Panel

Sau khi đăng nhập admin, bạn có thể:

1. **Test Connection** - Kiểm tra kết nối Realtime Database
2. **Insert User Data** - Thêm dữ liệu từ `app_data.json`
3. **Insert Doctor Data** - Thêm dữ liệu từ `doctor_data.json`
4. **Read All Data** - Đọc tất cả dữ liệu
5. **Clear All Data** - Xóa toàn bộ dữ liệu (cẩn thận!)

---

## Lưu ý

- Admin login **KHÔNG** lưu session
- Mỗi lần vào cần đăng nhập lại
- Không ảnh hưởng đến user đã đăng nhập
- Chỉ dùng cho mục đích test và quản trị

---

## Cấu trúc File

```
lib/
├── features/
│   ├── admin/
│   │   ├── screen_admin_login.dart   ← Màn hình đăng nhập admin
│   │   └── screen_admin_test.dart    ← Admin test panel
│   └── user/
│       └── auth/
│           ├── screen_login.dart     ← Màn hình đăng nhập user
│           ├── screen_register.dart
│           └── screen_forgot_password.dart
└── services/
    └── auth_service.dart             ← Service xác thực user
```

---

## Thay đổi Credentials Admin

Nếu muốn thay đổi tài khoản admin, sửa trong file:
`lib/features/admin/screen_admin_login.dart`

```dart
final Map<String, String> _adminAccounts = {
  'admin': 'admin123',      // Thay đổi ở đây
  'test': '123456',         // Hoặc thêm tài khoản mới
  'newadmin': 'newpass',    // Ví dụ
};
```
