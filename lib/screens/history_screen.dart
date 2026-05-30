import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _scans = [];
  double _totalCo2SavedKg = 0.0;
  int _totalScans = 0;
  int _totalWeightGrams = 0;

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await supabase
          .from('user_scan_events')
          .select('''
            id,
            ai_label,
            confidence,
            earned_xp,
            image_url,
            weight_grams,
            co2_saved_grams,
            created_at,
            waste_dictionary (
              name_vi,
              waste_groups (
                name_vi,
                code
              )
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      double co2Sum = 0.0;
      int weightSum = 0;
      for (var row in response) {
        co2Sum += (row['co2_saved_grams'] as num?)?.toDouble() ?? 0.0;
        weightSum += (row['weight_grams'] as num?)?.toInt() ?? 0;
      }

      if (mounted) {
        setState(() {
          _scans = response;
          _totalCo2SavedKg = co2Sum / 1000.0;
          _totalScans = response.length;
          _totalWeightGrams = weightSum;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading history data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật Ký Xanh'),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1A1C1E) : theme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildImpactDashboard(theme, isDark),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                    child: Text(
                      'Lịch sử phân loại',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (_scans.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Chưa có lịch sử quét rác',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Hãy phân loại rác bằng camera để bắt đầu tích lũy tác động xanh nhé!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final scan = _scans[index];
                          return _buildHistoryCard(scan, theme, isDark);
                        },
                        childCount: _scans.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            ),
    );
  }

  Widget _buildImpactDashboard(ThemeData theme, bool isDark) {
    final double treesEquivalent = _totalCo2SavedKg * 0.04;
    final double bulbHoursEquivalent = _totalCo2SavedKg * 100.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)] 
              : [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ĐÓNG GÓP TÍCH LŨY',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_totalCo2SavedKg.toStringAsFixed(2)} kg',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Lượng CO₂ giảm thiểu',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco_rounded, color: Colors.white, size: 36),
              ),
            ],
          ),
          const Divider(color: Colors.white30, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildImpactStatItem(
                Icons.restore_from_trash_rounded,
                '$_totalScans',
                'Lượt quét',
              ),
              _buildImpactStatItem(
                Icons.scale_rounded,
                '${(_totalWeightGrams / 1000.0).toStringAsFixed(1)} kg',
                'Khối lượng',
              ),
              _buildImpactStatItem(
                Icons.park_rounded,
                treesEquivalent.toStringAsFixed(3),
                'Cây hấp thụ',
              ),
            ],
          ),
          const Divider(color: Colors.white30, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Colors.yellowAccent, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Tương đương tiết kiệm thắp sáng đèn LED trong ${bulbHoursEquivalent.toStringAsFixed(0)} giờ!',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildHistoryCard(dynamic scan, ThemeData theme, bool isDark) {
    final dict = scan['waste_dictionary'];
    final String name = dict != null ? dict['name_vi'] : (scan['ai_label'] ?? 'Rác chưa phân loại');
    final String groupName = (dict != null && dict['waste_groups'] != null)
        ? dict['waste_groups']['name_vi']
        : 'Rác tổng hợp';
    final String groupCode = (dict != null && dict['waste_groups'] != null)
        ? dict['waste_groups']['code']
        : 'other';

    final double co2 = (scan['co2_saved_grams'] as num?)?.toDouble() ?? 0.0;
    final int weight = (scan['weight_grams'] as num?)?.toInt() ?? 0;
    final String imageUrl = scan['image_url'] ?? '';

    final DateTime createdAt = DateTime.parse(scan['created_at']).toLocal();
    final String timeStr = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')} - ${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';

    Color groupColor;
    switch (groupCode) {
      case 'plastic':
        groupColor = Colors.blue;
        break;
      case 'paper':
        groupColor = Colors.orange;
        break;
      case 'glass':
        groupColor = Colors.teal;
        break;
      case 'metal':
        groupColor = Colors.red;
        break;
      case 'organic':
        groupColor = Colors.green;
        break;
      default:
        groupColor = Colors.blueGrey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: isDark ? const Color(0xFF2A2D31) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isDark ? Colors.grey[850]! : Colors.grey[100]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200], child: const Icon(Icons.image)),
                      errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[200],
                      child: const Icon(Icons.restore_from_trash_rounded, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: groupColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      groupName,
                      style: TextStyle(color: groupColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-${co2.toStringAsFixed(1)}g CO₂',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '${weight}g',
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 14),
                    Text(
                      '+${scan['earned_xp']} XP',
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
  }
}
