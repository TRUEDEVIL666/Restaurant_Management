import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../controllers/user_controller.dart';
import '../../../models/user.dart';
import '../../findRestaurants/find_restaurants_screen.dart';
import '../forgot_password_screen.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController idController = TextEditingController(),
      passwordController = TextEditingController();
  bool _obscureText = true, loggingIn = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: idController,
            validator: emailOrPhoneValidator.call,
            onSaved: (value) {},
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: "Email Address or Phone Number",
            ),
          ),
          const SizedBox(height: defaultPadding),

          // Password Field
          TextFormField(
            controller: passwordController,
            obscureText: _obscureText,
            validator: signInPasswordValidator.call,
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

          // Forget Password
          GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                  ),
                ),
            child: Text(
              "Forget Password?",
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: defaultPadding),

          // Sign In Button
          loggingIn
              ? const CircularProgressIndicator()
              : ElevatedButton(
                onPressed: () async {
                  login();
                },
                child: const Text("Sign in"),
              ),
        ],
      ),
    );
  }

  Future<void> login() async {
    setState(() {
      loggingIn = true;
    });

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      checkAccount();
    }

    setState(() {
      loggingIn = false;
    });
  }

  Future<void> checkAccount() async {
    UserController userController = UserController();
    User? user = await userController.login(
      idController.text,
      passwordController.text,
    );

    if (user != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const FindRestaurantsScreen()),
        (_) => true,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid username or phone number or password"),
        ),
      );
    }
  }
}
