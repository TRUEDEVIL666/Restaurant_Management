import 'package:flutter/material.dart';
import 'package:restaurant_management/controllers/menu_controller.dart';
import 'package:restaurant_management/layouts/management/components/menu_update_dialog.dart';
import 'package:restaurant_management/models/menu.dart';
// Import the new dialog file

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  bool _isLoading = false;
  List<Menu> _menuItems = [];
  String? _errorMessage;
  final FoodMenuController menuController = FoodMenuController();

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
  }

  Future<void> _fetchMenuItems() async {
    // ... (fetch logic remains the same)
    setState(() => _isLoading = true);
    _errorMessage = null;
    try {
      final List<Menu> fetchedItems = await menuController.getAll();
      if (mounted) {
        setState(() {
          _menuItems = fetchedItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error fetching menu: $e";
          _isLoading = false;
        });
        _showSnackBar(_errorMessage!, isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    // ... (snackbar logic remains the same)
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError
                ? Colors.red
                : Theme.of(context).snackBarTheme.backgroundColor,
      ),
    );
  }

  Future<void> _deleteMenu(String menuId) async {
    // ... (delete logic remains the same)
    bool confirmDelete =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Delete'),
              content: Text('Are you sure you want to delete "$menuId"?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
    if (confirmDelete) {
      setState(() => _isLoading = true);
      bool success = false;
      try {
        await menuController.deleteItem(menuId);
        success = true;
        if (success) {
          _showSnackBar('Menu item deleted successfully.');
          await _fetchMenuItems();
        }
      } catch (e) {
        _showSnackBar('Error deleting item: $e', isError: true);
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        /* ... AppBar ... */
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchMenuItems,
          ),
        ],
      ),
      body: Stack(
        /* ... Body with _buildMenuList and Loading Overlay ... */
        children: [
          _buildMenuList(),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Menu Item',
        // --- MODIFIED onPressed ---
        onPressed:
            _isLoading
                ? null
                : () async {
                  // Call the external dialog function
                  final Menu? newMenuItem = await showAddOrUpdateMenuDialog(
                    context: context,
                  );

                  // Handle the result AFTER dialog closes
                  if (newMenuItem != null) {
                    setState(() => _isLoading = true);
                    bool success = false;
                    try {
                      success = await menuController.addItemWithId(newMenuItem);

                      if (success) {
                        _showSnackBar('Menu item added successfully.');
                        await _fetchMenuItems(); // Refresh list
                      } else {
                        _showSnackBar('Failed to add item.', isError: true);
                      }
                    } catch (e) {
                      _showSnackBar('Error adding item: $e', isError: true);
                    } finally {
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    }
                  }
                },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMenuList() {
    // ... (list building logic remains mostly the same) ...
    return RefreshIndicator(
      onRefresh: _fetchMenuItems,
      child: ListView.builder(
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final menuItem = _menuItems[index];
          final bool isAComboWithItems = /* ... */
              menuItem.isCombo &&
              menuItem.foodList != null &&
              menuItem.foodList!.isNotEmpty;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    /* ... ListTile ... */
                    title: Text(menuItem.id), // Using ID for now
                    subtitle: Text(
                      /* ... Subtitle ... */
                      'Price: \$${menuItem.price.toStringAsFixed(2)} - ${menuItem.isCombo ? "Combo" : "Single Item"}',
                    ),
                    trailing: Row(
                      /* ... Trailing icons ... */
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Edit Item',
                          // --- MODIFIED onPressed ---
                          onPressed:
                              _isLoading
                                  ? null
                                  : () async {
                                    // Call the external dialog function
                                    final Menu? updatedMenuItem =
                                        await showAddOrUpdateMenuDialog(
                                          context: context,
                                          existingMenu: menuItem,
                                        );

                                    if (updatedMenuItem != null) {
                                      setState(() => _isLoading = true);
                                      bool success = false;
                                      try {
                                        success = await menuController
                                            .updateItem(updatedMenuItem);

                                        if (success) {
                                          _showSnackBar(
                                            'Menu item updated successfully.',
                                          );
                                          await _fetchMenuItems();
                                        } else {
                                          _showSnackBar(
                                            'Failed to update item.',
                                            isError: true,
                                          );
                                        }
                                      } catch (e) {
                                        _showSnackBar(
                                          'Error updating item: $e',
                                          isError: true,
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isLoading = false);
                                        }
                                      }
                                    }
                                  },
                        ),
                        IconButton(
                          /* ... Delete button ... */
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete Item',
                          onPressed:
                              _isLoading
                                  ? null
                                  : () => _deleteMenu(menuItem.id),
                        ),
                      ],
                    ),
                  ),
                  if (isAComboWithItems)
                    Padding(
                      padding: const EdgeInsets.only(left: 18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Optional: Add a small divider or heading
                          // Divider(height: 1, thickness: 1),
                          // SizedBox(height: 6),
                          Text(
                            'Includes:',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 4),
                          // Create a Text widget for each item in foodList
                          ...menuItem.foodList!.map((foodItemMap) {
                            final String foodName = 'foodName',
                                quantity = 'quantity';
                            final String foodInfo =
                                "${foodItemMap[foodName]}: ${foodItemMap[quantity]}";

                            return Text(
                              '• $foodInfo',
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          }),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
