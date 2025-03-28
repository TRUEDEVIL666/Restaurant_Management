import 'package:flutter/material.dart';

class TableDetailScreen extends StatelessWidget {
  final int tableNumber;
  final Function(int) onCloseTable; // Hàm callback để cập nhật trạng thái bàn

  TableDetailScreen({required this.tableNumber, required this.onCloseTable});

  final List<String> menuItems = [
    'Phở',
    'Bún bò',
    'Cơm gà',
    'Gỏi cuốn',
    'Bánh mì',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bàn $tableNumber'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Menu', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(menuItems[index]),
                  trailing: SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text('Chọn'),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () => _showCloseTableDialog(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Đóng Bàn', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCloseTableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận đóng bàn'),
        content: Text('Bạn có chắc chắn muốn đóng bàn $tableNumber không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              onCloseTable(tableNumber); // Gọi callback để đổi trạng thái bàn
              Navigator.pop(context);
              Navigator.pop(context); // Quay lại màn hình danh sách bàn
            },
            child: Text('Đồng ý'),
          ),
        ],
      ),
    );
  }
}
