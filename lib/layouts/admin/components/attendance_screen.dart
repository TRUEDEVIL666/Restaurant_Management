import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  void _showAttendanceDialog(
    BuildContext context,
    Map<String, dynamic> userData,
    String userId,
  ) {
    final username = userData['username'] ?? '';
    final coefficient = userData['coefficient'] ?? 1;

    DateTime? checkIn;
    DateTime? checkOut;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("📝 Chấm công cho $username"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: 8, minute: 0),
                  );
                  if (picked != null) {
                    final now = DateTime.now();
                    checkIn = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      picked.hour,
                      picked.minute,
                    );
                  }
                },
                child: const Text("🕗 Chọn giờ vào"),
              ),
              const SizedBox(height: 12), // khoảng cách giữa 2 nút
              ElevatedButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: 16, minute: 0),
                  );
                  if (picked != null) {
                    final now = DateTime.now();
                    checkOut = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      picked.hour,
                      picked.minute,
                    );
                  }
                },
                child: const Text("🕕 Chọn giờ ra"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (checkIn != null && checkOut != null) {
                  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

                  await FirebaseFirestore.instance
                      .collection('attendance')
                      .add({
                        'userId': userId,
                        'username': username,
                        'checkIn': Timestamp.fromDate(checkIn!),
                        'checkOut': Timestamp.fromDate(checkOut!),
                        'date': today,
                        'coefficient': coefficient,
                      });

                  Navigator.pop(context);
                }
              },
              child: const Text("Lưu"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🕒 Chấm công & Lịch trực")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final username = data['username'] ?? 'Không tên';
              final role = data['role'] ?? 'unknown';
              final loginHistory = data['loginHistory'] as List<dynamic>?;

              String lastLogin = 'Không có';
              if (loginHistory != null && loginHistory.isNotEmpty) {
                final timestamp = loginHistory.last;
                final dateTime = (timestamp as Timestamp).toDate();
                lastLogin = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
              }

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(username),
                  subtitle: Text(
                    "Vai trò: $role\nLần đăng nhập gần nhất: $lastLogin",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        loginHistory != null && loginHistory.isNotEmpty
                            ? Icons.check_circle
                            : Icons.cancel,
                        color:
                            loginHistory != null && loginHistory.isNotEmpty
                                ? Colors.green
                                : Colors.red,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_calendar),
                        tooltip: "Chấm công giùm",
                        onPressed:
                            () => _showAttendanceDialog(
                              context,
                              data,
                              docs[index].id,
                            ),
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
