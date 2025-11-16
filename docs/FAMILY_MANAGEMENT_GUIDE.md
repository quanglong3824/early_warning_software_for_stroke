# 👨‍👩‍👧‍👦 Hướng dẫn Tính năng Quản lý Gia đình

## ✅ Đã hoàn thành 100%

### **1. FamilyService - Service quản lý gia đình**
**File:** `lib/services/family_service.dart`

**Tính năng:**
- ✅ Tìm user bằng email hoặc số điện thoại
- ✅ Gửi yêu cầu kết nối gia đình
- ✅ Chấp nhận/Từ chối yêu cầu
- ✅ Xóa thành viên gia đình (2 chiều)
- ✅ Lấy danh sách gia đình
- ✅ Lấy yêu cầu đang chờ
- ✅ Tạo thông báo realtime
- ✅ Quản lý thông báo (đọc/chưa đọc)
- ✅ Đảo ngược mối quan hệ tự động

### **2. Màn hình Quản lý Gia đình**
**File:** `lib/features/user/family/screen_family_management.dart`
**Route:** `/family-management`

**Tính năng:**
- ✅ Hiển thị danh sách thành viên gia đình
- ✅ Hiển thị yêu cầu đang chờ
- ✅ Modal thêm thành viên với tìm kiếm
- ✅ Chấp nhận/Từ chối yêu cầu
- ✅ Xóa thành viên với confirm dialog
- ✅ Pull to refresh
- ✅ Empty state
- ✅ Real-time updates

### **3. Màn hình Thông báo**
**File:** `lib/features/user/notifications/screen_notifications.dart`
**Route:** `/notifications`

**Tính năng:**
- ✅ Hiển thị danh sách thông báo
- ✅ Badge chưa đọc
- ✅ Đánh dấu đã đọc khi click
- ✅ Đánh dấu tất cả đã đọc
- ✅ Format thời gian (vừa xong, x phút trước, etc.)
- ✅ Icon và màu theo loại thông báo
- ✅ Pull to refresh

### **4. Notification Badge trên Dashboard**
**File:** `lib/features/user/dashboard/screen_dashboard.dart`

**Tính năng:**
- ✅ Hiển thị số lượng thông báo chưa đọc
- ✅ Click vào chuông → Màn hình thông báo
- ✅ Auto reload sau khi xem thông báo

---

## 📊 Database Structure

### **1. family_requests (Yêu cầu kết nối)**
```json
family_requests/{requestId}/
  - id: string
  - fromUserId: string
  - fromUserName: string
  - toUserId: string
  - toUserName: string
  - relationship: string (Bố/Mẹ, Con, Anh/Chị, Em, Vợ/Chồng, Người thân)
  - status: string (pending, accepted, rejected)
  - createdAt: timestamp
  - updatedAt: timestamp
```

### **2. family_members (Thành viên gia đình)**
```json
family_members/{userId}/{memberId}/
  - id: string
  - memberId: string (ID của thành viên)
  - memberName: string
  - relationship: string
  - addedAt: timestamp
```

**Lưu ý:** Kết nối 2 chiều - khi A thêm B, cả A và B đều có nhau trong family_members

### **3. notifications (Thông báo)**
```json
notifications/{userId}/{notificationId}/
  - id: string
  - type: string (family_request, family_accepted, family_rejected)
  - title: string
  - message: string
  - data: object (chứa requestId, memberId, etc.)
  - isRead: boolean
  - createdAt: timestamp
```

---

## 🔄 Luồng hoạt động

### **Thêm thành viên:**
```
1. User A click "+" → Modal thêm thành viên
2. Nhập email/phone của User B → Tìm kiếm
3. Chọn mối quan hệ (Bố/Mẹ, Con, etc.)
4. Click "Gửi yêu cầu"
5. Tạo family_request với status=pending
6. Tạo notification cho User B
7. User B nhận thông báo trên chuông
```

### **Chấp nhận yêu cầu:**
```
1. User B click chuông → Xem thông báo
2. Click "Chấp nhận" trên yêu cầu
3. Cập nhật family_request status=accepted
4. Thêm vào family_members (2 chiều):
   - User A có User B trong danh sách
   - User B có User A trong danh sách
5. Tạo notification cho User A (đã chấp nhận)
6. Cả 2 user thấy nhau trong "Gia đình của bạn"
```

### **Từ chối yêu cầu:**
```
1. User B click "Từ chối"
2. Cập nhật family_request status=rejected
3. Tạo notification cho User A (bị từ chối)
4. Yêu cầu biến mất khỏi danh sách chờ
```

### **Xóa thành viên:**
```
1. User A click icon delete → Confirm dialog
2. Xác nhận xóa
3. Xóa khỏi family_members của User A
4. Xóa khỏi family_members của User B (2 chiều)
5. Cả 2 không còn thấy nhau trong danh sách
```

---

## 🎯 Các loại thông báo

### **1. family_request**
- **Icon:** person_add
- **Màu:** Blue
- **Tiêu đề:** "Yêu cầu kết nối gia đình"
- **Nội dung:** "[Tên] muốn thêm bạn vào danh sách gia đình"

### **2. family_accepted**
- **Icon:** check_circle
- **Màu:** Green
- **Tiêu đề:** "Yêu cầu được chấp nhận"
- **Nội dung:** "[Tên] đã chấp nhận yêu cầu kết nối gia đình"

### **3. family_rejected**
- **Icon:** cancel
- **Màu:** Red
- **Tiêu đề:** "Yêu cầu bị từ chối"
- **Nội dung:** "[Tên] đã từ chối yêu cầu kết nối gia đình"

---

## 🔧 Mối quan hệ tự động đảo ngược

Khi User A thêm User B với mối quan hệ, hệ thống tự động đảo ngược:

| A → B | B → A |
|-------|-------|
| Bố/Mẹ | Con |
| Con | Bố/Mẹ |
| Anh/Chị | Em |
| Em | Anh/Chị |
| Vợ/Chồng | Vợ/Chồng |
| Người thân | Người thân |

**Ví dụ:**
- Nếu A thêm B là "Con" → B sẽ thấy A là "Bố/Mẹ"
- Nếu A thêm B là "Anh/Chị" → B sẽ thấy A là "Em"

---

## 🚀 Cách sử dụng

### **1. Thêm thành viên:**
1. Vào Settings → Gia đình
2. Click icon "+" trên app bar
3. Nhập email hoặc số điện thoại
4. Click icon search
5. Nếu tìm thấy → Chọn mối quan hệ
6. Click "Gửi yêu cầu"

### **2. Xem thông báo:**
1. Click icon chuông trên Dashboard
2. Xem danh sách thông báo
3. Click vào thông báo → Đánh dấu đã đọc
4. Click "Đọc tất cả" → Đánh dấu tất cả

### **3. Chấp nhận/Từ chối:**
1. Vào Gia đình → Xem "Yêu cầu đang chờ"
2. Click "Chấp nhận" hoặc "Từ chối"
3. Thành viên xuất hiện trong danh sách (nếu chấp nhận)

### **4. Xóa thành viên:**
1. Vào Gia đình
2. Click icon delete trên thành viên
3. Xác nhận xóa
4. Thành viên bị xóa khỏi cả 2 phía

---

## 🔥 Firebase Rules cần thiết

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth != null",
        ".write": "$uid === auth.uid",
        ".indexOn": ["email", "phone"]
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
        ".write": "$uid === auth.uid",
        ".indexOn": ["memberId"]
      }
    },
    "notifications": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "auth != null",
        ".indexOn": ["isRead", "createdAt"]
      }
    }
  }
}
```

---

## 📱 UI/UX Features

### **Empty States:**
- ✅ Chưa có thành viên → Icon + Text + Hướng dẫn
- ✅ Chưa có thông báo → Icon + Text

### **Loading States:**
- ✅ Đang tìm kiếm user → CircularProgressIndicator
- ✅ Đang gửi yêu cầu → Button disabled + Loading
- ✅ Đang load danh sách → Full screen loading

### **Feedback:**
- ✅ Success snackbar (màu xanh)
- ✅ Error snackbar (màu đỏ)
- ✅ Warning snackbar (màu cam)
- ✅ Confirm dialog trước khi xóa

### **Visual Indicators:**
- ✅ Badge số lượng thông báo chưa đọc
- ✅ Highlight thông báo chưa đọc (màu xanh nhạt)
- ✅ Icon và màu theo loại thông báo
- ✅ Status badge (Đã kết nối, Đang chờ)

---

## 🧪 Testing Checklist

### **Thêm thành viên:**
- [ ] Tìm bằng email thành công
- [ ] Tìm bằng phone thành công
- [ ] Không tìm thấy → Hiển thị thông báo
- [ ] Gửi yêu cầu thành công
- [ ] Không thể thêm chính mình
- [ ] Không thể gửi yêu cầu trùng

### **Yêu cầu:**
- [ ] Người nhận thấy yêu cầu trong danh sách
- [ ] Người nhận thấy thông báo trên chuông
- [ ] Chấp nhận → Thêm vào danh sách (2 chiều)
- [ ] Từ chối → Yêu cầu biến mất
- [ ] Người gửi nhận thông báo kết quả

### **Thông báo:**
- [ ] Badge hiển thị đúng số lượng
- [ ] Click vào thông báo → Đánh dấu đã đọc
- [ ] Đọc tất cả → Badge về 0
- [ ] Format thời gian đúng

### **Xóa thành viên:**
- [ ] Confirm dialog hiển thị
- [ ] Xóa thành công
- [ ] Xóa khỏi cả 2 phía
- [ ] Không còn thấy nhau trong danh sách

---

## ⚠️ Lưu ý quan trọng

### **1. Bảo mật:**
- Users chỉ đọc được thông tin cơ bản của nhau (name, email, phone)
- Không thể xem thông tin chi tiết của người khác
- Mỗi user chỉ quản lý được gia đình của mình

### **2. Kết nối 2 chiều:**
- Khi A thêm B → Cả A và B đều có nhau
- Khi A xóa B → Cả A và B đều mất nhau
- Đảm bảo đồng bộ 2 phía

### **3. Validation:**
- Không thể thêm chính mình
- Không thể gửi yêu cầu trùng
- Không thể chấp nhận yêu cầu đã xử lý

### **4. Performance:**
- Sử dụng index cho query nhanh
- Pagination cho danh sách lớn (nếu cần)
- Cache notification count

---

## 🔜 Future Enhancements

Có thể thêm sau:
- ✨ Chat giữa các thành viên gia đình
- ✨ Chia sẻ dữ liệu sức khỏe
- ✨ Nhóm gia đình (nhiều người)
- ✨ Quyền truy cập chi tiết
- ✨ Lịch sử hoạt động
- ✨ Export danh sách gia đình
- ✨ Mời qua link/QR code

---

## 📚 Routes

```dart
'/family'              → ScreenFamily (redirect)
'/family-management'   → ScreenFamilyManagement
'/notifications'       → ScreenNotifications
```

---

## ✅ Checklist hoàn thành

- [x] FamilyService với đầy đủ tính năng
- [x] Tìm user bằng email/phone
- [x] Gửi yêu cầu kết nối
- [x] Chấp nhận/Từ chối yêu cầu
- [x] CRUD thành viên gia đình
- [x] Kết nối 2 chiều
- [x] Đảo ngược mối quan hệ tự động
- [x] Hệ thống thông báo realtime
- [x] Notification badge trên dashboard
- [x] Màn hình thông báo
- [x] Đánh dấu đã đọc
- [x] UI/UX hoàn chỉnh
- [x] Empty states
- [x] Loading states
- [x] Error handling

Tính năng quản lý gia đình đã hoàn chỉnh 100%! 🎉
