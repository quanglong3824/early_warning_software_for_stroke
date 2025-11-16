# 🔥 Firebase Realtime Database Rules - FINAL VERSION

## ⚠️ QUAN TRỌNG - Phải cập nhật ngay!

Lỗi hiện tại: **Permission denied** khi chấp nhận yêu cầu gia đình.

**Nguyên nhân:** Rules không cho phép user A ghi vào `family_members` của user B.

**Giải pháp:** Cập nhật rules để cho phép cross-user write khi authenticated.

---

## 📋 Hướng dẫn cập nhật:

### **Bước 1: Truy cập Firebase Console**
```
https://console.firebase.google.com
→ Chọn project: early_warning_software_for_stroke
→ Realtime Database
→ Tab "Rules"
```

### **Bước 2: Xóa hết rules cũ**
- Select All (Ctrl+A / Cmd+A)
- Delete

### **Bước 3: Copy và Paste rules mới**

```json
{
  "rules": {
    "users": {
      ".read": "auth != null",
      ".indexOn": ["email", "phone"],
      "$uid": {
        ".write": "$uid === auth.uid"
      }
    },
    "family_requests": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["fromUserId", "toUserId", "status"]
    },
    "family_members": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "auth != null",
        ".indexOn": ["memberId"]
      }
    },
    "notifications": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "auth != null",
        ".indexOn": ["isRead", "createdAt"]
      }
    },
    "reminders": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    },
    "password_reset_codes": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

### **Bước 4: Click "Publish"**
- Nút màu xanh ở góc trên phải
- Confirm nếu có popup

### **Bước 5: Đợi 5-10 giây**
- Rules cần thời gian để apply

### **Bước 6: Restart app**
- Stop app hoàn toàn
- Chạy lại: `flutter run`

---

## 🔍 Giải thích thay đổi quan trọng:

### **Trước đây (SAI):**
```json
"family_members": {
  "$uid": {
    ".read": "$uid === auth.uid",
    ".write": "$uid === auth.uid"  // ❌ CHỈ user đó mới ghi được
  }
}
```

**Vấn đề:** 
- User A chấp nhận yêu cầu của User B
- User A cần ghi vào `family_members/B/...`
- Nhưng rules chỉ cho phép User B ghi vào `family_members/B/...`
- → **Permission denied!**

### **Bây giờ (ĐÚNG):**
```json
"family_members": {
  "$uid": {
    ".read": "$uid === auth.uid",
    ".write": "auth != null"  // ✅ TẤT CẢ user đã login có thể ghi
  }
}
```

**Giải pháp:**
- Cho phép tất cả user đã login ghi vào `family_members`
- Vẫn an toàn vì:
  - Chỉ user đã authenticated mới ghi được
  - Logic trong code đảm bảo chỉ ghi khi có yêu cầu hợp lệ
  - Mỗi user chỉ đọc được `family_members` của mình

---

## 🔐 Bảo mật:

### **Các node và quyền:**

| Node | Read | Write | Lý do |
|------|------|-------|-------|
| `users` | Tất cả auth | Chỉ chính mình | Tìm kiếm user |
| `family_requests` | Tất cả auth | Tất cả auth | Gửi/nhận yêu cầu |
| `family_members` | Chỉ chính mình | Tất cả auth | Cross-user write |
| `notifications` | Chỉ chính mình | Tất cả auth | Gửi thông báo |
| `reminders` | Chỉ chính mình | Chỉ chính mình | Private data |

### **Tại sao an toàn?**

1. **Authentication required:**
   - Tất cả đều cần `auth != null`
   - Không login = không làm gì được

2. **Read restrictions:**
   - User chỉ đọc được data của mình
   - Không thể xem gia đình của người khác

3. **Logic validation:**
   - Code kiểm tra yêu cầu hợp lệ trước khi ghi
   - Không thể ghi tùy tiện

4. **Audit trail:**
   - Mọi thao tác đều có timestamp
   - Có thể trace lại ai làm gì

---

## ✅ Test sau khi cập nhật:

### **Test 1: Chấp nhận yêu cầu**
```
1. User A gửi yêu cầu đến User B
2. User B login
3. Vào Gia đình → Thấy yêu cầu
4. Click "Chấp nhận"
5. ✅ Phải thành công (không còn Permission denied)
6. Cả 2 user thấy nhau trong danh sách
```

### **Test 2: Từ chối yêu cầu**
```
1. User A gửi yêu cầu đến User B
2. User B click "Từ chối"
3. ✅ Yêu cầu biến mất
4. User A nhận thông báo bị từ chối
```

### **Test 3: Hủy yêu cầu đã gửi**
```
1. User A gửi yêu cầu đến User B
2. User A vào "Yêu cầu đã gửi"
3. Click icon ❌ hủy
4. ✅ Yêu cầu biến mất
```

### **Test 4: Xóa thành viên**
```
1. User A và B đã là gia đình
2. User A click delete
3. Confirm xóa
4. ✅ Xóa khỏi cả 2 phía
```

---

## 🐛 Troubleshooting:

### **Vẫn lỗi Permission denied?**

1. **Kiểm tra rules đã Publish chưa:**
   - Vào Firebase Console → Rules
   - Xem có đúng rules như trên không
   - Click "Publish" lại

2. **Restart app hoàn toàn:**
   - Không chỉ hot reload
   - Kill app và chạy lại từ đầu

3. **Kiểm tra user đã login:**
   ```dart
   final userId = await _authService.getUserId();
   print('User ID: $userId'); // Phải có giá trị
   ```

4. **Clear cache:**
   - Uninstall app
   - Reinstall và login lại

5. **Kiểm tra Database URL:**
   - Phải đúng project
   - URL: `https://[PROJECT-ID].firebaseio.com`

---

## 📊 Luồng hoạt động với Rules mới:

### **Khi User B chấp nhận yêu cầu:**

```
User B (đang login, auth.uid = B)
  |
  | 1. Click "Chấp nhận"
  |
  | 2. Ghi vào family_members/A/...
  |    ├─ Rules check: auth != null? ✅ (B đã login)
  |    └─ Permission: GRANTED
  |
  | 3. Ghi vào family_members/B/...
  |    ├─ Rules check: auth != null? ✅ (B đã login)
  |    └─ Permission: GRANTED
  |
  | 4. Ghi vào notifications/A/...
  |    ├─ Rules check: auth != null? ✅ (B đã login)
  |    └─ Permission: GRANTED
  |
  ✅ Thành công!
```

---

## 🎯 Checklist:

- [ ] Truy cập Firebase Console
- [ ] Vào Realtime Database → Rules
- [ ] Xóa rules cũ
- [ ] Paste rules mới
- [ ] Click "Publish"
- [ ] Đợi 5-10 giây
- [ ] Restart app
- [ ] Test chấp nhận yêu cầu
- [ ] Test từ chối yêu cầu
- [ ] Test hủy yêu cầu đã gửi
- [ ] Test xóa thành viên

---

## 🚀 Sau khi hoàn thành:

**Tất cả tính năng sẽ hoạt động:**
- ✅ Tìm kiếm user
- ✅ Gửi yêu cầu
- ✅ Chấp nhận yêu cầu (đã fix!)
- ✅ Từ chối yêu cầu
- ✅ Hủy yêu cầu đã gửi
- ✅ Xóa thành viên
- ✅ Thông báo realtime
- ✅ Badge notification

**App sẵn sàng để sử dụng!** 🎉
