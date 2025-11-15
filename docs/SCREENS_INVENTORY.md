# Danh sách màn hình và Routes

## 📱 **Màn hình chính (Bottom Navigation)**

### 1. Dashboard
- **File:** `lib/features/dashboard/screen_dashboard.dart`
- **Route:** `/dashboard`
- **Class:** `ScreenDashboard`
- **Mô tả:** Trang chủ với thống kê, danh sách bệnh nhân, cảnh báo
- **Bottom Nav Index:** 0

### 2. Prediction Hub
- **File:** `lib/features/prediction/screen_prediction_hub.dart`
- **Route:** `/prediction-hub`
- **Class:** `ScreenPredictionHub`
- **Mô tả:** Hub dự đoán đột quỵ và tiểu đường
- **Bottom Nav Index:** 1

### 3. Forum
- **File:** `lib/features/community/screen_forum.dart`
- **Route:** `/forum`
- **Class:** `ScreenForum`
- **Mô tả:** Diễn đàn cộng đồng
- **Bottom Nav Index:** 2

### 4. Knowledge
- **File:** `lib/features/knowledge/screen_knowledge.dart`
- **Route:** `/knowledge`
- **Class:** `ScreenKnowledge`
- **Mô tả:** Thư viện kiến thức
- **Bottom Nav Index:** 3

### 5. Profile
- **File:** `lib/features/profile/screen_profile.dart`
- **Route:** `/profile`
- **Class:** `ScreenProfile`
- **Mô tả:** Thông tin cá nhân, quản lý, cài đặt
- **Bottom Nav Index:** 4

---

## 🔐 **Authentication (4 màn hình)**

### 6. Splash
- **File:** `lib/features/splash/screen_splash.dart`
- **Route:** `/splash`
- **Class:** `ScreenSplash`
- **Mô tả:** Màn hình khởi động

### 7. Onboarding
- **File:** `lib/features/auth/screen_onboarding.dart`
- **Route:** `/onboarding`
- **Class:** `ScreenOnboarding`
- **Mô tả:** Giới thiệu app lần đầu

### 8. Login
- **File:** `lib/features/auth/screen_login.dart`
- **Route:** `/login`
- **Class:** `ScreenLogin`
- **Mô tả:** Đăng nhập

### 9. Register
- **File:** `lib/features/auth/screen_register.dart`
- **Route:** `/register`
- **Class:** `ScreenRegister`
- **Mô tả:** Đăng ký tài khoản

### 10. Forgot Password
- **File:** `lib/features/auth/screen_forgot_password.dart`
- **Route:** `/forgot-password`
- **Class:** `ScreenForgotPassword`
- **Mô tả:** Quên mật khẩu

---

## 🏥 **Prediction & Health (5 màn hình)**

### 11. Stroke Form
- **File:** `lib/features/prediction/screen_stroke_form.dart`
- **Route:** `/stroke-form`
- **Class:** `ScreenStrokeForm`
- **Mô tả:** Form nhập liệu dự đoán đột quỵ

### 12. Stroke Result
- **File:** `lib/features/prediction/screen_stroke_result.dart`
- **Route:** `/stroke-result`
- **Class:** `ScreenStrokeResult`
- **Mô tả:** Kết quả dự đoán đột quỵ

### 13. Diabetes Form
- **File:** `lib/features/prediction/screen_diabetes_form.dart`
- **Route:** `/diabetes-form`
- **Class:** `ScreenDiabetesForm`
- **Mô tả:** Form nhập liệu dự đoán tiểu đường

### 14. Diabetes Result
- **File:** `lib/features/prediction/screen_diabetes_result.dart`
- **Route:** `/diabetes-result`
- **Class:** `ScreenDiabetesResult`
- **Mô tả:** Kết quả dự đoán tiểu đường

### 15. Health History
- **File:** `lib/features/health/screen_health_history.dart`
- **Route:** `/health-history`
- **Class:** `ScreenHealthHistory`
- **Mô tả:** Lịch sử sức khỏe và biểu đồ

---

## 🚨 **Emergency (2 màn hình)**

### 16. SOS Setup
- **File:** `lib/features/emergency/screen_sos.dart`
- **Route:** `/sos`
- **Class:** `ScreenSOS`
- **Mô tả:** Thiết lập SOS khẩn cấp

### 17. SOS Status
- **File:** `lib/features/emergency/screen_sos_status.dart`
- **Route:** `/sos-status`
- **Class:** `ScreenSOSStatus`
- **Mô tả:** Trạng thái SOS đang hoạt động

---

## 💬 **Communication (3 màn hình)**

### 18. Chat List
- **File:** `lib/features/chat/screen_chat_list.dart`
- **Route:** `/chat`
- **Class:** `ScreenChatList`
- **Mô tả:** Danh sách cuộc trò chuyện

### 19. Chat Detail
- **File:** `lib/features/chat/screen_chat_detail.dart`
- **Route:** `/chat-detail`
- **Class:** `ScreenChatDetail`
- **Mô tả:** Chi tiết cuộc trò chuyện

### 20. Video Call
- **File:** `lib/features/telemedicine/screen_video_call.dart`
- **Route:** `/video-call`
- **Class:** `ScreenVideoCall`
- **Mô tả:** Cuộc gọi video với bác sĩ

---

## 📝 **Management (6 màn hình)**

### 21. Appointments
- **File:** `lib/features/appointments/screen_appointments.dart`
- **Route:** `/appointments`
- **Class:** `ScreenAppointments`
- **Mô tả:** Danh sách lịch hẹn

### 22. Report Appointment
- **File:** `lib/features/hospital/screen_report_appointment.dart`
- **Route:** `/report-appointment`
- **Class:** `ScreenReportAppointment`
- **Mô tả:** Báo cáo và đặt lịch hẹn

### 23. Patient Management
- **File:** `lib/features/patients/screen_patient_management.dart`
- **Route:** `/patient-management`
- **Class:** `ScreenPatientManagement`
- **Mô tả:** Quản lý hồ sơ bệnh nhân

### 24. Family
- **File:** `lib/features/family/screen_family.dart`
- **Route:** `/family`
- **Class:** `ScreenFamily`
- **Mô tả:** Quản lý người thân

### 25. Prescriptions
- **File:** `lib/features/prescriptions/screen_prescriptions.dart`
- **Route:** `/prescriptions`
- **Class:** `ScreenPrescriptions`
- **Mô tả:** Quản lý đơn thuốc

### 26. Reminders
- **File:** `lib/features/reminders/screen_reminders.dart`
- **Route:** `/reminders`
- **Class:** `ScreenReminders`
- **Mô tả:** Nhắc nhở uống thuốc, khám bệnh

---

## 💊 **Pharmacy (2 màn hình)**

### 27. Pharmacy
- **File:** `lib/features/pharmacy/screen_pharmacy.dart`
- **Route:** `/pharmacy`
- **Class:** `ScreenPharmacy`
- **Mô tả:** Nhà thuốc online

### 28. Checkout
- **File:** `lib/features/pharmacy/screen_checkout.dart`
- **Route:** `/checkout`
- **Class:** `ScreenCheckout`
- **Mô tả:** Thanh toán đơn hàng

---

## 📚 **Knowledge & Community (3 màn hình)**

### 29. Article Detail
- **File:** `lib/features/knowledge/screen_article_detail.dart`
- **Route:** `/article-detail`
- **Class:** `ScreenArticleDetail`
- **Mô tả:** Chi tiết bài viết kiến thức

### 30. Topic Detail
- **File:** `lib/features/community/screen_topic_detail.dart`
- **Route:** `/topic-detail`
- **Class:** `ScreenTopicDetail`
- **Mô tả:** Chi tiết chủ đề diễn đàn

### 31. Rate Doctor
- **File:** `lib/features/reviews/screen_rate_doctor.dart`
- **Route:** `/rate-doctor`
- **Class:** `ScreenRateDoctor`
- **Mô tả:** Đánh giá bác sĩ

---

## ⚙️ **Settings & Others (3 màn hình)**

### 32. Settings
- **File:** `lib/features/settings/screen_settings.dart`
- **Route:** `/settings`
- **Class:** `ScreenSettings`
- **Mô tả:** Cài đặt ứng dụng

### 33. Healthy Plan
- **File:** `lib/features/prevention/screen_healthy_plan.dart`
- **Route:** `/healthy-plan`
- **Class:** `ScreenHealthyPlan`
- **Mô tả:** Kế hoạch sống khỏe

### 34. Placeholder
- **File:** `lib/features/common/screen_placeholder.dart`
- **Route:** N/A (dùng programmatically)
- **Class:** `ScreenPlaceholder`
- **Mô tả:** Màn hình placeholder cho tính năng đang phát triển

---

## 📊 **Tổng kết**

- **Tổng số màn hình:** 34
- **Màn hình chính (Bottom Nav):** 5
- **Authentication:** 5
- **Prediction & Health:** 5
- **Emergency:** 2
- **Communication:** 3
- **Management:** 6
- **Pharmacy:** 2
- **Knowledge & Community:** 3
- **Settings & Others:** 3

---

## 🗂️ **Cấu trúc thư mục**

```
lib/features/
├── appointments/        (1 screen)
├── auth/               (4 screens)
├── chat/               (2 screens)
├── common/             (1 screen - placeholder)
├── community/          (2 screens)
├── dashboard/          (1 screen)
├── emergency/          (2 screens)
├── family/             (1 screen)
├── health/             (1 screen)
├── hospital/           (1 screen)
├── knowledge/          (2 screens)
├── patients/           (1 screen)
├── pharmacy/           (2 screens)
├── prediction/         (5 screens)
├── prescriptions/      (1 screen)
├── prevention/         (1 screen)
├── profile/            (1 screen)
├── reminders/          (1 screen)
├── reviews/            (1 screen)
├── settings/           (1 screen)
├── splash/             (1 screen)
└── telemedicine/       (1 screen)
```

---

## ✅ **Trạng thái**

- ✅ Tất cả màn hình đã được kiểm tra
- ✅ Routes đã được cập nhật trong main.dart
- ✅ Bottom navigation đã được tách riêng
- ✅ SOS floating button đã được thêm
- ✅ Profile đã tích hợp các mục quản lý
- ✅ Drawer đã được tối ưu

**Lưu ý:** Không có file nào bị trùng lặp hoặc thừa. Tất cả đều có mục đích sử dụng rõ ràng.
