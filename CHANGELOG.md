# 📦 CHANGELOG

Lịch sử cập nhật các phiên bản của **EcoSort by Bao**

## [0.5.7] - 2026-08-29

### 🤖 Tối ưu hóa Tương thích Android 16 & HyperOS 3.0 (Android 16 & HyperOS 3.0 Compatibility Optimization)
- 🔴 **Sửa lỗi CRASH trên thiết bị 16KB page**: Nâng cấp `tflite_flutter` từ `0.11.0` lên `^0.12.1`. Phiên bản cũ đóng gói thư viện native `.so` được align 4KB, gây lỗi **SIGSEGV** trên các dòng máy Android 16 sử dụng 16KB memory page size.
- 📐 **Sửa lỗi 16KB page alignment cho JNI**: Đổi `useLegacyPackaging` từ `true` sang `false` trong `build.gradle.kts`. Setting cũ extract file `.so` không nén, vi phạm chuẩn 16KB page alignment bắt buộc trên Android 16.
- 🎯 **Nâng `targetSdk` lên API 36**: Cập nhật từ `targetSdk = 34` lên `targetSdk = 36` để tuân thủ chính sách Google Play và kích hoạt đầy đủ các behavior changes của Android 16 (edge-to-edge, predictive back gesture, photo picker mới).
- 🗑️ **Xóa permission `WRITE_EXTERNAL_STORAGE`**: Gỡ bỏ quyền đã bị vô hiệu hóa hoàn toàn từ Android 13+ (API 33). Trên Android 16, permission này bị bỏ qua và gây cảnh báo không cần thiết.
- 🚀 **Bật Impeller rendering engine**: Chuyển `EnableImpeller` từ `false` sang `true` trong `AndroidManifest.xml`. Flutter 3.41+ mặc định hỗ trợ Impeller trên Android, mang lại hiệu năng render tốt hơn đáng kể trên Android 16.

### 📦 Cập nhật Dependencies
- ⬆️ **`supabase_flutter`**: Nâng từ `^2.12.0` lên `^2.16.0` — cập nhật `gotrue` (2.20→2.27), `postgrest` (2.7→2.9), `realtime_client` (2.7→2.13), `storage_client` (2.5→2.8). Cải thiện auth deep link và real-time subscriptions trên Android 16.
- ⬆️ **`google_sign_in`**: Giữ `^7.2.0`, tự động resolve lên bản mới nhất tương thích — cập nhật Android platform plugin hỗ trợ Credential Manager API trên Android 16.
- 🔄 **13 dependencies đã được cập nhật** tổng cộng thông qua `flutter pub upgrade`, bao gồm các transitive dependencies quan trọng cho tương thích Android 16.

### 🗺️ Nâng cấp Tile Server Bản đồ (Stadia Maps Integration)
- 🗺️ **Loại bỏ Watermark CARTO**: Chuyển đổi nhà cung cấp Tile Server từ CARTO (bị dính watermark do siết chính sách API key) sang **Stadia Maps** với các style cao cấp: *Outdoors* (ngoài trời), *Alidade Smooth* (sáng tối giản), *Alidade Smooth Dark* (tối tối giản) và *Alidade Satellite* (vệ tinh).
- 🔐 **Bảo mật API Key với Envied**: Tích hợp cấu hình `STADIA_MAPS_API_KEY` trong `.env` / `.env.example` và mã hóa byte-level qua `Envied` (`Env.stadiaMapsApiKey`), hỗ trợ cơ chế tự động fallback về OpenStreetMap nếu thiếu key.

---

## [0.5.6] - 2026-06-08

### 🧠 Tích hợp Kiến trúc Hybrid AI Thế hệ mới (Next-Gen Hybrid AI Architecture Integration)
- 🤖 **Nâng cấp sang Gemini 3.5 Flash**: Thay thế mô hình cũ bằng `gemini-3.5-flash` - mô hình Flash thế hệ mới nhất của Google được tối ưu hóa cho tốc độ phản hồi siêu tốc và hoạt động agentic hiệu quả.
- ⚙️ **Đồng bộ hóa phản hồi dưới dạng JSON có cấu trúc (Structured JSON Mode)**: Cấu hình `GenerationConfig` với `responseMimeType: 'application/json'` và viết lại prompt để ép buộc Gemini trả về JSON thuần chứa dữ liệu phân loại (`category`, `classification`, `vietnamese_label`, `guidance`, `tip`).
- 🔄 **Xử lý dữ liệu đồng nhất (Unified Data Parsing)**: Giải mã JSON từ Gemini trong `ScanningScreen` và `ResultScreen` để chuyển đổi tự động thành Markdown với cùng một chuẩn hiển thị đồng bộ như TFLite Local.
- 🗃️ **Sửa lỗi đồng bộ nhãn CSDL (Database Metadata Alignment)**: Sửa lỗi nghiêm trọng khi lưu scan event vào Supabase. Giờ đây, khi Gemini nhận diện, nhãn đúng từ Gemini (`category` và `classification` tương ứng) sẽ được lưu đè lên nhãn TFLite đoán mò trước đó, đảm bảo tính đúng đắn của dữ liệu carbon giảm thiểu và XP tích lũy. Khi phân tích lại (Re-analyze), CSDL cũng được cập nhật đúng cột `ai_label` và `waste_dictionary_id` tương ứng với kết quả Gemini.
- ⚡ **Tinh chỉnh ngưỡng kích hoạt Cloud AI**: Hạ ngưỡng kích hoạt Gemini từ `80%` xuống còn `75%` (`_confidenceThreshold = 0.75`), giảm tải 30-40% số cuộc gọi API không cần thiết bằng cách ưu tiên kết quả offline chất lượng của TFLite Local.

---

## [0.5.5] - 2026-06-02

### ⚡ Tối ưu hóa Tốc độ Phân tích ảnh cực hạn (Extreme Image Analysis Speed Optimizations)
- 🚀 **Nén ảnh Native-code trước khi giải mã trên Dart**: Tích hợp `FlutterImageCompress` để resize ảnh về $224 \times 224$ trực tiếp ở tầng Native (Kotlin/Swift) trước khi giải mã trong Isolate. Giảm thời gian decode ảnh của Dart từ 5-8 giây xuống dưới **15ms** (tăng tốc gấp 500 lần).
- 📡 **Tối ưu hóa dung lượng truyền tải lên Gemini API**: Nâng cấp `GeminiService` tự động nén ảnh xuống $480 \times 480$ với chất lượng $65\%$ (~15KB) trước khi gửi qua API. Giúp giảm thiểu tối đa băng thông truyền tải và tăng tốc độ phản hồi trực tuyến, đặc biệt hiệu quả khi sử dụng mạng di động yếu.
- ⏱️ **Song song hóa tác vụ tách biên (ML Kit Segmentation)**: Điều chỉnh `ScanningScreen` khởi chạy `_runSegmentation` song song với luồng AI phân tích ngay từ `initState` thay vì đợi hoạt ảnh kết thúc, triệt tiêu thời gian chờ tuần tự vô ích.
- 🎬 **Rút ngắn hoạt ảnh & Tinh chỉnh độ trễ chuyển tiếp**: Rút ngắn hoạt ảnh quét laser từ 3.0s xuống còn **1.8s** để ứng dụng phản hồi nhanh hơn, đồng thời tối ưu độ trễ chuyển tiếp màn hình kết quả (300ms đối với Gemini, 800ms đối với TFLite Offline).

### ⚙️ Tối ưu hóa kỹ thuật Chuyên sâu (Advanced Engineering Optimization)
- 💾 **Sửa lỗi thiếu cột CSDL & Tối ưu RLS**: Cập nhật file migration `20260602173000_add_missing_scan_columns.sql` bổ sung các cột còn thiếu và tích hợp cơ chế **Custom JWT Claims** giúp hàm `is_admin()` kiểm tra quyền trực tiếp từ RAM, triệt tiêu đệ quy RLS và tăng tốc truy vấn DB lên gấp nhiều lần.
- ⚡ **Background Isolate & GPU Delegates cho AI**: Tách tiến trình suy luận TFLite sang một **Background Isolate** riêng thông qua `compute()` kết hợp với GPU/Metal Delegates, giải phóng Main Thread giúp duy trì hoạt ảnh quét laser ở tốc độ 60/120 FPS ổn định mà không giật lag.
- 📳 **Offline Outbox Pattern**: Thiết kế hàng đợi outbox offline cho `GameProvider` lưu trữ trong `SharedPreferences`, bảo toàn điểm số người dùng kiếm được khi mất mạng và đồng bộ tuần tự lên Supabase khi kết nối khôi phục.
- 🔄 **Đồng bộ hóa mã phân loại rác**: Cập nhật hàm `_getClassification` trong `scanning_screen.dart` và switch-case phân loại trong `result_screen.dart` sang các mã tiếng Anh chuẩn database (`hazardous`, `organic`, `recyclable`, `trash`). Khắc phục lỗi lệch ngôn ngữ khiến hệ số giảm thiểu CO₂ luôn bị lùi về giá trị mặc định.
- 🎨 **Sửa lỗi hiển thị màu sắc Lịch sử**: Sửa logic gán `groupColor` dựa theo code nhóm rác thực tế từ CSDL trong `history_screen.dart`, giúp các thẻ lịch sử hiển thị đúng màu đặc trưng của từng nhóm rác (Xanh dương cho Tái chế, Đỏ cho Nguy hại, Xanh lá cho Hữu cơ) thay vì tất cả hiển thị màu xám.

### 🩺 Sửa lỗi Hiển thị Kết quả AI (AI Result Display Fixes)
- 🏷️ **Dịch phân loại sang Tiếng Việt**: Sửa lỗi hàm `buildLocalGuidanceMarkdown` hiển thị mã phân loại thô tiếng Anh (`recyclable`, `organic`...) trong markdown kết quả. Nguyên nhân do switch-case dùng key tiếng Việt (`'tái chế'`, `'hữu cơ'`) nhưng `_getClassification()` trả về mã tiếng Anh → luôn rơi vào default. Giờ hiển thị đúng: `Tái chế ♻️`, `Hữu cơ 🍂`, `Nguy hại ☠️`, `Không tái chế 🗑️`.
- 🔍 **Hiển thị đúng nguồn phân tích AI**: Thêm field `analysisSource` truyền từ `ScanningScreen` → `ResultScreen` để theo dõi chính xác nguồn kết quả thực tế. Trước đây chip badge luôn hiển thị "AI Gemini (Online)" kể cả khi Gemini lỗi 503 và đang dùng kết quả TFLite offline. Giờ hiển thị đúng 3 trạng thái: **AI Gemini (Online)** khi Gemini thành công, **AI Local (Offline) · XX%** khi TFLite confidence ≥ 80%, và **AI Offline (Gemini không khả dụng)** khi Gemini lỗi/mất mạng và fallback về TFLite.
- 🔬 **Bổ sung Debug Logging Pipeline cho TFLite**: Thêm hệ thống logging chi tiết `[FLOW]` và `[TFLITE]` xuyên suốt luồng phân loại ảnh (`_startBackgroundAI`, `_classifyLocal`) giúp theo dõi chính xác: trạng thái interpreter, kích thước ảnh, shape tiền xử lý, toàn bộ output scores của 10 lớp rác, và quyết định gọi Gemini hay dùng TFLite offline.
- 🙈 **Ẩn nhãn đoán mò độ tự tin thấp khi quét**: Sửa lỗi UX hiển thị nhãn TFLite dự đoán sai lệch (như nhầm sang "Kim loại" với điểm số thấp) trên màn hình quét trước khi Gemini hiệu chỉnh lại thành "Plastic" (đúng) ở màn hình kết quả. Hiện tại, nhãn dự đoán chỉ hiển thị khi độ tự tin TFLite đạt $\ge 80\%$, ngược lại màn hình quét sẽ chỉ hiển thị dòng chữ chờ: `"Đang tối ưu phân tích bằng Cloud AI..."`.

---


## [0.5.4] - 2026-05-30

### 🗺️ Cách tân Bản đồ & Tìm kiếm địa điểm (CartoDB Map Layers & Address Search)
- 🎨 **Lớp bản đồ CartoDB cao cấp**: Tích hợp các lớp bản đồ vector sạch sẽ và hiện đại thay thế cho bản đồ mặc định đơn điệu: *CartoDB Voyager* (mặc định sáng), *CartoDB Positron* (tối giản), và *CartoDB Dark Matter* (**tự động đồng bộ với Dark Mode** của hệ thống).
- 🧭 **Bảng chọn lớp phủ BottomSheet**: Thiết kế bảng điều khiển BottomSheet mượt mà để chọn kiểu bản đồ và bật/tắt lớp phủ Giao thông & Đường đi xe đạp/đi bộ.
- 🔍 **Tìm địa điểm miễn phí (Nominatim API)**: Tích hợp thanh tìm kiếm địa chỉ ở đầu bản đồ sử dụng OpenStreetMap Nominatim API, cho phép tìm kiếm bất kỳ địa điểm nào và tự động quét các trạm rác xung quanh điểm đó.
- 📍 **Phân loại Marker trực quan**: Color-code các Marker hiển thị trên bản đồ dựa trên thuộc tính thực tế của thùng rác (Màu Xanh lá cho điểm tái chế, màu Xanh dương cho trạm thu gom lớn, màu Cam cho thùng rác nhỏ).

### 🏆 Nhật ký Xanh, Tác động môi trường (CO₂) & Nhiệm vụ / Streak
- 📊 **Nhật ký Xanh (Scan History & Carbon Stats)**: Bổ sung màn hình lịch sử quét rác và phân tích tác động môi trường. Quy đổi lượng CO₂ giảm thiểu thành các chỉ số thú vị như số lượng cây xanh hấp thụ hay số giờ tiết kiệm điện bóng đèn LED.
- 📅 **Nhiệm vụ Ngày & Streak (Daily Quests & Streak)**: Tích hợp hệ thống trò chơi hóa (gamification) gồm bảng nhiệm vụ hằng ngày ("Chiến binh phân loại", "Nhà thám hiểm Xanh", v.v.) và bộ đếm Streak 🔥 hoạt động liên tục lưu trữ thời gian thực trên Supabase.
- 🤝 **Đóng góp điểm rác mới (Crowdsourcing)**: Cho phép người dùng chụp ảnh thực tế tại vị trí GPS hiện tại (hệ thống sẽ tự động yêu cầu xác định vị trí GPS thực tế mới nhất của thiết bị khi chọn) hoặc **Ghim vị trí tùy chọn bất kỳ** trên bản đồ thông qua chế độ chọn vị trí trực quan (với ghim đỏ ở chính giữa màn hình giúp kéo thả bản đồ và tự động dịch địa chỉ ngược qua Nominatim), giúp đóng góp điểm rác ngay cả khi người dùng đang không có mặt trực tiếp tại đó. Thưởng nóng +20 XP sau khi Admin duyệt.

---

## [0.5.3] - 2026-05-25

### 🧠 Hủy kích hoạt tự động huấn luyện AI (Disable Auto-Train Engine)
- ⚠️ **Hủy bỏ chức năng Auto-Train**: Gỡ bỏ hoàn toàn workflow tự động huấn luyện mô hình TensorFlow `.github/workflows/auto_train.yml` và các scripts đi kèm do sự thiếu ổn định về dữ liệu đầu vào (dataset) dẫn đến mô hình hoạt động sai lệch so với thiết kế.
- 📱 **Chuyển về Model tĩnh trong Assets**: Gỡ bỏ service `ModelUpdateService` và logic cập nhật động từ server. Ứng dụng di động hiện tại sẽ tải và sử dụng mô hình gốc đóng gói sẵn ổn định trong assets (`assets/models/model_unquant.tflite`).

### 🛡️ Cải tiến xử lý ngoại lệ AI & Tách cấu trúc Web Admin (AI Fallback & Web Admin Modularization)
- 📡 **Cơ chế Fallback thông minh cho Gemini**: Cập nhật `GeminiService` đẩy ngoại lệ thay vì trả về chuỗi thông tin lỗi thô. Khi ứng dụng gặp sự cố mạng hoặc lỗi API, màn hình `ScanningScreen` tự động bắt lỗi và sử dụng kết quả từ mô hình TFLite Offline làm phương án dự phòng, đi kèm thông báo trực quan cho người dùng.
- 🧩 **Giải phóng tài nguyên ML Kit**: Đảm bảo giải phóng hoàn toàn tài nguyên của `SubjectSegmenter` trong hàm `dispose` của `ScanningScreen` nhằm tối ưu hóa RAM và hạn chế rò rỉ bộ nhớ (Memory Leak).
- ⚙️ **Mã hóa HTML bảo mật (XSS Prevention)**: Khắc phục lỗi CodeQL `js/xss-through-exception` trên trang quản trị Web Admin bằng việc tích hợp bộ lọc mã hóa HTML ký tự đặc biệt khi hiển thị thông tin ngoại lệ lỗi lên DOM.
- 📦 **Tách cấu trúc Module Web Admin**: Tái cấu trúc file `dashboard.html` từ ~1640 dòng thành các module Javascript riêng biệt (`js/dashboard_api.js` và `js/dashboard_ui.js`) theo chuẩn ES Modules, giúp tăng khả năng bảo trì và nâng cấp dự án.

---

## [0.5.2] - 2026-03-25

### 🧭 Tối ưu hóa Cấu trúc Điều hướng (Tab Navigation Optimization)
- 📌 **Chuyển đổi Tab bằng `IndexedStack`**: Thay đổi cơ chế chuyển đổi màn hình chính từ đẩy trang mới (`Navigator.push`) sang `IndexedStack`. Việc này giúp giữ thanh Bottom Navigation Bar luôn cố định ở chân màn hình, chuyển tab mượt mà và bảo toàn trạng thái của từng tab (như GPS, bản đồ, trang chủ).
- ⚙️ **Hỗ trợ nhúng Tab linh hoạt**: Thêm tham số `showBackButton` cho `MapScreen` và `AboutScreen`. Khi hiển thị dưới dạng tab con, nút Back trên app bar sẽ được ẩn đi để tăng tính đồng bộ và thẩm mỹ.
- 📐 **Bảo toàn khoảng cách đệm (Padding)**: Điều chỉnh thông minh chiều cao đệm cuối trang của màn hình thông tin để tránh bị Bottom Nav che khuất chữ bản quyền.

### 🎨 Khắc phục Triệt để Hiển thị Dark Mode (Full Dark Mode & Theme Sync)
- 🌓 **Đồng bộ màu sắc toàn diện**: Loại bỏ hoàn toàn các màu nền và màu chữ hardcode (như `Colors.white`, `Colors.black54`) và thay thế bằng các màu động lấy trực tiếp từ `Theme.of(context)` (như `theme.colorScheme.surface`, `theme.colorScheme.onSurface`).
- 🌙 **Hỗ trợ tối tối ưu**: Các Card dịch vụ quét, Card tra cứu ký hiệu, danh sách huy hiệu, các Contact Tile và hộp thoại Dialog đều tự động chuyển sang tông xám/đen cao cấp khi bật chế độ Tối của hệ điều hành, đảm bảo độ tương phản hoàn hảo và dễ đọc.
- 📯 **Bottom Nav Động**: Tự động chuyển màu nền thanh điều hướng dưới từ màu đen cố định sang màu sáng đi kèm bóng đổ nhẹ khi ở chế độ Sáng (Light Mode).

### 🏆 Đột phá Giao diện Kết quả AI (Premium Result Screen Redesign)
- 🌈 **Gradient động theo loại rác**: Màu nền Header và các vòng tròn icon tự động biến đổi dải màu gradient theo loại rác phân tích được (Xanh cho *Tái chế*, Nâu cho *Hữu cơ*, Đỏ cho *Nguy hại*, Cam cho *Thông thường*).
- 🔮 **Viền ảnh phát sáng (Glow Shadow)**: Áp dụng hiệu ứng viền bo góc bán trong suốt và bóng phát sáng theo tông màu phân loại của rác bao quanh ảnh chụp.
- 🏷️ **Badge định danh AI Engine**: Hiển thị rõ Pill Badge phân biệt nguồn phân tích: **AI Gemini (Online)** hoặc **AI Local (TFLite) · XX%**.
- 📈 **Hoạt ảnh xuất hiện tuần tự (Micro-animations)**: Tích hợp hiệu ứng trượt nhẹ từ dưới lên và mờ/tỏ dần (fade-in & slide-up) tuần tự cho từng thẻ thông tin kết quả.

---

## [0.5.1] - 2026-05-23

### 🎨 Đại tu Giao diện Mô tả Ký hiệu (Waste Symbols UI Upgrade)
- 🧠 **Bộ phân tích mô tả động (Dynamic Parser)**: Triển khai bộ phân tích cú pháp runtime để tự động chuyển đổi văn bản mô tả phẳng thành các widget UI có cấu trúc cao cấp.
- 📋 **Trình bày trực quan**:
    - **Thông số kỹ thuật**: Hiển thị các thông tin như *Chịu nhiệt*, *Dùng cho*, *Tái chế*... thành các thẻ thuộc tính (Property Cards) có viền bo tròn và đổ bóng nhẹ.
    - **Danh mục liệt kê**: Gom các dòng vật liệu ("Bao gồm") thành các thẻ danh sách (Checklist Cards) với chấm tròn chỉ hướng cùng tông màu.
    - **Cảnh báo đỏ (Red Alerts)**: Tự động phát hiện các từ khóa cấm/nguy cơ (⚠️, KHÔNG, NGUY HẠI) và hiển thị trong hộp thông báo cảnh báo trực quan với biểu tượng cảnh báo chuyên dụng.

### 🗑️ Tối ưu hóa Biểu tượng Thực tế (Realistic Trash Bin Icons)
- 📐 **Thiết kế lại SVG Thùng rác**: Redesign vector `_svgTrashBin` thành dạng hình học cân đối, đối xứng hoàn hảo, giúp tăng độ thẩm mỹ và sắc nét cho ứng dụng.
- 🇻🇳 **Đồng bộ hóa Thùng rác Việt Nam**: Loại bỏ hoàn toàn icon Android/Material (`Icons.delete_rounded`) mặc định và thay thế bằng vector thùng rác nắp lật ngoài đời thực cho tất cả các thùng phân loại rác Việt Nam (`SymbolStyle.colorBin`).

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
