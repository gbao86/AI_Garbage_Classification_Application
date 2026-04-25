# 📦 CHANGELOG

Lịch sử cập nhật các phiên bản của **EcoSort by Bao**

---

## [0.5.0] - 2026-04-13

### 🧠 Tự động hóa Huấn luyện AI (MLOps & Cloud Training)
- 🤖 **GitHub Actions Training**: Thiết lập quy trình tự động huấn luyện lại model AI trên đám mây khi đạt ngưỡng dữ liệu mới (50 ảnh được duyệt).
- 📈 **Chiến lược Huấn luyện Chuyên nghiệp**:
    - Triển khai kỹ thuật **Transfer Learning** với MobileNetV2.
    - Quy trình 2 giai đoạn: **Warm-up** (20 epochs) và **Fine-tuning** (50 epochs) với cơ chế **EarlyStopping** để tối ưu độ chính xác.
    - Tích hợp **Data Augmentation** (nhiễu hạt, biến đổi màu sắc, độ sáng) giúp model bền bỉ hơn trong điều kiện thực tế.
- 📝 **Đồng bộ hóa Nhãn**: Tự động sinh file `labels.txt` khớp với kiến trúc model mới sau mỗi lần train.

### 💼 Nâng cấp Web Admin UX (Content Editorial)
- ✍️ **Màn hình Biên tập Chuyên sâu**: Thêm giao diện chỉnh sửa dữ liệu (Tên chuẩn, Fun Fact) trước khi phê duyệt chính thức.
- 🛠️ **Luồng Duyệt 2 Bước**: Cập nhật thông tin biên tập và tự động "thăng hạng" rác vào Từ điển hệ thống thông qua Database RPC.
- 📊 **Minh bạch Dữ liệu AI**: Hiển thị nhãn TFLite và phân tích Gemini trực tiếp trong trình biên tập để Admin tham khảo.

### 📸 Tối ưu hóa Trải nghiệm Camera & Báo cáo
- 💡 **Sửa lỗi Brightness Check**: 
    - Khắc phục triệt để lỗi kẹt nút "Chụp lại" không phản hồi khi ảnh tối.
    - Tối ưu hóa thuật toán tính độ sáng bằng cách sử dụng ảnh thumbnail (100x100), giảm 99% tải RAM và triệt tiêu lỗi đồ họa GPU.
- 🚩 **Nâng cấp Báo cáo Phân loại**: Cho phép người dùng nhập tên vật phẩm đúng khi báo cáo ảnh sai, đồng thời tự động gửi kèm dữ liệu AI (Label, Confidence) về Server.
- ⚙️ **Hiện đại hóa Hạ tầng**:
    - Nâng cấp dự án lên **Java 17** và đồng bộ **jvmTarget** để đảm bảo tính ổn định.
    - Cấu hình **Gradle Toolchain** giúp tự động hóa việc quản lý JDK trên các môi trường khác nhau.

### 🛠️ Sửa lỗi & Cải thiện liên lạc (Hotfix & Connectivity)
- 📧 **Sửa lỗi Gửi Email**: Khai báo `mailto` scheme trong AndroidManifest để mở ứng dụng Email ổn định trên Android 11+.
- 🌐 **Sửa lỗi Mở Facebook**: Khai báo `https` scheme và tối ưu hóa logic `launchUrl` để ưu tiên mở ứng dụng Facebook thay vì trình duyệt.
- 💬 **Tối ưu hóa UX Email**: Tự động điền Tiêu đề và Nội dung mẫu khi người dùng nhấn liên hệ Admin.
- 🎨 **Cải thiện UI Liên hệ**: Thêm hiệu ứng gợn sóng (Ripple) và icon chỉ báo cho các nút liên lạc trên màn hình About.

---

## [0.4.0] - 2026-04-08

### 🛡️ Bảo mật & Chống Spam (Security & Anti-Spam)
- 🔐 **Chính sách Bảo mật (SECURITY.md)**: Thiết lập chính sách bảo mật chính thức cho dự án, cam kết bảo vệ dữ liệu người dùng và quy trình báo cáo lỗ hổng.
- 🧬 **Định danh ảnh bằng MD5 Hash**: Tích hợp thuật toán MD5 để tạo "dấu vân tay" duy nhất cho mỗi ảnh báo cáo.
- 🚫 **Chống Spam Báo cáo triệt để**:
    - Ngăn chặn việc gửi nhiều báo cáo cho cùng một tấm ảnh bằng cách kiểm tra mã băm trên cả Local và Server.
    - Sử dụng cơ chế `upsert` trên Supabase Storage để ghi đè thay vì tạo file mới khi trùng mã băm.
- 📑 **Chống gửi trùng dữ liệu Database**: Tự động khóa nút báo cáo và hiển thị trạng thái "Đã gửi" ngay khi phát hiện ảnh đã tồn tại trong hệ thống.

### 🎮 Nâng cấp Hệ thống Game (Game System 2.0)
- ☁️ **Dữ liệu Game Động (Dynamic Data)**: Chuyển toàn bộ database câu hỏi từ code cứng (hardcoded) lên Supabase.
- 🔄 **Đồng bộ hóa thời gian thực**: Game tự động cập nhật câu hỏi, link ảnh và fun fact mới nhất ngay khi Admin phê duyệt đóng góp từ cộng đồng.
- 🧹 **Bộ lọc Dữ liệu Sạch**: Tự động loại bỏ các câu hỏi thiếu thông tin hoặc chưa được Admin chuẩn hóa để đảm bảo trải nghiệm người chơi.

### 💼 Quản trị Hệ thống (Admin Dashboard 3.0)
- 🖥️ **Web Admin Hiện đại**: Nâng cấp giao diện quản trị với phong cách thiết kế mới, sử dụng Modal thay cho các hộp thoại cũ.
- ✍️ **Quy trình Phê duyệt Chuẩn**: Admin có thể chỉnh sửa tên rác, thêm Fun Fact và tạo Slug định danh ngay trong quá trình duyệt báo cáo rác sai từ người dùng.
- 🚀 **Sẵn sàng Deploy**: Tối ưu hóa mã nguồn Web Admin để triển khai lên các nền tảng như Vercel/GitHub Pages.

---

## [0.3.0] - 2026-04-02

### ✨ Tính năng Hình ảnh & Hiệu ứng AI (Visual & AI Effects)
- 🛸 **Hoạt ảnh Quét Laser**: Thêm tia laser quét ảnh từ trên xuống, tạo cảm giác công nghệ và "đánh lừa thị giác" giúp người dùng không có cảm giác phải chờ đợi AI phân tích.
- 🎯 **Phân tách Vật thể (Subject Segmentation)**: Tích hợp `Google ML Kit Subject Segmentation` để nhận diện, bóc tách chính xác hình dáng vật thể/rác thải ra khỏi phông nền.
- 🌌 **Hiệu ứng Thị giác Nâng cao (Visual FX)**:
  - Tự động làm mờ (Blur) phần phông nền xung quanh bằng GPU siêu mượt.
  - Giữ độ sắc nét tuyệt đối cho vật thể được nhận diện.
  - Áp dụng dải sáng gradient xanh lướt liên tục trên vật thể để làm nổi bật tâm điểm.

### ⚡ Tối ưu Hiệu năng & UI/UX
- 🔄 **Xử lý AI Đa luồng (Background Processing)**: Mô hình TFLite và Gemini API được đẩy xuống chạy ngầm hoàn toàn độc lập với giao diện, đảm bảo UI không bao giờ bị giật lag (freeze) trong quá trình quét.
- 🔤 **Văn bản Chuyển động Mượt mà**: Trạng thái và kết quả phân tích (khi Gemini trả về sau) được tự động cập nhật với hiệu ứng chuyển đổi êm ái (Fade & Slide) bằng `AnimatedSwitcher`.
- 🗜️ **Chống Tràn Bộ Nhớ (OOM Protection)**: Ép khung và nén mọi loại ảnh (không chỉ HEIC) về kích thước an toàn (~1080p) trước khi đưa qua ML Kit, triệt tiêu hoàn toàn lỗi văng app do tràn RAM (Out of Memory).

### 🛠️ Hệ thống & Sửa lỗi (Bug Fixes)
- 🧭 **Sửa lỗi Hướng ảnh (EXIF)**: Đọc chính xác chiều xoay dọc/ngang của ảnh từ camera, khắc phục triệt để lỗi vật thể bị nhận diện méo mó, cắt xéo.
- ⚙️ **Sửa lỗi Render Đồ họa Android**: Tạm tắt engine Impeller trên Android để chuyển về Skia, khắc phục hoàn toàn lỗi sọc nhằng màn hình và lỗi từ chối cấp phát bộ nhớ GPU (`GraphicBufferAllocator`) khi render nhiều lớp BlendMode phức tạp.

---

## [0.2.0] - 2026-03-31

### 🚀 Nâng cấp Thương hiệu & Bảo mật
- 🎨 **Biểu tượng ứng dụng mới**: Cập nhật Icon app chính thức theo phong cách hiện đại, tăng tính nhận diện thương hiệu.
- 🔐 **Bật mật API Key**:
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

## [0.1.2] - 2026-03-31

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

## [0.1.1] - 2026-03-30

### 🚀 Nâng cấp Premium & Tối ưu AI
- 🎨 **UI/UX Premium**: Đại tu toàn bộ giao diện theo chuẩn thiết kế quốc tế (Premium Modern UI).
- 🗺️ **EcoSort Maps 2.0**: Thêm chế độ vệ tinh, giao thông và metadata điểm rác.
- 🛠️ **Hệ thống & Fix**: Sửa lỗi `CardTheme` tương thích Flutter 3.35+.

---

## [0.1.0] - 2026-03-29

### ✨ Tính năng mới khởi đầu
- 🗺️ **Tính năng Bản đồ**: Thêm màn hình Bản đồ điểm bỏ rác công cộng sử dụng OpenStreetMap.
- 📍 **Định vị GPS**: Tự động xác định vị trí người dùng.
- 🌍 **Đa ngôn ngữ**: Dịch nhãn rác sang Tiếng Việt.
- 📱 **Xử lý ảnh HEIC**: Hỗ trợ định dạng ảnh từ iPhone.

---

## [0.0.2] - 2025-05-09

### 🆕 Cập nhật
- 🧠 **Thêm API Gemini 1.5 Flash**: Hỗ trợ nhận diện thông minh.
- 🤖 **Tối ưu mô hình TFLite**: Cải thiện tốc độ nhận dạng.

---

## [0.0.1] - Initial Release (2025-05-05)
### 🚀 Ứng dụng Phân loại Rác bằng AI
- Tính năng chụp ảnh và phân loại rác cơ bản.
