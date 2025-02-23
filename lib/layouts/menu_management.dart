import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_management/controllers/dish_controller.dart';
import 'package:restaurant_management/models/dish.dart';
import 'package:restaurant_management/services/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MaterialApp(
      home: MenuManagementScreen(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class MenuManagementScreen extends StatefulWidget {
  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final DishController _dishController = DishController();
  File? _file;
  bool _isImage = false;

  Future<void> _pickImageFromGallery() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      String? extension = file.extension?.toLowerCase();

      _isImage =
          extension != null && ['png', 'jpg', 'jpeg'].contains(extension);

      if (_isImage) {
        setState(() {
          _file = File(file.path!);
        });
      } else {
        print("File chosen isn't an image");
      }
    }
  }

  void _showInputDialog(BuildContext context) {
    TextEditingController dishName = TextEditingController(),
        dishIngredients = TextEditingController(),
        dishCategory = TextEditingController(),
        dishSubcategories = TextEditingController(),
        dishPrice = TextEditingController(),
        dishDiscount = TextEditingController();

    final List<TextEditingController> controllerList = [
      dishName,
      dishIngredients,
      dishCategory,
      dishSubcategories,
      dishPrice,
      dishDiscount,
    ];

    bool isFilled = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Creating a dish'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: dishName,
                      decoration: InputDecoration(labelText: 'Dish name'),
                    ),
                    TextField(
                      controller: dishIngredients,
                      decoration: InputDecoration(labelText: 'Ingredients'),
                    ),
                    TextField(
                      controller: dishCategory,
                      decoration: InputDecoration(labelText: 'Category'),
                    ),
                    TextField(
                      controller: dishSubcategories,
                      decoration: InputDecoration(labelText: 'Sub-categories'),
                    ),
                    TextField(
                      controller: dishPrice,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Price'),
                    ),
                    TextField(
                      controller: dishDiscount,
                      decoration: InputDecoration(labelText: 'Discount'),
                    ),
                    MaterialButton(
                      onPressed: () async {
                        await _pickImageFromGallery();
                        setState(() {});
                      },
                      child: Text('Upload image'),
                    ),
                    _file != null
                        ? Image.file(
                          _file!,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        )
                        : Text('No image selected'),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    setState(() {
                      _file = null;
                    });
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Submit'),
                  onPressed: () async {
                    controllerList.forEach((controller) {
                      if (controller.text.isEmpty) {
                        isFilled = false;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Center(child: Text('Missing input value')),
                          ),
                        );
                      }
                    });

                    if (isFilled &&
                        await _dishController.uploadDish(
                          _file,
                          Dish(
                            dishName: dishName.text,
                            imgPath: 'menu/${dishName.text}.png',
                            ingredients: [],
                            category: dishCategory.text,
                            subCategories: [],
                            price: double.parse(dishPrice.text),
                            discount: double.parse(dishDiscount.text),
                          ),
                        )) {
                      _file = null;
                      Navigator.of(context).pop();
                    } else {
                      isFilled = true;
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
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
                'lib/assets/images/backgrounds/monkey.jpg',
                fit: BoxFit.fill,
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height / 4,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => {_showInputDialog(context)},
                          child: Text('CREATE DISH'),
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width / 40),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => {},
                          child: Text('UPDATE DISH'),
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width / 40),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => {},
                          child: Text('DELETE DISH'),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => {},
                          child: Text('CREATE USER'),
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width / 40),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => {},
                          child: Text('UPDATE USER'),
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width / 40),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => {},
                          child: Text('DELETE USER'),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => {},
                          child: Text('CREATE SOMETHING'),
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width / 40),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => {},
                          child: Text('UPDATE SOMETHING'),
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width / 40),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => {},
                          child: Text('DELETE SOMETHING'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
