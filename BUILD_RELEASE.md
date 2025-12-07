# SEWS - Hướng dẫn Build Bản Release 1.0.0

## Thông tin phiên bản
- **Tên ứng dụng**: SEWS - Cảnh báo sớm đột quỵ
- **Phiên bản**: 1.0.0
- **Build number**: 1
- **Package name (Android)**: com.sews.stroke_warning

## Yêu cầu hệ thống
- Flutter SDK >= 3.5.4
- Dart SDK >= 3.5.4
- Android SDK (API 23+)
- Xcode (cho iOS build)

## Chuẩn bị trước khi build

### 1. Cập nhật dependencies
```bash
flutter pub get
```

### 2. Tạo app icons (nếu cần)
```bash
flutter pub run flutter_launcher_icons
```

### 3. Kiểm tra lỗi
```bash
flutter analyze
```

## Build cho Android

### Build APK (Debug)
```bash
flutter build apk --debug
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Build APK (Release)
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build App Bundle (cho Google Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### Build APK theo kiến trúc (giảm dung lượng)
```bash
flutter build apk --split-per-abi --release
```
Output:
- `app-armeabi-v7a-release.apk` (~15MB)
- `app-arm64-v8a-release.apk` (~16MB)
- `app-x86_64-release.apk` (~17MB)

## Build cho Web

### Build Web (Release)
```bash
flutter build web --release
```
Output: `build/web/`

### Build Web với base href (nếu deploy vào subfolder)
```bash
flutter build web --release --base-href "/sews/"
```

## Build cho iOS (yêu cầu macOS + Xcode)

### Build iOS (Release)
```bash
flutter build ios --release
```

### Build IPA
```bash
flutter build ipa --release
```

## Cấu hình Signing cho Release

### Android
1. Tạo keystore:
```bash
keytool -genkey -v -keystore sews-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sews
```

2. Tạo file `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=sews
storeFile=../sews-release-key.jks
```

3. Cập nhật `android/app/build.gradle` để sử dụng keystore

### iOS
1. Cấu hình trong Xcode với Apple Developer account
2. Tạo provisioning profile và certificate

## Kiểm tra bản build

### Kiểm tra APK
```bash
flutter install --release
```

### Kiểm tra Web locally
```bash
cd build/web
python3 -m http.server 8080
# Mở http://localhost:8080
```

## Các tính năng đã hoàn thành (v1.0.0)

### User Features
- ✅ Đăng ký/Đăng nhập (Email, Google)
- ✅ Dashboard với thống kê sức khỏe
- ✅ Dự đoán nguy cơ đột quỵ và tiểu đường
- ✅ Theo dõi lịch sử sức khỏe
- ✅ Quản lý gia đình
- ✅ Đặt lịch hẹn bác sĩ
- ✅ Chat với bác sĩ
- ✅ SOS khẩn cấp
- ✅ Nhắc nhở uống thuốc
- ✅ Thư viện kiến thức
- ✅ Diễn đàn cộng đồng
- ✅ Cài đặt và hồ sơ

### Doctor Features
- ✅ Dashboard quản lý ca trực
- ✅ Quản lý bệnh nhân
- ✅ Quản lý lịch hẹn
- ✅ Xử lý SOS
- ✅ Chat với bệnh nhân
- ✅ Quản lý lịch làm việc
- ✅ Xem đánh giá

### Admin Features
- ✅ Dashboard tổng quan
- ✅ Quản lý Users
- ✅ Quản lý Doctors
- ✅ Quản lý Patients
- ✅ Quản lý SOS
- ✅ Quản lý Predictions
- ✅ Quản lý Appointments
- ✅ Quản lý Knowledge
- ✅ Quản lý Community

## Lưu ý quan trọng

1. **Firebase Configuration**: Đảm bảo `google-services.json` (Android) và `GoogleService-Info.plist` (iOS) đã được cấu hình đúng.

2. **API Keys**: Không commit các API keys vào git. Sử dụng environment variables hoặc file riêng.

3. **Testing**: Chạy tests trước khi build release:
```bash
flutter test
```

4. **Performance**: Bản release đã được tối ưu với:
   - Minify code
   - Shrink resources
   - Tree shaking
   - ProGuard rules

## Liên hệ
- Email: support@sews.app
- Website: https://sews.app
