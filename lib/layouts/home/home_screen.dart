import 'package:flutter/material.dart';
import 'package:restaurant_management/controllers/table_controller.dart';
import 'package:restaurant_management/layouts/home/TableDetailScreen.dart';
import 'package:restaurant_management/layouts/profile/profile_screen.dart';
import 'package:restaurant_management/models/table.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Trang hiện tại
  List<RestaurantTable> tables = [];
  TableController tableController = TableController();

  @override
  void initState() {
    super.initState();
    loadTables();
  }

  Future<void> loadTables() async {
    setState(() async {
      tables = await tableController.getItems();
      _onItemTapped(0);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex == 1) {
          setState(() {
            _selectedIndex = 0; // Quay về Home khi đang ở Profile
          });
          return false; // Không thoát app
        }
        return true; // Cho phép thoát app nếu đang ở Home
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selectedIndex == 0 ? 'Chọn Bàn Ăn' : 'Hồ Sơ Cá Nhân'),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [_buildTableGrid(), ProfileScreen()],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.table_chart),
              label: 'Bàn ăn',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hồ sơ'),
          ],
        ),
      ),
    );
  }

  Widget _buildTableGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.5,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        int tableIndex = int.parse(tables[index].id) - 1;
        bool isOpened = tables[index].isOccupied;

        return ElevatedButton(
          onPressed: () {
            if (!isOpened) {
              _showConfirmationDialog(context, tableIndex);
            } else {
              _navigateToDetailScreen(context, tableIndex);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isOpened ? Colors.green : Colors.grey,
            padding: EdgeInsets.symmetric(vertical: 16),
            textStyle: TextStyle(fontSize: 18),
          ),
          child: Text('Bàn ${tableIndex + 1}'),
        );
      },
    );
  }

  void _showConfirmationDialog(BuildContext context, int tableNumber) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Xác nhận mở bàn'),
            content: Text(
              'Bạn có chắc chắn muốn mở bàn ${tableNumber + 1} không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Không'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    switchTableState(tableNumber);
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

  void switchTableState(int tableNumber) {
    setState(() {
      tables[tableNumber].isOccupied = !tables[tableNumber].isOccupied;
      tableController.updateItem(tables[tableNumber]);
    });
  }

  void _navigateToDetailScreen(BuildContext context, int tableNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TableDetailScreen(
              tableNumber: tableNumber,
              onCloseTable: (closedTable) {
                switchTableState(closedTable);
              },
            ),
      ),
    );
  }
}
