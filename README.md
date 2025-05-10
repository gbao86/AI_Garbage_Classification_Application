♻️ Ứng Dụng Phân Loại Rác AI

Phiên bản: 1.0.1
Tác giả: gbao86
Nền tảng: Flutter (đa nền tảng: Android, iOS, Web, Desktop)


---

📌 Giới thiệu

Ứng dụng sử dụng trí tuệ nhân tạo để phân loại rác thải thông qua hình ảnh. Người dùng có thể chụp ảnh hoặc tải lên hình ảnh rác thải, và ứng dụng sẽ phân loại chúng vào các nhóm như: rác hữu cơ, vô cơ, tái chế, v.v.


---

🚀 Tính năng

📷 Nhận diện rác thải từ hình ảnh

🧠 Phân loại rác bằng mô hình AI tích hợp

💾 Hỗ trợ đa nền tảng: Android, iOS, Web, Desktop

🌐 Giao diện người dùng thân thiện và dễ sử dụng



---

🛠️ Cài đặt

Yêu cầu

Flutter SDK 3.x

Dart SDK

Thiết bị hoặc trình giả lập Android/iOS hoặc trình duyệt Web


Các bước cài đặt

1. Clone repository:

git clone https://github.com/gbao86/AI_Garbage_Classification_Application.git
cd AI_Garbage_Classification_Application


2. Cài đặt các gói phụ thuộc:

flutter pub get


3. Chạy ứng dụng:

Android/iOS:

flutter run

Web:

flutter run -d chrome




---

📁 Cấu trúc thư mục

AI_Garbage_Classification_Application/ 
├── assets/                   # Thư mục chứa hình ảnh, icon, v.v. 
|     └── images/             # Hình minh họa giao diện, 
|     ├── models/             # Các model dữ liệu mô hình 
├── lib/                      # Code chính của ứng dụng Flutter   
       ├── screens/              # Các màn hình giao diện chính 
       ├── services/             # Dịch vụ gọi API và xử lý logic 
       ├── utils/                # Các tiện ích dùng chung 
       └── widgets/              # Các widget tái sử dụng 
├── android/                 # Mã Android gốc 
├── ios/                     # Mã iOS gốc 
├── pubspec.yaml             # File cấu hình dự án Flutter 
├── README.md                # Tài liệu giới thiệu dự án 
├── LICENSE                  # Giấy phép MIT 
└── CHANGELOG.md             # Lịch sử cập nhật phiên bản


---

🧪 Công nghệ sử dụng

Flutter: Phát triển ứng dụng đa nền tảng

TensorFlow Lite: Mô hình AI nhẹ cho thiết bị di động

Dart: Ngôn ngữ lập trình chính


---

🤝 Đóng góp

Rất hoan nghênh mọi đóng góp từ cộng đồng! Nếu bạn muốn cải thiện ứng dụng, vui lòng:

1. Fork repository


2. Tạo nhánh mới: git checkout -b feature/ten-tinh-nang


3. Commit thay đổi: git commit -m 'Thêm tính năng mới'


4. Push lên nhánh của bạn: git push origin feature/ten-tinh-nang


5. Tạo Pull Request


---

🕒 Lịch sử phiên bản

Xem chi tiết tại [CHANGELOG](./CHANGELOG.md)

---

📄 Giấy phép

Dự án này được phát hành theo giấy phép [MIT License](./LICENSE).


---

❗ Báo lỗi & Đề xuất

Gặp sự cố? Có ý tưởng cải tiến?  
Hãy tạo một [Issue tại đây](https://github.com/gbao86/AI_Garbage_Classification_Application/issues) để cùng nhau cải thiện dự án nhé!

