import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_management/layouts/home/ComboSelectionScreen.dart';
import 'package:restaurant_management/layouts/home/TableDetailScreen.dart';
import 'package:restaurant_management/layouts/profile/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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


Future<void> _closeTable(int tableNumber) async {
  final prefs = await SharedPreferences.getInstance();
  final tableKey = 'table_$tableNumber';

  // Xóa dữ liệu local
  await prefs.remove('${tableKey}_openTime');

  // Xóa combo
  for (var i = 1; i <= 3; i++) {
    await prefs.remove('${tableKey}_combo_Combo $i');
  }

  // Xóa ticket
  for (var price in [219, 259, 299]) {
    await prefs.remove('${tableKey}_ticket_$price');
  }

  // Xóa dữ liệu Firestore liên quan (nếu có)
  final tableRef = FirebaseFirestore.instance.collection('tables').doc(tableNumber.toString());
  await tableRef.update({
    'currentBillId': FieldValue.delete(),
    'status': 'closed',
  }).catchError((e) {
    print('Không thể cập nhật Firestore: $e');
  });

  setState(() {
    tableStatus[tableNumber] = false;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Đã đóng bàn $tableNumber')),
  );
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

        return GestureDetector(
  onLongPress: () => _showCloseTableDialog(context, tableNumber),
  child: ElevatedButton(
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
  ),
);

      },
    );
  }

  void _showCloseTableDialog(BuildContext context, int tableNumber) {
  bool isOpened = tableStatus[tableNumber] ?? false;

  if (!isOpened) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bàn $tableNumber chưa được mở!')),
    );
    return;
  }

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
          onPressed: () async {
            Navigator.pop(context);
            await _closeTable(tableNumber);
          },
          child: Text('Đóng bàn'),
        ),
      ],
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
        builder: (context) => ComboSelectionScreen(
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
