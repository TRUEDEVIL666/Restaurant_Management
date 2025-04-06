import 'package:flutter/material.dart';
import 'package:restaurant_management/controllers/menu_controller.dart';
import 'package:restaurant_management/controllers/table_controller.dart';
import 'package:restaurant_management/models/menu.dart';
import 'package:restaurant_management/models/table.dart';

class TableDetailScreen extends StatefulWidget {
  final RestaurantTable table;
  TableDetailScreen({required this.table});

  @override
  State<TableDetailScreen> createState() => _TableDetailScreenState();
}

class _TableDetailScreenState extends State<TableDetailScreen> {
  List<Menu> menuItems = [];
  final FoodMenuController menuController = FoodMenuController();
  final TableController tableController = TableController();

  @override
  void initState() {
    super.initState();
    loadMenu();
  }

  Future<void> loadMenu() async {
    menuItems = await menuController.getItems();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bàn ${widget.table.id}'),
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
                  title: Text(menuItems[index].id),
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
              'Bạn có chắc chắn muốn đóng bàn ${widget.table.id} không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    tableController.switchTableState(widget.table);
                  });
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
