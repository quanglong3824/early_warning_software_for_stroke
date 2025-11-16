# 🔔 Hướng dẫn Tính năng Nhắc nhở

## ✅ Đã hoàn thành

### **1. Notification Service**
**File:** `lib/services/notification_service.dart`

**Tính năng:**
- ✅ Khởi tạo Flutter Local Notifications
- ✅ Xin quyền thông báo (Android/iOS)
- ✅ Hiển thị thông báo ngay lập tức
- ✅ Lên lịch thông báo một lần
- ✅ Lên lịch thông báo lặp lại hàng ngày
- ✅ Hủy thông báo
- ✅ Timezone support (Asia/Ho_Chi_Minh)

### **2. Màn hình Danh sách Nhắc nhở**
**File:** `lib/features/user/reminders/screen_reminders_list.dart`

**Tính năng:**
- ✅ Hiển thị danh sách nhắc nhở từ Realtime Database
- ✅ Bật/tắt nhắc nhở (switch)
- ✅ Xóa nhắc nhở (với confirm dialog)
- ✅ Kiểm tra quyền thông báo
- ✅ Banner yêu cầu cấp quyền
- ✅ Empty state khi chưa có nhắc nhở
- ✅ Real-time sync với database

### **3. Màn hình Thêm Nhắc nhở**
**File:** `lib/features/user/reminders/screen_add_reminder.dart`

**Tính năng:**
- ✅ Form nhập tên thuốc (required)
- ✅ Form nhập ghi chú (optional)
- ✅ Time picker chọn giờ
- ✅ Lưu vào Realtime Database
- ✅ Tự động lên lịch notification
- ✅ Validation đầy đủ

### **4. Android Permissions**
**File:** `android/app/src/main/AndroidManifest.xml`

**Đã thêm:**
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

**Receivers:**
- ScheduledNotificationBootReceiver (khôi phục notifications sau reboot)
- ScheduledNotificationReceiver (xử lý scheduled notifications)

---

## 📊 Database Structure

```json
reminders/
  {userId}/
    {reminderId}/
      - title: string (Tên thuốc)
      - note: string (Ghi chú)
      - time: string (HH:mm format)
      - isActive: boolean
      - createdAt: timestamp
      - updatedAt: timestamp
```

---

## 🔧 Dependencies đã thêm

```yaml
flutter_local_notifications: ^17.0.0
permission_handler: ^11.0.1
timezone: ^0.9.2
```

---

## 🚀 Cách sử dụng

### **1. Truy cập tính năng**
Settings → Nhắc nhở uống thuốc

### **2. Cấp quyền thông báo**
- Lần đầu mở app sẽ tự động yêu cầu quyền
- Nếu từ chối, có banner hướng dẫn cấp quyền
- Click "Cấp quyền" để mở dialog permissions

### **3. Thêm nhắc nhở**
1. Click icon "+" trên app bar
2. Nhập tên thuốc (bắt buộc)
3. Nhập ghi chú (tùy chọn)
4. Chọn thời gian
5. Click "Lưu nhắc nhở"

### **4. Quản lý nhắc nhở**
- **Bật/tắt:** Dùng switch bên phải
- **Xóa:** Click icon thùng rác
- **Xem chi tiết:** Hiển thị tên, ghi chú, thời gian

### **5. Nhận thông báo**
- Thông báo sẽ hiển thị đúng giờ đã chọn
- Lặp lại hàng ngày
- Có âm thanh và rung (nếu được bật)
- Hiển thị ngay cả khi app đóng

---

## 🎯 Luồng hoạt động

### **Thêm nhắc nhở:**
```
1. User nhập thông tin
2. Lưu vào Realtime Database
3. Tạo notification ID (hash từ reminder ID)
4. Lên lịch daily notification
5. Hiển thị trong danh sách
```

### **Bật/tắt nhắc nhở:**
```
1. User toggle switch
2. Cập nhật isActive trong database
3. Nếu bật: scheduleDailyNotification()
4. Nếu tắt: cancelNotification()
5. Reload danh sách
```

### **Xóa nhắc nhở:**
```
1. User click delete → confirm dialog
2. Xóa khỏi Realtime Database
3. Hủy notification
4. Reload danh sách
```

---

## 📱 Android Configuration

### **Notification Channel:**
- **ID:** `reminders_channel`
- **Name:** Nhắc nhở
- **Description:** Kênh thông báo nhắc nhở uống thuốc
- **Importance:** High
- **Priority:** High

### **Schedule Mode:**
- `AndroidScheduleMode.exactAllowWhileIdle`
- Cho phép notification chính xác ngay cả khi device ở chế độ Doze

### **Boot Receiver:**
- Tự động khôi phục notifications sau khi device reboot
- Không cần user mở app lại

---

## 🔐 Permissions

### **Runtime Permissions (Android 13+):**
- `POST_NOTIFICATIONS` - Hiển thị thông báo

### **Manifest Permissions:**
- `SCHEDULE_EXACT_ALARM` - Lên lịch chính xác
- `USE_EXACT_ALARM` - Sử dụng exact alarm
- `RECEIVE_BOOT_COMPLETED` - Nhận sự kiện boot
- `VIBRATE` - Rung khi có thông báo

---

## 🧪 Testing

### **Test thêm nhắc nhở:**
1. Mở Settings → Nhắc nhở
2. Click "+"
3. Nhập: "Aspirin 100mg"
4. Ghi chú: "Sau bữa ăn sáng"
5. Chọn giờ (ví dụ: 08:00)
6. Lưu

### **Test notification:**
1. Đặt thời gian 1-2 phút sau giờ hiện tại
2. Đợi đến giờ
3. Kiểm tra notification hiển thị
4. Click notification (optional)

### **Test bật/tắt:**
1. Toggle switch OFF
2. Kiểm tra notification bị hủy
3. Toggle switch ON
4. Kiểm tra notification được lên lịch lại

### **Test xóa:**
1. Click icon delete
2. Confirm
3. Kiểm tra xóa khỏi danh sách
4. Kiểm tra notification bị hủy

---

## ⚠️ Lưu ý

### **Android 12+ (API 31+):**
- Cần permission `SCHEDULE_EXACT_ALARM`
- User có thể revoke trong Settings

### **Android 13+ (API 33+):**
- Cần runtime permission `POST_NOTIFICATIONS`
- Phải request qua dialog

### **iOS:**
- Cần config trong `Info.plist`
- Request permissions khi app start

### **Timezone:**
- Đã set timezone: `Asia/Ho_Chi_Minh`
- Notification sẽ hiển thị theo giờ Việt Nam

### **Battery Optimization:**
- Một số device có thể kill notifications
- Hướng dẫn user tắt battery optimization cho app

---

## 🔄 Future Enhancements

Có thể thêm:
- ✨ Edit reminder (hiện tại chỉ có add/delete)
- ✨ Snooze notification
- ✨ Notification history
- ✨ Multiple times per day
- ✨ Custom notification sound
- ✨ Medication tracking (đã uống/chưa uống)
- ✨ Statistics và reports

---

## 📚 Routes

```dart
'/reminders-list' → ScreenRemindersList
'/add-reminder'   → ScreenAddReminder
```

---

## ✅ Checklist

- [x] NotificationService với đầy đủ tính năng
- [x] CRUD reminders với Realtime Database
- [x] UI danh sách nhắc nhở
- [x] UI thêm nhắc nhở
- [x] Permission handling
- [x] Android permissions config
- [x] Daily repeating notifications
- [x] Timezone support
- [x] Boot receiver
- [x] Link từ Settings

Tính năng nhắc nhở đã hoàn chỉnh! 🎉
