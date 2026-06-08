# 🔐 Chính Sách Bảo Mật (Security Policy)

Chính sách bảo mật này mô tả các biện pháp bảo vệ thông tin, quản lý khóa bảo mật, cơ chế chống spam và quy trình báo cáo lỗ hổng bảo mật cho dự án **EcoSort by Bao**.

---

## 🛡️ Phiên Bản Được Hỗ Trợ (Supported Versions)

Chúng tôi chỉ cung cấp các bản cập nhật bảo mật cho phiên bản được duy trì mới nhất.

| Phiên Bản (Version) | Trạng Thái Hỗ Trợ (Supported) | Ghi Chú |
| ------------------- | ----------------------------- | ------- |
| `0.5.x`             | ✅ Có hỗ trợ (Yes)            | Phiên bản hiện tại (`v0.5.6`) |
| `< 0.5.0`           | ❌ Không hỗ trợ (No)          | Vui lòng nâng cấp lên bản mới nhất |

---

## 🚨 Báo Cáo Lỗ Hổng Bảo Mật (Reporting a Vulnerability)

**Vui lòng KHÔNG báo cáo lỗ hổng bảo mật thông qua các Issue công khai trên GitHub.**

Nếu phát hiện bất kỳ vấn đề bảo mật nào, vui lòng báo cáo một cách an toàn qua:

- 📧 **Email:** tiktokthu10@gmail.com
- 📝 **Nội dung báo cáo nên bao gồm:**
  - Mô tả chi tiết về lỗ hổng bảo mật.
  - Các bước tái hiện (Proof of Concept - PoC nếu có).
  - Tác động tiềm tàng đến hệ thống hoặc dữ liệu người dùng.

### ⏱️ Cam kết thời gian phản hồi:
- **Phản hồi ban đầu:** Trong vòng **48 giờ**.
- **Cập nhật tiến độ:** Mỗi **3–5 ngày làm việc**.
- **Thời gian khắc phục:** Tùy thuộc vào mức độ nghiêm trọng của lỗ hổng.

---

## 📌 Phạm Vi Áp Dụng (Scope)

Chính sách này áp dụng cho các thành phần trực thuộc dự án:
- 📱 Ứng dụng di động Flutter (**EcoSort by Bao**).
- ☁️ Cơ sở dữ liệu và dịch vụ Backend (**Supabase**).
- 🖥️ Trang Quản trị Web (**Web Admin Dashboard**).

Chính sách này **không** áp dụng cho:
- Dịch vụ của bên thứ ba (ví dụ: cơ sở hạ tầng của Google ML Kit, hạ tầng máy chủ của Supabase).

---

## 🔐 Các Biện Pháp Bảo Mật Hệ Thống

### 1. Xác Thực & Phân Quyền (Authentication & Authorization)
- **Supabase Auth**: Sử dụng để quản lý đăng nhập và phiên làm việc (session) an toàn cho người dùng và quản trị viên.
- **Row Level Security (RLS)**: Bắt buộc kích hoạt trên toàn bộ các bảng trong cơ sở dữ liệu Supabase. 
  - Người dùng thông thường chỉ có quyền đọc/ghi dữ liệu của chính họ (kiểm tra qua `auth.uid()`).
  - Chỉ các tài khoản có vai trò `admin` hoặc `super_admin` (được xác thực thông qua hàm cơ sở dữ liệu `public.is_admin()`) mới được phép truy cập hoặc chỉnh sửa dữ liệu hệ thống nâng cao.

### 2. Bảo Mật Khóa API & Biến Môi Trường (API Keys & Secrets)
Để cân bằng giữa tính bảo mật và khả năng vận hành của ứng dụng phía Client:
- **Ứng dụng di động Flutter**:
  - Khóa API nhạy cảm (như **Gemini API Key**) được quản lý qua file `.env` (được ẩn khỏi Git qua `.gitignore`) và mã hóa/xáo trộn (obfuscate) bằng package **Envied** khi build nhằm hạn chế tối đa việc bị dịch ngược mã nguồn (reverse engineering) để lấy khóa dạng văn bản thuần (plain text).
  - Các thông tin cấu hình môi trường khác (như `SUPABASE_URL`, `GOOGLE_WEB_CLIENT_ID`) được giữ ở dạng thông thường phục vụ kết nối.
- **Trang Quản trị Web (Web Admin)**:
  - Sử dụng tệp cấu hình sinh tự động `web_admin/js/config.js` đồng bộ từ `.env` qua script `scripts/sync_env.dart`.
  - Các khóa kết nối Supabase tại đây là khóa Client (Publishable Key / Anon Key), an toàn khi chạy trên trình duyệt vì toàn bộ dữ liệu đã được bảo vệ chặt chẽ ở tầng Backend bằng chính sách RLS.

### 3. Chống Spam & Bảo Vệ Tài Nguyên (Anti-Spam & Data Protection)
Để chống spam tải lên và phá hoại tài nguyên lưu trữ:
- **Mã hóa Hash hình ảnh (MD5 Checksum)**: Khi người dùng chụp hoặc tải lên một hình ảnh để báo cáo phân loại sai, ứng dụng sẽ tính toán mã hash MD5 của tệp ảnh đó.
- **Kiểm tra trùng lặp**: Hệ thống sẽ kiểm tra xem người dùng hiện tại đã gửi báo cáo nào có chứa mã MD5 tương tự chưa. Nếu phát hiện trùng lặp, ứng dụng sẽ chặn yêu cầu gửi mới để tránh spam dữ liệu và lãng phí băng thông lưu trữ (Storage).

### 4. Nhật Ký Hệ Thống & Kiểm Toán (Audit Logs)
- Các thao tác nhạy cảm hoặc yêu cầu đặc quyền lớn (ví dụ: thay đổi cấu hình hệ thống, phê duyệt yêu cầu) bắt buộc phải ghi lại nhật ký kiểm toán (`audit_logs`) trên Supabase để phục vụ mục đích truy vết và phát hiện xâm nhập trái phép.

---

## 🔒 Chính Sách Quyền Riêng Tư (Privacy)

Chúng tôi tôn trọng quyền riêng tư của người dùng:
- Chỉ thu thập các thông tin tối thiểu cần thiết cho tính năng gamification (như tên hiển thị, điểm kinh nghiệm XP, huy hiệu).
- Hình ảnh rác thải được tải lên hệ thống chỉ phục vụ cho việc:
  - Cải tiến độ chính xác của mô hình AI offline.
  - Phục vụ kiểm duyệt nội dung của quản trị viên để đảm bảo tính lành mạnh của cộng đồng.
- Không thu thập hoặc bán thông tin cá nhân của người dùng cho bên thứ ba.

---

## ⚖️ Cam Kết Tiết Lộ Có Trách Nhiệm (Responsible Disclosure)

- Vui lòng dành một khoảng thời gian hợp lý để chúng tôi sửa lỗi trước khi công bố thông tin ra công chúng.
- Không khai thác lỗ hổng vượt quá mức cần thiết để chứng minh (Proof of Concept).
- Tuyệt đối không truy cập, sửa đổi hoặc xóa dữ liệu của người dùng khác.

---

## 📢 Cập Nhật Bảo Mật

Mọi thay đổi liên quan đến bảo mật sẽ được ghi nhận rõ ràng tại [CHANGELOG.md](./CHANGELOG.md).

---

## 🙌 Lời Cảm Ơn

Chúng tôi vô cùng trân trọng nỗ lực của các nhà nghiên cứu bảo mật và cộng đồng đóng góp trong việc phát hiện và cải thiện độ an toàn cho hệ thống.
