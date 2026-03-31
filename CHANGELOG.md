# 📦 CHANGELOG

Lịch sử cập nhật các phiên bản của **EcoSort by Bao**

---

## [1.0.7] - 2026-03-31

### 🚀 Nâng cấp Thương hiệu & Bảo mật
- 🎨 **Biểu tượng ứng dụng mới**: Cập nhật Icon app chính thức theo phong cách hiện đại, tăng tính nhận diện thương hiệu.
- 🔐 **Bảo mật API Key**: 
    - Triển khai thư viện `Envied` để mã hóa và giấu API Key.
    - Chuyển toàn bộ cấu hình nhạy cảm sang file `.env` (đã được cấu hình gitignore).
- 🧠 **Cơ chế xử lý kép (TFLite → Gemini Flash)**:
    - Sử dụng model **gemini-flash-latest** (luôn cập nhật bản Flash mới nhất) cho tốc độ phản hồi siêu nhanh.
    - Ưu tiên phân tích Offline bằng TFLite 10 lớp để tiết kiệm tài nguyên.
    - Tự động gọi Gemini Online khi TFLite chưa sẵn sàng hoặc độ tin cậy dưới 80%.
- 🎮 **Thử thách & Học tập 2.0**:
    - Mini game chuyên nghiệp với 200 câu hỏi random, ảnh minh họa online, timer/streak/combo và cộng điểm chính xác sau mỗi lượt chơi.
- 🏅 **Kho huy hiệu riêng**: 
    - Hiển thị đầy đủ huy hiệu đã mở/chưa mở cùng tiến độ mở khóa badge kế tiếp ngay trên ứng dụng.
- 📱 **UI/UX đa thiết bị**:
    - Giao diện game responsive theo từng thiết bị, khắc phục tràn layout trên màn hình nhỏ.
- 🛠️ **Hệ thống & Fix**:
    - Tối ưu ảnh (resize/compress) trước khi gửi lên Cloud để giảm độ trễ và tiết kiệm băng thông.
    - Chuẩn hóa định dạng Markdown cho toàn bộ kết quả phân tích.

---

## [1.0.6] - 2026-03-31

### 🚀 Nâng cấp & Sửa lỗi quan trọng
- 🧭 **Tính năng La bàn (Compass)**: 
    - Thêm nút la bàn tự động xuất hiện khi xoay bản đồ.
    - Hỗ trợ quay bản đồ về hướng chính Bắc nhanh chóng bằng một chạm.
- 📍 **Sửa lỗi Định vị GPS**:
    - Khắc phục triệt để lỗi Marker người dùng bị "kéo theo" tâm bản đồ khi vuốt.
    - Marker hiện tại sẽ đứng yên tại vị trí GPS thực tế theo tiêu chuẩn Google Maps.
- 🏷️ **Rebranding**: Chính thức đổi tên ứng dụng thành **EcoSort by Bao** để tăng tính thân thiện và cá nhân hóa.
- 🧠 **AI Engine 10 Classes**:
    - Cập nhật logic và ánh xạ dữ liệu tiếng Việt cho mô hình nhận diện 10 loại rác mới.
    - Tối ưu hóa việc xử lý nhãn và phân nhóm rác (Tái chế, Hữu cơ, Nguy hại).
- 🛠️ **Hệ thống & Fix**:
    - Sửa lỗi biên dịch `camera.center!` trên Flutter 3.35+.
    - Loại bỏ hoàn toàn các cảnh báo `deprecated` (withOpacity, background).
    - Tối ưu hóa hiệu năng render bản đồ.

---

## [1.0.5] - 2026-03-30

### 🚀 Nâng cấp Premium & Tối ưu AI
- 🎨 **UI/UX Premium**: Đại tu toàn bộ giao diện theo chuẩn thiết kế quốc tế (Premium Modern UI).
- 🗺️ **EcoSort Maps 2.0**: Thêm chế độ vệ tinh, giao thông và metadata điểm rác.
- 🛠️ **Hệ thống & Fix**: Sửa lỗi `CardTheme` tương thích Flutter 3.35+.

---

## [1.0.4] - 2026-03-29

### ✨ Tính năng mới khởi đầu
- 🗺️ **Tính năng Bản đồ**: Thêm màn hình Bản đồ điểm bỏ rác công cộng sử dụng OpenStreetMap.
- 📍 **Định vị GPS**: Tự động xác định vị trí người dùng.
- 🌍 **Đa ngôn ngữ**: Dịch nhãn rác sang Tiếng Việt.
- 📱 **Xử lý ảnh HEIC**: Hỗ trợ định dạng ảnh từ iPhone.

---

## [1.0.1] - 2025-05-09

### 🆕 Cập nhật
- 🧠 **Thêm API Gemini 1.5 Flash**: Hỗ trợ nhận diện thông minh.
- 🤖 **Tối ưu mô hình TFLite**: Cải thiện tốc độ nhận dạng.

---

## [1.0.0] - Initial Release (2025-05-05)
### 🚀 Ứng dụng Phân loại Rác bằng AI
- Tính năng chụp ảnh và phân loại rác cơ bản.
