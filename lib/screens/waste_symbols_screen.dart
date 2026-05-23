import 'package:flutter/material.dart';

class WasteSymbolsScreen extends StatelessWidget {
  const WasteSymbolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final List<Map<String, dynamic>> symbols = [
      {
        'title': 'Vòng lặp Mobius',
        'subtitle': 'Biểu tượng tái chế chung',
        'description': 'Cho biết sản phẩm hoặc bao bì có thể tái chế được. Nếu có % ở giữa, nó cho biết bao nhiêu phần trăm vật liệu tái chế đã được sử dụng.',
        'icon': Icons.sync,
        'color': Colors.green,
      },
      {
        'title': 'PET hoặc PETE (Số 1)',
        'subtitle': 'Nhựa Polyethylene Terephthalate',
        'description': 'Thường thấy ở chai nước suối, nước ngọt. Có thể tái chế nhưng nên dùng một lần duy nhất vì dễ tích tụ vi khuẩn.',
        'icon': Icons.looks_one_outlined,
        'color': Colors.blue,
      },
      {
        'title': 'HDPE (Số 2)',
        'subtitle': 'Nhựa Polyethylene tỷ trọng cao',
        'description': 'Dùng cho bình sữa, chai dầu gội, nước giặt. Đây là loại nhựa an toàn nhất và có khả năng tái chế cao.',
        'icon': Icons.looks_two_outlined,
        'color': Colors.blue.shade700,
      },
      {
        'title': 'PVC (Số 3)',
        'subtitle': 'Nhựa Polyvinyl Chloride',
        'description': 'Dùng trong màng bọc thực phẩm, ống nước. Chứa chất độc hại, rất khó tái chế và không nên dùng để đựng thực phẩm nóng.',
        'icon': Icons.looks_3_outlined,
        'color': Colors.red.shade400,
      },
      {
        'title': 'LDPE (Số 4)',
        'subtitle': 'Nhựa Polyethylene tỷ trọng thấp',
        'description': 'Dùng làm túi nilon, vỏ bọc thực phẩm. Khá an toàn nhưng khó tái chế hơn HDPE.',
        'icon': Icons.looks_4_outlined,
        'color': Colors.blue.shade300,
      },
      {
        'title': 'PP (Số 5)',
        'subtitle': 'Nhựa Polypropylene',
        'description': 'Thường dùng làm hộp sữa chua, hộp đựng thức ăn nóng. Chịu nhiệt tốt và an toàn để tái sử dụng.',
        'icon': Icons.looks_5_outlined,
        'color': Colors.orange,
      },
      {
        'title': 'PS (Số 6)',
        'subtitle': 'Nhựa Polystyrene',
        'description': 'Dùng làm hộp xốp đựng cơm, ly mì ăn liền. Có hại cho sức khỏe khi gặp nhiệt độ cao và rất khó tái chế.',
        'icon': Icons.looks_6_outlined,
        'color': Colors.red.shade700,
      },
      {
        'title': 'Other (Số 7)',
        'subtitle': 'Các loại nhựa khác',
        'description': 'Bao gồm nhựa PC, BPA hoặc các hỗn hợp nhựa. Thường không thể tái chế và có nguy cơ chứa chất độc hại.',
        'icon': Icons.help_outline_rounded,
        'color': Colors.grey,
      },
      {
        'title': 'Thùng rác có gạch chéo',
        'subtitle': 'Rác thải điện tử (WEEE)',
        'description': 'Không được vứt vào thùng rác sinh hoạt. Chứa các kim loại nặng cần được xử lý riêng tại điểm thu gom đồ điện tử.',
        'icon': Icons.delete_forever_rounded,
        'color': Colors.red,
      },
      {
        'title': 'Biểu tượng Seedling',
        'subtitle': 'Bao bì phân hủy sinh học',
        'description': 'Chứng nhận sản phẩm có thể phân hủy hoàn toàn trong điều kiện ủ công nghiệp.',
        'icon': Icons.eco_outlined,
        'color': Colors.green.shade700,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ký hiệu rác thải', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: symbols.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = symbols[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item['icon'], color: item['color'], size: 28),
                ),
                title: Text(
                  item['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  item['subtitle'],
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Text(
                      item['description'],
                      style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
