import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phan_loai_rac_qua_hinh_anh/services/gemini_service.dart';

class ResultScreen extends StatefulWidget {
  final File image;
  final String processingResult;
  final String? tfliteLabel;
  final double tfliteConfidence;
  final String classificationType;
  // 'gemini' = Gemini thành công, 'tflite' = TFLite offline, 'tflite_fallback' = Gemini lỗi dùng TFLite
  final String analysisSource;

  const ResultScreen({
    super.key,
    required this.image,
    required this.processingResult,
    this.tfliteLabel,
    this.tfliteConfidence = 0.0,
    this.classificationType = '',
    this.analysisSource = 'tflite',
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isReporting = false;
  bool _hasReported = false;
  String? _imageHash;
  final TextEditingController _suggestedNameController = TextEditingController();

  bool _hasSavedScan = false;
  late String _currentResultText;
  late String _currentClassificationType;
  late String _currentAnalysisSource;
  bool _isReanalyzing = false;
  bool _isReanalyzed = false;
  String? _insertedScanEventId;

  @override
  void initState() {
    super.initState();
    _currentResultText = widget.processingResult;
    _currentClassificationType = widget.classificationType;
    _currentAnalysisSource = widget.analysisSource;
    _calculateImageHash();
  }

  @override
  void dispose() {
    _suggestedNameController.dispose();
    super.dispose();
  }

  Future<void> _calculateImageHash() async {
    final bytes = await widget.image.readAsBytes();
    if (mounted) {
      setState(() {
        _imageHash = md5.convert(bytes).toString();
      });
      _checkExistingReport();
      _saveScanEvent(); // Tự động lưu lịch sử quét rác và cộng điểm
    }
  }

  Future<void> _saveScanEvent() async {
    if (_hasSavedScan) return;
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return; // Chỉ lưu nếu đã đăng nhập

    try {
      final supabase = Supabase.instance.client;
      
      // 1. Nén ảnh quét
      File compressedFile = await _compressForReport(widget.image);
      
      // 2. Upload ảnh lên bucket 'waste-reports' dưới thư mục scans/
      final fileName = '${_imageHash ?? DateTime.now().millisecondsSinceEpoch}.jpg';
      final imagePath = 'scans/${user.id}/$fileName';
      
      await supabase.storage.from('waste-reports').upload(
        imagePath,
        compressedFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final String publicUrl = supabase.storage.from('waste-reports').getPublicUrl(imagePath);

      // 3. Tra cứu waste_dictionary_id từ slug/tfliteLabel nếu có
      String? wasteDictId;
      if (widget.tfliteLabel != null) {
        try {
          final dict = await supabase
              .from('waste_dictionary')
              .select('id')
              .eq('slug', widget.tfliteLabel!)
              .maybeSingle();
          if (dict != null) {
            wasteDictId = dict['id'] as String?;
          }
        } catch (_) {}
      }

      // 4. Lấy hệ số CO2 từ waste_groups tương ứng
      double co2Coefficient = 0.5; // mặc định
      if (_currentClassificationType.isNotEmpty) {
        try {
          final group = await supabase
              .from('waste_groups')
              .select('co2_coefficient')
              .eq('code', _currentClassificationType)
              .maybeSingle();
          if (group != null) {
            co2Coefficient = (group['co2_coefficient'] as num).toDouble();
          }
        } catch (_) {}
      }

      final int weightGrams = 100; // Mặc định 100g cho một vật thể quét
      final double co2Saved = weightGrams * co2Coefficient;
      final int earnedXp = 10;

      // 5. Thêm bản ghi vào user_scan_events và lấy ID về
      final res = await supabase.from('user_scan_events').insert({
        'user_id': user.id,
        'waste_dictionary_id': wasteDictId,
        'ai_label': widget.tfliteLabel ?? 'unknown',
        'confidence': widget.tfliteConfidence,
        'earned_xp': earnedXp,
        'image_url': publicUrl,
        'weight_grams': weightGrams,
        'co2_saved_grams': co2Saved,
      }).select('id').maybeSingle();

      if (res != null) {
        _insertedScanEventId = res['id'] as String?;
      }

      // 6. Cộng điểm kinh nghiệm
      await supabase.rpc('rpc_award_points', params: {
        'p_delta': earnedXp,
        'p_reason': 'waste_scan',
        'p_ref_type': 'scan',
        'p_metadata': {'co2_saved_grams': co2Saved},
      });

      // 7. Cập nhật tiến trình nhiệm vụ hàng ngày và Streak hoạt động
      await _updateQuestProgress('scan_count', 1);
      await _updateDailyStreak();

      _hasSavedScan = true;
      debugPrint('Saved scan event successfully.');
    } catch (e) {
      debugPrint('Error saving scan event: $e');
    }
  }

  Future<void> _updateScanEventAfterReanalysis(String newClassType) async {
    if (_insertedScanEventId == null) return;
    try {
      final supabase = Supabase.instance.client;
      
      double co2Coefficient = 0.5;
      try {
        final group = await supabase
            .from('waste_groups')
            .select('co2_coefficient')
            .eq('code', newClassType)
            .maybeSingle();
        if (group != null) {
          co2Coefficient = (group['co2_coefficient'] as num).toDouble();
        }
      } catch (_) {}

      final double newCo2Saved = 100 * co2Coefficient; // 100g rác

      await supabase.from('user_scan_events').update({
        'ai_label': 'gemini_reanalyzed',
        'co2_saved_grams': newCo2Saved,
      }).eq('id', _insertedScanEventId!);

      debugPrint('Updated scan event after reanalysis successfully.');
    } catch (e) {
      debugPrint('Error updating scan event after reanalysis: $e');
    }
  }

  Future<void> _reanalyzeWithGemini() async {
    if (_isReanalyzing) return;
    setState(() {
      _isReanalyzing = true;
    });

    try {
      final geminiService = GeminiService();
      final String geminiResult = await geminiService.processImageAndGetGuidance(widget.image);
      
      String newClassType = _currentClassificationType;
      if (geminiResult.contains('Tái chế') || geminiResult.contains('tái chế') || geminiResult.contains('recyclable')) {
        newClassType = 'recyclable';
      } else if (geminiResult.contains('Hữu cơ') || geminiResult.contains('hữu cơ') || geminiResult.contains('organic')) {
        newClassType = 'organic';
      } else if (geminiResult.contains('Nguy hại') || geminiResult.contains('nguy hại') || geminiResult.contains('hazardous')) {
        newClassType = 'hazardous';
      } else if (geminiResult.contains('Không tái chế') || geminiResult.contains('trash')) {
        newClassType = 'trash';
      }

      setState(() {
        _currentResultText = geminiResult;
        _currentClassificationType = newClassType;
        _currentAnalysisSource = 'gemini';
        _isReanalyzed = true;
      });

      await _updateScanEventAfterReanalysis(newClassType);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Đã phân tích nâng cao thành công bằng Gemini AI!'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error reanalyzing with Gemini: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi gọi Gemini AI: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReanalyzing = false;
        });
      }
    }
  }

  Future<void> _updateQuestProgress(String questType, int increment) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Lấy danh sách nhiệm vụ active cùng loại
      final activeQuests = await supabase
          .from('quests')
          .select()
          .eq('quest_type', questType)
          .eq('is_active', true);

      for (var quest in activeQuests) {
        final questId = quest['id'];
        final targetCount = quest['target_count'] as int;
        final rewardXp = quest['reward_xp'] as int;

        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        
        final userQuestRecord = await supabase
            .from('user_quests')
            .select()
            .eq('user_id', user.id)
            .eq('quest_id', questId)
            .eq('date', todayStr)
            .maybeSingle();

        int newProgress = increment;
        bool alreadyRewarded = false;

        if (userQuestRecord != null) {
          newProgress = (userQuestRecord['progress_count'] as int) + increment;
          alreadyRewarded = userQuestRecord['is_rewarded'] as bool;
        }

        final bool isCompleted = newProgress >= targetCount;

        await supabase.from('user_quests').upsert({
          'user_id': user.id,
          'quest_id': questId,
          'date': todayStr,
          'progress_count': newProgress,
          'is_completed': isCompleted,
          'is_rewarded': alreadyRewarded || isCompleted,
          'updated_at': DateTime.now().toIso8601String(),
        });

        if (isCompleted && !alreadyRewarded) {
          await supabase.rpc('rpc_award_points', params: {
            'p_delta': rewardXp,
            'p_reason': 'quest_completed',
            'p_ref_type': 'quest',
            'p_metadata': {'quest_title': quest['title_vi']},
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating quest progress: $e');
    }
  }

  Future<void> _updateDailyStreak() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final profile = await supabase
          .from('profiles')
          .select('current_streak, longest_streak, last_active_date')
          .eq('id', user.id)
          .single();

      final lastActiveStr = profile['last_active_date'] as String?;
      final int currentStreak = (profile['current_streak'] as num?)?.toInt() ?? 0;
      final int longestStreak = (profile['longest_streak'] as num?)?.toInt() ?? 0;

      final today = DateTime.now();
      final todayStr = today.toIso8601String().substring(0, 10);

      if (lastActiveStr == todayStr) return;

      int newStreak = 1;
      if (lastActiveStr != null) {
        final lastActiveDate = DateTime.parse(lastActiveStr);
        final difference = today.difference(lastActiveDate).inDays;

        if (difference == 1) {
          newStreak = currentStreak + 1;
        } else if (difference > 1) {
          newStreak = 1;
        }
      }

      final int newLongestStreak = newStreak > longestStreak ? newStreak : longestStreak;

      await supabase.from('profiles').update({
        'current_streak': newStreak,
        'longest_streak': newLongestStreak,
        'last_active_date': todayStr,
      }).eq('id', user.id);
    } catch (e) {
      debugPrint('Error updating daily streak: $e');
    }
  }

  Future<void> _checkExistingReport() async {
    if (_imageHash == null) return;
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('waste_submissions')
          .select('id')
          .eq('submitter_id', user.id)
          .like('scan_image_path', '%$_imageHash%')
          .maybeSingle();

      if (response != null && mounted) {
        setState(() => _hasReported = true);
      }
    } catch (e) {
      debugPrint('Error checking existing report: $e');
    }
  }

  Future<File> _compressForReport(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(tempDir.path, "report_${_imageHash ?? DateTime.now().millisecondsSinceEpoch}.jpg");

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        format: CompressFormat.jpeg,
        quality: 50, 
        minWidth: 512,
        minHeight: 512,
      );

      return result != null ? File(result.path) : file;
    } catch (e) {
      return file;
    }
  }

  Future<void> _reportIncorrectClassification() async {
    if (_isReporting || _hasReported) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để báo cáo')),
      );
      return;
    }

    final suggestedName = _suggestedNameController.text.trim();
    if (suggestedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên đúng của vật phẩm')),
      );
      return;
    }

    setState(() => _isReporting = true);

    try {
      final supabase = Supabase.instance.client;
      File compressedFile = await _compressForReport(widget.image);

      final fileName = '$_imageHash.jpg';
      final imagePath = 'reports/${user.id}/$fileName';
      
      await supabase.storage.from('waste-reports').upload(
        imagePath,
        compressedFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final String publicUrl = supabase.storage.from('waste-reports').getPublicUrl(imagePath);

      await supabase.from('waste_submissions').insert({
        'submitter_id': user.id,
        'status': 'pending_review',
        'tflite_top_label': widget.tfliteLabel,
        'tflite_confidence': widget.tfliteConfidence,
        'gemini_payload': {
          'result_text': widget.processingResult, 
          'image_hash': _imageHash
        },
        'suggested_name_vi': suggestedName,
        'rejection_reason': 'Người dùng báo cáo rác sai',
        'scan_image_path': publicUrl,
      });

      if (mounted) {
        setState(() => _hasReported = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Báo cáo thành công! Cảm ơn bạn đã giúp hệ thống tốt hơn.'),
          ),
        );
      }
    } catch (e) {
      if (e.toString().contains('unique') || e.toString().contains('already exists')) {
        setState(() => _hasReported = true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isReporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sử dụng classificationType từ field thay vì parse từ markdown
    Color statusColor;
    IconData statusIcon;
    String statusText;
    LinearGradient statusGradient;

    switch (_currentClassificationType) {
      case 'hazardous':
        statusColor = Colors.redAccent;
        statusIcon = Icons.warning_amber_rounded;
        statusText = 'Rác Nguy hại';
        statusGradient = const LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case 'organic':
        statusColor = Colors.brown;
        statusIcon = Icons.eco_rounded;
        statusText = 'Rác Hữu cơ';
        statusGradient = const LinearGradient(
          colors: [Color(0xFF5D4037), Color(0xFF8D6E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case 'recyclable':
        statusColor = Colors.green;
        statusIcon = Icons.recycling_rounded;
        statusText = 'Có thể Tái chế';
        statusGradient = const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case 'trash':
      default:
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.delete_outline_rounded;
        statusText = 'Rác không tái chế';
        statusGradient = const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFFF9800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Kết quả phân tích'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isReporting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(_hasReported ? Icons.check_circle_outline : Icons.report_problem_outlined, 
                       color: _hasReported ? Colors.greenAccent : null),
            onPressed: (_isReporting || _hasReported || _imageHash == null) ? null : () => _showReportDialog(),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 290,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: statusGradient,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.25),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 2.0,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.file(widget.image, height: 220, width: double.infinity, fit: BoxFit.cover),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  _animateWidget(_buildSummaryCard(theme, statusColor, statusIcon, statusText, statusGradient), 0),
                  const SizedBox(height: 16),
                  _animateWidget(_buildInfoChips(theme, statusColor), 1),
                  const SizedBox(height: 20),
                  _animateWidget(
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
                        boxShadow: [
                          BoxShadow(
                            color: theme.brightness == Brightness.dark
                                ? Colors.black.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(Icons.description_rounded, color: statusColor),
                              const SizedBox(width: 8),
                              const Text('Chi tiết hướng dẫn', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                            ],
                          ),
                          const Divider(height: 30),
                          MarkdownBody(
                            data: _currentResultText,
                            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                              p: const TextStyle(fontSize: 16, height: 1.6),
                            ),
                          ),
                          if (widget.tfliteLabel != null && !_isReanalyzed) ...[
                            const Divider(height: 30),
                            Center(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: statusColor,
                                  side: BorderSide(color: statusColor.withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                icon: _isReanalyzing 
                                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: statusColor))
                                    : const Icon(Icons.auto_awesome_rounded, size: 18),
                                label: Text(
                                  _isReanalyzing ? 'Đang phân tích...' : 'Chưa chuẩn? Phân tích sâu bằng Gemini AI',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                onPressed: _isReanalyzing ? null : _reanalyzeWithGemini,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    2,
                  ),
                  const SizedBox(height: 30),
                  _animateWidget(
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Phân loại ảnh khác'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: theme.primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: (_isReporting || _hasReported || _imageHash == null) ? null : () => _showReportDialog(),
                          icon: Icon(_hasReported ? Icons.check_circle : Icons.report_gmailerrorred_rounded, 
                                     color: _hasReported ? Colors.green : Colors.redAccent),
                          label: Text(_hasReported ? 'Đã gửi báo cáo cho ảnh này' : 'Kết quả này chưa đúng? Báo cáo ngay', 
                                     style: TextStyle(color: _hasReported ? Colors.green : Colors.redAccent, 
                                     decoration: _hasReported ? null : TextDecoration.underline)),
                        ),
                      ],
                    ),
                    3,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận báo cáo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vui lòng nhập tên đúng của vật phẩm:'),
            const SizedBox(height: 12),
            TextField(
              controller: _suggestedNameController,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Chai nhựa Aquafina',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.brightness == Brightness.dark ? theme.colorScheme.surface : Colors.grey[100],
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Text(
              'Hệ thống sẽ lưu lại ảnh này để cải thiện trí tuệ nhân tạo.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: _isReporting ? null : () { 
              if (_suggestedNameController.text.trim().isEmpty) return;
              Navigator.pop(ctx); 
              _reportIncorrectClassification(); 
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), 
            child: const Text('Gửi báo cáo')
          ),
        ],
      ),
    );
  }

  Widget _animateWidget(Widget child, int delayIndex) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delayIndex * 150),
      curve: Curves.easeOutCubic,
      builder: (context, value, childWidget) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0.0, 30.0 * (1 - value)),
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildInfoChips(ThemeData theme, Color statusColor) {
    String sourceLabel;
    IconData sourceIcon;
    switch (_currentAnalysisSource) {
      case 'gemini':
        sourceLabel = 'AI Gemini (Online)';
        sourceIcon = Icons.auto_awesome;
        break;
      case 'tflite_fallback':
        sourceLabel = 'AI Offline (Gemini không khả dụng)';
        sourceIcon = Icons.cloud_off_rounded;
        break;
      case 'tflite':
      default:
        sourceLabel = 'AI Local (Offline) · ${(widget.tfliteConfidence * 100).toStringAsFixed(0)}%';
        sourceIcon = Icons.memory_rounded;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: theme.brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(sourceIcon, color: statusColor, size: 16),
              const SizedBox(width: 6),
              Text(
                sourceLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(ThemeData theme, Color color, IconData icon, String statusText, LinearGradient gradient) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tình trạng phân loại',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
