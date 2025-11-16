# ⚡ QUICK START GUIDE

**Thời gian setup:** ~10 phút

---

## 🎯 BƯỚC 1: FIREBASE SETUP (5 phút)

### 1.1. Apply Firebase Rules

```bash
# 1. Mở Firebase Console
open https://console.firebase.google.com

# 2. Chọn project → Realtime Database → Rules
# 3. Copy rules từ COMPLETE_SETUP_GUIDE.md
# 4. Paste và click Publish
```

### 1.2. Check Files

```bash
# Android
ls android/app/google-services.json

# iOS  
ls ios/Runner/GoogleService-Info.plist

# Nếu không có, download từ Firebase Console
```

---

## 🎯 BƯỚC 2: INSTALL DEPENDENCIES (2 phút)

```bash
# Clean và get dependencies
flutter clean
flutter pub get

# iOS: Install pods
cd ios
pod install
cd ..
```

---

## 🎯 BƯỚC 3: CHECK SETUP (1 phút)

```bash
# Check Flutter
flutter doctor -v

# Nếu có issues, fix theo hướng dẫn
```

---

## 🎯 BƯỚC 4: RUN APP (2 phút)

```bash
# List devices
flutter devices

# Run on device
flutter run

# Hoặc chọn device cụ thể
flutter run -d <device-id>
```

---

## 🚀 COMMANDS NHANH

### Clean & Rebuild:
```bash
flutter clean && flutter pub get && flutter run
```

### Build APK:
```bash
flutter build apk --release
```

### Build iOS:
```bash
flutter build ios --release
```

### Run Tests:
```bash
flutter test
```

### Format Code:
```bash
flutter format .
```

---

## 🔧 SCRIPT TỰ ĐỘNG

```bash
# Chạy script build commands
./BUILD_COMMANDS.sh

# Hoặc
bash BUILD_COMMANDS.sh
```

---

## ✅ VERIFICATION

### Test các tính năng:

```bash
# 1. Login
# - Email/Password ✓
# - Google Sign-In ✓

# 2. Location
# - Grant permission ✓
# - Get current location ✓

# 3. SOS
# - Send SOS ✓
# - Real-time status ✓

# 4. Notifications
# - Grant permission ✓
# - Schedule reminder ✓
# - Receive notification ✓

# 5. Family
# - Add member ✓
# - Accept request ✓
# - See members ✓
```

---

## 🐛 COMMON ISSUES

### Issue: Google Sign-In fails

```bash
# Fix:
cd android
./gradlew signingReport
# Copy SHA-1 → Firebase Console → Add fingerprint
# Download new google-services.json
flutter clean && flutter run
```

### Issue: Location not working

```bash
# Check permissions in AndroidManifest.xml
# Check Info.plist for iOS
# Grant permissions on device
```

### Issue: Build fails

```bash
# Deep clean:
flutter clean
rm -rf build/ ios/Pods/
flutter pub get
cd ios && pod install && cd ..
flutter run
```

---

## 📱 DEVICE REQUIREMENTS

### Android:
- Min SDK: 23 (Android 6.0)
- Target SDK: 34 (Android 14)
- Google Play Services

### iOS:
- Min iOS: 13.0
- Xcode: 14.0+
- CocoaPods

---

## 🎉 DONE!

Nếu tất cả steps trên OK, app đã sẵn sàng!

**Next:** Test tất cả tính năng và deploy.

---

*Quick Start Guide - 16/11/2025*
