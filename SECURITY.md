# Security Policy (Chính sách Bảo mật)

## 🛡️ Cam kết của chúng tôi (Our Commitment)
Chúng tôi tại **EcoSort by Bao** cam kết bảo vệ dữ liệu của người dùng và tính toàn vẹn của hệ thống. Ứng dụng sử dụng các tiêu chuẩn bảo mật hiện đại từ hệ sinh thái Supabase và Google ML Kit để đảm bảo rằng thông tin cá nhân và đóng góp của bạn luôn được an toàn.

## ✅ Các phiên bản được hỗ trợ (Supported Versions)
Chúng tôi chỉ cung cấp các bản vá bảo mật cho các phiên bản chính thức mới nhất. Vui lòng cập nhật ứng dụng thường xuyên để đảm bảo an toàn.

| Phiên bản | Được hỗ trợ |
| :--- | :---: |
| 1.0.9 | ✅ Yes |
| 1.0.8 | ❌ No |
| < 1.0.7 | ❌ No |

## 🚨 Báo cáo lỗ hổng (Reporting a Vulnerability)
**Vui lòng KHÔNG công khai các vấn đề bảo mật trong mục "Issues" của GitHub.**

Nếu bạn phát hiện bất kỳ lỗ hổng bảo mật nào, vui lòng báo cáo theo quy trình sau:
1. Gửi email trực tiếp đến: `tiktokthu10@gmail.vn` (Hoặc email quản trị viên của bạn).
2. Mô tả chi tiết lỗ hổng và các bước để tái hiện lỗi (Proof of Concept).
3. Chúng tôi sẽ xác nhận báo cáo trong vòng **48 giờ** và phản hồi về lộ trình khắc phục.

## 🔐 Các biện pháp bảo mật cốt lõi (Core Security Measures)

### 1. Xác thực & Phân quyền (Auth & RLS)
- **Supabase Auth:** Toàn bộ quá trình đăng nhập và quản lý phiên (session) được xử lý bởi Supabase, đảm bảo mật khẩu được mã hóa an toàn.
- **Row Level Security (RLS):** Chúng tôi áp dụng chính sách bảo mật tầng dòng tại Database. Người dùng chỉ có quyền đọc/ghi dữ liệu thuộc sở hữu của chính họ thông qua `auth.uid()`.

### 2. Chống Spam & Bảo vệ Tài nguyên (Anti-Spam Logic)
- **Content-Addressable Storage:** Từ phiên bản **1.0.9**, mọi ảnh báo cáo rác sai đều được xử lý qua mã băm **MD5 Hash**. 
- **Duy nhất cho mỗi ảnh:** Hệ thống sẽ kiểm tra "dấu vân tay" của ảnh trước khi tải lên. Nếu cùng một tấm ảnh bị gửi nhiều lần, hệ thống sẽ tự động chặn và ghi đè (upsert), ngăn chặn việc tấn công spam làm tràn bộ nhớ lưu trữ.

### 3. Bảo vệ API & Môi trường (Environment Security)
- **Envied Encryption:** Các khóa API (Gemini, Supabase Key) được mã hóa bằng thư viện `Envied` và không bao giờ được commit trực tiếp lên repository dưới dạng văn bản thuần túy.

### 4. Quản trị An toàn (Admin Security)
- **Double Authorization:** Các thao tác nhạy cảm trên hệ thống Web Admin yêu cầu quyền quản trị viên cao cấp và được ghi lại qua **Audit Logs** để truy vết hành vi.

## 👤 Quyền riêng tư (Privacy)
- Chúng tôi không thu thập thông tin cá nhân ngoài những gì cần thiết cho tính năng Gamification (như Tên hiển thị và XP).
- Ảnh rác thải bạn gửi lên chỉ được sử dụng cho mục đích cải thiện mô hình AI và kiểm duyệt cộng đồng.
