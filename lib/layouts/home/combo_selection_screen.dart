import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_management/layouts/home/table_detail_screen.dart';
import 'package:restaurant_management/models/table.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComboSelectionScreen extends StatefulWidget {
  final RestaurantTable table;

  const ComboSelectionScreen({super.key, required this.table});

  @override
  State<ComboSelectionScreen> createState() => _ComboSelectionScreenState();
}

class _ComboSelectionScreenState extends State<ComboSelectionScreen> {
  Map<String, int> selectedCombos = {};
  Map<int, int> selectedTicketCounts = {};
  DateTime tableOpenTime = DateTime.now();

  List<String> drinkCombos = ['Combo 1', 'Combo 2', 'Combo 3'];
  List<int> ticketPrices = [219, 259, 299];

  @override
  void initState() {
    super.initState();
    _loadSavedSelections();
  }

  Future<void> _loadSavedSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final tableKey = 'table_${widget.table.id}';

    setState(() {
      final savedTimeMillis = prefs.getInt('${tableKey}_openTime');
      if (savedTimeMillis != null) {
        tableOpenTime = DateTime.fromMillisecondsSinceEpoch(savedTimeMillis);
      }

      for (var combo in drinkCombos) {
        selectedCombos[combo] = prefs.getInt('${tableKey}_combo_$combo') ?? 0;
      }
      for (var price in ticketPrices) {
        selectedTicketCounts[price] =
            prefs.getInt('${tableKey}_ticket_$price') ?? 0;
      }
    });
  }

  Future<void> _saveSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final tableKey = 'table_${widget.table}';

    await prefs.setInt(
      '${tableKey}_openTime',
      tableOpenTime.millisecondsSinceEpoch,
    );

    selectedCombos.forEach((combo, count) {
      prefs.setInt('${tableKey}_combo_$combo', count);
    });
    selectedTicketCounts.forEach((price, count) {
      prefs.setInt('${tableKey}_ticket_$price', count);
    });
  }

  Future<void> _saveSelectionsToFirestore() async {
    final tableNumber = widget.table.toString();
    final firestore = FirebaseFirestore.instance;

    // Tạo billId dạng "bill_tableNumber_timestamp"
    String billId =
        'bill_${widget.table}_${DateTime.now().millisecondsSinceEpoch}';

    // Tạo document bill mới trong "bills"
    final billRef = firestore.collection('bills').doc(billId);

    Map<String, int> ticketCountsStringKey = selectedTicketCounts.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    await billRef.set({
      'billId': billId,
      'tableNumber': widget.table,
      'openTime': tableOpenTime,
      'combos': selectedCombos,
      'tickets': ticketCountsStringKey,
      'status': 'open',
    });

    // Ghi billId hiện tại vào tables/{tableNumber}
    final tableRef = firestore.collection('tables').doc(tableNumber);

    await tableRef.set({
      'tableNumber': widget.table,
      'openTime': tableOpenTime.millisecondsSinceEpoch,
      'status': 'open',
      'currentBillId': billId,
    });
  }

  void _saveAndContinue() async {
    await _saveSelections();
    await _saveSelectionsToFirestore(); // 🔥 Ghi dữ liệu vào Firestore

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TableDetailScreen(table: widget.table),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bàn ${widget.table} - Chọn Combo & Giá Vé')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thời gian mở bàn: ${_formatDateTime(tableOpenTime)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),

            Text('Chọn Combo Nước:', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            _buildDrinkComboSelection(),
            SizedBox(height: 24),

            Text('Chọn Giá Vé:', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            _buildTicketPriceSelection(),

            Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Hủy'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Xác nhận'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrinkComboSelection() {
    return Column(
      children:
          drinkCombos.map((combo) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(combo, style: TextStyle(fontSize: 16)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        setState(() {
                          if (selectedCombos[combo]! > 0) {
                            selectedCombos[combo] = selectedCombos[combo]! - 1;
                          }
                        });
                      },
                    ),
                    Text(
                      '${selectedCombos[combo]}',
                      style: TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline),
                      onPressed: () {
                        setState(() {
                          selectedCombos[combo] = selectedCombos[combo]! + 1;
                        });
                      },
                    ),
                  ],
                ),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildTicketPriceSelection() {
    return Column(
      children:
          ticketPrices.map((price) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${price}K VND', style: TextStyle(fontSize: 16)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        setState(() {
                          if (selectedTicketCounts[price]! > 0) {
                            selectedTicketCounts[price] =
                                selectedTicketCounts[price]! - 1;
                          }
                        });
                      },
                    ),
                    Text(
                      '${selectedTicketCounts[price]}',
                      style: TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline),
                      onPressed: () {
                        setState(() {
                          selectedTicketCounts[price] =
                              selectedTicketCounts[price]! + 1;
                        });
                      },
                    ),
                  ],
                ),
              ],
            );
          }).toList(),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} - ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
