<div align="center">

<!-- HEADER BANNER -->
<img src="https://capsule-render.vercel.app/api?type=waving&color=0:00ff88,50:00c9ff,100:00ff88&height=220&section=header&text=EcoSort%20by%20Bao&fontSize=64&fontAlignY=38&fontColor=ffffff&desc=AI-Powered%20Waste%20Classification&descAlignY=60&descSize=18&animation=fadeIn" width="100%"/>

<!-- TYPING ANIMATION -->
<a href="https://github.com/gbao86/AI_Garbage_Classification_Application">
  <img src="https://readme-typing-svg.herokuapp.com?font=Space+Mono&weight=700&size=18&duration=3000&pause=800&color=00FF88&center=true&vCenter=true&multiline=true&width=700&height=70&lines=♻+Edge+AI+%7C+TFLite+%3C15ms+%7C+GPU+Delegate;☁+Gemini+3.5+Flash+Cloud+Fallback+%7C+Neon+Segmentation" alt="Typing SVG"/>
</a>

<br/>

<!-- BADGES -->
[![Version](https://img.shields.io/badge/version-0.5.8-00ff88?style=for-the-badge&logo=flutter&logoColor=white&labelColor=0c1419)](./CHANGELOG.md)
[![Platform](https://img.shields.io/badge/Flutter%20%7C%20Dart-blue?style=for-the-badge&logo=flutter&logoColor=white&labelColor=0c1419)](https://flutter.dev)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-ff3d5a?style=for-the-badge&logo=gnu&logoColor=white&labelColor=0c1419)](./LICENSE)
[![Kaggle](https://img.shields.io/badge/Kaggle-Notebook-20BEFF?style=for-the-badge&logo=kaggle&logoColor=white&labelColor=0c1419)](https://www.kaggle.com/code/jisy736386/phan-loai-rac)
[![APK](https://img.shields.io/badge/↓%20APK-v0.5.8-00ff88?style=for-the-badge&logo=android&logoColor=white&labelColor=0c1419)](https://drive.google.com/drive/folders/1swY2GXq4YbI0cJ71cbgdRxbpDXIc1g91?usp=sharing)

</div>

---

## 📌 Tổng quan

**EcoSort by Bao** là giải pháp phân loại rác sinh hoạt kết hợp 3 tầng công nghệ:

| Tầng | Công nghệ | Vai trò |
|:---:|:---|:---|
| 🧠 **Edge AI** | TFLite · GPU Delegate | Suy luận cục bộ &lt;15ms, không cần mạng |
| ☁ **LLM Cloud** | Gemini 3.5 Flash | Fallback thông minh khi confidence &lt;75% |
| 👁 **Vision** | ML Kit Segmentation | Vẽ viền Neon phát sáng quanh rác |

---

## 🎬 Hybrid AI Pipeline

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 Người dùng
    participant App as 📱 Flutter App
    participant ML  as 👁 ML Kit Segmentation
    participant TF  as ⚡ TFLite (Local GPU)
    participant API as ✨ Gemini 3.5 Flash
    participant DB  as 🗄 Supabase

    User->>App: Chụp ảnh rác thải
    Note over App: Khởi 2 luồng song song

    par Visual Masking
        App->>ML: Trích xuất viền đối tượng
        ML-->>App: Mask ảnh trả về
    and Edge AI Inference
        App->>TF: Ảnh 224×224px → GPU Delegate
        TF-->>App: Label + Confidence score
    end

    alt Confidence ≥ 75%
        Note over App,DB: ✅ Dùng kết quả local — tiết kiệm quota
        App->>DB: Lưu lịch sử · Cộng XP · Ghi CO₂
    else Confidence < 75%
        Note over App,API: ☁ Kích hoạt Cloud Fallback
        App->>API: Gửi ảnh 15KB đã nén
        API-->>App: JSON payload chuẩn
        App->>DB: Ghi nhận với nhãn Gemini đã hiệu chỉnh
    end

    App-->>User: Vẽ viền Neon · Hiển thị hướng dẫn · +XP
```

<details>
<summary><b>📐 Xem sơ đồ Dataflow Flowchart</b></summary>

```mermaid
graph TD
    classDef start   fill:#00ff88,stroke:#00c853,color:#000,font-weight:bold
    classDef process fill:#0d2b38,stroke:#00c9ff,color:#cde4e0
    classDef decide  fill:#1a2400,stroke:#ffd600,color:#ffd600
    classDef cloud   fill:#1a0d2b,stroke:#b46fff,color:#b46fff
    classDef local   fill:#2b0d10,stroke:#ff3d5a,color:#ff7a8a

    A([📸 Chụp / Chọn ảnh]):::start --> B(Tiền xử lý · Kotlin Native):::process
    B --> D[TFLite · GPU Delegate]:::local
    D --> E{Confidence ≥ 75%?}:::decide
    E -->|✅ Đủ tin cậy| F[Hiển thị kết quả local]:::process
    E -->|❌ Thấp| G{Có kết nối mạng?}:::decide
    G -->|📶 Online| H[Gemini 3.5 Flash · Cloud]:::cloud
    G -->|📵 Offline| I[Fallback TFLite · Outbox Queue]:::process
    H --> J[JSON payload → Supabase sync]:::cloud
    F --> L([✨ ML Kit Neon Render · +XP · CO₂]):::start
    I --> L
    J --> L
```

</details>

---

## 🚀 Tính năng đột phá

### 🧠 Dual AI Brain
- **TFLite Local** — `model_unquant.tflite` chạy trên GPU Delegate, 224×224px, 10 lớp, **&lt;15ms** hoàn toàn offline
- **Gemini 3.5 Flash** — auto kích hoạt khi confidence &lt;75%, trả JSON cấu trúc với hướng dẫn xử lý chi tiết
- **DB Label Sync** — Gemini hiệu chỉnh nhãn → tự đồng bộ ngược Supabase, cập nhật CO₂ + XP tương ứng

### 🛸 Neon Segmentation
- **ML Kit Subject Segmentation** chạy song song với luồng AI — không thêm latency
- Vẽ mask phát sáng theo màu nhóm: `🟢 Tái chế` · `🟤 Hữu cơ` · `🔴 Nguy hại`

### ⚡ Native Performance
- Nén ảnh tầng **Kotlin/Swift** trước khi vào Dart Isolate → Main Thread **0% blocked**
- Đạt **60/120 FPS** mượt, zero jank khi quét liên tục

### 📡 Offline-First Architecture
- **Outbox Pattern** — điểm, streak, nhiệm vụ offline ghi vào `SharedPreferences`
- Tự đồng bộ tuần tự lên Supabase khi có mạng trở lại — không bao giờ mất dữ liệu

### 🗺️ Eco Map Crowdsourcing
- CartoDB Vector Map · dark/light auto-sync
- Ghim trạm rác mới · geocode Nominatim · upload ảnh thực tế nhận XP

---

## 🧠 Mô hình AI Offline

> 📓 **Kaggle Notebook**: [Xem toàn bộ training pipeline tại đây](https://www.kaggle.com/code/jisy736386/phan-loai-rac)

**Dataset: 13,348 ảnh · 10 lớp phân loại**

| Lớp | Tên tiếng Việt | Số ảnh | Nhóm |
|:---:|:---|:---:|:---|
| 🔋 Battery | Pin cũ | 756 | ☠️ Nguy hại |
| 🥬 Biological | Hữu cơ sinh học | 699 | 🍂 Hữu cơ |
| 📦 Cardboard | Bìa Carton | 1,411 | ♻️ Tái chế |
| 👕 Clothes | Quần áo cũ | 1,892 | ♻️ Tái chế |
| 🥛 Glass | Chai lọ thủy tinh | 1,736 | ♻️ Tái chế |
| 🔩 Metal | Lon, mảnh kim loại | 930 | ♻️ Tái chế |
| 📝 Paper | Giấy vụn, sách cũ | 1,336 | ♻️ Tái chế |
| 🥤 Plastic | Chai nhựa, túi nilon | 1,597 | ♻️ Tái chế |
| 👟 Shoes | Giày dép hỏng | 1,449 | ♻️ Tái chế |
| 🗑️ Trash | Rác không tái chế khác | 453 | 🗑️ Không tái chế |

---

## 🛠️ Tech Stack

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![TensorFlow](https://img.shields.io/badge/TFLite-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white)
![Google Cloud](https://img.shields.io/badge/Gemini%203.5-4285F4?style=for-the-badge&logo=google&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Kotlin](https://img.shields.io/badge/Kotlin-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white)
![OpenStreetMap](https://img.shields.io/badge/OpenStreetMap-7EBC6F?style=for-the-badge&logo=openstreetmap&logoColor=white)
![Vite](https://img.shields.io/badge/Vite-646CFF?style=for-the-badge&logo=vite&logoColor=white)

</div>

---

## 📸 Giao diện ứng dụng

| 🏠 Màn hình chính | 🗺️ Bản đồ điểm đổ rác |
|:---:|:---:|
| ![Home](assets/images/home_preview_ver0.5.4.jpg) | ![Map](assets/images/map_review_v0.5.4.jpg) |

| 📊 Nhật ký & CO₂ | ℹ️ Về ứng dụng |
|:---:|:---:|
| ![History](assets/images/new_ver0.5.4.jpg) | ![About](assets/images/about_screen_v0.5.4.jpg) |

---

## 🏗️ Cài đặt & Chạy dự án

<details>
<summary><b>🛠️ Xem chi tiết quy trình thiết lập</b></summary>

### Yêu cầu
- Flutter SDK `v3.x.x`
- JDK `17+` · Gradle latest
- Tài khoản Supabase đã migrate tables
- Gemini API Key đã kích hoạt

### Các bước

```bash
# 1. Clone dự án
git clone https://github.com/gbao86/AI_Garbage_Classification_Application.git
cd AI_Garbage_Classification_Application

# 2. Cài dependencies
flutter pub get

# 3. Config biến môi trường
cp .env.example .env
# → Điền Gemini API Key + Supabase URL/Key vào .env

# 4. Build runner (sinh env.g.dart)
dart run build_runner build --delete-conflicting-outputs

# 5. Chạy!
flutter run
```

### Cấu trúc thư mục

```
phan_loai_rac_qua_hinh_anh/
├── lib/
│   ├── features/     # Game, Quiz, Outbox
│   ├── screens/      # Home, Scanning, Map, Result
│   ├── services/     # AI Gemini, TFLite, Supabase
│   ├── theme/        # Dark/Light Mode config
│   └── widgets/      # Camera, Dialog components
├── web_admin/        # HTML/JS/Vite Admin Panel
├── supabase/         # Migrations, RPC functions
└── assets/models/    # model_unquant.tflite
```

</details>


## 📥 Tải xuống

<div align="center">

[![Download APK](https://img.shields.io/badge/↓%20Download%20APK%20v0.5.7-00ff88?style=for-the-badge&logo=android&logoColor=white&labelColor=0c1419)](https://drive.google.com/drive/folders/1swY2GXq4YbI0cJ71cbgdRxbpDXIc1g91?usp=drive_link)

</div>

---

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:00ff88,50:00c9ff,100:00ff88&height=120&section=footer&reversal=false&animation=fadeIn" width="100%"/>

**Phát triển bởi [Trịnh Gia Bảo](https://github.com/gbao86) · HCMUNRE**

📧 `tiktokthu10@gmail.com`

*Garbage in, wisdom out.*

</div>