import 'package:flutter/material.dart';
import 'package:restaurant_management/layouts/home/TableDetailScreen.dart';
import 'package:restaurant_management/layouts/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Trang hiện tại
  final List<int> tableNumbers = List.generate(10, (index) => index + 1);
  final Map<int, bool> tableStatus = {};

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
          children: [
            _buildTableGrid(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.table_chart), label: 'Bàn ăn'),
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
          child: Text('Bàn $tableNumber'),
        );
      },
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
              tableStatus[closedTable] = false;
            });
          },
        ),
      ),
    );
  }
}
