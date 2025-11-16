# Firebase Realtime Database Rules - Hướng dẫn

## 📋 Tổng quan

Trong hệ thống SEWS, **TẤT CẢ** users (bao gồm users thường, doctors, và admins) đều được lưu trong node `users`.

Phân biệt bằng field `role`:
- `role: 'user'` - Người dùng thường
- `role: 'doctor'` - Bác sĩ
- `role: 'admin'` - Quản trị viên

## ⚠️ LƯU Ý QUAN TRỌNG

### Node `doctors` (DEPRECATED)
Node `doctors` trong rules là **KHÔNG CÒN DÙNG NỮA**. Đây là node cũ từ thiết kế ban đầu.

**Hiện tại:**
- Bác sĩ được lưu trong node `users` với `role: 'doctor'`
- Admin đọc danh sách bác sĩ bằng query: `users.orderByChild('role').equalTo('doctor')`

## 🔧 Rules hiện tại

### Node `users`
```json
{
  "users": {
    ".read": "auth != null",
    ".write": "auth != null",
    ".indexOn": ["email", "phone", "name", "role", "specialty"],
    "$uid": {
      ".write": "auth.uid == $uid || root.child('users').child(auth.uid).child('role').val() == 'admin'"
    }
  }
}
```

**Giải thích:**
- `.read: "auth != null"` - Bất kỳ user đã đăng nhập nào cũng có thể đọc TOÀN BỘ danh sách users
- `.write: "auth != null"` - Bất kỳ user đã đăng nhập nào cũng có thể tạo user mới
- `$uid.write` - Chỉ chính user đó hoặc admin mới có thể sửa thông tin user cụ thể

**Index:**
- `role` - Để query theo role (user, doctor, admin)
- `specialty` - Để query bác sĩ theo chuyên khoa
- `email`, `phone`, `name` - Để tìm kiếm

## 📊 Cấu trúc dữ liệu User

### User thường
```json
{
  "uid": "abc123",
  "name": "Nguyễn Văn A",
  "email": "user@example.com",
  "phone": "0987654321",
  "role": "user",
  "password": "hashed_password",
  "loginMethod": "email",
  "isBlocked": false,
  "isDeleted": false,
  "createdAt": 1234567890,
  "updatedAt": 1234567890
}
```

### Doctor (Bác sĩ)
```json
{
  "uid": "def456",
  "name": "BS. Trần Thị B",
  "email": "doctor@example.com",
  "phone": "0987654322",
  "role": "doctor",
  "specialty": "Tim mạch",
  "hospitalId": "hospital_001",
  "password": "hashed_password",
  "loginMethod": "email",
  "isBlocked": false,
  "isDeleted": false,
  "rating": 4.5,
  "totalReviews": 10,
  "createdAt": 1234567890,
  "updatedAt": 1234567890
}
```

### Admin
```json
{
  "uid": "ghi789",
  "name": "Admin SEWS",
  "email": "admin@sews.app",
  "role": "admin",
  "password": "hashed_password",
  "loginMethod": "email",
  "isBlocked": false,
  "isDeleted": false,
  "createdAt": 1234567890,
  "updatedAt": 1234567890
}
```

## 🔍 Query Examples

### Lấy tất cả users
```dart
final snapshot = await database.child('users').get();
```

### Lấy chỉ users thường
```dart
final snapshot = await database
    .child('users')
    .orderByChild('role')
    .equalTo('user')
    .get();
```

### Lấy chỉ doctors
```dart
final snapshot = await database
    .child('users')
    .orderByChild('role')
    .equalTo('doctor')
    .get();
```

### Lấy doctors theo chuyên khoa
```dart
final snapshot = await database
    .child('users')
    .orderByChild('specialty')
    .equalTo('Tim mạch')
    .get();
```

## 🚨 Troubleshooting

### Lỗi: "Permission Denied"
**Nguyên nhân:** User chưa đăng nhập
**Giải pháp:** Đảm bảo `FirebaseAuth.instance.currentUser != null`

### Lỗi: "Index not defined"
**Nguyên nhân:** Query sử dụng field chưa được index
**Giải pháp:** Thêm field vào `.indexOn` trong rules

### Không load được danh sách
**Nguyên nhân:** Rules chỉ cho phép đọc từng user cụ thể
**Giải pháp:** Đảm bảo `.read: "auth != null"` ở level `users`, không chỉ ở `$uid`

## ✅ Checklist

- [x] Rules cho phép đọc toàn bộ node `users`
- [x] Index cho field `role` để query
- [x] Index cho field `specialty` cho doctors
- [x] Admin có thể sửa bất kỳ user nào
- [x] User chỉ có thể sửa thông tin của chính họ

## 📚 Tài liệu tham khảo

- [Firebase Realtime Database Rules](https://firebase.google.com/docs/database/security)
- [Query Data](https://firebase.google.com/docs/database/flutter/lists-of-data)
- [Indexing Data](https://firebase.google.com/docs/database/security/indexing-data)
