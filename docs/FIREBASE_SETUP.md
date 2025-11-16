# Firebase Realtime Database Setup

## ⚠️ Lỗi Permission Denied

Nếu bạn gặp lỗi "Permission Denied" khi đọc/ghi dữ liệu, đó là do Firebase Realtime Database Rules chưa được cấu hình đúng.

## 🔧 Cách sửa (QUAN TRỌNG):

### ⚠️ Vấn đề với Rules hiện tại:
Rules hiện tại của bạn chỉ cho phép đọc từng user cụ thể (`$uid`), KHÔNG cho phép đọc toàn bộ danh sách users. Đây là lý do admin không thể load danh sách users.

### Bước 1: Mở Firebase Console
1. Truy cập: https://console.firebase.google.com
2. Chọn project của bạn
3. Vào **Realtime Database** (menu bên trái)
4. Chọn tab **Rules**

### Bước 2: Cập nhật Rules

**QUAN TRỌNG**: Thay đổi phần `users` trong rules:

#### Option 1: Rules cho Development (Dễ dàng nhưng KHÔNG AN TOÀN cho production)
```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```
⚠️ **Cảnh báo**: Rules này cho phép mọi người đọc/ghi dữ liệu. CHỈ dùng cho development!

#### Option 2: Rules cho Production (Khuyến nghị)
```json
{
  "rules": {
    "users": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$uid": {
        ".read": "auth != null",
        ".write": "auth != null && (auth.uid == $uid || root.child('users').child(auth.uid).child('role').val() == 'admin')"
      }
    },
    "sos": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "appointments": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "predictions": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "prescriptions": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "chat": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "notifications": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "family_groups": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

### Bước 3: Publish Rules
1. Nhấn nút **Publish** để áp dụng rules mới
2. Đợi vài giây để rules được cập nhật

### Bước 4: Test lại
1. Refresh app (Cmd+R hoặc F5)
2. Đăng nhập lại
3. Thử load dữ liệu

## 📝 Giải thích Rules

### `"auth != null"`
- Chỉ cho phép users đã đăng nhập

### `"auth.uid == $uid"`
- User chỉ có thể đọc/ghi dữ liệu của chính họ

### `"root.child('users').child(auth.uid).child('role').val() == 'admin'"`
- Admin có thể đọc/ghi tất cả dữ liệu

## 🔍 Debug Permission Issues

### Kiểm tra user đã đăng nhập chưa:
```dart
final user = FirebaseAuth.instance.currentUser;
print('Current user: ${user?.uid}');
print('Is authenticated: ${user != null}');
```

### Kiểm tra rules trong console:
1. Vào Firebase Console
2. Realtime Database → Rules
3. Xem rules hiện tại

### Test rules với Simulator:
1. Trong Firebase Console, tab Rules
2. Nhấn "Rules Playground"
3. Test với các scenarios khác nhau

## 🚨 Lỗi thường gặp

### 1. "Permission Denied" khi đọc dữ liệu
**Nguyên nhân**: User chưa đăng nhập hoặc rules không cho phép
**Giải pháp**: 
- Kiểm tra `FirebaseAuth.instance.currentUser`
- Cập nhật rules để cho phép đọc

### 2. "Permission Denied" khi ghi dữ liệu
**Nguyên nhân**: Rules không cho phép ghi
**Giải pháp**:
- Kiểm tra rules `.write`
- Đảm bảo user có quyền ghi

### 3. Rules không áp dụng
**Nguyên nhân**: Chưa publish hoặc cache
**Giải pháp**:
- Nhấn Publish trong Firebase Console
- Đợi vài giây
- Clear cache và refresh app

## 📚 Tài liệu tham khảo

- [Firebase Realtime Database Rules](https://firebase.google.com/docs/database/security)
- [Understanding Firebase Rules](https://firebase.google.com/docs/database/security/core-syntax)
- [Rules Simulator](https://firebase.google.com/docs/database/security/rules-simulator)

## 💡 Tips

1. **Development**: Dùng rules đơn giản (`.read: true, .write: true`)
2. **Production**: Dùng rules chi tiết với authentication
3. **Testing**: Dùng Rules Playground để test
4. **Monitoring**: Theo dõi logs trong Firebase Console
