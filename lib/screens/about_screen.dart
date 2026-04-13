import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = "...";
  final int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version.split('+').first;
      });
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'tiktokthu10@gmail.com',
      queryParameters: {
        'subject': 'Contact from EcoSort App User',
        'body': 'Hi Trinh Gia Bao,\n\nI am using your EcoSort app and would like to...'
      },
    );

    try {
      // Encode các ký tự đặc biệt trong query
      final String urlString = emailLaunchUri.toString();
      await launchUrl(Uri.parse(urlString));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy ứng dụng Email trên thiết bị này'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _launchFacebook() async {
    const String fbUrl = "https://www.facebook.com/BaOU.me/";
    final Uri url = Uri.parse(fbUrl);
    
    try {
      // LaunchMode.externalApplication giúp ưu tiên mở app Facebook nếu có
      final bool launched = await launchUrl(
        url, 
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        throw Exception('Could not launch FB');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở liên kết Facebook'),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F3),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            stretch: true,
            backgroundColor: theme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              title: const Text('Về ứng dụng', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [theme.primaryColor, theme.primaryColor.withAlpha(200)],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    right: -20,
                    child: Icon(Icons.eco_rounded, size: 200, color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                          ),
                          child: const Icon(Icons.auto_awesome, size: 60, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'EcoSort by Bao v$_version',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    theme,
                    title: 'Sứ mệnh của chúng tôi',
                    content: 'Được phát triển bởi Trịnh Gia Bảo, ứng dụng sử dụng công nghệ AI để nhận diện rác thải, giúp người dùng hình thành thói quen phân loại rác tại nguồn, bảo vệ môi trường bền vững.',
                    icon: Icons.explore_rounded,
                    iconColor: Colors.orange,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    theme,
                    title: 'Công nghệ sử dụng',
                    content: 'Kết hợp giữa mô hình TFLite chạy Offline và Gemini AI Online để đảm bảo độ chính xác tối ưu trong mọi điều kiện kết nối.',
                    icon: Icons.psychology_rounded,
                    iconColor: Colors.blue,
                  ),
                  const SizedBox(height: 32),
                  Text('Liên hệ với chúng tôi', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildContactTile(
                    theme,
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: 'tiktokthu10@gmail.com',
                    color: Colors.redAccent,
                    onTap: _launchEmail,
                  ),
                  const SizedBox(height: 12),
                  _buildContactTile(
                    theme,
                    icon: Icons.facebook_rounded,
                    label: 'Facebook',
                    value: 'Trinh Gia Bao',
                    color: Colors.blueAccent,
                    onTap: _launchFacebook,
                  ),
                  const SizedBox(height: 48),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '© $_currentYear EcoSort by Bao',
                          style: const TextStyle(color: Colors.black38, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        const Text('Made with ❤️ for the Planet', style: TextStyle(color: Colors.black26, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(ThemeData theme, {required String title, required String content, required IconData icon, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(color: Colors.black54, fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildContactTile(ThemeData theme, {
    required IconData icon, 
    required String label, 
    required String value, 
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
