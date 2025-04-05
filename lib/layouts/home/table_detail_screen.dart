import 'package:flutter/material.dart';
import 'package:restaurant_management/controllers/dish_controller.dart';
import 'package:restaurant_management/models/dish.dart';

class TableDetailScreen extends StatefulWidget {
  final int tableNumber;
  final Function(int) onCloseTable; // Hàm callback để cập nhật trạng thái bàn

  TableDetailScreen({required this.tableNumber, required this.onCloseTable});

  @override
  State<TableDetailScreen> createState() => _TableDetailScreenState();
}

class _TableDetailScreenState extends State<TableDetailScreen> {
  List<Dish> menuItems = [];
  final DishController dishController = DishController();

  @override
  void initState() {
    super.initState();
    loadMenu();
  }

  Future<void> loadMenu() async {
    setState(() async {
      menuItems = await dishController.getItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bàn ${widget.tableNumber}'),
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
            child: Text(
              'Menu',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(menuItems[index].dishName),
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
      builder:
          (context) => AlertDialog(
            title: Text('Xác nhận đóng bàn'),
            content: Text(
              'Bạn có chắc chắn muốn đóng bàn ${widget.tableNumber} không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  widget.onCloseTable(
                    widget.tableNumber,
                  ); // Gọi callback để đổi trạng thái bàn
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
