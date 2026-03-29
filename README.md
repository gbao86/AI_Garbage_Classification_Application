# ♻️ Waste Classification AI - Ứng Dụng Phân Loại Rác Thông Minh

[![Version](https://img.shields.io/badge/version-1.0.4-green.svg)](./CHANGELOG.md)
[![Platform](https://img.shields.io/badge/platform-Flutter-blue.svg)](https://flutter.dev)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](./LICENSE)

Ứng dụng sử dụng trí tuệ nhân tạo (AI) tiên tiến để nhận diện và phân loại rác thải qua hình ảnh, giúp người dùng xử lý rác đúng cách và bảo vệ môi trường.

---

## 📌 Giới thiệu

**Waste Classification AI** là giải pháp công nghệ nhằm hỗ trợ cộng đồng phân loại rác tại nguồn một cách dễ dàng và chính xác. Bằng cách kết hợp sức mạnh của mô hình **TFLite (Offline)** và **Gemini AI (Online)**, ứng dụng cung cấp khả năng nhận diện đa dạng các loại rác thải và đưa ra hướng dẫn xử lý chi tiết theo tiêu chuẩn môi trường.

---

## 🎥 Video Demo

> ⚠️ **Lưu ý**: Video demo hiện tại đang ở phiên bản **v1.0.1**. Ứng dụng đã được cập nhật rất nhiều về giao diện (Modern UI) và các chức năng mới ở phiên bản hiện tại (**v1.0.4**). Video demo cho phiên bản mới nhất sẽ sớm được cập nhật.

👉 [Xem Video Demo trên YouTube (v1.0.1)](https://youtu.be/YuI4tK1fNLU?si=LTzk0kVj0328i7m5)

---

## 🚀 Tính năng nổi bật (v1.0.4)

- 📷 **Nhận diện thông minh**: Chụp ảnh hoặc chọn từ thư viện để AI phân tích loại rác.
- 🗺️ **Bản đồ điểm bỏ rác**: Tìm kiếm các điểm thu gom rác công cộng gần bạn thông qua OpenStreetMap.
- 📍 **Định vị GPS**: Tự động xác định vị trí thực tế của người dùng trên bản đồ.
- 🌍 **Đa ngôn ngữ**: Toàn bộ dữ liệu được ánh xạ sang Tiếng Việt chuẩn, dễ hiểu.
- 📱 **Hỗ trợ HEIC**: Xử lý mượt mà các định dạng ảnh chất lượng cao từ iPhone.
- 🧠 **Cơ chế xử lý kép**: Ưu tiên phân tích Offline bằng TFLite và dự phòng bằng Gemini 1.5 Flash Online.
- 🎨 **Giao diện Modern UI**: Thiết kế hiện đại, sạch sẽ và tối ưu trải nghiệm người dùng (UX).

---

## 🛠️ Công nghệ sử dụng

- **Flutter & Dart**: Nền tảng phát triển ứng dụng đa nền tảng.
- **TensorFlow Lite**: Chạy mô hình AI nhận diện rác thải ngay trên thiết bị (Offline).
- **Google Gemini API**: Phân tích chuyên sâu cho các trường hợp hình ảnh phức tạp.
- **OpenStreetMap**: Hệ thống bản đồ mở và hoàn toàn miễn phí.
- **Markdown Support**: Hiển thị kết quả hướng dẫn xử lý chuyên nghiệp.

---

## 📁 Cấu trúc thư mục

<img width="338" alt="folder structure" src="https://github.com/user-attachments/assets/5d8090be-1ef1-4347-ba02-14f0bb3bcc90" />

---

## 🏗️ Cài đặt & Chạy ứng dụng

### Yêu cầu hệ thống
- Flutter SDK 3.x
- Dart SDK
- Android Studio / VS Code

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

3. **Chạy ứng dụng**:
   ```bash
   flutter run
   ```

---

## 🤝 Đóng góp

Mọi đóng góp từ cộng đồng đều được trân trọng! Nếu bạn có ý tưởng cải thiện ứng dụng:
1. Fork dự án.
2. Tạo nhánh tính năng: `git checkout -b feature/tinh-nang-moi`.
3. Commit thay đổi: `git commit -m 'Thêm tính năng mới'`.
4. Push lên nhánh: `git push origin feature/tinh-nang-moi`.
5. Tạo Pull Request.

📥 **Trải nghiệm nhanh**: [Tải file APK cài đặt tại đây](https://drive.google.com/file/d/1213GsWXbb6MnhcNWX-Rw91m5oS8cE7Z5/view?usp=drive_link)

---

## 🕒 Lịch sử cập nhật
Xem chi tiết các thay đổi qua từng phiên bản tại [CHANGELOG.md](./CHANGELOG.md).

## 📄 Giấy phép
Dự án được phát hành theo giấy phép **GNU General Public License v3**. Xem chi tiết tại file [LICENSE](./LICENSE).

---

## ❗ Báo lỗi & Đề xuất
Nếu bạn gặp sự cố hoặc có ý tưởng mới, hãy tạo một [Issue tại đây](https://github.com/gbao86/AI_Garbage_Classification_Application/issues).

---
**Phát triển bởi Trịnh Gia Bảo**  
📧 Liên hệ: tiktokthu10@gmail.com
