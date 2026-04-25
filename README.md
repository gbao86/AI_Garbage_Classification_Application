# ♻️ EcoSort by Bao - Ứng Dụng Phân Loại Rác Thông Minh
> Ứng dụng phân loại rác bằng AI sử dụng Flutter, TFLite và Gemini AI.

[![Version](https://img.shields.io/badge/version-0.5.0-green.svg)](./CHANGELOG.md)
[![Platform](https://img.shields.io/badge/platform-Flutter-blue.svg)](https://flutter.dev)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](./LICENSE)
[![Security Policy](https://img.shields.io/badge/Security-Policy-red.svg)](./SECURITY.md)

Ứng dụng sử dụng trí tuệ nhân tạo (AI) tiên tiến để nhận diện và phân loại rác thải qua hình ảnh, giúp người dùng xử lý rác đúng cách và bảo vệ môi trường.

## 📌 Tổng quan

**EcoSort by Bao** là ứng dụng hỗ trợ phân loại rác thải thông minh thông qua hình ảnh.

Hệ thống kết hợp:
- ⚡ **TFLite (Offline)** – nhận diện nhanh ngay trên thiết bị
- 🌐 **Gemini AI (Online)** – phân tích nâng cao khi cần
- 🧠 **Google ML Kit** – bóc tách vật thể chính xác

→ Giúp người dùng phân loại rác đúng cách trong điều kiện thực tế.

---

## 🎥 Video Demo

> ⚠️ **Lưu ý**: Video demo hiện tại đang ở phiên bản **v0.0.2**. Ứng dụng đã được cập nhật rất nhiều về giao diện (Modern UI) và các chức năng mới ở phiên bản hiện tại (**v0.5.0**). Video demo cho phiên bản mới nhất sẽ sớm được cập nhật.

👉 [Xem Video Demo trên YouTube (v0.0.2)](https://youtu.be/YuI4tK1fNLU?si=LTzk0kVj0328i7m5)

---

## 🚀 Tính năng nổi bật

- 📷 Nhận diện rác bằng AI (camera & thư viện ảnh)
- 🧠 Cơ chế AI kép (Offline → Online fallback)
- 🛸 Bóc tách vật thể + hiệu ứng trực quan
- 🗺️ Bản đồ điểm bỏ rác (OpenStreetMap)
- 📍 Định vị GPS thời gian thực
- 🎮 Hệ thống game (XP, huy hiệu, quiz)
- 🔐 Chống spam bằng hash ảnh
- 🖥️ Dashboard quản trị (Supabase)
- 🎨 Giao diện hiện đại, responsive

---

## 🛠️ Công nghệ sử dụng

- **Flutter / Dart**
- **Supabase** (Auth, Database, Storage, Realtime)
- **TensorFlow Lite**
- **Google ML Kit**
- **Gemini API**
- **OpenStreetMap**

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

📥 **Trải nghiệm nhanh**: [Tải file APK cài đặt tại đây](https://drive.google.com/file/d/17-gyxwDu6FJkL1elVjXdykcm4oO5e6v_/view?usp=sharing)

---
**Phát triển bởi Trịnh Gia Bao (gbao86)**
📧 Liên hệ: tiktokthu10@gmail.com
