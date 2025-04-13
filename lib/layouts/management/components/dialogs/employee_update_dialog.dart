import 'package:flutter/material.dart';
import 'package:restaurant_management/models/user.dart';

// --- External Dialog Function ---
Future<User?> showAddOrUpdateEmployeeDialog({
  required BuildContext context,
  User? existingEmployee,
}) async {
  // --- Controllers ---
  final formKey = GlobalKey<FormState>(); // For validation
  final TextEditingController usernameController = TextEditingController(),
      emailController = TextEditingController(),
      phoneController = TextEditingController(),
      passwordController = TextEditingController();

  // --- Dialog State ---
  bool obscurePassword = true;

  // Pre-fill form if editing
  if (existingEmployee != null) {
    usernameController.text = existingEmployee.username;
    emailController.text = existingEmployee.email;
    phoneController.text = existingEmployee.phoneNumber;
  }

  User? resultData;

  await showDialog<void>(
    context: context,
    barrierDismissible: false, // User must tap button!
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        // Use StatefulBuilder for local state like dropdown, obscureText
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              existingEmployee == null ? 'Add Employee' : 'Edit Employee',
            ),
            content: SingleChildScrollView(
              child: Form(
                // Wrap content in a Form
                key: formKey,
                child: ListBody(
                  children: <Widget>[
                    // --- Username ---
                    TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username *',
                      ),
                      validator:
                          (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Username cannot be empty'
                                  : null,
                    ),
                    const SizedBox(height: 10),

                    // --- Email ---
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email *'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Email cannot be empty';
                        // Basic email format check
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                          return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // --- Phone Number ---
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                      ),
                      keyboardType: TextInputType.phone,
                      validator:
                          (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Phone number cannot be empty'
                                  : null,
                    ),
                    const SizedBox(height: 15),

                    // --- Password (Required on Add, Optional on Edit) ---
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText:
                            existingEmployee == null
                                ? 'Password *'
                                : 'New Password (Optional)',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed:
                              () => setDialogState(
                                () => obscurePassword = !obscurePassword,
                              ),
                        ),
                      ),
                      validator: (value) {
                        // Required only if adding a new employee
                        if (existingEmployee == null &&
                            (value == null || value.isEmpty)) {
                          return 'Password is required for new employee';
                        }
                        // Optional: Add password strength validation if needed
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              TextButton(
                child: Text(existingEmployee == null ? 'Add' : 'Update'),
                onPressed: () {
                  // --- Validate Form ---
                  if (formKey.currentState?.validate() ?? false) {
                    // --- Prepare Data ---
                    // IMPORTANT: Send plain text password if entered, controller handles hashing.
                    final plainPassword = passwordController.text.trim();

                    if (existingEmployee != null) {
                      resultData = existingEmployee;
                      resultData?.username = usernameController.text.trim();
                      resultData?.email = emailController.text.trim();
                      resultData?.phoneNumber = phoneController.text.trim();
                      resultData?.role = 'employee';
                      if (plainPassword.isNotEmpty) {
                        resultData?.password = plainPassword;
                      }
                    } else {
                      resultData = User(
                        username: usernameController.text.trim(),
                        email: emailController.text.trim(),
                        phoneNumber: phoneController.text.trim(),
                        role: 'employee',
                        password: plainPassword,
                      );
                    }

                    // --- Pop with Result ---
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );

  return resultData; // Return collected data or null
}
