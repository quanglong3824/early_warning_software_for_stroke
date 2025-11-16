# 🌐 WEB DEPLOYMENT GUIDE

**Platform:** Flutter Web  
**Port:** 8080  
**Status:** ✅ Running

---

## 🚀 QUICK START

```bash
# Run on web
flutter run -d web-server --web-port=8080

# Build for production
flutter build web --release

# Preview build
cd build/web
python3 -m http.server 8080
```

---

## 📝 NOTES

### Web Limitations:
- ❌ Local Notifications không hoạt động
- ❌ Background location tracking hạn chế
- ⚠️ GPS location có thể kém chính xác hơn mobile
- ⚠️ Google Sign-In cần config riêng cho web

### Web Advantages:
- ✅ Không cần install
- ✅ Cross-platform
- ✅ Easy to share (URL)
- ✅ Auto updates

---

## 🔧 WEB-SPECIFIC CONFIG

### 1. index.html
File: `web/index.html`

Đảm bảo có Firebase config:
```html
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-auth-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-database-compat.js"></script>
```

### 2. Firebase Config
```javascript
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT.firebaseapp.com",
  databaseURL: "https://YOUR_PROJECT.firebaseio.com",
  projectId: "YOUR_PROJECT",
  storageBucket: "YOUR_PROJECT.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID"
};
```

---

## 🌍 ACCESS APP

Sau khi build xong, truy cập:

```
http://localhost:8080
```

---

## 🐛 TROUBLESHOOTING

### Issue: CORS Error
```bash
# Run with CORS disabled (Chrome)
open -na Google\ Chrome --args --user-data-dir=/tmp/chrome_dev --disable-web-security
```

### Issue: Firebase not working
- Check firebase config in web/index.html
- Verify Firebase Hosting setup
- Check browser console for errors

---

*Web Deployment Guide - 16/11/2025*
