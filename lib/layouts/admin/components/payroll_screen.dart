import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

              return FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get(),
                builder: (context, userDetailsSnapshot) {
                  if (!userDetailsSnapshot.hasData) {
                    return const ListTile(title: Text('Đang tính lương...'));
                  }

                  // Lấy loginHistory từ dữ liệu người dùng
                  final loginHistory =
                      userDetailsSnapshot.data!['loginHistory']
                          as List<dynamic>?;

                  // Đảm bảo loginHistory không null và có kiểu Timestamp
                  if (loginHistory == null || loginHistory.isEmpty) {
                    return const ListTile(
                      title: Text('Không có lịch sử đăng nhập'),
                    );
                  }

                  // Đếm số lần đăng nhập (số ngày làm việc)
                  int daysWorked = 0;

                  // Kiểm tra xem mỗi phần tử trong loginHistory có phải là Timestamp không
                  for (var login in loginHistory) {
                    if (login is Timestamp) {
                      daysWorked++;
                    }
                  }

                  // Tính lương: Lương = Lương cơ bản * Hệ số * Số ngày làm việc
                  final total = salary * coefficient * daysWorked;

                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                      title: Text(username),
                      subtitle: Text(
                        "Đi làm: $daysWorked ngày • Hệ số: $coefficient × Lương cơ bản: ₫${_formatCurrency(salary)}",
                      ),
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
