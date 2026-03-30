# ♻️ EcoSort by Bao - Ứng Dụng Phân Loại Rác Thông Minh

[![Version](https://img.shields.io/badge/version-1.0.7-green.svg)](./CHANGELOG.md)
[![Platform](https://img.shields.io/badge/platform-Flutter-blue.svg)](https://flutter.dev)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](./LICENSE)

Ứng dụng sử dụng trí tuệ nhân tạo (AI) tiên tiến để nhận diện và phân loại rác thải qua hình ảnh, giúp người dùng xử lý rác đúng cách và bảo vệ môi trường.

---

## 📌 Giới thiệu

**EcoSort by Bao** là giải pháp công nghệ nhằm hỗ trợ cộng đồng phân loại rác tại nguồn một cách dễ dàng và chính xác. Bằng cách kết hợp sức mạnh của mô hình **TFLite (Offline)** và **Gemini AI (Online)**, ứng dụng cung cấp khả năng nhận diện đa dạng các loại rác thải và đưa ra hướng dẫn xử lý chi tiết theo tiêu chuẩn môi trường.

---

## 🎥 Video Demo

> ⚠️ **Lưu ý**: Video demo hiện tại đang ở phiên bản **v1.0.1**. Ứng dụng đã được cập nhật rất nhiều về giao diện (Modern UI) và các chức năng mới ở phiên bản hiện tại (**v1.0.7**). Video demo cho phiên bản mới nhất sẽ sớm được cập nhật.

👉 [Xem Video Demo trên YouTube (v1.0.1)](https://youtu.be/YuI4tK1fNLU?si=LTzk0kVj0328i7m5)

---

## 🚀 Tính năng nổi bật (v1.0.7)

- 📷 **Nhận diện thông minh**: Chụp ảnh hoặc chọn từ thư viện để AI phân tích loại rác.
- 🗺️ **Bản đồ điểm bỏ rác**: Tìm kiếm các điểm thu gom rác công cộng gần bạn thông qua OpenStreetMap hoàn toàn miễn phí.
- 📍 **Định vị GPS**: Tự động xác định vị trí thực tế của người dùng trên bản đồ.
- 🌍 **Đa ngôn ngữ**: Toàn bộ dữ liệu được ánh xạ sang Tiếng Việt chuẩn, dễ hiểu.
- 📱 **Hỗ trợ HEIC**: Xử lý mượt mà các định dạng ảnh chất lượng cao từ iPhone.
- 🧠 **Cơ chế xử lý kép**: Ưu tiên phân tích Offline bằng TFLite và tự động dùng Gemini Flash Online khi TFLite chưa sẵn sàng hoặc độ tin cậy dưới 80% (API Key Gemini được mã hóa để tăng bảo mật).
- 🎮 **Thử thách & Học tập 2.0**: Mini game chuyên nghiệp với 200 câu hỏi random, ảnh minh họa online, timer/streak/combo và cộng điểm chính xác sau mỗi lượt chơi.
- 🏅 **Kho huy hiệu riêng**: Hiển thị đầy đủ huy hiệu đã mở/chưa mở cùng tiến độ mở khóa badge kế tiếp ngay trên app.
- 📱 **UI/UX đa thiết bị**: Giao diện game responsive theo từng thiết bị, khắc phục tràn layout trên màn hình nhỏ.
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

```text
phan_loai_rac_qua_hinh_anh/
├── android/                  # Cấu hình dự án Android
├── assets/                   # Tài nguyên ứng dụng (Images, Models)
├── ios/                      # Cấu hình dự án iOS
├── lib/                      # Mã nguồn chính (Dart)
│   ├── models/               # Định nghĩa các lớp dữ liệu
│   ├── screens/              # Các màn hình giao diện chính
│   ├── services/             # Xử lý Logic AI & API
│   ├── theme/                # Cấu hình giao diện (Styles)
│   ├── utils/                # Hàm tiện ích & Hằng số
│   ├── widgets/              # Thành phần UI dùng chung
│   └── main.dart             # tđiểm bắt đầu của ứng dụng
├── pubspec.yaml              # Quản lý thư viện & tài nguyên
└── README.md                 # Tài liệu hướng dẫn dự án
```

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
**Phát triển bởi Trịnh Gia Bảo (gbao86)**  
📧 Liên hệ: tiktokthu10@gmail.com
