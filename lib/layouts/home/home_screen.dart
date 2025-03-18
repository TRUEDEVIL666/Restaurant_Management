import 'package:flutter/material.dart';
import 'package:restaurant_management/layouts/home/TableDetailScreen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
  
}

class _HomeScreenState extends State<HomeScreen> {
  final List<int> tableNumbers = List.generate(10, (index) => index + 1);
  final Map<int, bool> tableStatus = {}; // Lưu trạng thái mở bàn
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text('Chọn Bàn Ăn')),
      body: GridView.builder(
        padding: EdgeInsets.all(10.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.5,
        ),
        itemCount: tableNumbers.length,
        itemBuilder: (context, index) {
          int tableNumber = tableNumbers[index];
          bool isOpened = tableStatus[tableNumber] ?? false;

          return ElevatedButton(
            onPressed: () {
              if (!isOpened) {
                _showConfirmationDialog(context, tableNumber);
              } else {
                _navigateToDetailScreen(context, tableNumber);
              }
            },
              style: ElevatedButton.styleFrom(
              backgroundColor: isOpened ? Colors.green : Colors.grey,
              padding: EdgeInsets.symmetric(vertical: 16),
              textStyle: TextStyle(fontSize: 18),
            ),
            child: Text('Bàn ${tableNumbers[index]}'),
          );
        },
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, int tableNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận mở bàn'),
        content: Text('Bạn có chắc chắn muốn mở bàn $tableNumber không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Không'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                tableStatus[tableNumber] = true;
              });
              Navigator.pop(context);
              _navigateToDetailScreen(context, tableNumber);
            },
            child: Text('Có'),
          ),
        ],
      ),
    );
  }

  void _navigateToDetailScreen(BuildContext context, int tableNumber) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TableDetailScreen(
        tableNumber: tableNumber,
        onCloseTable: (closedTable) {
          setState(() {
            tableStatus[closedTable] = false; // Cập nhật trạng thái bàn về chưa mở
          });
        },
      ),
    ),
  );
}

}



