import 'package:flutter/material.dart';
import 'package:restaurant_management/controllers/user_controller.dart';
import 'package:restaurant_management/models/user.dart';

import '../../../constants.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController(),
      emailController = TextEditingController(),
      phoneController = TextEditingController(),
      passwordController = TextEditingController(),
      passwordConfirmController = TextEditingController();
  bool _obscureText = true, isSigningUp = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Full Name Field
          TextFormField(
            controller: nameController,
            validator: nameValidator.call,
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
            validator: signUpPasswordValidator.call,
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
            validator: signUpPasswordValidator.call,
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

          // Phone Field
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: phoneController,
                  validator: phoneNumberValidator.call,
                  onSaved: (value) {},
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: "Phone number"),
                ),
              ),
              // ElevatedButton(onPressed: () {}, child: Text("Send OTP")),
            ],
          ),
          const SizedBox(height: defaultPadding),

          // Text('Confirm OTP'),
          // const OtpForm(),
          // const SizedBox(height: defaultPadding),

          // Sign Up Button
          isSigningUp
              ? const CircularProgressIndicator()
              : ElevatedButton(
                onPressed: () async {
                  signUp();
                },
                child: const Text("Sign Up"),
              ),
        ],
      ),
    );
  }

  Future<void> signUp() async {
    setState(() {
      isSigningUp = true;
    });

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      createAccount();
    }

    setState(() {
      isSigningUp = false;
    });
  }

  Future<void> createAccount() async {
    UserController userController = UserController();
    String username = nameController.text,
        password = passwordController.text,
        confirmPassword = passwordConfirmController.text,
        phone = phoneController.text,
        email = emailController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));

      return;
    }

    // Checking if the username, phone, or email already exists
    String error = "already exists";
    var checks = {
      "username": await userController.checkUsername(username),
      "phone": await userController.checkPhone(phone),
      "email": await userController.checkEmail(email),
    };

    bool isValid = true;
    for (var entry in checks.entries) {
      if (!entry.value) {
        isValid = false;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${entry.key} $error")));
      }
    }

    if (isValid) {
      User user = User(
        username: username,
        password: password,
        email: email,
        phoneNumber: phone,
      );

      userController.addItem(user);
      Navigator.pop(context);
    }
  }
}
