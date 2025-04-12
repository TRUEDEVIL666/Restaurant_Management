import 'package:flutter/material.dart';

class PayrollScreen extends StatelessWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("💸 Tính lương")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(4, (index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text("Nhân viên ${index + 1}"),
              subtitle: const Text("Số giờ làm: 168h"),
              trailing: const Text("₫6,720,000"),
            ),
          );
        }),
      ),
    );
  }
}
