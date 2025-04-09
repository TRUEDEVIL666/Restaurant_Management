import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_management/layouts/home/screens/combo_selection/ComboSelectionScreen.dart';
import 'package:restaurant_management/layouts/profile/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<int> tableNumbers = List.generate(10, (index) => index + 1);
  final Map<int, bool> tableStatus = {};

  @override
  void initState() {
    super.initState();
    _loadOpenedTables();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


//Truy cập firestore để kiểm tra bàn nào đang mở đang đóng thì hiện lại(Dành cho trường hợp reset lại app)
  Future<void> _loadOpenedTables() async {
    final snapshot = await FirebaseFirestore.instance.collection('tables').get();
    final newTableStatus = <int, bool>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final id = doc.id; // expect something like 'table_1' or '1'
      final tableNum = int.tryParse(id.replaceAll(RegExp(r'[^\d]'), '')) ?? -1;

      if (tableNum > 0) {
        newTableStatus[tableNum] = data['status'] == 'opened';
      }
    }

    setState(() {
      tableStatus.addAll(newTableStatus);
    });
  }

//Hàm đóng bàn nhưng chưa sử dụng có thể bỏ qua được
  Future<void> _closeTable(int tableNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final tableKey = 'table_$tableNumber';

    await prefs.remove('${tableKey}_openTime');
    for (var i = 1; i <= 3; i++) {
      await prefs.remove('${tableKey}_combo_Combo $i');
    }
    for (var price in [219, 259, 299]) {
      await prefs.remove('${tableKey}_ticket_$price');
    }

    final tableRef = FirebaseFirestore.instance.collection('tables').doc('table_$tableNumber');
    await tableRef.set({
      'status': 'closed',
      'currentBillId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      tableStatus[tableNumber] = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã đóng bàn $tableNumber')),
    );
  }


//Hàm này liên quan tới hàm đóng bàn, công dụng chính là sẽ hiện thông báo có chắc chắn đóng bàn khi đã thanh toán rồi không
  void _showCloseTableDialog(BuildContext context, int tableNumber) {
    if (!(tableStatus[tableNumber] ?? false)) {
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


//Hàm này dùng để khi mở 1 bàn thì hiện lên thông báo có chắc chắn muốn mở không, nếu đã mở thì truy cập firestore để thay đổi biến status từ close sang open
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
            onPressed: () async {
              setState(() {
                tableStatus[tableNumber] = true;
              });

              await FirebaseFirestore.instance.collection('tables').doc('table_$tableNumber').set({
                'status': 'opened',
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              Navigator.pop(context);
              _navigateToDetailScreen(context, tableNumber);
            },
            child: Text('Có'),
          ),
        ],
      ),
    );
  }

//Hàm này sau khi chọn mở bàn thì di chuyển tới trang comboselection screen để chọn loại ăn buffet hoặc gọi món
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

//Hàm này để xây dựng ra UI bàn(tui đang cho bàn 1 - 10)
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex == 1) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }
        return true;
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
}
