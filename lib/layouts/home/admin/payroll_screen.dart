import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PayrollScreen extends StatelessWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("💸 Tính lương nhân viên")),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('users').get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = userSnapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              final username = userData['username'] ?? 'Không tên';
              final salary = (userData['salary'] ?? 0).toDouble();
              final coefficient = (userData['coefficient'] ?? 1).toDouble();

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('attendance')
                    .where('userId', isEqualTo: userId)
                    .get(),
                builder: (context, attendanceSnapshot) {
                  if (!attendanceSnapshot.hasData) {
                    return const ListTile(title: Text('Đang tính lương...'));
                  }

                  final daysWorked = attendanceSnapshot.data!.docs.length;
                  final total = salary * coefficient * daysWorked;

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.account_balance_wallet_outlined),
                      title: Text(username),
                      subtitle: Text("Đi làm: $daysWorked ngày • Hệ số: $coefficient × Lương: ₫${_formatCurrency(salary)}"),
                      trailing: Text("₫${_formatCurrency(total)}"),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatCurrency(double value) {
    return NumberFormat("#,##0", "vi_VN").format(value);
  }
}
