import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultScreen extends StatelessWidget {
  final File image;
  final String processingResult;

  const ResultScreen({
    super.key,
    required this.image,
    required this.processingResult,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Logic xác định màu sắc dựa trên kết quả phân loại
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.recycling_rounded;
    
    if (processingResult.contains('nguy hại')) {
      statusColor = Colors.redAccent;
      statusIcon = Icons.warning_amber_rounded;
    } else if (processingResult.contains('không tái chế') || processingResult.contains('trash')) {
      statusColor = Colors.orangeAccent;
      statusIcon = Icons.delete_outline_rounded;
    } else if (processingResult.contains('hữu cơ')) {
      statusColor = Colors.brown;
      statusIcon = Icons.eco_rounded;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Kết quả phân tích'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Phần Header với Hình ảnh
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
                      // Khung ảnh bo góc
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 15,
                              offset: Offset(0, 8),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            image,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ],
            ),

            // Phần nội dung chi tiết
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thẻ Tóm tắt Phân loại
                  _buildSummaryCard(statusColor, statusIcon),
                  
                  const SizedBox(height: 20),
                  
                  // Thẻ Chi tiết (Sử dụng Markdown)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description_rounded, color: theme.primaryColor),
                            const SizedBox(width: 10),
                            Text(
                              'Chi tiết hướng dẫn',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        MarkdownBody(
                          data: processingResult,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                            strong: const TextStyle(fontWeight: FontWeight.bold),
                            listBullet: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Nút hành động
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Phân loại ảnh khác'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
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

  Widget _buildSummaryCard(Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tình trạng phân loại',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  _extractClassificationType(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hàm hỗ trợ trích xuất loại rác chính để hiển thị nổi bật
  String _extractClassificationType() {
    if (processingResult.contains('tái chế')) return 'Có thể Tái chế';
    if (processingResult.contains('nguy hại')) return 'Rác Nguy hại';
    if (processingResult.contains('hữu cơ')) return 'Rác Hữu cơ';
    if (processingResult.contains('không tái chế')) return 'Rác không tái chế';
    return 'Đang xác định';
  }
}
