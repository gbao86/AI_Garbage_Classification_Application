<div align="center">

# 🌿 EcoSort Web Admin Portal

### *Hệ thống Quản trị & Điều hành Nội bộ Thế hệ mới cho EcoSort by Bao*

[![Version](https://img.shields.io/badge/version-0.1.2-00ff88?style=for-the-badge&logo=vite&logoColor=white&labelColor=0c1419)](./CHANGELOG.md)
[![Vite](https://img.shields.io/badge/Vite-v8.2.2-646CFF?style=for-the-badge&logo=vite&logoColor=white&labelColor=0c1419)](https://vitejs.dev/)
[![TailwindCSS](https://img.shields.io/badge/Tailwind_CSS-v3.4-38B2AC?style=for-the-badge&logo=tailwindcss&logoColor=white&labelColor=0c1419)](https://tailwindcss.com/)
[![Supabase](https://img.shields.io/badge/Supabase-v2.101.1-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white&labelColor=0c1419)](https://supabase.com)
[![Cloudflare Pages](https://img.shields.io/badge/Cloudflare-Pages-F38020?style=for-the-badge&logo=cloudflare&logoColor=white&labelColor=0c1419)](https://ecosort-by-bao-admin.pages.dev/)
[![Security](https://img.shields.io/badge/Vulnerabilities-0_Patched-brightgreen?style=for-the-badge&logo=githubactions&logoColor=white&labelColor=0c1419)](#-bảo-mật--an-toàn-hệ-thống-zero-vulnerabilities)

<br/>

> 🌐 **Cổng thông tin Web Admin chính thức:**  
> 👉 [**ecosort-by-bao-admin.pages.dev**](https://ecosort-by-bao-admin.pages.dev/)

</div>

---

## 📌 Mục lục

- [✨ Giới thiệu](#-giới-thiệu)
- [🛠️ Công nghệ sử dụng](#️-công-nghệ-sử-dụng)
- [🗂️ Cấu trúc thư mục](#️-cấu-trúc-thư-mục)
- [🔐 Phân quyền RBAC](#-phân-quyền-rbac)
- [🚀 Tính năng nổi bật](#-tính-năng-nổi-bật)
- [🛡️ Bảo mật & An toàn Hệ thống](#️-bảo-mật--an-toàn-hệ-thống-zero-vulnerabilities)
- [☁️ Deploy lên Cloudflare Pages](#️-deploy-lên-cloudflare-pages)
- [📜 Changelog](#-changelog)

---

## ✨ Giới thiệu

**EcoSort Web Admin** là bảng điều khiển Single-Page Application (SPA) chuyên dụng nội bộ cho **Admin** và **Super Admin** thuộc ứng dụng phân loại rác **EcoSort by Bao**.

Dự án vận hành trên nền tảng **Vite** kết nối trực tiếp với **Supabase Cloud BaaS** nhằm:
- 📥 **Duyệt báo cáo rác:** Thẩm định dữ liệu hình ảnh & nhãn AI từ người dùng ứng dụng di động, tự động slug hóa và đẩy dữ liệu chuẩn vào Từ điển rác (`waste_dictionary`).
- 👥 **Quản trị người dùng:** Tra cứu, phân trang, khóa tài khoản (Ban 100 năm), mở khóa, đặt lại mật khẩu và kiểm soát quyền hạn người dùng tức thì.
- 🛡️ **Phê duyệt 2 bước (Double-Approval):** Cơ chế bảo mật đa chữ ký cho các hành động đặc quyền (Nâng/Hạ quyền Admin, Xóa dữ liệu nhạy cảm, Bật/Tắt Kill Switch khẩn cấp).
- ⚙️ **Cấu hình hệ thống:** Điều chỉnh thời gian bảo trì, điểm số thưởng trò chơi và mô hình AI Gemini toàn hệ thống.

---

## 🛠️ Công nghệ sử dụng

| Công nghệ | Phiên bản | Mục đích & Vai trò |
| :--- | :---: | :--- |
| ⚡ **[Vite](https://vitejs.dev/)** | `v8.2.2` | Build tool thế hệ mới, Dev server với Hot Module Replacement (HMR) cực nhanh |
| 🎨 **[Tailwind CSS](https://tailwindcss.com/)** | `v3.4.1` | Styling framework với thiết kế hiện đại, responsive & dark mode linh hoạt |
| ⚙️ **[PostCSS](https://postcss.org/)** | `v8.5.26` | CSS transformation pipeline & Autoprefixer tương thích đa trình duyệt |
| 📦 **[esbuild](https://esbuild.github.io/)** | `v0.28.2` | JavaScript & TypeScript bundler siêu tốc |
| ⚡ **[@supabase/supabase-js](https://supabase.com/)** | `v2.101.1` | SDK JavaScript chính thức kết nối Supabase Auth, REST & PostgreSQL RPC |
| 📜 **Vanilla JS (ES Modules)** | `ES2022` | Tách biệt logic UI/API sạch sẽ, phòng chống lỗ hổng XSS |

---

## 🗂️ Cấu trúc thư mục

```
web_admin/
├── 📄 index.html           # Màn hình Đăng nhập Admin (Supabase Auth)
├── 📄 dashboard.html       # Màn hình Điều hành chính (Dashboard SPA)
├── 📁 js/
│   ├── 🔑 auth.js          # Logic xác thực, Session management & RBAC Guard
│   ├── ⚙️ config.js        # Cấu hình Supabase URL & Key (Sinh tự động từ script)
│   ├── 🔌 dashboard_api.js  # Tầng kết nối API, Supabase Database & gọi RPC
│   └── 🖥️ dashboard_ui.js   # Tầng giao diện, DOM Render & Modal Event Listeners
├── 📁 src/
│   └── 🎨 tailwind.css     # Directives nguồn của Tailwind CSS
├── 📁 dist/                # Bundle sản phẩm tĩnh sau khi build (Deploy target)
├── 📄 package.json         # Danh sách Dependencies & Scripts npm
├── 📄 vite.config.js       # Cấu hình Vite Build Tool & Server
├── 📄 tailwind.config.cjs  # Cấu hình Theme & Design System Tailwind
├── 📄 postcss.config.cjs   # Cấu hình CSS Plugins
├── 📄 env.sample           # File mẫu biến môi trường
├── 📄 README.md            # Tài liệu kỹ thuật chi tiết
└── 📄 CHANGELOG.md         # Lịch sử cập nhật các phiên bản
```

---

## 🔐 Phân quyền RBAC

Hệ thống bảo mật **Role-Based Access Control (RBAC)** 3 tầng vững chắc:

| Vai trò (Role) | Quyền hạn trên Web Admin |
| :---: | :--- |
| 👑 **`super_admin`** | Toàn quyền điều hành: Quản lý người dùng, duyệt rác, cấu hình hệ thống, duyệt & thực thi Yêu cầu đặc quyền. |
| 🛡️ **`admin`** | Quản lý người dùng cấp `user`/`admin`, duyệt rác, xem cấu hình (Read-only). **Không thể tác động lên `super_admin`**. |
| 👤 **`user`** | ❌ **Bị chặn tuyệt đối** ngay tại màn hình đăng nhập (Auto SignOut). |

### 🛡️ Lớp bảo vệ đa tầng:
1. **Lớp 1 (UI Level):** Tự động ẩn/vô hiệu hóa các nút bấm nhạy cảm kèm Tooltip giải thích.
2. **Lớp 2 (Client JS Level):** Hàm `checkAdminPermissions` & `openUserActionModal` chặn thao tác trái quyền trước khi mở Modal.
3. **Lớp 3 (Backend Database Level):** Toàn bộ PostgreSQL RPC Function (`admin_get_users`, `admin_ban_user`, `privileged_action_add_approval`) được viết với `SECURITY DEFINER`, xác thực `auth.uid()` & kiểm tra role trực tiếp trong CSDL — **Không thể bị bypass bằng cURL hay Postman**.

---

## 🚀 Tính năng nổi bật

### 🗂️ 1. Quản lý & Duyệt báo cáo rác (Waste Submissions)
- Hiển thị báo cáo phân loại rác từ người dùng di động theo trạng thái: **Chờ duyệt**, **Đã duyệt**, **Từ chối**.
- Xem chi tiết ảnh chụp thực tế, nhãn TFLite Local, nhãn Gemini Cloud AI & độ tin cậy.
- **Form Duyệt chuyên nghiệp:** Tự động tạo `slug` tiếng Việt không dấu, nạp danh mục nhóm rác từ CSDL và lưu trực tiếp vào Từ điển rác (`waste_dictionary`).

### 👥 2. Điều hành người dùng (User Management)
- Bảng dữ liệu phân trang thông minh (25 bản ghi/trang), hỗ trợ tìm kiếm tên/email & lọc theo Vai trò / Trạng thái.
- **Ban / Unban tài khoản:** Khóa vĩnh viễn (100 năm) kèm lý do bắt buộc. Backend tự động hủy toàn bộ session active (`auth.sessions`) lập tức đá người dùng ra khỏi app.
- **Gửi Mail Reset Mật khẩu:** Kích hoạt luồng đặt lại mật khẩu an toàn qua Email Supabase Auth.
- **Đề xuất Đổi quyền 2 bước:** Tự động tạo Yêu cầu đặc quyền khi nâng/hạ quyền Admin.

### 🛡️ 3. Phê duyệt 2 bước (Privileged Actions - Double Approval)
- Ngăn chặn nguy cơ lạm quyền từ 1 Admin đơn lẻ.
- Các tác vụ nguy hiểm (Đổi Role Admin, Xóa dữ liệu lớn, Bật/Tắt Kill Switch) bắt buộc phải tạo **Yêu cầu phê duyệt**.
- Cần **ít nhất 2 chữ ký xác nhận** từ 2 Admin/Super Admin khác nhau để chuyển trạng thái sang `approved` trước khi được nhấn nút **Thực thi (Execute)**.

### ⚙️ 4. Cấu hình hệ thống (System Settings)
- Bật/Tắt chế độ Bảo trì toàn ứng dụng (`maintenance_mode`).
- Bật/Tắt công tắc Ngắt khẩn cấp (`kill_switch`) vô hiệu hóa tính năng ghi API khi có sự cố.
- Cấu hình hệ số điểm thưởng Gamification & Mô hình AI Gemini toàn hệ thống.

---

## 🛡️ Bảo mật & An toàn Hệ thống (Zero Vulnerabilities)

Dự án Web Admin cam kết đạt chuẩn an toàn bảo mật cao nhất, đã được kiểm tra & vá toàn bộ lỗ hổng qua **GitHub Dependabot**:

| Gói phụ thuộc | Phiên bản an toàn | Mã lỗ hổng đã vá |
| :--- | :---: | :--- |
| **Vite** | `v8.2.2` | `CVE-2026-53571` (`server.fs.deny` Windows Alternate Paths Bypass) & `launch-editor` NTLMv2 Leak |
| **PostCSS** | `v8.5.26` | `GHSA-6g55-p6wh-862q` (Arbitrary File Read) & `GHSA-79ch-rjh7-4835` (Path Traversal) |
| **esbuild** | `v0.28.2` | Windows `servedir` Path Traversal Arbitrary File Read |

> 🔒 **Chính sách Overrides:** File `package.json` cài đặt chính sách `"overrides"` cố định phiên bản an toàn cho `esbuild`, `postcss`, `vite`, chống hoàn toàn nguy cơ bị downgrade bởi các thư viện trung gian.

---

## ☁️ Deploy lên Cloudflare Pages

Dự án được cấu hình tự động tích hợp CI/CD với **Cloudflare Pages**:

1. **Đồng bộ cấu hình:** Đảm bảo file `web_admin/js/config.js` đã được cập nhật thông tin Supabase mới nhất.
2. **Cấu hình dự án trên Cloudflare Pages Dashboard:**
   - **Root Directory:** `web_admin`
   - **Framework Preset:** `Vite`
   - **Build Command:** `npm run build`
   - **Build Output Directory:** `dist`
3. **Cấu hình Supabase Auth Redirect URLs:**
   - Thêm URL Cloudflare Pages vào Supabase Dashboard:  
     `https://ecosort-by-bao-admin.pages.dev/**`

---

## 📜 Changelog

Xem nhật ký lịch sử cập nhật chi tiết theo từng phiên bản tại **[CHANGELOG.md](./CHANGELOG.md)**.

---

<div align="center">

Được thiết kế & phát triển với ❤️ bởi **Bao**  
*EcoSort by Bao Admin v0.1.2 · GPL v3 License*

</div>
