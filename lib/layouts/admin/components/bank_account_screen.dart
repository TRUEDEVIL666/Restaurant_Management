import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {

  void _showBankDialog(BuildContext context, {
    String? docId,
    String initialName = '',
    String initialNumber = '',
    String initialCode = '',
    bool isActive = true,
  }) {
    final nameController = TextEditingController(text: initialName);
    final numberController = TextEditingController(text: initialNumber);
    final codeController = TextEditingController(text: initialCode);
    bool active = isActive;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(docId == null ? "➕ Thêm tài khoản" : "✏️ Sửa tài khoản"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Tên chủ TK"),
                    ),
                    TextField(
                      controller: numberController,
                      decoration: const InputDecoration(labelText: "Số tài khoản"),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: "Mã ngân hàng"),
                    ),
                    SwitchListTile(
                      value: active,
                      title: const Text("Đang hoạt động"),
                      onChanged: (val) => setStateDialog(() => active = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
                ElevatedButton(
                  onPressed: () async {
                    final data = {
                      'accountName': nameController.text,
                      'accountNumber': numberController.text,
                      'bankCode': codeController.text,
                      'isActive': active,
                    };

                    if (docId == null) {
                      await FirebaseFirestore.instance.collection('banks').add(data);
                    } else {
                      await FirebaseFirestore.instance.collection('banks').doc(docId).update(data);
                    }

                    Navigator.pop(context);
                  },
                  child: const Text("Lưu"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🗑️ Xóa tài khoản"),
        content: const Text("Bạn có chắc chắn muốn xóa tài khoản này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('banks').doc(docId).delete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🏦 Tài khoản ngân hàng")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBankDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('banks').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Chưa có tài khoản ngân hàng nào."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return Card(
                child: ListTile(
                  title: Text("${data['accountName']}"),
                  subtitle: Text("STK: ${data['accountNumber']} • Ngân hàng: ${data['bankCode']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        data['isActive'] == true ? Icons.check_circle : Icons.cancel,
                        color: data['isActive'] == true ? Colors.green : Colors.red,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showBankDialog(
                          context,
                          docId: docId,
                          initialName: data['accountName'],
                          initialNumber: data['accountNumber'],
                          initialCode: data['bankCode'],
                          isActive: data['isActive'] ?? true,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, docId),
                      ),
                    ],
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
