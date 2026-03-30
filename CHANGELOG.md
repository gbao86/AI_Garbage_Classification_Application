# 📦 CHANGELOG

Lịch sử cập nhật các phiên bản của **EcoSort by Bao**

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
    - Tối ưu và tinh chỉnh lại mô hình AI phân loại rác để đảm bảo độ chính xác (cấm độc quyền đoán nhãn 'metal').
    - Cập nhật logic và ánh xạ dữ liệu tiếng Việt cho mô hình nhận diện 10 loại rác mới.
    - Tối ưu hóa việc xử lý nhãn và phân nhóm rác (Tái chế, Hữu cơ, Nguy hại).
- 🔐 **Gemini 2.0 API Key (mã hóa key)**: 
    - Thêm API Key Gemini 2.0 và mã hóa key để tăng bảo mật.
- 🛠️ **Hệ thống & Fix**:
    - Sửa lỗi biên dịch `camera.center!` trên Flutter 3.35+.
    - Loại bỏ hoàn toàn các cảnh báo `deprecated` (withOpacity, background).
    - Tối ưu hóa hiệu năng render bản đồ.

---

## [1.0.5] - 2026-03-30

### 🚀 Nâng cấp Premium & Tối ưu AI
- 🎨 **UI/UX Premium**: Đại tu toàn bộ giao diện theo chuẩn thiết kế quốc tế (Premium Modern UI).
    - Sử dụng font Plus Jakarta Sans hiện đại.
    - Áp dụng hệ thống Soft Shadows và Rounded Corners (28px) tạo chiều sâu.
    - Thiết kế lại Custom Bottom Navigation Bar dạng Floating cực kỳ chuyên nghiệp.
- 🗺️ **EcoSort Maps 2.0**:
    - Thêm chế độ xem Bản đồ Vệ tinh độ phân giải cao.
    - Tích hợp lớp phủ Giao thông thời gian thực.
    - Hiệu ứng **Pulsing Blue Dot** định vị người dùng sinh động.
    - Marker điểm rác thông minh kèm Metadata chi tiết (Loại rác, giờ mở cửa, mô tả).
- 🧠 **AI Engine mới**:
    - Cập nhật mô hình TFLite 10 loại rác mới nhất.
    - Tối ưu ánh xạ nhãn AI sang Tiếng Việt chuẩn.
    - Nâng cấp logic phân loại: Gộp nhóm Thủy tinh và xử lý nhãn động.
- 🛠️ **Hệ thống & Fix**:
    - Sửa lỗi `CardTheme` tương thích Flutter 3.35+.
    - Cập nhật chuẩn `withValues` thay cho `withOpacity`.
    - Tối ưu hóa việc gọi API Overpass lấy điểm rác Real-time.

---

## [1.0.4] - 2026-03-29

### ✨ Tính năng mới khởi đầu
- 🗺️ **Tính năng Bản đồ**: Thêm màn hình Bản đồ điểm bỏ rác công cộng sử dụng OpenStreetMap.
- 📍 **Định vị GPS**: Tự động xác định vị trí người dùng.
- 🌍 **Đa ngôn ngữ**: Dịch nhãn rác sang Tiếng Việt.
- 📱 **Xử lý ảnh HEIC**: Hỗ trợ định dạng ảnh từ iPhone.

---

## [1.0.3] - 2026-02-21

### 🧠 Cải tiến AI & Chuẩn hóa dữ liệu
- 🌍 **Chuẩn hóa ánh xạ nhãn tiếng Việt**: Hoàn thiện bộ quy tắc chuyển đổi nhãn để tăng tính nhất quán trên toàn ứng dụng.
- 📷 **Tối ưu tiền xử lý ảnh**: Cải thiện ổn định suy luận theo kích thước/độ sáng ảnh đầu vào.
- 🗺️ **Chuẩn bị dữ liệu bản đồ**: Tối ưu logic truy vấn điểm thu gom từ OpenStreetMap để sẵn sàng mở rộng ở phiên bản sau.
- 🛠️ **Hệ thống & Fix**: Nâng cấp tính ổn định luồng xử lý ảnh và cập nhật các đoạn tương thích nền tảng.

---

## [1.0.2] - 2026-01-25

### ✨ Hoàn thiện MVP
- 📷 **Cải thiện chọn/chụp ảnh**: Tăng độ tin cậy khi thao tác với thư viện ảnh và xử lý metadata đầu vào.
- 🤖 **Nâng cấp cơ chế dự phòng**: Tăng độ ổn định khi gọi Gemini để giảm lỗi trong điều kiện mạng không ổn định.
- 🧠 **Tối ưu mô hình TFLite**: Điều chỉnh runtime nhằm tăng tốc độ nhận dạng và giảm độ trễ.
- 🧰 **Hệ thống & Fix**: Cải thiện trải nghiệm phản hồi người dùng (loading/state) và xử lý lỗi đồng bộ hơn.

---

## [1.0.1] - 2025-05-09

### 🆕 Cập nhật
- 🧠 **Thêm API Gemini 1.5 Flash**: Hỗ trợ nhận diện thông minh.
- 🤖 **Tối ưu mô hình TFLite**: Cải thiện tốc độ nhận dạng.

---

## [1.0.0] - Initial Release (2025-05-05)
### 🚀 Ứng dụng Phân loại Rác bằng AI
- Tính năng chụp ảnh và phân loại rác cơ bản.
