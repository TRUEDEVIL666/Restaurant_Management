import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  User? _user;
  String _userEmail = "Đang tải...";
  String _username = "Đang tải...";
  String _phoneNumber = "Đang tải...";
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();  // Gọi hàm load dữ liệu khi trang được khởi tạo
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? userId = prefs.getString('userId');  // Lấy ID người dùng từ SharedPreferences

    if (userId != null) {
      print("User ID: $userId");

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Lưu dữ liệu người dùng vào biến
        setState(() {
          _username = userData['username'] ?? 'Unknown';
          _userEmail = userData['email'] ?? 'No email';
          _phoneNumber = userData['phoneNumber'] ?? 'No phone';
        });

        print("User loaded: $_username, Email: $_userEmail, Phone: $_phoneNumber");
      } else {
        print("User ID not found in Firestore");
      }
    } else {
      print("No user ID found in SharedPreferences");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tên người dùng:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(_username, style: TextStyle(fontSize: 16, color: Colors.blue)),
            SizedBox(height: 16),
            
            Text('Email:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(_userEmail, style: TextStyle(fontSize: 16, color: Colors.blue)),
            SizedBox(height: 16),
            
            Text('Số điện thoại:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(_phoneNumber, style: TextStyle(fontSize: 16, color: Colors.blue)),
            SizedBox(height: 24),
            
            Text('Mật khẩu hiện tại:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrentPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            Text('Mật khẩu mới:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            Text('Xác nhận mật khẩu mới:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _changePassword,
                child: Text('Cập nhật mật khẩu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changePassword() async {
    if (_user == null) return;
    String currentPassword = _currentPasswordController.text;
    String newPassword = _newPasswordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      _showMessage('Mật khẩu mới không trùng khớp!');
      return;
    }

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: _userEmail,
        password: currentPassword,
      );

      await _user!.reauthenticateWithCredential(credential);
      await _user!.updatePassword(newPassword);
      _showMessage('Mật khẩu đã được cập nhật thành công!');
    } catch (e) {
      _showMessage('Đổi mật khẩu thất bại! Kiểm tra lại thông tin.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
