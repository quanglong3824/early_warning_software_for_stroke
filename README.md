🚀 Hệ thống Sàng lọc & Cảnh báo Sớm Rủi ro Đột quỵTên dự án (tiếng Anh): Stroke Early Warning Software (SEWS)
Loại dự án: Đồ án Tốt nghiệp
Một hệ thống đa nền tảng (Mobile & Web) ứng dụng mô hình AI (Machine Learning) để sàng lọc, giám sát và hỗ trợ ra quyết định cho việc theo dõi rủi ro đột quỵ từ xa.
🎯 Giới thiệu & Vấn đề
Đột quỵ là một trong những nguyên nhân gây tử vong và tàn tật hàng đầu. Việc theo dõi các chỉ số sức khỏe tại nhà (huyết áp, đường huyết, BMI) đóng vai trò quan trọng trong việc phòng ngừa, nhưng thường mang tính thủ công, bị động và thiếu sự kết nối.
Dự án này giải quyết vấn đề bằng cách xây dựng một hệ thống khép kín: - Thu thập dữ liệu: Bệnh nhân tự nhập chỉ số qua một ứng dụng mobile đơn giản. - Phân tích (AI): Backend sử dụng mô hình Machine Learning (.pkl đã huấn luyện) để phân tích dữ liệu và tính toán "Điểm số Rủi ro" (Risk Score) theo thời gian thực. - Cảnh báo & Can thiệp:Người thân nhận được cảnh báo ngay lập tức qua app nếu rủi ro tăng cao.Bác sĩ (hoặc SV Y khoa) có một "Bảng điều khiển Sàng lọc" (Triage Dashboard), tự động ưu tiên các bệnh nhân nguy hiểm nhất lên đầu để can thiệp.
✨ Tính năng chính
Hệ thống bao gồm 3 Giao diện Người dùng (Clients) và 1 Backend (API) thống nhất.

1. Ứng dụng Bệnh nhân (Patient App - Flutter Mobile)
   Mục tiêu: Dành cho người lớn tuổi, ưu tiên sự đơn giản.
   Tính năng:
   Giao diện với nút bấm to, văn bản rõ ràng, quy trình tối giản.
   Nhật ký sức khỏe: Nhập các chỉ số hàng ngày (Huyết áp, Đường huyết, BMI, Nhịp tim).
   Xem lịch sử đo đơn giản.
   Nhận và xem các khuyến nghị, dặn dò từ Bác sĩ.
2. Ứng dụng Người thân (Caregiver App - Flutter Mobile)
   Mục tiêu: Dành cho con cái, người thân (ví dụ: sinh viên) theo dõi từ xa.
   Tính năng:
   Quản lý và theo dõi nhiều hồ sơ bệnh nhân (ví dụ: cha và mẹ).
   Xem Dashboard trực quan: Biểu đồ, xu hướng sức khỏe của người thân.
   Nhận Thông báo Đẩy (Push Notification): Nhận cảnh báo ngay lập tức khi:
   Chỉ số của bệnh nhân vượt ngưỡng an toàn (ví dụ: Huyết áp > 160).
   Điểm rủi ro AI dự đoán tăng lên mức "Báo động".
3. Cổng thông tin Bác sĩ (Doctor Portal - Flutter Web)
   Mục tiêu: Công cụ làm việc cho Bác sĩ hoặc Sinh viên Y khoa (tại bàn làm việc).
   Tính năng:
        Bảng điều khiển Sàng lọc (Triage Dashboard): 
        Tính năng "sát thủ" của dự án. 
        Tự động hiển thị danh sách bệnh nhân đã được sắp xếp theo mức độ rủi ro (cao xuống thấp) dựa trên kết quả của mô hình AI.   
        Quản lý danh sách bệnh nhân đang theo dõi.  
        Xem chi tiết lịch sử, biểu đồ của từng bệnh nhân.
        Gửi khuyến nghị, dặn dò (sẽ hiển thị trên Patient App).

### 4) Backend (Python API & AI Core)
- API (FastAPI/Flask) quản lý CSDL (Xác thực, CRUD).
- Endpoint `/predict` để host file `stroke_model.pkl`.
- Xử lý tính toán, phân loại rủi ro và gửi cảnh báo.

#### 🏗️ Cấu trúc Hệ thống
- Clients (Flutter): 3 giao diện (Patient Mobile, Caregiver Mobile, Doctor Web) từ một codebase; dùng responsive và conditional UI.
- Backend (Python): API server giao tiếp với CSDL và thực thi mô hình `.pkl` để trả dự đoán.
- Firebase: Xác thực (Firebase Authentication) và thông báo đẩy (Firebase Cloud Messaging - FCM).

#### 💻 Công nghệ sử dụng
- Frontend: Flutter (Dart) — Xây dựng Android, iOS, Web từ 1 codebase.
- Backend: Python (FastAPI/Flask) — Host file `.pkl`, hiệu năng cao.
- Cơ sở dữ liệu: PostgreSQL/MySQL — Hỗ trợ UUID, JSON và các quan hệ phức tạp.
- Mô hình AI: scikit-learn, Pandas — Thư viện tiêu chuẩn cho `.pkl`.
- Cloud: Firebase — Xử lý Auth và FCM.
- Thiết kế CSDL: dbdiagram.io — Trực quan hóa và thiết kế schema.

#### 🗃️ Thiết kế CSDL (tóm tắt)
- Bảng lõi: `nguoi_dung`, `ho_so_benh_nhan`, `ho_so_nguoi_than`, `ho_so_bac_si`.
- Bảng dữ liệu động: `chi_so_suc_khoe` (lưu huyết áp, BMI... hằng ngày).
- Bảng AI: `ket_qua_du_doan` (lưu output của model `.pkl`).
- Bảng liên kết: `lien_ket_*` (quản lý quan hệ N-N).
- Chi tiết: xem `database/schema.dbdiagram` trong dự án.
|
|-- 📂 backend_api/ (Du an Python/FastAPI)
| |-- /models/
| | |-- stroke_model.pkl (File mo hinh AI)
| |-- /app/
| | |-- main.py (Code API)
| | |-- database.py
| | |-- crud.py
| |-- requirements.txt
|
|-- 📂 early_warning_software_for_stroke/ (Du an Flutter)
| |-- /lib/
| | |-- /core/ (Services, API client, DB local)
| | |-- /models/ (Dart models)
| | |-- /providers/ (Quan ly State - Provider/Bloc)
| | |-- /features/ (Cac man hinh chinh)
| | | |-- /auth/ (Dang nhap, Dang ky)
| | | |-- /patient_app/ (UI/Logic cho Benh nhan)
| | | |-- /caregiver_app/ (UI/Logic cho Nguoi than)
| | | |-- /doctor_portal/ (UI/Logic cho Bac si - Web)
| | |-- main.dart (Entry point, dieu huong vai tro)
| | |-- firebase_options.dart (File cau hinh tu flutterfire)
| |-- /web/
| | |-- index.html
| |-- /android/
| |-- pubspec.yaml
|
|-- 📄 README.md (Ban dang doc file nay)
🛠 Cài đặt và Chạy thửYêu cầuFlutter (Bản 3.x.x)Python (Bản 3.9+)Một CSDL PostgreSQL (hoặc MySQL)Tài khoản Firebase1. Cài đặt Backend (Python)Bash# 1. Di chuyen vao thu muc backend
cd backend_api

# 2. Tao moi truong ao

python -m venv venv
source venv/bin/activate # Tren macOS/Linux
venv\Scripts\activate # Tren Windows

# 3. Cai dat thu vien

pip install -r requirements.txt

# 4. Cau hinh bien moi truong (.env)

# (Tao file .env va cau hinh DATABASE_URL, ...)

# 5. Chay server API (Vi du voi FastAPI & Uvicorn)

uvicorn app.main:app --reload 2. Cài đặt Frontend (Flutter)Bash# 1. Di chuyen vao thu muc flutter
cd early_warning_software_for_stroke

# 2. Cau hinh Firebase (Ban da lam buoc nay)

flutterfire configure

# 3. Lay cac package

flutter pub get

# 4. Chay ung dung (Chon nen tang)

flutter run -d chrome # Chay Doctor Portal (Web)
flutter run -d [device_id] # Chay App Mobile (Android/iOS)
👤 Tác giảHọ và Tên: [Tên của bạn]MSSV: [Mã số SV của bạn]Lớp: [Lớp của bạn]GVHD: [Tên Giảng viên Hướng dẫn]
