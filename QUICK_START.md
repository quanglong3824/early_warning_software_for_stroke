# 🚀 Quick Start Guide

## Chạy Ứng Dụng (Chỉ 1 Lệnh)

```bash
./start.sh
```

**Tất cả output sẽ hiển thị trực tiếp trên terminal!**

## Dừng Ứng Dụng

Nhấn `Ctrl+C`

## URLs

- **Flutter App**: Xem trong terminal output
- **Flask API**: http://localhost:5001

---

## Yêu Cầu

- Flutter SDK (đã cài trong `~/development/flutter`)
- Python 3.8+ với các packages: flask, scikit-learn==1.6.1, pandas

## Troubleshooting

### Lỗi: "Flutter command not found"
```bash
source ~/.zshrc
```

### Lỗi: "Port 5001 already in use"
Script `./start.sh` đã tự động xử lý việc này! Nó sẽ tự động kill process cũ trước khi chạy mới.
Nếu vẫn gặp lỗi, bạn có thể chạy thủ công:
```bash
lsof -ti :5001 | xargs kill -9
```

### Lỗi: "No module named 'flask'"
```bash
pip3 install flask flask-cors scikit-learn==1.6.1 numpy pandas joblib
```
