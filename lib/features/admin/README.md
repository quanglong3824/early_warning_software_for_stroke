# Admin Panel - SEWS Healthcare System

## 🔐 Tài khoản Admin Test

```
Email:    admin@sews.app
Password: admin123456
Name:     Admin SEWS
```

## 📱 Danh sách màn hình Admin

### 1. Xác thực (Auth)
- ✅ Splash Screen (`screen_admin_splash.dart`)
- ✅ Đăng nhập Admin (`screen_admin_login.dart`)
- ✅ Quên mật khẩu Admin (`screen_admin_forgot_password.dart`)

### 2. Tổng quan (Dashboard)
- ✅ Dashboard Admin (`screen_admin_dashboard.dart`)
  - Thống kê tổng quan hệ thống
  - Hoạt động gần đây
  - Thống kê nhanh

### 3. Quản lý Users
- ✅ Quản lý Users (`screen_admin_users.dart`)
  - Danh sách users
  - Thêm/Chặn/Chi tiết user
  - Tìm kiếm và lọc

### 4. Quản lý Bác sĩ
- ✅ Quản lý Bác sĩ (`screen_admin_doctors.dart`)
  - Danh sách bác sĩ
  - Thêm/Chặn/Chi tiết bác sĩ
  - Xem đánh giá

### 5. Quản lý Bệnh nhân
- ✅ Quản lý Bệnh nhân (`screen_admin_patients.dart`)
  - Danh sách bệnh nhân
  - Chi tiết hồ sơ
  - Xuất dữ liệu

### 6. Tổng hợp SOS
- ✅ Tổng hợp SOS (`screen_admin_sos.dart`)
  - Bản đồ SOS
  - Danh sách cuộc gọi SOS
  - Thống kê SOS

### 7. Dự đoán & AI
- ✅ Tổng hợp Dự đoán (`screen_admin_predictions.dart`)
  - Dự đoán Đột quỵ
  - Dự đoán Tiểu đường
  - Thống kê nguy cơ

### 8. Tương tác BV
- ✅ Tổng hợp Lịch hẹn & Chat (`screen_admin_appointments.dart`)
  - Quản lý lịch hẹn
  - Thống kê chat
  - Hoạt động gần đây

### 9. Thuốc
- ✅ Tổng hợp Thuốc (`screen_admin_pharmacy.dart`)
  - Đơn thuốc
  - Nhà thuốc
  - Thống kê

### 10. Ngăn ngừa
- ✅ Tổng hợp Ngăn ngừa (`screen_admin_knowledge.dart`)
  - Thư viện kiến thức
  - Quản lý nhắc nhở

### 11. Cộng đồng
- ✅ Tổng hợp Cộng đồng (`screen_admin_community.dart`)
  - Diễn đàn
  - Đánh giá bác sĩ

## 🚀 Cách sử dụng

### Tạo tài khoản Admin tự động
Tài khoản admin sẽ được tạo tự động khi chạy app lần đầu thông qua `screen_admin_splash.dart`

### Tạo tài khoản Admin thủ công
```dart
import 'package:your_app/services/admin_test_account.dart';

// Tạo tài khoản admin mặc định
await AdminTestAccount.createAdminAccount();

// Hoặc tạo tài khoản admin tùy chỉnh
await AdminTestAccount.createCustomAdmin(
  email: 'admin2@sews.app',
  password: 'password123',
  name: 'Admin 2',
);
```

## 🎨 Màu sắc Admin Panel
- Primary: `#6B46C1` (Purple)
- Background: `#F6F6F8` (Light Gray)
- Success: Green
- Warning: Orange
- Error: Red

## 📝 Ghi chú
- Tất cả màn hình đã được tạo với UI hoàn chỉnh
- Dữ liệu hiện tại là mock data để demo
- Cần kết nối với Firebase Realtime Database để có dữ liệu thực
