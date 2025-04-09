import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuScreen extends StatefulWidget {
  final int tableNumber;
  final List<String> includedDishes;

  MenuScreen({
    required this.tableNumber,
    required this.includedDishes,
  });

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final List<Map<String, dynamic>> allDishes = [
    {
      'name': 'Bò Mỹ',
      'price': 50,
      'image': 'https://source.unsplash.com/featured/?beef'
    },
    {
      'name': 'Gà rán',
      'price': 40,
      'image': 'https://source.unsplash.com/featured/?fried-chicken'
    },
    {
      'name': 'Salad',
      'price': 30,
      'image': 'https://source.unsplash.com/featured/?salad'
    },
    {
      'name': 'Hải sản',
      'price': 60,
      'image': 'https://source.unsplash.com/featured/?seafood'
    },
    {
      'name': 'Lẩu thái',
      'price': 70,
      'image': 'https://source.unsplash.com/featured/?hotpot'
    },
    {
      'name': 'Coca',
      'price': 20,
      'image': 'https://source.unsplash.com/featured/?coke'
    },
  ];

  Map<String, int> selectedQuantities = {};

  void updateQuantity(String dishName, int change) {
    setState(() {
      selectedQuantities[dishName] =
          (selectedQuantities[dishName] ?? 0) + change;
      if (selectedQuantities[dishName]! <= 0) {
        selectedQuantities.remove(dishName);
      }
    });
  }

  Future<void> submitOrder() async {
    final orderItems = selectedQuantities.entries.map((entry) {
      final dishName = entry.key;
      final quantity = entry.value;

      final dish = allDishes.firstWhere(
        (d) => d['name'] == dishName,
        orElse: () => {'price': 0},
      );

      return {
        'name': dishName,
        'quantity': quantity,
        'unitPrice': dish['price'],
      };
    }).toList();

    final billQuery = await FirebaseFirestore.instance
        .collection('bills')
        .where('tableNumber', isEqualTo: widget.tableNumber)
        .where('status', isEqualTo: 'open')
        .limit(1)
        .get();

    String billId;

    if (billQuery.docs.isEmpty) {
      final billRef =
          await FirebaseFirestore.instance.collection('bills').add({
        'tableNumber': widget.tableNumber,
        'status': 'open',
        'timestamp': Timestamp.now(),
      });
      billId = billRef.id;
    } else {
      billId = billQuery.docs.first.id;
    }

    await FirebaseFirestore.instance
        .collection('bills')
        .doc(billId)
        .collection('orders')
        .add({
      'timestamp': Timestamp.now(),
      'items': orderItems,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đặt món thành công!')),
    );

    setState(() {
      selectedQuantities.clear();
    });
  }

  Widget buildDishCard(Map<String, dynamic> dish) {
  final name = dish['name'];
  final price = dish['price'];
  final image = dish['image'];
  final isIncluded = widget.includedDishes.contains(name);
  final quantity = selectedQuantities[name] ?? 0;

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 5,
          offset: Offset(2, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hình ảnh (đặt chiều cao cụ thể thay vì Expanded)
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          child: Image.network(
            image,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[300],
              height: 100,
              child: Icon(Icons.fastfood, size: 40),
            ),
          ),
        ),
        // Phần nội dung
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6),
              Text(
                isIncluded ? 'Đã bao gồm' : '$price k',
                style: TextStyle(
                  fontSize: 13,
                  color: isIncluded ? Colors.green : Colors.black,
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, size: 22),
                    onPressed: () => updateQuantity(name, -1),
                  ),
                  Text(
                    '$quantity',
                    style: TextStyle(fontSize: 16),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, size: 22),
                    onPressed: () => updateQuantity(name, 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đặt món - Bàn ${widget.tableNumber}')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 200, // mỗi item tối đa 200px ngang
    crossAxisSpacing: 12,
    mainAxisSpacing: 6,
    childAspectRatio: 0.75,
  ),
  itemCount: allDishes.length,
  itemBuilder: (context, index) {
    return buildDishCard(allDishes[index]);
  },
)

      ),
      bottomNavigationBar: Padding(
  padding: const EdgeInsets.all(12.0),
  child: Row(
    children: [
      Expanded(
        child: ElevatedButton(
          onPressed: submitOrder,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.green,
          ),
          child: Text(
            'Xác nhận đặt món',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: ElevatedButton(
          onPressed: () {
            // TODO: xử lý logic thanh toán tại đây
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Chức năng thanh toán đang phát triển')),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.redAccent,
          ),
          child: Text(
            'Thanh toán',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    ],
  ),
),
 );
  }
}
