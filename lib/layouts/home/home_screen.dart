import 'package:flutter/material.dart';
import 'package:restaurant_management/controllers/table_controller.dart';
import 'package:restaurant_management/layouts/home/table_detail_screen.dart';
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
    tables = await tableController.getItems();
    _onItemTapped(0);
    setState(() {});
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

  void _showConfirmationDialog(BuildContext context, int tableIndex) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Xác nhận mở bàn'),
            content: Text(
              'Bạn có chắc chắn muốn mở bàn ${tableIndex + 1} không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Không'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    tableController.switchTableState(tables[tableIndex]);
                  });
                  Navigator.pop(context);
                  _navigateToDetailScreen(context, tableIndex);
                },
                child: Text('Có'),
              ),
            ],
          ),
    );
  }

  Future<void> _navigateToDetailScreen(
    BuildContext context,
    int tableIndex,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TableDetailScreen(table: tables[tableIndex]),
      ),
    );
    setState(() {
      loadTables();
    });
  }
}
