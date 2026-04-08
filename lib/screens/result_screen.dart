import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ResultScreen extends StatefulWidget {
  final File image;
  final String processingResult;

  const ResultScreen({
    super.key,
    required this.image,
    required this.processingResult,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isReporting = false;
  bool _hasReported = false;
  String? _imageHash;

  @override
  void initState() {
    super.initState();
    _calculateImageHash();
  }

  // Tạo "dấu vân tay" duy nhất cho ảnh để chống spam
  Future<void> _calculateImageHash() async {
    final bytes = await widget.image.readAsBytes();
    setState(() {
      _imageHash = md5.convert(bytes).toString();
    });
    _checkExistingReport();
  }

  // Kiểm tra xem trong phiên làm việc hiện tại hoặc trên DB đã có báo cáo này chưa
  Future<void> _checkExistingReport() async {
    if (_imageHash == null) return;
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Tìm xem đã có bản ghi nào với image hash này của user này chưa
      // Chúng ta tìm trong cột scan_image_path vì nó chứa hash ở tên file
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

    setState(() => _isReporting = true);

    try {
      final supabase = Supabase.instance.client;
      File compressedFile = await _compressForReport(widget.image);

      // SỬ DỤNG HASH LÀM TÊN FILE: Chống spam vật lý trên Storage
      final fileName = '$_imageHash.jpg';
      final imagePath = 'reports/${user.id}/$fileName';
      
      // Sử dụng upsert: true để nếu có gửi lại cũng chỉ ghi đè đúng file đó, không tạo file mới
      await supabase.storage.from('waste-reports').upload(
        imagePath,
        compressedFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final String publicUrl = supabase.storage.from('waste-reports').getPublicUrl(imagePath);

      // Kiểm tra lại một lần nữa trước khi insert để tránh race condition
      await supabase.from('waste_submissions').insert({
        'submitter_id': user.id,
        'status': 'pending_review',
        'gemini_payload': {'result_text': widget.processingResult, 'image_hash': _imageHash},
        'suggested_name_vi': null,
        'rejection_reason': 'Người dùng báo cáo phân loại sai',
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
      // Nếu lỗi là do trùng lặp (Unique constraint) thì cũng coi như đã báo cáo
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

    Color statusColor = Colors.green;
    IconData statusIcon = Icons.recycling_rounded;

    if (widget.processingResult.contains('nguy hại')) {
      statusColor = Colors.redAccent;
      statusIcon = Icons.warning_amber_rounded;
    } else if (widget.processingResult.contains('không tái chế') || widget.processingResult.contains('trash')) {
      statusColor = Colors.orangeAccent;
      statusIcon = Icons.delete_outline_rounded;
    } else if (widget.processingResult.contains('hữu cơ')) {
      statusColor = Colors.brown;
      statusIcon = Icons.eco_rounded;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
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
                  _buildSummaryCard(statusColor, statusIcon),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description_rounded, color: theme.primaryColor),
                            const SizedBox(width: 10),
                            const Text('Chi tiết hướng dẫn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        const Divider(height: 30),
                        MarkdownBody(data: widget.processingResult, styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 16, height: 1.6))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Phân loại ảnh khác'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: theme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận báo cáo'),
        content: const Text('Hệ thống sẽ ghi lại hình ảnh này để cải thiện trí tuệ nhân tạo. Mỗi ảnh chỉ cần báo cáo một lần.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: _isReporting ? null : () { 
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

  Widget _buildSummaryCard(Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 30)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tình trạng phân loại', style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text(_extractClassificationType(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _extractClassificationType() {
    if (widget.processingResult.contains('tái chế')) return 'Có thể Tái chế';
    if (widget.processingResult.contains('nguy hại')) return 'Rác Nguy hại';
    if (widget.processingResult.contains('hữu cơ')) return 'Rác Hữu cơ';
    return 'Rác không tái chế';
  }
}
