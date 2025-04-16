import 'package:flutter/material.dart';
import 'package:restaurant_management/models/menu.dart';
// Import your Menu model definition

// Renamed to be public, requires context, returns Future<Menu?>
Future<FoodMenu?> showAddOrUpdateMenuDialog({
  required BuildContext context,
  FoodMenu? existingMenu,
}) async {
  // --- Controllers ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController foodItemNameController = TextEditingController();
  final TextEditingController foodItemQuantityController =
      TextEditingController();

  // --- Dialog State ---
  bool isCombo = existingMenu?.isCombo ?? false;
  List<Map<String, dynamic>> currentFoodList =
      existingMenu?.foodList != null
          ? List<Map<String, dynamic>>.from(existingMenu!.foodList!)
          : [];
  const String foodItemNameKey =
      'foodName'; // Use the keys defined in your state file
  const String foodItemQuantityKey =
      'quantity'; // Use the keys defined in your state file

  if (existingMenu != null) {
    nameController.text =
        existingMenu.id; // Assuming ID is used as name for now
    priceController.text = existingMenu.price.toString();
  }

  // Variable to hold the result when 'Save' is pressed
  FoodMenu? resultMenu;

  await showDialog<void>(
    context: context,
    barrierDismissible: false, // User must tap button!
    builder: (BuildContext dialogContext) {
      // Use a different context name
      // Use StatefulBuilder for local dialog state updates
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              existingMenu == null ? 'Add Menu Item' : 'Edit Menu Item',
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  // --- Basic Item Details ---
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item ID / Name',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      suffixText: ' đ',
                    ),
                  ),
                  const SizedBox(height: 15),
                  // --- Combo Checkbox ---
                  Row(
                    children: [
                      const Text('Is Combo Meal?'),
                      const Spacer(),
                      Checkbox(
                        value: isCombo,
                        onChanged:
                            (bool? value) =>
                                setDialogState(() => isCombo = value ?? false),
                      ),
                    ],
                  ),
                  // --- Conditional Food List Editor ---
                  if (isCombo) ...[
                    const Divider(height: 20),
                    Text(
                      'Combo Items',
                      style: Theme.of(dialogContext).textTheme.titleMedium,
                    ), // Use dialogContext if needed for theme
                    const SizedBox(height: 10),
                    // Add Item Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: foodItemNameController,
                            decoration: const InputDecoration(
                              labelText: 'Item Name',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: foodItemQuantityController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              labelText: 'Qty',
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.green,
                          ),
                          tooltip: 'Add Item to Combo',
                          padding: const EdgeInsets.only(bottom: 0, left: 4),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final String newItemName =
                                foodItemNameController.text.trim();
                            final int? newItemQty = int.tryParse(
                              foodItemQuantityController.text.trim(),
                            );
                            if (newItemName.isNotEmpty &&
                                newItemQty != null &&
                                newItemQty > 0) {
                              setDialogState(() {
                                currentFoodList.add({
                                  foodItemNameKey: newItemName,
                                  foodItemQuantityKey: newItemQty,
                                });
                                foodItemNameController.clear();
                                foodItemQuantityController.clear();
                              });
                            } else {
                              /* Optionally provide local visual feedback, but NO snackbar */
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Display Items List
                    if (currentFoodList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No items added yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      Column(
                        children:
                            currentFoodList.map((item) {
                              final index = currentFoodList.indexOf(item);
                              final itemName =
                                  item[foodItemNameKey]?.toString() ??
                                  'No Name';
                              final itemQty =
                                  (item[foodItemQuantityKey] is int)
                                      ? item[foodItemQuantityKey] as int
                                      : 1;
                              return ListTile(
                                title: Text('$itemName  x $itemQty'),
                                dense: true,
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red.shade300,
                                  ),
                                  tooltip: 'Remove Item',
                                  onPressed:
                                      () => setDialogState(
                                        () => currentFoodList.removeAt(index),
                                      ),
                                ),
                                contentPadding: EdgeInsets.zero,
                              );
                            }).toList(),
                      ),
                  ], // End isCombo block
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ), // Pop without result
              TextButton(
                child: Text(existingMenu == null ? 'Add' : 'Update'),
                // --- NO ASYNC HERE ---
                onPressed: () {
                  // --- Validation ---
                  final String nameOrId = nameController.text.trim();
                  final double? price = double.tryParse(priceController.text);
                  if (nameOrId.isEmpty) {
                    /* NO SNACKBAR */
                    return;
                  }
                  if (price == null || price < 0) {
                    /* NO SNACKBAR */
                    return;
                  }

                  // --- Prepare Result ---
                  resultMenu = FoodMenu(
                    id: nameOrId,
                    imgPath: '',
                    isCombo: isCombo,
                    price: price,
                    foodList: isCombo ? currentFoodList : null,
                  );

                  // --- Pop with Result ---
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          );
        },
      );
    },
  );

  // Return the Menu object (or null if cancelled)
  return resultMenu;
}
