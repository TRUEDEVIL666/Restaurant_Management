import 'package:flutter/material.dart';
import 'package:restaurant_management/controllers/user_controller.dart';
import 'package:restaurant_management/models/user.dart';

import '../../../constants.dart';
import '../../phoneLogin/phone_login_screen.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController(),
      emailController = TextEditingController(),
          // TODO: Implement and assign the phone number controller
          phoneController =
          TextEditingController(),
      passwordController = TextEditingController(),
      passwordConfirmController = TextEditingController();
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Full Name Field
          TextFormField(
            controller: nameController,
            validator: requiredValidator.call,
            onSaved: (value) {},
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: "Full Name"),
          ),
          const SizedBox(height: defaultPadding),

          // Email Field
          TextFormField(
            controller: emailController,
            validator: emailValidator.call,
            onSaved: (value) {},
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: "Email Address"),
          ),
          const SizedBox(height: defaultPadding),

          // Password Field
          TextFormField(
            controller: passwordController,
            obscureText: _obscureText,
            validator: passwordValidator.call,
            textInputAction: TextInputAction.next,
            onChanged: (value) {},
            onSaved: (value) {},
            decoration: InputDecoration(
              hintText: "Password",
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                child:
                    _obscureText
                        ? const Icon(Icons.visibility_off, color: bodyTextColor)
                        : const Icon(Icons.visibility, color: bodyTextColor),
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),

          // Confirm Password Field
          TextFormField(
            controller: passwordConfirmController,
            obscureText: _obscureText,
            decoration: InputDecoration(
              hintText: "Confirm Password",
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                child:
                    _obscureText
                        ? const Icon(Icons.visibility_off, color: bodyTextColor)
                        : const Icon(Icons.visibility, color: bodyTextColor),
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          // Sign Up Button
          ElevatedButton(
            onPressed: () async {
              if (await createUser()) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
                );
              }
            },
            child: const Text("Sign Up"),
          ),
        ],
      ),
    );
  }

  Future<bool> createUser() async {
    UserController userController = UserController();
    String username = nameController.text,
        password = passwordController.text,
        confirmPassword = passwordConfirmController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));

      return false;
    }

    if (await userController.checkUsername(username)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Username already exists")));

      return false;
    }

    User user = User(
      username: username,
      password: passwordController.text,
      email: emailController.text,

      // TODO: Replace empty string here with phone number from phone login
      phoneNumber: "",
    );

    userController.addItem(user);

    return true;
  }
}
