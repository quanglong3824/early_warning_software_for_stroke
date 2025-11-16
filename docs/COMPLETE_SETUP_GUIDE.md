# 🚀 HƯỚNG DẪN SETUP HOÀN CHỈNH

**Ngày cập nhật:** 16/11/2025  
**Phiên bản:** 1.0.0

---

## 📋 MỤC LỤC

1. [Firebase Rules](#firebase-rules)
2. [Dependencies](#dependencies)
3. [Android Setup](#android-setup)
4. [iOS Setup](#ios-setup)
5. [Build Commands](#build-commands)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)

---

## 🔥 FIREBASE RULES

### Realtime Database Rules (FULL)

Copy toàn bộ rules này vào Firebase Console → Realtime Database → Rules:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth != null",
        ".write": "$uid === auth.uid || auth != null",
        ".indexOn": ["email", "phone", "name"]
      }
    },
    "patients": {
      "$patientId": {
        ".read": "auth != null",
        ".write": "auth != null",
        ".indexOn": ["primaryUserId", "status"]
      }
    },
    "health_records": {
      "$patientId": {
        ".read": "auth != null",
        ".write": "auth != null",
        ".indexOn": ["recordedByUserId", "createdAt"]
      }
    },
    "sos_requests": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["userId", "status", "createdAt", "assignedHospitalId"]
    },
    "hospitals": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "hospital_notifications": {
      "$hospitalId": {
        ".read": "auth != null",
        ".write": "auth != null",
        ".indexOn": ["createdAt", "type"]
      }
    },
    "chat_sessions": {
      "$sessionId": {
        ".read": "auth != null",
        ".write": "auth != null",
        "messages": {
          ".indexOn": ["createdAt", "senderId"]
        }
      }
    },
    "appointments": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["userId", "doctorId", "status", "appointmentTime"]
    },
    "prescriptions": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["patientId", "doctorId", "createdAt"]
    },
    "reminders": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid",
        ".indexOn": ["time", "isActive", "createdAt"]
      }
    },
    "family_requests": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["fromUserId", "toUserId", "status", "createdAt"]
    },
    "family_members": {
      "$uid": {
        ".read": "$uid === auth.uid || auth != null",
        ".write": "$uid === auth.uid || auth != null",
        ".indexOn": ["memberId", "addedAt"]
      }
    },
    "family_groups": {
      "$groupId": {
        ".read": "auth != null",
        ".write": "auth != null",
        ".indexOn": ["creatorId", "createdAt", "memberCount"]
      }
    },
    "family_group_members": {
      "$groupId": {
        ".read": "auth != null",
        "$userId": {
          ".write": "auth != null"
        },
        ".indexOn": ["role", "joinedAt"]
      }
    },
    "user_family_groups": {
      "$userId": {
        ".read": "$userId === auth.uid || auth != null",
        ".write": "$userId === auth.uid || auth != null",
        ".indexOn": ["role", "joinedAt"]
      }
    },
    "family_group_invitations": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["toUserId", "fromUserId", "groupId", "status", "createdAt"]
    },
    "notifications": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "auth != null",
        ".indexOn": ["isRead", "createdAt", "type"]
      }
    },
    "knowledge_articles": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["category", "publishedAt", "authorDoctorId"]
    },
    "forum_threads": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["createdByUserId", "createdAt", "category"]
    },
    "forum_posts": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["threadId", "createdByUserId", "createdAt"]
    },
    "pharmacies": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "drugs": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["category", "name"]
    },
    "orders": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["userId", "status", "createdAt"]
    },
    "doctors": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["hospitalId", "specialty", "rating"]
    },
    "doctor_stats": {
      "$doctorId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    },
    "reviews": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["doctorId", "userId", "createdAt", "rating"]
    }
  }
}
```

### Cách apply Firebase Rules:

1. Truy cập: https://console.firebase.google.com
2. Chọn project của bạn
3. Realtime Database → Rules
4. Copy toàn bộ JSON trên
5. Paste vào editor
6. Click **Publish**
7. Đợi vài giây để rules được apply

---

## 📦 DEPENDENCIES

### Current Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # UI
  cupertino_icons: ^1.0.8

  # Firebase
  firebase_core: ^4.2.1
  firebase_database: ^12.0.4
  firebase_auth: ^6.1.2
  cloud_firestore: ^6.1.0
  firebase_messaging: ^14.7.9

  # Authentication
  google_sign_in: ^6.2.2
  crypto: ^3.0.3

  # State Management
  provider: ^6.1.1

  # Storage
  shared_preferences: ^2.2.2

  # Notifications
  flutter_local_notifications: ^17.0.0
  permission_handler: ^11.0.1
  timezone: ^0.9.2

  # Location
  geolocator: ^10.1.0
  geocoding: ^2.1.1

  # Utils
  url_launcher: ^6.2.2
  intl: ^0.18.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  flutter_launcher_icons: ^0.13.1
```

### Install Dependencies:

```bash
flutter pub get
```

---

## 📱 ANDROID SETUP

### 1. AndroidManifest.xml

File: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>

    <application
        android:label="SEWS"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <!-- Notification Receivers -->
        <receiver 
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:enabled="true"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>

        <receiver 
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
            android:enabled="true"
            android:exported="true" />

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### 2. build.gradle (Project level)

File: `android/build.gradle`

```gradle
buildscript {
    ext.kotlin_version = '1.9.0'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        classpath 'com.google.gms:google-services:4.4.0'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(':app')
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
```

### 3. build.gradle (App level)

File: `android/app/build.gradle`

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

android {
    namespace "com.example.early_warning_software_for_stroke"
    compileSdk 34
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.example.early_warning_software_for_stroke"
        minSdkVersion 23
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}

flutter {
    source '../..'
}

dependencies {
    implementation 'com.google.firebase:firebase-bom:32.7.0'
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'androidx.multidex:multidex:2.0.1'
}

apply plugin: 'com.google.gms.google-services'
```

### 4. Google Services

Đảm bảo có file: `android/app/google-services.json`

Nếu chưa có:
1. Truy cập Firebase Console
2. Project Settings → General
3. Scroll xuống "Your apps"
4. Click Android icon
5. Download `google-services.json`
6. Copy vào `android/app/`

---

## 🍎 iOS SETUP

### 1. Info.plist

File: `ios/Runner/Info.plist`

Thêm các keys sau:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Cần quyền vị trí để gửi SOS khẩn cấp và tìm bệnh viện gần nhất</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>Cần quyền vị trí để theo dõi vị trí trong trường hợp khẩn cấp</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Cần quyền vị trí để theo dõi vị trí trong trường hợp khẩn cấp</string>

<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
    <string>location</string>
</array>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 2. Podfile

File: `ios/Podfile`

```ruby
platform :ios, '13.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  # Firebase
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Database'
  pod 'Firebase/Messaging'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
```

### 3. Install Pods:

```bash
cd ios
pod install
cd ..
```

### 4. GoogleService-Info.plist

Đảm bảo có file: `ios/Runner/GoogleService-Info.plist`

Nếu chưa có:
1. Truy cập Firebase Console
2. Project Settings → General
3. Scroll xuống "Your apps"
4. Click iOS icon
5. Download `GoogleService-Info.plist`
6. Copy vào `ios/Runner/`

---

## 🔨 BUILD COMMANDS

### 1. Clean Project

```bash
flutter clean
flutter pub get
```

### 2. Build Android (Debug)

```bash
flutter build apk --debug
```

### 3. Build Android (Release)

```bash
flutter build apk --release
```

### 4. Build Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

### 5. Build iOS (Debug)

```bash
flutter build ios --debug
```

### 6. Build iOS (Release)

```bash
flutter build ios --release
```

### 7. Run on Device

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Specific device
flutter devices
flutter run -d <device-id>
```

### 8. Run with Flavor (if needed)

```bash
# Development
flutter run --flavor dev

# Production
flutter run --flavor prod
```

---

## 🧪 TESTING

### 1. Check for Issues

```bash
flutter doctor -v
```

### 2. Analyze Code

```bash
flutter analyze
```

### 3. Run Tests

```bash
flutter test
```

### 4. Check Dependencies

```bash
flutter pub outdated
```

### 5. Format Code

```bash
flutter format .
```

---

## 🔍 TROUBLESHOOTING

### Issue 1: Google Sign-In Error

**Error:** `PlatformException(sign_in_failed)`

**Solution:**
```bash
# 1. Check SHA-1 fingerprint
cd android
./gradlew signingReport

# 2. Add SHA-1 to Firebase Console
# Project Settings → General → Your apps → Android
# Add SHA-1 fingerprint

# 3. Download new google-services.json
# Replace android/app/google-services.json

# 4. Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Issue 2: Firebase Database Permission Denied

**Error:** `DatabaseError: Permission denied`

**Solution:**
```bash
# 1. Check Firebase Rules (see above)
# 2. Ensure user is authenticated
# 3. Check indexes are created
# 4. Verify auth.uid matches userId
```

### Issue 3: Location Permission Not Working

**Error:** Location services disabled

**Solution:**
```bash
# Android:
# 1. Check AndroidManifest.xml has permissions
# 2. Request permissions at runtime
# 3. Enable location on device

# iOS:
# 1. Check Info.plist has usage descriptions
# 2. Request permissions at runtime
# 3. Enable location on device
```

### Issue 4: Notifications Not Showing

**Error:** Notifications not appearing

**Solution:**
```bash
# Android:
# 1. Check POST_NOTIFICATIONS permission (Android 13+)
# 2. Enable notifications in device settings
# 3. Check notification channel

# iOS:
# 1. Request notification permissions
# 2. Enable notifications in device settings
# 3. Check Info.plist configuration
```

### Issue 5: Build Failed

**Error:** Build failed with errors

**Solution:**
```bash
# 1. Clean project
flutter clean
rm -rf build/
rm -rf ios/Pods/
rm -rf ios/.symlinks/
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec

# 2. Get dependencies
flutter pub get

# 3. iOS: Reinstall pods
cd ios
pod deintegrate
pod install
cd ..

# 4. Rebuild
flutter run
```

### Issue 6: Gradle Build Error

**Error:** Gradle build failed

**Solution:**
```bash
# 1. Update Gradle
cd android
./gradlew wrapper --gradle-version 8.1.0

# 2. Clean Gradle cache
./gradlew clean
./gradlew --stop

# 3. Rebuild
cd ..
flutter clean
flutter pub get
flutter run
```

---

## ✅ VERIFICATION CHECKLIST

### Before Building:

- [ ] Firebase project created
- [ ] Firebase Rules applied
- [ ] google-services.json added (Android)
- [ ] GoogleService-Info.plist added (iOS)
- [ ] SHA-1 fingerprint added to Firebase
- [ ] Dependencies installed (`flutter pub get`)
- [ ] No errors in `flutter doctor`

### After Building:

- [ ] App launches successfully
- [ ] Login works (email/password)
- [ ] Google Sign-In works
- [ ] Location permission works
- [ ] Notifications work
- [ ] SOS feature works
- [ ] Family management works
- [ ] Reminders work

---

## 📞 SUPPORT

### Firebase Console:
https://console.firebase.google.com

### Flutter Documentation:
https://docs.flutter.dev

### Package Documentation:
- Firebase: https://firebase.flutter.dev
- Geolocator: https://pub.dev/packages/geolocator
- Notifications: https://pub.dev/packages/flutter_local_notifications

---

## 🚀 QUICK START

```bash
# 1. Clone project
git clone <your-repo>
cd early_warning_software_for_stroke

# 2. Install dependencies
flutter pub get

# 3. Setup Firebase
# - Add google-services.json (Android)
# - Add GoogleService-Info.plist (iOS)
# - Apply Firebase Rules

# 4. Run
flutter run

# 5. Build
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

---

## 📝 NOTES

### Important:
- Always test on real devices for location and notifications
- Emulators may not support all features
- Keep Firebase Rules updated
- Monitor Firebase Console for errors
- Check Firebase Usage & Billing

### Performance:
- Use `flutter build --release` for production
- Enable ProGuard for Android
- Optimize images and assets
- Use lazy loading where possible

### Security:
- Never commit google-services.json to public repos
- Use environment variables for sensitive data
- Keep dependencies updated
- Monitor security advisories

---

*Document được tạo bởi Kiro AI - 16/11/2025*
