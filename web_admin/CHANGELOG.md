# CHANGELOG — EcoSort Web Admin

Tất cả các thay đổi đáng chú ý của module **Web Admin** sẽ được ghi lại tại đây.

Định dạng theo chuẩn [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [0.1.3] - 2026-09-21

### 🎮 Quản lý Ngân hàng Câu hỏi Game Quiz (Game Questions Management)
- **Tab Quản trị mới trên Sidebar**: Bổ sung tab **Bộ câu hỏi Game** (`game_questions`) với icon puzzle trực quan, hỗ trợ quản lý toàn diện ngân hàng câu hỏi phân loại rác cho tính năng Game Quiz trên ứng dụng di động.
- **Biên soạn & Thêm câu hỏi trực tiếp qua Modal (Thay thế nhập liệu thủ công qua SQL Supabase)**:
  - Cho phép Admin thêm câu hỏi mới trực tiếp từ giao diện web mà không cần phải truy cập Supabase viết câu lệnh SQL thủ công.
  - **Form nhập liệu thông minh (`#question-modal`)**:
    - Tên vật phẩm / loại rác (`name_vi`).
    - Nhóm phân loại đúng (`waste_group_id` nạp tự động từ danh mục nhóm rác hệ thống).
    - Link hình ảnh từ internet (URL bên ngoài giúp tối ưu dung lượng lưu trữ CSDL Supabase).
    - Khung xem trước hình ảnh trực tiếp (Live Image Preview) kèm cơ chế fallback thông minh khi link ảnh lỗi.
    - Kiến thức bổ sung / Mẹo sống xanh (`fun_fact`).
    - Công tắc kích hoạt / tạm ẩn câu hỏi (`is_active`).
  - Tự động sinh `slug` tiếng Việt chuẩn hóa kết hợp hậu tố bảo mật ngẫu nhiên (`generateSecureRandomString`) để đảm bảo tính toàn vẹn dữ liệu trong `waste_dictionary`.
  - Tự động tạo bản ghi trong `waste_dictionary` và liên kết với `game_questions` chỉ qua 1 lần nhấn Lưu.
- **Thao tác nhanh trên từng Card câu hỏi**:
  - **Kích hoạt / Tạm tắt tức thì (1-Click Toggle)**: Đổi trạng thái hiển thị câu hỏi trong Game chỉ với một chạm mà không cần mở form.
  - **Chỉnh sửa câu hỏi (Edit Modal)**: Đổ dữ liệu hiện tại lên modal để sửa tên, nhóm rác, link ảnh, mẹo sống xanh và trạng thái kích hoạt.
  - **Xóa câu hỏi (Delete)**: Xác nhận an toàn trước khi xóa câu hỏi khỏi trò chơi.
- **Tìm kiếm, Lọc & Phân trang**:
  - Ô tìm kiếm thời gian thực theo tên vật phẩm rác.
  - Bộ lọc câu hỏi theo Nhóm rác (Hữu cơ, Vô cơ, Tái chế, Nguy hại, v.v.).
  - Bộ lọc trạng thái: Đang bật (Hoạt động) / Đã tắt (Tạm ẩn) / Tất cả.
  - Phân trang 12 câu hỏi/trang giúp tải mượt mà trên mọi thiết bị.
- **Tầng kết nối API (`dashboard_api.js`)**:
  - Thêm `apiFetchGameQuestions`: Truy vấn danh sách câu hỏi kèm dữ liệu kết nối lồng nhau (`waste_dictionary` & `waste_groups`).
  - Thêm `apiInsertGameQuestion`: Tạo mới đồng thời trong `waste_dictionary` và `game_questions`.
  - Thêm `apiUpdateGameQuestion`: Cập nhật đồng bộ thông tin từ điển và câu hỏi game.
  - Thêm `apiToggleGameQuestionActive`: Đổi trạng thái `is_active` nhanh chóng.
  - Thêm `apiDeleteGameQuestion`: Xóa câu hỏi an toàn khỏi CSDL.

### 📍 Quản lý & Thẩm định Điểm thu gom Cộng đồng (Community Collection Points Approval)
- **Tab Quản trị mới trên Sidebar**: Bổ sung tab **Điểm thu gom** (`collection_points`) với giao diện Glassmorphism hiện đại, đồng bộ hoàn toàn với ngôn ngữ thiết kế tổng thể của EcoSort Admin.
- **Duyệt điểm rác đóng góp từ cộng đồng**:
  - Giải quyết triệt để vấn đề các điểm rác do người dùng gửi từ bản đồ ứng dụng di động (`is_verified = false`) bị tồn đọng chưa có nơi thẩm định.
  - Lưới hiển thị Card dạng Grid tương thích responsive (1/2/3 cột) hiển thị hình ảnh thực tế, loại rác thu gom, người đóng góp và ngày gửi.
  - **Duyệt nhanh / Từ chối nhanh**: Các nút thao tác một chạm trực tiếp trên thẻ Card cho các điểm chờ duyệt.
  - **Modal Chi tiết**: Hỗ trợ xem hình ảnh phóng to, bản đồ địa chỉ, mô tả của người dân và thông tin tài khoản người đóng góp (`profiles.display_name`).
- **Bộ lọc & Phân trang**:
  - Hỗ trợ lọc theo trạng thái: *Chờ duyệt*, *Đã duyệt*, *Tất cả*.
  - Phân trang 12 điểm/trang giúp tải nhanh, tiết kiệm băng thông và tối ưu hiệu năng.
- **Tầng kết nối API (`dashboard_api.js`)**:
  - Thêm `apiFetchCollectionPoints`: Truy vấn bảng `collection_points` liên kết `profiles` qua foreign key `collection_points_created_by_fkey`.
  - Thêm `apiApproveCollectionPoint`: Cập nhật `is_verified: true` giúp điểm thu gom lập tức hiển thị công khai trên bản đồ Flutter cho cộng đồng.
  - Thêm `apiRejectCollectionPoint`: Loại bỏ điểm thu gom vi phạm hoặc không chính xác khỏi hệ thống.

### 🎨 Tái cấu trúc Toàn diện UI/UX & Responsive Đa Thiết bị (Design System Overhaul)
- **Tương thích Responsive Đa Màn hình (Mobile, Tablet, Desktop)**:
  - Bổ sung thanh điều hướng trên cùng (Mobile Top Bar) với nút Menu Hamburger và chuyển đổi theme một chạm cho điện thoại và máy tính bảng.
  - Sidebar dạng ngăn kéo trượt (Sliding Drawer) kèm lớp phủ mờ (Backdrop overlay) tự động đóng khi chuyển tab trên thiết bị di động.
  - Layout co dãn linh hoạt (`lg:ml-64`, padding co dãn `p-4 sm:p-6 lg:p-8`), bảng biểu có vùng cuộn ngang mượt mà, chống tràn viền trên mọi kích thước màn hình.
- **Tối ưu Độ tương phản & Hiển thị Hoàn hảo cả Chế độ Sáng/Tối (Light & Dark Mode)**:
  - Khắc phục triệt để lỗi chữ trắng trên nền sáng ở các tiêu đề trang, thẻ Card, danh sách người dùng và các cửa sổ Modal.
  - Đồng bộ bảng màu cao cấp chuẩn SaaS doanh nghiệp (`slate-900`/`white`, đường viền `slate-200`/`slate-800`), chữ hiển thị rõ ràng, tương phản cao, dễ nhìn.
- **Loại bỏ Thiết kế Dạng AI Template (De-AI Aesthetic)**:
  - Loại bỏ các bóng mờ phát sáng lòe loẹt, góc bo cong quá khổ (`rounded-[2.5rem]`), thay bằng tiêu chuẩn thiết kế phẳng hiện đại, tinh tế (`rounded-xl`, `rounded-2xl`).
  - Tối ưu biểu mẫu nhập liệu, các nút bấm thao tác và bảng dữ liệu chuyên nghiệp.

### 🧠 Cấu hình Trí tuệ Nhân tạo (Gemini AI Model Upgrade)
- **Nâng cấp Model Gemini 3.8 Flash**: Đồng bộ cấu hình mặc định toàn hệ thống sang `gemini-3.8-flash` (giảm 50% chi phí token API và gia tăng độ chính xác nhận diện phân loại rác).

---

## [0.1.2] - 2026-08-29

### 🛡️ Nâng cấp Bảo mật & Vá Lỗ hổng Dependency (Security Updates & Dependabot Vulnerability Fixes)
- 🔒 **Vite (`CVE-2026-53571` & `launch-editor` NTLMv2 Leak)**: Nâng cấp `vite` từ `^6.4.2` lên `^8.2.2` trong `package.json` và `package-lock.json`. Khắc phục triệt để lỗ hổng bypass `server.fs.deny` trên hệ điều hành Windows (CVE-2026-53571) và nguy cơ rò rỉ NTLMv2 hash qua đường dẫn UNC.
- 🔒 **PostCSS (`Arbitrary File Read` & `Path Traversal`)**: Nâng cấp `postcss` từ `^8.5.10` lên `^8.5.26` và bổ sung cấu hình `"overrides": { "postcss": "$postcss" }` trong `package.json`. Khắc phục triệt me lỗ hổng đọc file trái phép qua comment `sourceMappingURL` trên Windows (GHSA-6g55-p6wh-862q & GHSA-79ch-rjh7-4835).
- 🔒 **esbuild (`Windows Path Traversal Arbitrary File Read`)**: Nâng cấp `esbuild` từ `^0.28.0` lên `^0.28.2`. Khắc phục lỗ hổng Path Traversal đọc file hệ thống trên Windows khi chạy Dev Server với thuộc tính `servedir`.

### 📦 Đóng gói & Xây dựng (Build & Dependencies)
- **Cập nhật Overrides**: Thiết lập chính sách `overrides` khóa phiên bản an toàn cho `esbuild`, `postcss`, `vite` nhằm chống bị downgraded từ các gói phụ thuộc trung gian.
- **Kiểm thử đóng gói sản phẩm**: Chạy `npm run build` kiểm tra bundle sản phẩm tĩnh Vite đảm bảo 51 modules được biên dịch thành công 100% không dính warning hay lỗi cú pháp runtime.

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
