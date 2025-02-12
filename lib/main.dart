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
    home: FoodMenuScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class FoodMenuScreen extends StatefulWidget {
  @override
  State<FoodMenuScreen> createState() => _FoodMenuScreenState();
}

class _FoodMenuScreenState extends State<FoodMenuScreen> {
  final DishController _dishController = DishController();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  int _selectedIndex = 1;
  List<Dish> menu = [];

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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
            Center(
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
                                ConnectionState.waiting || snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: 24.0,
                                ),
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(14),
                                          topRight: Radius.circular(14),
                                        ),
                                        child: Image.asset(
                                          'lib/assets/images/backgrounds/default_food_image.png',
                                          width: double.infinity,
                                          height: 150,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 20,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              dish.dishName,
                                              style: TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Spacer(),
                                            Text(
                                              '\$ ${dish.price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.only(
                                top: 24.0,
                              ),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(14),
                                        topRight: Radius.circular(14),
                                      ),
                                      child: Image(
                                        width: double.infinity,
                                        height: 150,
                                        image: NetworkImage(snapshot.data!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 20,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            dish.dishName,
                                            style: TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Spacer(),
                                          Text(
                                            '\$ ${dish.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.food_bank),
              label: 'Main dish',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_food_beverage),
              label: 'Drinks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.reorder),
              label: 'Confirm Order',
            ),
          ],
        ),
      ),
    );
  }
}
