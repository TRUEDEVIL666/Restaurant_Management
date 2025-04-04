import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TableDetailScreen extends StatefulWidget {
  final int tableNumber;
  final Function(int) onCloseTable;

  TableDetailScreen({required this.tableNumber, required this.onCloseTable});

  @override
  _TableDetailScreenState createState() => _TableDetailScreenState();
}

class _TableDetailScreenState extends State<TableDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Danh sách món ăn
  final List<String> menuItems = ['Phở', 'Bún bò', 'Cơm gà', 'Gỏi cuốn', 'Bánh mì'];
  Map<String, int> orderQuantities = {}; // Lưu số lượng món đã chọn

 
Future<void> _addNewOrder() async {
  if (orderQuantities.isEmpty || orderQuantities.values.every((q) => q == 0)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Vui lòng chọn ít nhất một món!')),
    );
    return;
  }

  String tableId = widget.tableNumber.toString();
  final tableRef = _firestore.collection('tables').doc(tableId);
  final tableSnapshot = await tableRef.get();

  if (!tableSnapshot.exists || !tableSnapshot.data()!.containsKey('currentBillId')) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Không tìm thấy bill hiện tại cho bàn này!')),
    );
    return;
  }

  String currentBillId = tableSnapshot['currentBillId'];
  final billRef = _firestore.collection('bills').doc(currentBillId);
  final ordersRef = billRef.collection('orders');

  // Tạo orderId tăng dần
  int newOrderId = 1;
  final orderSnapshot = await ordersRef.get();
  if (orderSnapshot.docs.isNotEmpty) {
    newOrderId = orderSnapshot.docs.length + 1;
  }

  // Lưu order mới
  await ordersRef.doc(newOrderId.toString()).set({
    'items': orderQuantities,
    'timestamp': FieldValue.serverTimestamp(),
  });

  setState(() {
    orderQuantities = {};
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Order #$newOrderId đã được lưu thành công!')),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bàn ${widget.tableNumber} - Order Món Ăn'),
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
                String item = menuItems[index];
                int quantity = orderQuantities[item] ?? 0;

                return ListTile(
                  title: Text(item, style: TextStyle(fontSize: 18)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            if (quantity > 0) orderQuantities[item] = quantity - 1;
                          });
                        },
                      ),
                      Text(quantity.toString(), style: TextStyle(fontSize: 18)),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline, color: Colors.green),
                        onPressed: () {
                          setState(() {
                            orderQuantities[item] = quantity + 1;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: _addNewOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
                child: Text('Xác nhận Order', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
