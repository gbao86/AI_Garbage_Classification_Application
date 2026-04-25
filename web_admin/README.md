# EcoSort Web Admin

> Hệ thống quản trị nội bộ cho ứng dụng phân loại rác **EcoSort by Bao**.
> Giao diện dành riêng cho Admin và Super Admin — không dành cho người dùng thông thường.

---

## 📋 Mục lục

- [Giới thiệu](#giới-thiệu)
- [Công nghệ sử dụng](#công-nghệ-sử-dụng)
- [Cấu trúc thư mục](#cấu-trúc-thư-mục)
- [Cài đặt & Khởi chạy](#cài-đặt--khởi-chạy)
- [Biến môi trường](#biến-môi-trường)
- [Phân quyền](#phân-quyền)
- [Tính năng](#tính-năng)
- [Database & API (Supabase RPC)](#database--api-supabase-rpc)
- [Changelog](#changelog)

---

## Giới thiệu

Web Admin là một **Single-Page Application (SPA)** thuần HTML/JS được build bằng **Vite**, kết nối trực tiếp với **Supabase** để:
- Quản lý và duyệt các báo cáo phân loại rác từ người dùng App.
- Quản lý tài khoản người dùng (xem, khóa, reset mật khẩu).
- Đẩy dữ liệu đã duyệt vào bảng Từ điển rác (`waste_dictionary`) phục vụ App hiển thị cho người dùng cuối.

---

## Công nghệ sử dụng

| Công nghệ | Mục đích |
|---|---|
| [Vite](https://vitejs.dev/) `^5.2` | Build tool & Dev server (HMR) |
| [Tailwind CSS](https://tailwindcss.com/) `^3.4` | Styling framework |
| [PostCSS](https://postcss.org/) + Autoprefixer | Xử lý CSS pipeline |
| [@supabase/supabase-js](https://supabase.com/docs/reference/javascript) `^2.101` | Kết nối Supabase Auth & Database |
| HTML5 + Vanilla JS (ES Modules) | Giao diện & Logic |

---

## Cấu trúc thư mục

```
web_admin/
├── index.html          # Trang đăng nhập Admin
├── dashboard.html      # Trang Dashboard chính
├── js/
│   ├── auth.js         # Logic xác thực Supabase (login, checkAdminPermissions)
│   └── config.js       # Cấu hình Supabase URL & Key (tự sinh, không sửa tay)
├── src/
│   └── tailwind.css    # Điểm vào CSS (Tailwind directives)
├── dist/               # Kết quả build production (gitignored)
├── node_modules/       # Dependencies (gitignored)
├── package.json
├── vite.config.js
├── tailwind.config.cjs
├── postcss.config.cjs
├── env.sample          # Mẫu file biến môi trường
├── README.md           # File này
└── CHANGELOG.md        # Lịch sử thay đổi
```

---

## Cài đặt & Khởi chạy

### Yêu cầu

- [Node.js](https://nodejs.org/) >= 18.x
- npm >= 9.x

### Cài đặt

```bash
cd web_admin
npm install
```

### Chạy Development Server

```bash
npm run dev
```

Mở trình duyệt tại: **`http://localhost:5173`**

> ⚠️ Luôn dùng `npm run dev` để quản lý log và hot-reload. Không chạy file HTML trực tiếp bằng cách double-click (sẽ thiếu module Supabase).

### Build Production

```bash
npm run build
```

Kết quả xuất ra thư mục `dist/`.

---

## Biến môi trường

Tạo file `.env` trong thư mục `web_admin/` dựa trên file mẫu `env.sample`:

```env
VITE_SUPABASE_URL=https://<your-project>.supabase.co
VITE_SUPABASE_ANON_KEY=<your-anon-key>
```

> **Lưu ý:** File `js/config.js` hiện tại được tự động sinh bởi script Dart của dự án. Nếu chỉnh sửa cần thận trọng.

---

## Phân quyền

Web Admin áp dụng mô hình **RBAC (Role-Based Access Control)** hai tầng:

| Role | Quyền hạn |
|---|---|
| `super_admin` | Toàn quyền trên mọi tài khoản và dữ liệu |
| `admin` | Quản lý `user` và `admin`, **không thể** tác động lên `super_admin` |
| `user` | **Không được phép đăng nhập** vào Web Admin |

**Cơ chế bảo vệ:**
1. **Tầng UI (Cosmetic):** Các nút thao tác bị disable, tooltip cảnh báo.
2. **Tầng JS:** Hàm `openUserActionModal` kiểm tra role trước khi mở bất kỳ modal thao tác nào.
3. **Tầng Backend:** Các PostgreSQL RPC (`admin_ban_user`, `admin_get_users`) đều kiểm tra `auth.uid()` và role trước khi thực thi — đây là lớp bảo vệ cuối cùng và không thể bị bypass.

---

## Tính năng

### 🗂️ Tab Duyệt Rác (Waste Submissions)
- Xem danh sách báo cáo phân loại rác từ người dùng App theo trạng thái (Chờ duyệt / Đã duyệt / Từ chối).
- Xem chi tiết: Ảnh quét, nhãn AI (TFLite + Gemini), tên đề xuất, fun fact.
- **Duyệt vào Từ điển:** Form nhập tên chuẩn, chọn nhóm rác, thêm fun fact → tự động slug hóa và lưu vào `waste_dictionary`.
- Từ chối báo cáo không hợp lệ.

### 👥 Tab Quản lý Người dùng (User Management)
- Bảng dữ liệu phân trang (25 dòng/trang) với đầy đủ thông tin: Avatar, Tên, Email, Role, Trạng thái, Last Login.
- **Tìm kiếm & Lọc:** Theo email/tên, theo role, theo trạng thái hoạt động.
- **Ban / Unban:** Khóa tài khoản kèm lý do bắt buộc (Backend kill session ngay lập tức).
- **Reset Password:** Gửi link đặt lại mật khẩu qua email.
- **Audit Logs:** Xem lịch sử hành động từ bảng `public.audit_logs` *(đang phát triển)*.

---

## Database & API (Supabase RPC)

Web Admin sử dụng hai PostgreSQL Function với `SECURITY DEFINER` để truy cập an toàn vào `auth.users`:

### `public.admin_get_users(p_page, p_limit, p_search)`
Lấy danh sách người dùng kèm email và `total_count` để phân trang.
> Kiểm tra role của người gọi trước khi trả về dữ liệu.

### `public.admin_ban_user(p_user_id, p_reason, p_is_locked)`
Khóa/Mở khóa tài khoản thực hiện đúng 3 bước:
1. Cập nhật `public.profiles` (is_locked, locked_reason).
2. Cập nhật `auth.users.banned_until` (100 năm nếu ban).
3. Xóa `auth.sessions` — đá văng user ra ngay lập tức.
4. Ghi `public.audit_logs`.
> Chặn Admin ban Super Admin ở tầng Backend.

Xem SQL đầy đủ trong [CHANGELOG.md](./CHANGELOG.md#️-sql--database-hướng-dẫn-thiết-lập).

---

## Changelog

Xem [CHANGELOG.md](./CHANGELOG.md) để biết lịch sử thay đổi chi tiết theo từng phiên bản.

---

<p align="center">
  Được xây dựng với ❤️ bởi <strong>Bao</strong> · <em>EcoSort Admin v0.1.0</em>
</p>
