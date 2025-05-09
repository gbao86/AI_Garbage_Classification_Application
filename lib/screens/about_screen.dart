import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Về ứng dụng'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Ứng dụng Phân Loại Rác AI',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Phiên bản: 1.0.0',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Ứng dụng Phân Loại Rác AI được phát triển bởi Trịnh Gia Bảo, sử dụng mô hình trí tuệ nhân tạo tiên tiến để nhận diện nhanh chóng và chính xác các loại rác thải.\n\nChỉ cần chụp ảnh hoặc chọn ảnh từ thư viện, hệ thống sẽ tự động phân tích, xác định loại rác (hữu cơ, tái chế, nguy hại...) và đưa ra hướng dẫn xử lý chi tiết, giúp bạn góp phần bảo vệ môi trường từ những hành động nhỏ nhất.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Liên hệ:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Email: tiktokthu10@gmail.com',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Facebook: Trinh Gia Bao',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
