# 🔐 Thông tin đăng nhập

## 👥 **Tài khoản Demo**

### **1. User (Bệnh nhân)**
```
Username: user
Password: 123456
```
**Chức năng:**
- Dashboard bệnh nhân
- Dự đoán đột quỵ/tiểu đường
- Diễn đàn cộng đồng
- Thư viện kiến thức
- Quản lý hồ sơ cá nhân
- Chat với bác sĩ
- Đặt lịch hẹn
- Quản lý đơn thuốc
- SOS khẩn cấp

**Route:** `/dashboard`

---

### **2. Doctor (Bác sĩ)**
```
Username: doctor
Password: 123456
```
**Chức năng:**
- Dashboard trực ca
- Quản lý bệnh nhân
- Quản lý lịch hẹn
- Xử lý SOS khẩn cấp
- Chat với bệnh nhân
- Video call tư vấn
- Tạo đơn thuốc
- Xem đánh giá
- Cài đặt tài khoản

**Route:** `/doctor/dashboard`

---

## 🔄 **Flow đăng nhập**

```
Splash Screen (3s)
    ↓
Login Screen
    ↓
    ├─→ user/123456 → User Dashboard (/dashboard)
    └─→ doctor/123456 → Doctor Dashboard (/doctor/dashboard)
```

---

## 🎯 **Role-Based Navigation**

### **User Role:**
```dart
if (username == 'user' && password == '123456') {
  Navigator.pushReplacementNamed(context, '/dashboard');
}
```

### **Doctor Role:**
```dart
if (username == 'doctor' && password == '123456') {
  Navigator.pushReplacementNamed(context, '/doctor/dashboard');
}
```

---

## 📱 **Màn hình theo Role**

### **User Screens (34 screens)**
- Dashboard, Prediction Hub, Forum, Knowledge, Profile
- Stroke/Diabetes Forms & Results
- SOS, Chat, Video Call
- Appointments, Prescriptions, Reminders
- Family Management, Settings
- Pharmacy, Checkout

### **Doctor Screens (12 screens)**
- Doctor Dashboard
- Patient List & Profile
- Appointment Management
- SOS Queue & Case Detail
- Doctor Chat & Video Call
- Create Prescription
- Doctor Reviews
- Doctor Settings

---

## 🔒 **Security Notes**

### **Production:**
- ❌ **KHÔNG** sử dụng hardcoded credentials
- ✅ Implement proper authentication (JWT, OAuth)
- ✅ Hash passwords (bcrypt, argon2)
- ✅ Use secure storage
- ✅ Implement session management
- ✅ Add 2FA for doctors

### **Current (Demo):**
- ⚠️ Hardcoded credentials for testing only
- ⚠️ No encryption
- ⚠️ No session management
- ⚠️ For development/demo purposes

---

## 🚀 **Testing**

### **Test User Login:**
1. Run app: `flutter run`
2. Wait for splash screen
3. Enter: `user` / `123456`
4. Click "Đăng nhập"
5. Should navigate to User Dashboard

### **Test Doctor Login:**
1. Run app: `flutter run`
2. Wait for splash screen
3. Enter: `doctor` / `123456`
4. Click "Đăng nhập"
5. Should navigate to Doctor Dashboard

---

## 📊 **Routes Summary**

| Role | Username | Password | Route | Screens |
|------|----------|----------|-------|---------|
| **User** | `user` | `123456` | `/dashboard` | 34 screens |
| **Doctor** | `doctor` | `123456` | `/doctor/dashboard` | 12 screens |

---

## 🔄 **Logout Flow**

### **User:**
```dart
// From Profile > Đăng xuất
Navigator.pushReplacementNamed(context, '/login');
```

### **Doctor:**
```dart
// From Settings > Đăng xuất
Navigator.pushReplacementNamed(context, '/login');
```

---

## ✅ **Implementation Checklist**

- [x] Login screen với role detection
- [x] User routes (34 screens)
- [x] Doctor routes (12 screens)
- [x] Navigation based on role
- [x] Logout functionality
- [ ] Remember me feature
- [ ] Biometric authentication
- [ ] Password reset
- [ ] Session timeout
- [ ] Multi-device login

---

## 📝 **Next Steps**

### **Phase 1: Authentication**
1. Implement proper backend authentication
2. Add JWT token management
3. Secure storage for credentials
4. Session management

### **Phase 2: Authorization**
1. Role-based access control (RBAC)
2. Permission management
3. Screen-level authorization
4. API-level authorization

### **Phase 3: Security**
1. Password encryption
2. 2FA for doctors
3. Biometric login
4. Security audit

---

## 🎉 **Current Status**

✅ **Login system hoạt động!**
- ✅ User login → User Dashboard
- ✅ Doctor login → Doctor Dashboard
- ✅ Role-based navigation
- ✅ All routes configured
- ✅ Ready for testing!

**Test ngay:** `flutter run`
