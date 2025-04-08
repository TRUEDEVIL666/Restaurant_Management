import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_management/layouts/home/screens/combo_selection/MenuScreen.dart';

class ComboSelectionScreen extends StatefulWidget {
  final int tableNumber;
  final Function(int) onCloseTable;

  const ComboSelectionScreen({
    Key? key,
    required this.tableNumber,
    required this.onCloseTable,
  }) : super(key: key);

  @override
  State<ComboSelectionScreen> createState() => _ComboSelectionScreenState();
}

class _ComboSelectionScreenState extends State<ComboSelectionScreen> {
  String? selectedMealType; // 'buffet' hoặc 'order'
  bool mealTypeLocked = false;
  String selectedBuffetCombo = 'combo1'; // mặc định
  int buffetQuantity = 1;
  bool useDrinkCombo = true; // Mặc định có dùng combo nước
  bool buffetOptionsLocked = false;

  Map<String, List<String>> comboIncludedDishes = {
    'combo1': ['Bò Mỹ', 'Gà rán', 'Salad'],
    'combo2': ['Bò Mỹ', 'Gà rán', 'Salad', 'Hải sản'],
    'combo3': ['Bò Mỹ', 'Gà rán', 'Salad', 'Hải sản', 'Lẩu thái'],
  };
  List<Map<String, dynamic>> allDishes = [
    {'name': 'Bò Mỹ', 'price': 50},
    {'name': 'Gà rán', 'price': 40},
    {'name': 'Salad', 'price': 30},
    {'name': 'Hải sản', 'price': 60},
    {'name': 'Lẩu thái', 'price': 70},
    {'name': 'Coca', 'price': 20},
  ];

  @override
  void initState() {
    super.initState();
    _loadMealTypeFromFirestore();
  }

  Future<void> _loadMealTypeFromFirestore() async {
  final doc = await FirebaseFirestore.instance
      .collection('tables')
      .doc('table_${widget.tableNumber}')
      .get();

  if (doc.exists) {
    final data = doc.data()!;
    final mealType = data['mealType'];
    final locked = data['mealTypeLocked'] ?? false;

    if (mealType == 'order' && locked) {
      // 👉 Nếu là gọi món và đã lock, chuyển luôn sang menu
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MenuScreen(
              tableNumber: widget.tableNumber,
              includedDishes: [], // gọi món không có món bao gồm
            ),
          ),
        );
      });
    } else {
      // 👇 Nếu là buffet hoặc chưa xác nhận
      setState(() {
        selectedMealType = mealType;
        mealTypeLocked = locked;
        selectedBuffetCombo = data['buffetCombo'] ?? 'combo1';
        buffetQuantity = data['buffetQuantity'] ?? 1;
        useDrinkCombo = data['useDrinkCombo'] ?? true;
        buffetOptionsLocked = data['buffetOptionsLocked'] ?? false;
      });
    }
  }
}


  Future<void> _saveMealTypeToFirestore() async {
    await FirebaseFirestore.instance
        .collection('tables')
        .doc('table_${widget.tableNumber}')
        .set({
          'mealType': selectedMealType,
          'mealTypeLocked': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  void _onMealTypeConfirm() async {
    if (selectedMealType != null) {
      await _saveMealTypeToFirestore();
      setState(() {
        mealTypeLocked = true;
      });
    }
  }

  void _onSubmit() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã lưu thông tin bàn ${widget.tableNumber}')),
    );
    await FirebaseFirestore.instance
        .collection('tables')
        .doc('table_${widget.tableNumber}')
        .set({
          'mealType': selectedMealType,
          'buffetCombo': selectedBuffetCombo,
          'buffetQuantity': buffetQuantity,
          'drinkCombo': 'comboDrink1',
          'buffetOptionsLocked': true,
          'mealTypeLocked': true,
          'useDrinkCombo': useDrinkCombo,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    buffetOptionsLocked = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bàn ${widget.tableNumber}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chọn kiểu ăn:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        mealTypeLocked
                            ? null
                            : () => setState(() => selectedMealType = 'buffet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selectedMealType == 'buffet'
                              ? Colors.green
                              : Colors.grey[300],
                      foregroundColor:
                          selectedMealType == 'buffet'
                              ? Colors.white
                              : Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Buffet'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        mealTypeLocked
                            ? null
                            : () => setState(() => selectedMealType = 'order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selectedMealType == 'order'
                              ? Colors.green
                              : Colors.grey[300],
                      foregroundColor:
                          selectedMealType == 'order'
                              ? Colors.white
                              : Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Gọi món'),
                  ),
                ),
              ],
            ),

            if (!mealTypeLocked) ...[
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: selectedMealType != null ? _onMealTypeConfirm : null,
                icon: Icon(Icons.lock),
                label: Text('Xác nhận kiểu ăn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ] else ...[
              SizedBox(height: 24),
              Text(
                'Đã chọn: ${selectedMealType == 'buffet' ? 'Buffet' : 'Gọi món'}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              if (selectedMealType == 'buffet') _buildBuffetOptions(),
              if (selectedMealType == 'order') _buildOrderOptions(),

              Spacer(),
ElevatedButton(
  onPressed: () async {
    if (selectedMealType == 'buffet') {
      // Lưu thông tin buffet
      await FirebaseFirestore.instance
          .collection('tables')
          .doc('table_${widget.tableNumber}')
          .set({
            'mealType': selectedMealType,
            'buffetCombo': selectedBuffetCombo,
            'buffetQuantity': buffetQuantity,
            'drinkCombo': 'comboDrink1',
            'useDrinkCombo': useDrinkCombo,
            'mealTypeLocked': true,
            'buffetOptionsLocked': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } else if (selectedMealType == 'order') {
      // Lưu thông tin gọi món
      await FirebaseFirestore.instance
          .collection('tables')
          .doc('table_${widget.tableNumber}')
          .set({
            'mealType': selectedMealType,
            'useDrinkCombo': useDrinkCombo,
            'mealTypeLocked': true,
            'buffetOptionsLocked': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }

    // Chuyển đến MenuScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuScreen(
          tableNumber: widget.tableNumber,
          includedDishes: selectedMealType == 'buffet'
              ? List<String>.from(
                  comboIncludedDishes[selectedBuffetCombo] ?? [])
              : [],
        ),
      ),
    );
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    padding: EdgeInsets.symmetric(vertical: 16),
  ),
  child: Center(child: Text('Xác nhận & chuyển sang Menu')),
),
],
          ],
        ),
      ),
    );
  }

  // 🥤 Với buffet: chọn combo nước + vé
  Widget _buildBuffetOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn combo buffet:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Column(
          children: [
            RadioListTile<String>(
              title: Text('Combo Buffet 259'),
              value: 'combo1',
              groupValue: selectedBuffetCombo,
              onChanged:
                  buffetOptionsLocked
                      ? null
                      : (value) => setState(() => selectedBuffetCombo = value!),
            ),
            RadioListTile<String>(
              title: Text('Combo Buffet 299'),
              value: 'combo2',
              groupValue: selectedBuffetCombo,
              onChanged:
                  buffetOptionsLocked
                      ? null
                      : (value) => setState(() => selectedBuffetCombo = value!),
            ),
            RadioListTile<String>(
              title: Text('Combo Buffet 359'),
              value: 'combo3',
              groupValue: selectedBuffetCombo,
              onChanged:
                  buffetOptionsLocked
                      ? null
                      : (value) => setState(() => selectedBuffetCombo = value!),
            ),
          ],
        ),

        SizedBox(height: 16),
        Text('Số lượng người dùng buffet:', style: TextStyle(fontSize: 16)),
        SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove),
              onPressed:
                  buffetQuantity > 1
                      ? () => setState(() => buffetQuantity--)
                      : null,
            ),
            Text('$buffetQuantity', style: TextStyle(fontSize: 18)),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => setState(() => buffetQuantity++),
            ),
          ],
        ),

        SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: useDrinkCombo,
              onChanged:
                  buffetOptionsLocked
                      ? null
                      : (value) =>
                          setState(() => useDrinkCombo = value ?? true),
            ),
            SizedBox(width: 8),
            Text(
              'Dùng combo nước đi kèm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  // 🍽 Với gọi món: chọn món
  Widget _buildOrderOptions() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 16),
      Row(
        children: [
          Checkbox(
            value: useDrinkCombo,
            onChanged: (value) {
              setState(() {
                useDrinkCombo = value ?? true;
              });
            },
          ),
          SizedBox(width: 8),
          Text(
            'Dùng combo nước đi kèm',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      SizedBox(height: 12),
      Text(
        'Nhấn "Xác nhận & chuyển sang Menu" để tiếp tục.',
        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
      ),
    ],
  );
}

}
