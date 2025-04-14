import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmployeeScreen extends StatelessWidget {
  const EmployeeScreen({super.key});

  void showEditEmployeeDialog(
    BuildContext context, {
    required String username,
    required String role,
    required double salary,
    required double coefficient,
    required void Function(String, String, double, double) onSave,
  }) {
    final nameController = TextEditingController(text: username);
    String selectedRole = role;

    final salaryController = TextEditingController(text: salary.toString());
    final coefficientController = TextEditingController(
      text: coefficient.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("🛠️ Sửa thông tin nhân viên"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Tên"),
                ),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: "Vai trò"),
                  items: const [
                    DropdownMenuItem(
                      value: 'employee',
                      child: Text('Nhân viên'),
                    ),
                    DropdownMenuItem(value: 'manager', child: Text('Quản lý')),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Quản trị viên'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedRole = value;
                    }
                  },
                ),

                TextField(
                  controller: salaryController,
                  decoration: const InputDecoration(labelText: "Lương"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: coefficientController,
                  decoration: const InputDecoration(labelText: "Hệ số lương"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                onSave(
                  nameController.text,
                  selectedRole,
                  double.tryParse(salaryController.text) ?? 0,
                  double.tryParse(coefficientController.text) ?? 1,
                );
                Navigator.pop(context);
              },
              child: const Text("Lưu"),
            ),
          ],
        );
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("👥 Quản lý nhân viên")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Thêm nhân viên mới (tuỳ bạn)
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('Lỗi tải dữ liệu'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(data['username'] ?? 'Chưa có tên'),
                  subtitle: Text(data['role'] ?? 'Không rõ vai trò'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      showEditEmployeeDialog(
                        context,
                        username: data['username'] ?? '',
                        role: data['role'] ?? '',
                        salary: (data['salary'] ?? 0).toDouble(),
                        coefficient: (data['coefficient'] ?? 1).toDouble(),
                        onSave: (
                          newUsername,
                          newRole,
                          newSalary,
                          newCoefficient,
                        ) async {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(docId)
                              .update({
                                'username': newUsername,
                                'role': newRole,
                                'salary': newSalary,
                                'coefficient': newCoefficient,
                              });
                        },
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
