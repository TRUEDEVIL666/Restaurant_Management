import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/Waitstaff.dart';
import 'controllers/WaitstaffController.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    home: Login(),
    debugShowCheckedModeBanner: false,
  ));
}

class Login extends StatefulWidget {
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _usernameController = TextEditingController(),
      _passwordController = TextEditingController();

  bool _isLoading = false;
  String _message = '';

  Future<void> _handleLogin(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _message = 'Successfully logged in';
      FocusScope.of(context).requestFocus(FocusNode());
    });

    final name = _usernameController.text;
    final pass = _passwordController.text;

    try {
      Waitstaff? waitstaff = await WaitstaffFirestore.login(name, pass);

      if (waitstaff != null) {
        // If login is successful, you can navigate to another screen or show success
        setState(() {
          _isLoading = false;
        });
        // Navigator.pushReplacementNamed(context, '/home'); // Example: navigate to home screen
      } else {
        // If login failed, show an error message
        setState(() {
          _isLoading = false;
          _message = 'Incorrect Username or Password';
        });
      }

      if (_message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _message,
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(children: [
        Positioned.fill(
          child: Image.asset(
            'lib/assets/images/backgrounds/login_background.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "CHEZ LUMIÈRE",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                    height: 4,
                  ),
                ),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    floatingLabelStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    hintText: 'asd',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Color.fromRGBO(255, 255, 255, 0.5),
                    contentPadding: EdgeInsets.only(
                      left: 10,
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    floatingLabelStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    hintText: '123',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Color.fromRGBO(255, 255, 255, 0.5),
                    contentPadding: EdgeInsets.only(
                      left: 10,
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromRGBO(181, 35, 58, 1.0),
                        Color.fromRGBO(206, 42, 66, 1.0),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(80),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                          ),
                          onPressed: () {
                            _handleLogin(context);
                          },
                          child: Text(
                            "SIGN IN",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.black,
                        thickness: 1,
                      ),
                    ),
                    SizedBox(
                      width: 4,
                    ),
                    Text('OR'),
                    SizedBox(
                      width: 4,
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.black,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Color.fromRGBO(41, 182, 246, 1),
                    textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    "REGISTER",
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    ));
  }
}
