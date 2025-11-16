# 🔧 Hướng dẫn Fix lỗi Google Sign-In

## ❌ Lỗi hiện tại

```
ClientException {
  "error": {
    "code": 403,
    "message": "People API has not been used in project 484558690842 before or it is disabled..."
  }
}
```

## ✅ Giải pháp

### **Bước 1: Enable People API**

1. **Truy cập link sau:**
   ```
   https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=484558690842
   ```

2. **Click nút "ENABLE" (Bật)**
   - Đợi vài giây để API được kích hoạt
   - Bạn sẽ thấy status chuyển sang "Enabled"

### **Bước 2: Kiểm tra OAuth Consent Screen**

1. **Truy cập:**
   ```
   https://console.cloud.google.com/apis/credentials/consent?project=484558690842
   ```

2. **Cấu hình thông tin:**
   - **App name:** SEWS (hoặc tên app của bạn)
   - **User support email:** Email của bạn
   - **Developer contact email:** Email của bạn
   - **App domain:** (Tùy chọn)

3. **Publishing status:**
   - **Testing:** Chỉ test users được phép đăng nhập
   - **Production:** Mọi người đều có thể đăng nhập (cần verify)

4. **Thêm Test Users (nếu ở chế độ Testing):**
   - Click "Add Users"
   - Nhập email của bạn
   - Save

### **Bước 3: Kiểm tra OAuth 2.0 Client IDs**

1. **Truy cập:**
   ```
   https://console.cloud.google.com/apis/credentials?project=484558690842
   ```

2. **Kiểm tra Web Client:**
   - Client ID: `484558690842-o8paac719fa5qbe1pispm4ji2ocn06aj.apps.googleusercontent.com`
   - Authorized JavaScript origins:
     - `http://localhost`
     - `http://localhost:8080`
     - `https://yourdomain.com` (production)
   - Authorized redirect URIs:
     - `http://localhost:8080/__/auth/handler`
     - `https://yourdomain.com/__/auth/handler`

### **Bước 4: Restart App**

Sau khi enable People API:

```bash
# Stop app hiện tại
# Ctrl+C trong terminal

# Clean và rebuild
flutter clean
flutter pub get

# Run lại
flutter run -d web-server --web-port=8080
```

---

## 🔍 Kiểm tra

### **Test Google Sign-In:**

1. Mở app: http://localhost:8080
2. Click "Đăng nhập"
3. Click icon Google
4. Chọn tài khoản Google
5. Cho phép quyền truy cập
6. Đăng nhập thành công!

### **Nếu vẫn lỗi:**

1. **Clear browser cache:**
   - Chrome: Ctrl+Shift+Delete
   - Xóa cookies và cached images

2. **Kiểm tra Console log:**
   - F12 → Console tab
   - Xem lỗi chi tiết

3. **Thử incognito mode:**
   - Ctrl+Shift+N (Chrome)
   - Test lại

---

## 📋 Checklist

- [ ] Enable People API
- [ ] Configure OAuth Consent Screen
- [ ] Add Test Users (nếu Testing mode)
- [ ] Check OAuth Client IDs
- [ ] Restart app
- [ ] Clear browser cache
- [ ] Test Google Sign-In

---

## 🚨 Lỗi thường gặp

### **1. "People API has not been used"**
**Giải pháp:** Enable People API (Bước 1)

### **2. "Access blocked: This app's request is invalid"**
**Giải pháp:** 
- Cấu hình OAuth Consent Screen
- Thêm email vào Test Users

### **3. "redirect_uri_mismatch"**
**Giải pháp:**
- Thêm redirect URI vào OAuth Client
- Format: `http://localhost:8080/__/auth/handler`

### **4. "idpiframe_initialization_failed"**
**Giải pháp:**
- Clear cookies
- Thử incognito mode
- Check browser console

---

## 🔐 Bảo mật

### **Production Deployment:**

Khi deploy lên production:

1. **Update Authorized domains:**
   - OAuth Consent Screen → Authorized domains
   - Thêm domain của bạn

2. **Update OAuth Client:**
   - Authorized JavaScript origins: `https://yourdomain.com`
   - Authorized redirect URIs: `https://yourdomain.com/__/auth/handler`

3. **Publish app:**
   - OAuth Consent Screen → Publish App
   - (Có thể cần verify nếu yêu cầu sensitive scopes)

---

## 📱 Mobile (Android/iOS)

Nếu cần Google Sign-In cho mobile:

### **Android:**

1. **Get SHA-1 fingerprint:**
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

2. **Add to Firebase:**
   - Firebase Console → Project Settings
   - Add Android app
   - Add SHA-1 fingerprint

3. **Download google-services.json**
   - Place in `android/app/`

### **iOS:**

1. **Add URL Scheme:**
   - Open `ios/Runner/Info.plist`
   - Add reversed client ID

2. **Download GoogleService-Info.plist**
   - Place in `ios/Runner/`

---

## 🆘 Support

Nếu vẫn gặp vấn đề:

1. **Check Firebase Console:**
   - Authentication → Sign-in method
   - Ensure Google is enabled

2. **Check Google Cloud Console:**
   - APIs & Services → Enabled APIs
   - Verify People API is listed

3. **Check error logs:**
   - Browser console (F12)
   - Flutter console
   - Firebase Console → Authentication → Users

---

## ✅ Kết quả mong đợi

Sau khi hoàn thành các bước trên:

- ✅ People API được enable
- ✅ OAuth Consent Screen đã cấu hình
- ✅ Test users được thêm (nếu Testing mode)
- ✅ Google Sign-In hoạt động bình thường
- ✅ User được tạo trong Firebase Authentication
- ✅ User data được lưu vào Realtime Database

---

## 📚 Tài liệu tham khảo

- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [People API](https://developers.google.com/people)
- [OAuth 2.0](https://developers.google.com/identity/protocols/oauth2)

---

**Lưu ý:** Sau khi enable People API, có thể mất vài phút để thay đổi có hiệu lực. Hãy đợi 2-3 phút rồi thử lại.
