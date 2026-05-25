# CHANGELOG — EcoSort Web Admin

Tất cả các thay đổi đáng chú ý của module **Web Admin** sẽ được ghi lại tại đây.

Định dạng theo chuẩn [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [0.1.1] - 2026-05-25

### 🛡️ Hành động đặc quyền & Duyệt 2 bước (Privileged Actions & Double-Approval)
- **Hàng đợi yêu cầu đặc quyền:** Thêm Tab giao diện quản lý danh sách yêu cầu nhạy cảm (`privileged_action_requests`) kèm bộ lọc trạng thái và phân trang.
- **Phê duyệt & Từ chối:** Hỗ trợ xem chi tiết yêu cầu, danh sách phê duyệt từ `privileged_action_approvals` và cho phép Admin phê duyệt (gọi RPC `privileged_action_add_approval`) hoặc Từ chối yêu cầu.
- **Thực thi tự động:** Cho phép thực thi trực tiếp hành động trên UI (đổi role trong profiles, xoá điểm bỏ rác, bật/tắt Kill Switch) sau khi đạt đủ 2 chữ ký từ Admin khác nhau.
- **Tạo yêu cầu thủ công:** Form tạo yêu cầu đặc quyền mới cho Admin.

### ⚙️ Quản lý cấu hình hệ thống (System Settings)
- **Giao diện cấu hình tập trung:** Thêm Tab quản lý cấu hình hệ thống nạp trực tiếp từ `system_settings` (Bảo trì, Ngắt khẩn cấp, Điểm thưởng trò chơi, AI Gemini Model).
- **Phân quyền theo vai trò (RBAC):** Chỉ có `super_admin` được quyền chỉnh sửa và lưu cấu hình hệ thống; `admin` thường chỉ được quyền Xem (các trường nhập liệu bị khóa).

### 👤 Tối ưu hóa Quản lý User
- **Liên kết nâng/hạ cấp nhanh:** Bổ sung nút "Đề xuất nâng lên Admin" và "Đề xuất hạ xuống User" trong Modal Quản lý User để gửi yêu cầu đặc quyền duyệt 2 bước nhanh chóng.
- **Sửa lỗi cú pháp Promise:** Khắc phục lỗi runtime gán Promise sai cách khi kiểm tra hành động tự nâng/hạ quyền chính mình trong hàm `openUserActionModal`.

### 📦 Build & Đóng gói
- Khởi chạy thành công bộ đóng gói sản phẩm tĩnh Vite đảm bảo ứng dụng không lỗi cú pháp.

### 🔒 Bảo mật XSS & Tái cấu trúc ES Modules
- **Ngăn chặn XSS qua Exception (XSS Prevention)**: Khắc phục cảnh báo CodeQL `js/xss-through-exception` bằng cách mã hóa HTML các thông điệp ngoại lệ (`e.message`) khi ghi đè vào thuộc tính `innerHTML` của các phần tử DOM.
- **Tách cấu trúc Module Javascript (ES Modules)**: Tái cấu trúc tệp `dashboard.html` bằng cách di chuyển toàn bộ logic JavaScript sang hai tệp module chuyên biệt:
  - `js/dashboard_api.js`: Quản lý tất cả các yêu cầu kết nối cơ sở dữ liệu Supabase và lời gọi hàm RPC.
  - `js/dashboard_ui.js`: Quản lý các biến trạng thái giao diện (View State), render phần tử DOM, xử lý sự kiện hiển thị modal/tab và xuất ra cửa sổ `window` toàn cục để duy trì sự tương thích với mã HTML cũ.

---

## [0.1.0] - 2026-04-25

### 🏗️ Cơ sở hạ tầng (Infrastructure)

- **Chuyển đổi sang Vite (Node.js):** Loại bỏ hoàn toàn server tĩnh Express; toàn bộ dự án Web Admin được migrate sang môi trường Vite để có Hot Module Replacement (HMR) và quản lý luồng log tập trung.
- **Cấu hình Vite + PostCSS + Tailwind CSS:** Thiết lập `vite.config.js`, `postcss.config.cjs`, `tailwind.config.cjs` và file nguồn `src/tailwind.css` để xử lý CSS tự động khi build.
- **Tích hợp `@supabase/supabase-js` qua npm:** Thay thế hoàn toàn việc nạp thư viện Supabase từ CDN bên ngoài (gây lỗi cache 304, treo trình duyệt) bằng module cục bộ từ `node_modules`.
- **Dev server:** Khởi chạy bằng `npm run dev` thay vì chạy nền ngầm không kiểm soát, server mặc định tại `http://localhost:5173`.
- **`env.sample`:** Thêm file mẫu biến môi trường, hướng dẫn cấu hình `SUPABASE_URL` và `SUPABASE_ANON_KEY`.

### 🔐 Xác thực & Phân quyền (Auth & RBAC)

- **Sửa lỗi `column profiles.email does not exist`:** Cập nhật `auth.js` để lấy email từ session (`auth.users`) thay vì truy vấn vào bảng `public.profiles` (nơi không có cột email).
- **Kiểm tra quyền Admin tại đăng nhập (`checkAdminPermissions`):** Hàm kiểm tra `role` từ bảng `public.profiles` trước khi cho phép vào Dashboard. Chỉ `admin` và `super_admin` được phép truy cập.
- **Tự động đá văng User thường:** Nếu tài khoản đăng nhập không thuộc role được phép, hệ thống tự động gọi `signOut()` và hiển thị thông báo từ chối.
- **Trả về `role` trong `checkAdminPermissions`:** Cập nhật để hàm trả về `{ id, email, role }` nhằm phục vụ phân quyền UI sau khi đăng nhập.
- **Phân quyền RBAC UI (Cosmetic):**
  - `super_admin` có toàn quyền thao tác trên tất cả tài khoản.
  - `admin` chỉ được quản lý `admin` và `user`, **không thể tác động lên `super_admin`**.
  - Nút "QUẢN LÝ" tự động bị vô hiệu hóa (disabled + tooltip) khi Admin xem thông tin Super Admin.
  - Nếu Admin cố tình bypass CSS và gọi hàm JS, hệ thống vẫn chặn bằng kiểm tra trong `openUserActionModal`.
- **Xóa vai trò Moderator:** Loại bỏ hoàn toàn `moderator` khỏi giao diện vì chưa được thiết kế nghiệp vụ.

### 🗂️ Dashboard - Tab Duyệt Rác (Submissions)

- **Giao diện Card duyệt báo cáo:** Hiển thị danh sách báo cáo rác từ bảng `waste_submissions` theo trạng thái (Chờ duyệt / Đã duyệt / Từ chối).
- **Modal Chi tiết Báo cáo:** Xem đầy đủ ảnh, tên AI đề xuất, nhãn TFLite + độ tin cậy, phân tích Gemini, Fun Fact.
- **UX Duyệt vào Hệ thống (Approve Modal):** Thay thế hộp thoại `confirm()` cơ bản bằng một Modal Form hoàn chỉnh:
  - Điền sẵn `suggested_name_vi` và `suggested_fun_fact` từ AI.
  - Dropdown chọn Nhóm Rác (`waste_group_id`) được nạp tự động từ bảng `public.waste_groups` (Tái chế, Hữu cơ, Nguy hại, Không tái chế).
  - Tự động tạo `slug` tiếng Việt không dấu (slugify) kèm chuỗi ngẫu nhiên để chống trùng lặp.
  - Khi xác nhận: Insert bản ghi mới vào `public.waste_dictionary` + Update trạng thái submission thành `approved`.
  - Nút Từ Chối: Cập nhật trạng thái submission thành `rejected`.
- **Phân tách logic RPC:** Thay thế lệnh gọi RPC cũ `admin_approve_waste_submission` bằng logic trực tiếp phía Client JS để linh hoạt truyền tham số đầy đủ.

### 👥 Dashboard - Tab Quản lý Người dùng (User Management)

- **Bảng danh sách người dùng (Data Table):** Hiển thị Avatar (chữ cái đầu), Tên hiển thị, Email, Vai trò (Badge màu), Trạng thái hoạt động/bị khóa, Thời gian đăng nhập lần cuối.
- **Toolbar:** Thanh tìm kiếm theo Email/Tên, Bộ lọc theo Role (User/Admin/Super Admin), Bộ lọc theo Trạng thái (Hoạt động/Bị khóa).
- **Phân trang (Pagination):** Giới hạn 25 dòng mỗi trang với nút Trước/Sau. Hiển thị thông tin tổng số (`total_count` từ RPC).
- **Gọi RPC `admin_get_users`:** Kết nối tới PostgreSQL Function được tạo với `SECURITY DEFINER`, hỗ trợ tham số `p_page`, `p_limit`, `p_search`. Trả về email thực từ `auth.users` một cách an toàn.
- **User Action Modal:** Bảng thao tác 2 nhóm:
  - *Tác vụ Bảo mật:* Gửi link Reset Password qua email (`db.auth.resetPasswordForEmail`), Xem Audit Logs.
  - *Tác vụ Kiểm soát:* Khóa (Ban) / Mở khóa (Unban) tài khoản kèm lý do bắt buộc. Gọi RPC `admin_ban_user` phía Backend (thực hiện 3 bước: update profiles, ban auth.users 100 năm, xóa sessions).
- **Error handling thông minh:** Nếu RPC chưa được tạo trên Database, hiển thị thông báo lỗi tường minh chỉ dẫn cách khắc phục thay vì crash ứng dụng.

### 🛠️ SQL / Database (Hướng dẫn thiết lập)

- **`admin_get_users` RPC:** Function `SECURITY DEFINER` với `search_path = public, auth`, kiểm tra quyền trước khi trả về dữ liệu. Sửa lỗi `column reference "id" is ambiguous` bằng cách dùng tên bảng đầy đủ `public.profiles.id`.
- **`admin_ban_user` RPC:** Function 3 bước: Update `public.profiles`, Update `auth.users.banned_until`, Delete `auth.sessions`. Ghi Audit Log tự động. Ngăn Admin khóa Super Admin.
