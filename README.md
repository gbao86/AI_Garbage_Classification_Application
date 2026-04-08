# ♻️ EcoSort by Bao - Ứng Dụng Phân Loại Rác Thông Minh

[![Version](https://img.shields.io/badge/version-1.0.9-green.svg)](./CHANGELOG.md)
[![Platform](https://img.shields.io/badge/platform-Flutter-blue.svg)](https://flutter.dev)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](./LICENSE)
[![Security Policy](https://img.shields.io/badge/Security-Policy-red.svg)](./SECURITY.md)

Ứng dụng sử dụng trí tuệ nhân tạo (AI) tiên tiến để nhận diện và phân loại rác thải qua hình ảnh, giúp người dùng xử lý rác đúng cách và bảo vệ môi trường.

---

## 📌 Giới thiệu

**EcoSort by Bao** là giải pháp công nghệ nhằm hỗ trợ cộng đồng phân loại rác tại nguồn một cách dễ dàng và chính xác. Bằng cách kết hợp sức mạnh của mô hình **TFLite (Offline)**, **Google ML Kit** và **Gemini AI (Online)**, ứng dụng cung cấp khả năng nhận diện đa dạng các loại rác thải, bóc tách vật thể thông minh và đưa ra hướng dẫn xử lý chi tiết theo tiêu chuẩn môi trường.

---

## 🎥 Video Demo

> ⚠️ **Lưu ý**: Video demo hiện tại đang ở phiên bản **v1.0.1**. Ứng dụng đã được cập nhật rất nhiều về giao diện (Modern UI) và các chức năng mới ở phiên bản hiện tại (**v1.0.9**). Video demo cho phiên bản mới nhất sẽ sớm được cập nhật.

👉 [Xem Video Demo trên YouTube (v1.0.1)](https://youtu.be/YuI4tK1fNLU?si=LTzk0kVj0328i7m5)

---

## 🚀 Tính năng nổi bật (v1.0.9)

- 📷 **Nhận diện thông minh**: Chụp ảnh hoặc chọn từ thư viện để AI phân tích loại rác.
- 🛸 **Quét & Phân tách Vật thể**: Sử dụng hoạt ảnh tia laser và AI bóc tách phông nền, làm nổi bật rác thải bằng hiệu ứng gradient phát sáng chuyên nghiệp.
- 🔐 **Bảo mật & Chống Spam**: Tích hợp mã băm **MD5 Hash** định danh ảnh, ngăn chặn spam báo cáo và tối ưu hóa tài nguyên lưu trữ.
- 🎮 **Game Hệ thống 2.0**: Toàn bộ câu hỏi, ảnh và kiến thức được đồng bộ thời gian thực từ Supabase. Chế độ lọc dữ liệu sạch đảm bảo chất lượng câu hỏi.
- 🗺️ **Bản đồ điểm bỏ rác**: Tìm kiếm các điểm thu gom rác công cộng gần bạn thông qua OpenStreetMap hoàn toàn miễn phí.
- 📍 **Định vị GPS**: Tự động xác định vị trí thực tế của người dùng trên bản đồ.
- 🧠 **Cơ chế xử lý kép**: Ưu tiên phân tích Offline bằng TFLite và tự động dùng Gemini Flash Online khi cần thiết.
- 🏅 **Hệ thống Huy hiệu**: Theo dõi tiến trình và mở khóa các danh hiệu môi trường dựa trên điểm tích lũy (XP).
- 🖥️ **Web Admin Dashboard**: Hệ thống quản trị mạnh mẽ giúp duyệt báo cáo cộng đồng và cập nhật database rác thải tức thì.
- 🎨 **Giao diện Modern UI**: Thiết kế hiện đại, responsive và tối ưu hóa trải nghiệm trên nhiều loại màn hình.

---

## 🛠️ Công nghệ sử dụng

- **Flutter & Dart**: Nền tảng phát triển ứng dụng di động.
- **Supabase**: Backend-as-a-Service (Auth, Database, Storage, Realtime, Edge Functions).
- **TensorFlow Lite**: Chạy mô hình AI nhận diện rác thải ngay trên thiết bị (Offline).
- **Google ML Kit**: Bóc tách vật thể (Subject Segmentation).
- **Google Gemini API**: Phân tích chuyên sâu hình ảnh bằng mô hình ngôn ngữ lớn (VLM).
- **Crypto (MD5)**: Định danh và bảo mật dữ liệu hình ảnh.
- **OpenStreetMap**: Hệ thống bản đồ mở.

---

## 📁 Cấu trúc thư mục

```text
phan_loai_rac_qua_hinh_anh/
├── lib/                      # Mã nguồn ứng dụng Flutter
│   ├── features/             # Các tính năng (Game, Quiz, v.v.)
│   ├── models/               # Cấu trúc dữ liệu
│   ├── screens/              # Giao diện người dùng
│   ├── services/             # Logic AI, Supabase & API
│   └── utils/                # Tiện ích & Cấu hình (Env, Constants)
├── web_admin/                # Mã nguồn Web Quản trị (HTML/JS/Supabase)
├── assets/                   # Tài nguyên (Ảnh, Models AI)
├── SECURITY.md               # Chính sách bảo mật dự án
├── CHANGELOG.md              # Nhật ký thay đổi phiên bản
└── README.md                 # Hướng dẫn này
```

---

## 🏗️ Cài đặt & Chạy ứng dụng

### Yêu cầu hệ thống
- Flutter SDK 3.x
- Dart SDK
- Tài khoản Supabase (để cấu hình Database/Auth)

### Các bước cài đặt
1. **Clone repository**:
   ```bash
   git clone https://github.com/gbao86/AI_Garbage_Classification_Application.git
   cd AI_Garbage_Classification_Application
   ```

2. **Cài đặt các gói phụ thuộc**:
   ```bash
   flutter pub get
   ```

3. **Cấu hình môi trường**:
   Tạo file `.env` và chạy lệnh sau để mã hóa:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Chạy ứng dụng**:
   ```bash
   flutter run
   ```

---

## 🛡️ Bảo mật
Dự án áp dụng các tiêu chuẩn bảo mật nghiêm ngặt. Vui lòng xem chi tiết tại [SECURITY.md](./SECURITY.md).

---

## 🤝 Đóng góp
Mọi đóng góp từ cộng đồng đều được trân trọng! Nếu bạn có ý tưởng cải thiện ứng dụng, vui lòng tạo Pull Request hoặc Issue.

📥 **Trải nghiệm nhanh**: [Tải file APK cài đặt tại đây](https://drive.google.com/file/d/1Bx9xzlBwJToTYMj50hDGFpsETBDBLDlY/view?usp=sharing)

---
**Phát triển bởi Trịnh Gia Bao (gbao86)**
📧 Liên hệ: tiktokthu10@gmail.com
