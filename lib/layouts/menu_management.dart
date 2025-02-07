import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_management/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    home: Menu_Management_Screen(),
    debugShowCheckedModeBanner: false,
  ));
}

class Menu_Management_Screen extends StatefulWidget {
  @override
  State<Menu_Management_Screen> createState() => _Menu_Management_ScreenState();
}

class _Menu_Management_ScreenState extends State<Menu_Management_Screen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/backgrounds/monkey.jpg',
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 4,
            left: 0,
            right: 0,
            child: Table(
              children: [
                TableRow(
                  children: [
                    ElevatedButton(
                      onPressed: () => {},
                      child: Text('CREATE DISH'),
                    ),
                    ElevatedButton(
                      onPressed: () => {},
                      child: Text('UPDATE DISH'),
                    ),
                    ElevatedButton(
                      onPressed: () => {},
                      child: Text('DELETE DISH'),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    ElevatedButton(
                      onPressed: () => {},
                      child: Text('CREATE USER'),
                    ),
                    ElevatedButton(
                      onPressed: () => {},
                      child: Text('UPDATE USER'),
                    ),
                    ElevatedButton(
                      onPressed: () => {},
                      child: Text('DELETE USER'),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    ElevatedButton(
                      onPressed: () => {},
                      child: Text('CREATE SOMETHING'),
                    ),
                    ElevatedButton(
                      onPressed: () => {},
                      child: Text('UPDATE SOMETHING'),
                    ),
                    ElevatedButton(
                      onPressed: () => {},
                      child: Text('DELETE SOMETHING'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
