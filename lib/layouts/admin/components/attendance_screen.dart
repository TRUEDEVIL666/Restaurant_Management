import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🕒 Chấm công & Lịch trực")),
      body: ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) => Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text("Nhân viên ${index + 1}"),
            subtitle: const Text("Ca trực: 08:00 - 16:00"),
            trailing: const Text("✅ Đã chấm"),
          ),
        ),
      ),
    );
  }
}
