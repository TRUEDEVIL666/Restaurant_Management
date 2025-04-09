import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_management/firebase_options.dart';
import 'package:restaurant_management/layouts/management/employee_management_screen.dart';
import 'package:restaurant_management/layouts/management/menu_management_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure that binding is initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant Manager',
      theme: ThemeData(
        primarySwatch:
            Colors.deepOrange, // Or another color fitting a restaurant theme
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false, // Remove debug banner
      home:
          const ManagerDashboardScreen(), // Start the app with the manager screen
    );
  }
}

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Manager Dashboard'),
        // Optional: Add actions like logout
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.logout),
        //     onPressed: () {
        //       // Handle logout logic
        //     },
        //   ),
        // ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          // Center the column content vertically
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildDashboardButton(
                context: context,
                icon: Icons.restaurant_menu,
                label: 'Manage Food Menu',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MenuManagementScreen(),
                    ),
                  );
                  print('Navigating to Menu Management...');
                },
              ),
              const SizedBox(height: 24), // Spacing between buttons
              _buildDashboardButton(
                context: context,
                icon: Icons.people,
                label: 'Manage Employees',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmployeeManagementScreen(),
                    ),
                  );
                  print('Navigating to Employee Management...');
                },
              ),
              // Add more options here if needed (e.g., View Reports, Settings)
              // const SizedBox(height: 24),
              // _buildDashboardButton(...)
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to create styled buttons consistently
  Widget _buildDashboardButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        textStyle: const TextStyle(fontSize: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Softer corners
        ),
      ),
    );
  }
}
