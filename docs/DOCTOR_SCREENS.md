# 📋 Danh sách màn hình Bác sĩ

## 🏥 **12 Màn hình Doctor**

### **1. Dashboard Trực Ca**
- **File:** `screen_doctor_dashboard.dart`
- **Route:** `/doctor/dashboard`
- **Mô tả:** Trang chủ bác sĩ, hiển thị ca trực, thống kê bệnh nhân

### **2. Danh sách Bệnh nhân**
- **File:** `screen_patient_list.dart`
- **Route:** `/doctor/patients`
- **Mô tả:** Danh sách tất cả bệnh nhân đang theo dõi

### **3. Hồ sơ Bệnh nhân**
- **File:** `screen_patient_profile.dart`
- **Route:** `/doctor/patient-profile`
- **Mô tả:** Chi tiết hồ sơ bệnh nhân, lịch sử khám

### **4. Quản lý Lịch hẹn**
- **File:** `screen_appointment_management.dart`
- **Route:** `/doctor/appointments`
- **Mô tả:** Quản lý lịch hẹn khám bệnh

### **5. Chi tiết Yêu cầu Lịch hẹn**
- **File:** `screen_appointment_request_detail.dart`
- **Route:** `/doctor/appointment-request`
- **Mô tả:** Chi tiết yêu cầu đặt lịch từ bệnh nhân

### **6. Danh sách Hàng đợi SOS**
- **File:** `screen_sos_queue.dart`
- **Route:** `/doctor/sos-queue`
- **Mô tả:** Danh sách các cuộc gọi SOS khẩn cấp

### **7. Chi tiết Ca SOS**
- **File:** `screen_sos_case_detail.dart`
- **Route:** `/doctor/sos-case`
- **Mô tả:** Chi tiết ca SOS, hướng dẫn xử lý

### **8. Màn hình Chat**
- **File:** `screen_doctor_chat.dart`
- **Route:** `/doctor/chat`
- **Mô tả:** Chat với bệnh nhân

### **9. Màn hình Cuộc gọi Video**
- **File:** `screen_doctor_video_call.dart`
- **Route:** `/doctor/video-call`
- **Mô tả:** Gọi video tư vấn bệnh nhân

### **10. Màn hình Tạo Đơn thuốc**
- **File:** `screen_create_prescription.dart`
- **Route:** `/doctor/create-prescription`
- **Mô tả:** Tạo và quản lý đơn thuốc

### **11. Màn hình Xem Đánh giá**
- **File:** `screen_doctor_reviews.dart`
- **Route:** `/doctor/reviews`
- **Mô tả:** Xem đánh giá từ bệnh nhân

### **12. Màn hình Cài đặt**
- **File:** `screen_doctor_settings.dart`
- **Route:** `/doctor/settings`
- **Mô tả:** Cài đặt tài khoản bác sĩ

---

## 📂 **Cấu trúc thư mục**

```
lib/features/doctor/
├── dashboard/
│   └── screen_doctor_dashboard.dart
├── patients/
│   ├── screen_patient_list.dart
│   └── screen_patient_profile.dart
├── appointments/
│   ├── screen_appointment_management.dart
│   └── screen_appointment_request_detail.dart
├── emergency/
│   ├── screen_sos_queue.dart
│   └── screen_sos_case_detail.dart
├── communication/
│   ├── screen_doctor_chat.dart
│   └── screen_doctor_video_call.dart
├── prescriptions/
│   └── screen_create_prescription.dart
├── reviews/
│   └── screen_doctor_reviews.dart
└── settings/
    └── screen_doctor_settings.dart
```

---

## 🔗 **Liên kết với User Data**

### **Dữ liệu chia sẻ:**
- ✅ Patients (bệnh nhân)
- ✅ Appointments (lịch hẹn)
- ✅ Prescriptions (đơn thuốc)
- ✅ Chat messages
- ✅ SOS calls
- ✅ Reviews (đánh giá)

### **Dữ liệu riêng Doctor:**
- Doctor profile
- Doctor schedule (lịch trực)
- Doctor statistics (thống kê)
- Doctor notifications
