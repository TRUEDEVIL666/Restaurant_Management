import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_management/controllers/dish_controller.dart';

import '../firebase_options.dart';
import '../models/dish.dart';
import '../services/firebase_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    home: Food_Menu(),
    debugShowCheckedModeBanner: false,
  ));
}

class Food_Menu extends StatefulWidget {
  @override
  State<Food_Menu> createState() => _Food_MenuState();
}

class _Food_MenuState extends State<Food_Menu> {
  final DishController _dishController = DishController();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  List<Dish> menu = [];
  TextStyle defaultStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
  );

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  void _loadMenu() async {
    List<Dish> tempMenu = await _dishController.getMenu();
    setState(() {
      menu = tempMenu;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'lib/assets/images/backgrounds/food_menu_background.jpg',
                fit: BoxFit.fill,
              ),
            ),
            Transform.scale(
              scale: 1.5,
              child: Center(
                child: Container(
                  width: 300,
                  height: 600,
                  child: menu.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: menu.length,
                          itemBuilder: (context, index) {
                            Dish dish = menu[index];
                            return FutureBuilder<String>(
                              future: _storageService.getImage(dish.imgPath),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return ListTile(
                                    title: Text(dish.dishName),
                                    subtitle: Text('Loading image...'),
                                    leading:
                                        CircularProgressIndicator(),
                                  );
                                }
              
                                if (snapshot.hasError) {
                                  return ListTile(
                                    title: Text(dish.dishName),
                                    subtitle: Text('Error loading image'),
                                    leading: Icon(Icons.error),
                                  );
                                }
              
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(snapshot.data!),
                                  ),
                                  title: Text(
                                    dish.dishName,
                                    style: defaultStyle,
                                  ),
                                  subtitle: Text(
                                    '\$${dish.price}',
                                    style: defaultStyle,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
