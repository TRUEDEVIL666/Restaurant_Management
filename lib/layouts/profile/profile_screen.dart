import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _name = 'Người dùng';
  String _email = 'example@gmail.com';
  String _password = '123456'; // Mật khẩu mặc định (chỉ mô phỏng)

  bool _showPasswordFields = false; // Kiểm soát hiển thị trường mật khẩu

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Họ và Tên:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: _nameController, decoration: InputDecoration(hintText: _name)),
            SizedBox(height: 16),
            Text('Email:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: _emailController, decoration: InputDecoration(hintText: _email)),
            SizedBox(height: 24),

            // Nút mở rộng phần đổi mật khẩu
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showPasswordFields = !_showPasswordFields;
                  });
                },
                child: Text(_showPasswordFields ? 'Ẩn đổi mật khẩu' : 'Thay đổi mật khẩu'),
              ),
            ),

            if (_showPasswordFields) ...[
              SizedBox(height: 16),
              Text('Mật khẩu hiện tại:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(hintText: 'Nhập mật khẩu hiện tại'),
              ),
              SizedBox(height: 16),
              Text('Mật khẩu mới:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(hintText: 'Nhập mật khẩu mới'),
              ),
              SizedBox(height: 16),
              Text('Xác nhận mật khẩu mới:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(hintText: 'Nhập lại mật khẩu mới'),
              ),
              SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _changePassword,
                  child: Text('Cập nhật mật khẩu'),
                ),
              ),
              SizedBox(height: 24),
            ],

            Center(
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: Text('Lưu Thay Đổi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm cập nhật thông tin cá nhân
  void _saveProfile() {
    setState(() {
      _name = _nameController.text.isNotEmpty ? _nameController.text : _name;
      _email = _emailController.text.isNotEmpty ? _emailController.text : _email;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cập nhật thông tin thành công!')),
    );
  }

  // Hàm đổi mật khẩu
  void _changePassword() {
    String currentPassword = _currentPasswordController.text;
    String newPassword = _newPasswordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ thông tin!');
      return;
    }

    if (currentPassword != _password) {
      _showMessage('Mật khẩu hiện tại không đúng!');
      return;
    }

    if (newPassword.length < 6) {
      _showMessage('Mật khẩu mới phải có ít nhất 6 ký tự!');
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage('Mật khẩu mới không trùng khớp!');
      return;
    }

    // Cập nhật mật khẩu
    setState(() {
      _password = newPassword;
    });

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    _showMessage('Mật khẩu đã được cập nhật thành công!');
  }

  // Hiển thị thông báo
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
