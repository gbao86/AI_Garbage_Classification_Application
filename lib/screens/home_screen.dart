import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/scanning_screen.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/about_screen.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/map_screen.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/waste_symbols_screen.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:phan_loai_rac_qua_hinh_anh/features/game/game_provider.dart';
import 'package:phan_loai_rac_qua_hinh_anh/services/auth_service.dart';
import 'package:phan_loai_rac_qua_hinh_anh/features/game/game_screen.dart';
import 'package:phan_loai_rac_qua_hinh_anh/features/game/badge_inventory_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  String _processingMessage = '';
  final ImagePicker _picker = ImagePicker();
  Interpreter? _interpreter;
  List<String> _labels = [];
  int _currentIndex = 0;
  bool _hasPlayedGame = false;

  final Map<String, String> _labelTranslations = {
    'battery': 'Pin / Ắc quy',
    'biological': 'Rác hữu cơ',
    'cardboard': 'Bìa các-tông',
    'clothes': 'Quần áo',
    'glass': 'Thủy tinh',
    'metal': 'Kim loại',
    'paper': 'Giấy',
    'plastic': 'Nhựa',
    'shoes': 'Giày dép',
    'trash': 'Rác thông thường',
  };

  static String buildLocalGuidanceMarkdown({
    required String translatedLabel,
    required String originalLabel,
    required String classification,
    required double confidencePct,
    required bool lowConfidence,
  }) {
    final confidenceText = confidencePct.toStringAsFixed(2);

    String disposal;
    String where;
    String harm;
    String tip;

    switch (classification) {
      case 'tái chế':
        disposal = 'Làm sạch (nếu có thể), để khô và tháo rời các phần khác vật liệu.';
        where = 'Bỏ vào thùng/túi tái chế hoặc mang đến điểm thu gom tái chế gần nhất.';
        harm = 'Lẫn bẩn/dính dầu mỡ có thể làm giảm khả năng tái chế và tăng rác thải chôn lấp.';
        tip = 'Ưu tiên tái sử dụng trước khi tái chế (refill, dùng lại hộp/chai).';
        break;
      case 'hữu cơ':
        disposal = 'Tách khỏi rác tái chế, để trong túi kín hoặc thùng có nắp.';
        where = 'Bỏ vào thùng rác hữu cơ (nếu có) hoặc ủ compost tại nhà.';
        harm = 'Để lẫn rác tái chế gây mùi, thu hút côn trùng và làm hỏng vật liệu tái chế.';
        tip = 'Giảm rác hữu cơ bằng cách lên kế hoạch bữa ăn, bảo quản thực phẩm đúng cách.';
        break;
      case 'nguy hại':
        disposal = 'Giữ nguyên trạng, không đập vỡ/khui mở; bọc kín nếu có nguy cơ rò rỉ.';
        where = 'Mang đến điểm thu gom rác nguy hại (pin, ắc quy, hóa chất) hoặc chương trình thu hồi.';
        harm = 'Có thể gây ô nhiễm đất/nước và ảnh hưởng sức khỏe nếu rò rỉ hoặc bị đốt.';
        tip = 'Ưu tiên sản phẩm sạc lại, dùng bền để giảm phát sinh rác nguy hại.';
        break;
      default:
        disposal = 'Buộc kín, hạn chế để lẫn với nhóm tái chế/hữu cơ.';
        where = 'Bỏ vào thùng rác thường theo quy định địa phương.';
        harm = 'Lẫn nhóm tái chế/hữu cơ sẽ làm tăng chi phí xử lý và giảm hiệu quả phân loại.';
        tip = 'Cân nhắc thay thế bằng sản phẩm ít bao bì, dễ tái chế.';
    }

    final note = lowConfidence
        ? '\n\n**Lưu ý**: Độ tin cậy chưa cao. Bạn có thể thử chụp lại ảnh rõ hơn (đủ sáng, vật thể chiếm khung hình) hoặc dùng chế độ Online để được hướng dẫn chi tiết.'
        : '';

    return '**Loại rác:** $translatedLabel ($originalLabel)  \n'
        '**Phân loại:** $classification  \n'
        '**Độ tin cậy:** $confidenceText%$note\n'
        '\n'
        '**Hướng dẫn xử lý:**\n'
        '- **Cách vứt bỏ:** $disposal\n'
        '- **Nơi xử lý:** $where\n'
        '- **Tác hại nếu xử lý sai:** $harm\n'
        '\n'
        '**Mẹo sống xanh:** $tip';
  }

  @override
  void initState() {
    super.initState();
    _initializeModelAndLabels();
    _checkHasPlayedGame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GameProvider>().syncFromSupabase();
    });
  }

  Future<void> _checkHasPlayedGame() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _hasPlayedGame = prefs.getBool('has_played_game') ?? false);
    }
  }

  Future<void> _initializeModelAndLabels() async {
    try {
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      if (mounted) {
        setState(() {
          _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
        });
      }

      // Thử khởi tạo với GPU Delegate để tăng tốc
      try {
        final options = InterpreterOptions();
        if (Platform.isAndroid) {
          options.addDelegate(GpuDelegateV2());
        }
        _interpreter = await Interpreter.fromAsset('assets/models/model_unquant.tflite', options: options);
        debugPrint('Khởi tạo TFLite thành công với GPU Delegate.');
      } catch (gpuError) {
        debugPrint('Lỗi khởi tạo GPU Delegate, đang thử lùi về CPU: $gpuError');
        // Fallback lùi về CPU thuần
        _interpreter = await Interpreter.fromAsset('assets/models/model_unquant.tflite');
        debugPrint('Khởi tạo TFLite thành công với CPU Fallback.');
      }
    } catch (e) {
      debugPrint('Lỗi khởi tạo mô hình/nhãn TFLite: $e');
    }
  }

  Future<double> _calculateAverageBrightness(File file) async {
    try {
      // Tối ưu: Chỉ nén và đọc một bản thu nhỏ của ảnh để tính độ sáng
      // Giúp tránh lỗi Out Of Memory (OOM) và không làm treo Main Thread
      final bytes = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 100,
        minHeight: 100,
        quality: 20,
      );

      if (bytes == null) return 0.0;
      final image = img.decodeImage(bytes);
      if (image == null) return 0.0;

      double totalLuminance = 0;
      int count = 0;

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final luminance = (0.2126 * pixel.r) + (0.7152 * pixel.g) + (0.0722 * pixel.b);
          totalLuminance += luminance;
          count++;
        }
      }
      return count > 0 ? totalLuminance / count : 0.0;
    } catch (e) {
      debugPrint("Lỗi tính độ sáng: $e");
      return 100.0; // Mặc định cho qua nếu gặp lỗi kỹ thuật
    }
  }

  // --- SỬA LỖI Ở ĐÂY: Hàm nén ảnh siêu nhẹ để chống tràn RAM ---
  Future<File?> _optimizeImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(tempDir.path, "optimized_${DateTime.now().millisecondsSinceEpoch}.jpg");

      // Ép khung tối đa 1080x1080 cho mọi loại ảnh
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        format: CompressFormat.jpeg,
        quality: 85,
        minWidth: 1080,
        minHeight: 1080,
      );

      return result != null ? File(result.path) : file;
    } catch (e) {
      debugPrint("Lỗi nén ảnh: $e");
      return file;
    }
  }

  Future<void> _openAccountSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final auth = AuthService.instance;
    final user = auth.currentUser;
    final profile = await auth.fetchMyProfile();
    if (!context.mounted) return;

    final displayName = profile?['display_name']?.toString().trim();
    final subtitle = (displayName != null && displayName.isNotEmpty) ? displayName : 'EcoSort';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tài khoản', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email_outlined),
                title: Text(user?.email ?? '—'),
                subtitle: Text(subtitle),
              ),
              if (profile != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.stars_outlined),
                  title: Text('Cấp ${profile['level'] ?? '—'} · ${profile['xp_total'] ?? 0} XP'),
                ),
              ],
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await auth.signOut();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Đăng xuất'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) {
        if (mounted) setState(() => _processingMessage = '');
        return;
      }

      setState(() => _processingMessage = 'Đang kiểm tra chất lượng ảnh...');

      // 1. Kiểm tra độ sáng trước khi nén/xử lý nặng
      final brightness = await _calculateAverageBrightness(File(pickedFile.path));
      
      // Ngưỡng độ sáng (0-255), thường 40-50 là rất tối
      if (brightness < 45) {
        if (mounted) {
          final proceed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Ảnh hơi tối'),
              content: const Text('Ảnh của bạn có vẻ hơi thiếu sáng, điều này có thể làm giảm độ chính xác của AI. Bạn có muốn chụp lại không?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Chụp lại')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Vẫn dùng')),
              ],
            ),
          );
          if (proceed == false) {
             setState(() => _processingMessage = '');
             // Chờ một chút để Dialog đóng hẳn và giải phóng bộ nhớ trước khi mở lại Camera
             await Future.delayed(const Duration(milliseconds: 400));
             if (mounted) _processImage(source);
             return;
          }
        }
      }

      setState(() => _processingMessage = 'Đang tối ưu ảnh...');

      // 2. Tối ưu ảnh
      File? processedFile = await _optimizeImage(File(pickedFile.path));
      if (!mounted) return;

      setState(() {
        _image = processedFile;
        _processingMessage = '';
      });

      if (_image != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanningScreen(
              image: _image!,
              classifierInterpreter: _interpreter,
              labels: _labels,
              labelTranslations: _labelTranslations,
              buildLocalGuidanceMarkdown: buildLocalGuidanceMarkdown,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _processingMessage = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              // Tab 0: Home view
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await context.read<GameProvider>().syncFromSupabase();
                  },
                  color: theme.primaryColor,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hành động nhỏ, lợi ích lớn',
                                          style: theme.textTheme.bodyLarge,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                'EcoSort by Bao',
                                                style: theme.textTheme.headlineMedium?.copyWith(
                                                  color: theme.primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (context.watch<GameProvider>().streak > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(colors: [Colors.orange, Colors.redAccent]),
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.redAccent.withValues(alpha: 0.3),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    )
                                                  ]
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 14),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${context.watch<GameProvider>().streak} ngày',
                                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.brightness == Brightness.dark
                                                  ? Colors.black.withValues(alpha: 0.2)
                                                  : Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 15,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.person_outline_rounded, color: theme.primaryColor),
                                          tooltip: 'Tài khoản',
                                          onPressed: () => _openAccountSheet(context),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.brightness == Brightness.dark
                                                  ? Colors.black.withValues(alpha: 0.2)
                                                  : Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 15,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.notifications_none_rounded, color: theme.primaryColor),
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: const Row(
                                                  children: [
                                                    Icon(Icons.construction_rounded, color: Colors.white, size: 18),
                                                    SizedBox(width: 10),
                                                    Expanded(child: Text('Tính năng thông báo đang được phát triển!')),
                                                  ],
                                                ),
                                                backgroundColor: Colors.orange.shade700,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              _buildHeroBanner(theme),
                              const SizedBox(height: 40),

                              Text('Dịch vụ', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),
                              _buildActionGrid(theme),
                              _buildHistoryActionCard(theme),

                              if (_processingMessage.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                _buildLoadingStatus(theme),
                              ],

                              _buildDailyQuestsSection(theme),

                              const SizedBox(height: 40),
                              _buildKnowledgeSection(theme),

                              const SizedBox(height: 40),
                              _buildMiniGameSection(theme),

                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Tab 1: Maps View
              const MapScreen(showBackButton: false),
              // Tab 2: About View
              const AboutScreen(showBackButton: false),
            ],
          ),
          _buildCustomBottomNav(theme),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.eco_rounded, size: 120, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: const Text('AI Powered', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bảo vệ Trái Đất\nbằng Trí Tuệ Nhân Tạo',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2, letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Phân loại đúng để tái chế hiệu quả hơn.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            title: 'Máy ảnh',
            subtitle: 'Quét trực tiếp',
            icon: Icons.camera_rounded,
            color: theme.primaryColor,
            onTap: () => _processImage(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildActionCard(
            title: 'Thư viện',
            subtitle: 'Chọn ảnh có sẵn',
            icon: Icons.photo_library_rounded,
            color: Colors.blue.shade600,
            onTap: () => _processImage(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildKnowledgeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tra cứu', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WasteSymbolsScreen()),
          ),
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: theme.brightness == Brightness.dark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.green, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ký hiệu rác thải',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tìm hiểu ý nghĩa các biểu tượng trên bao bì rác thải.',
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.3), size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniGameSection(ThemeData theme) {
    final game = context.watch<GameProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thử thách & Học tập', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GameScreen()),
          ),
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9000), Color(0xFFFFB75E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _hasPlayedGame ? '🎮 Tiếp tục' : 'Mới',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chiến binh\nPhân loại',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.stars_rounded, color: Colors.orange, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Điểm của bạn: ${game.score}',
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (game.earnedBadges.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: game.earnedBadges.take(3).map((badgeName) {
                            final icon = game.badgeIcons[badgeName] ?? '🏅';
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '$icon $badgeName',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Text(
                          'Chưa có huy hiệu - chơi game để mở khóa!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BadgeInventoryScreen()),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Kho huy hiệu',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.sports_esports_rounded,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingStatus(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24)
      ),
      child: Row(
        children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _processingMessage,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBottomNav(ThemeData theme) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? const Color(0xFF1A1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Trang chủ', _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
            _buildNavItem(1, Icons.map_rounded, 'Bản đồ', _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1)),
            _buildNavItem(2, Icons.info_rounded, 'Thông tin', _currentIndex == 2, onTap: () => setState(() => _currentIndex = 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isSelected, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final unselectedColor = theme.brightness == Brightness.dark ? Colors.white54 : Colors.black45;
    final selectedColor = theme.brightness == Brightness.dark ? Colors.greenAccent : theme.primaryColor;
    final labelColor = theme.brightness == Brightness.dark ? Colors.white : theme.primaryColor;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? selectedColor : unselectedColor, size: 26),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? labelColor : unselectedColor,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryActionCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoryScreen()),
        ),
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: theme.brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.history_rounded, color: Colors.green, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nhật ký Xanh & Tác động',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Xem lịch sử quét rác và biểu đồ lượng CO₂ đã giảm thiểu.',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.3), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyQuestsSection(ThemeData theme) {
    final game = context.watch<GameProvider>();
    final quests = game.dailyQuests;
    final isDark = theme.brightness == Brightness.dark;

    if (quests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Text('Nhiệm vụ Hôm nay', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: quests.length,
          itemBuilder: (context, index) {
            final q = quests[index];
            final bool isCompleted = q['is_completed'] as bool;
            final int progress = q['progress_count'] as int;
            final int target = q['target_count'] as int;
            final double percent = (progress / target).clamp(0.0, 1.0);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              color: isDark ? const Color(0xFF2A2D31) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isDark ? Colors.grey[850]! : Colors.grey[100]!),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.orange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: isCompleted ? Colors.green : Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q['title_vi'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            q['description'] ?? '',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent,
                              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                              color: isCompleted ? Colors.green : theme.primaryColor,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$progress/$target',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isCompleted ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 14),
                            Text(
                              '+${q['reward_xp']} XP',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }
}