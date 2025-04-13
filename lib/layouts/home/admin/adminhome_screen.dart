import 'package:flutter/material.dart';
import 'package:restaurant_management/layouts/home/admin/attendance_screen.dart';
import 'package:restaurant_management/layouts/home/admin/bank_account_screen.dart';
import 'package:restaurant_management/layouts/home/admin/manage_employee_screen.dart';
import 'package:restaurant_management/layouts/home/admin/payroll_screen.dart';
import 'package:restaurant_management/layouts/home/admin/revenue_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_AdminFeature> features = [
      _AdminFeature(
        title: '📈 Tổng thu ',
        subtitle: 'Xem báo cáo tổng thu',
        icon: Icons.show_chart,
        color: Colors.deepPurpleAccent,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RevenueScreen()),
            ),
      ),
      _AdminFeature(
        title: '👥 Quản lý nhân viên',
        subtitle: 'Thêm / sửa thông tin nhân viên',
        icon: Icons.people_outline,
        color: Colors.teal,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EmployeeScreen()),
            ),
      ),
      _AdminFeature(
        title: '🕒 Chấm công & Lịch trực',
        subtitle: 'Theo dõi thời gian làm việc',
        icon: Icons.access_time,
        color: Colors.indigo,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AttendanceScreen()),
            ),
      ),
      _AdminFeature(
        title: '💸 Tính lương',
        subtitle: 'Lập bảng lương tự động',
        icon: Icons.monetization_on_outlined,
        color: Colors.orange,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PayrollScreen()),
            ),
      ),
      _AdminFeature(
        title: '🏦 Quản lý tài khoản ngân hàng',
        subtitle: 'Quản lý tài khoản ',
        icon: Icons.account_balance_outlined,
        color: Colors.blueAccent,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BankAccountScreen(),
              ),
            ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trang Admin"),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Xin chào, Cửa hàng trưởng 👋",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Dưới đây là các chức năng quản lý của bạn.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ...features.map((feature) => _buildFeatureTile(feature)).toList(),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(_AdminFeature feature) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: feature.color.withOpacity(0.2),
          child: Icon(feature.icon, color: feature.color),
        ),
        title: Text(
          feature.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(feature.subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded),
        onTap: feature.onTap,
      ),
    );
  }
}

class _AdminFeature {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _AdminFeature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
