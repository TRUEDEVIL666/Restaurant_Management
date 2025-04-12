import 'package:flutter/material.dart';

class EmployeeScreen extends StatelessWidget {
  const EmployeeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("👥 Quản lý nhân viên")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Chuyển tới form thêm nhân viên
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(6, (index) {
          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text("Nhân viên ${index + 1}"),
              subtitle: const Text("Ca sáng - Phục vụ"),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {},
              ),
            ),
          );
        }),
      ),
    );
  }
}
