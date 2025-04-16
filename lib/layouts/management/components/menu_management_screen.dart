// lib/layouts/management/menu_management_screen.dart

import 'dart:async'; // Not strictly necessary for this version, but good practice

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_management/controllers/menu_controller.dart';
// Assuming the dialog is correctly placed and imported
import 'package:restaurant_management/layouts/management/components/dialogs/menu_update_dialog.dart';
import 'package:restaurant_management/models/menu.dart'; // Ensure FoodMenu model is correctly imported
import 'package:shimmer/shimmer.dart'; // For loading placeholders

// --- FoodMenu Model (Ensure this matches your actual model file) ---
// This is included here for completeness, but should be in its own file (e.g., lib/models/menu.dart)
/*
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodMenu {
  final String id;
  bool isCombo;
  double price;
  List<Map<String, dynamic>>? foodList;
  String? imgPath;
  bool isActive; // <-- Make sure this field exists

  FoodMenu({
    required this.id,
    required this.isCombo,
    required this.price,
    this.foodList,
    this.imgPath,
    bool? isActive,
  }) : isActive = isActive ?? true; // Default to true

  static dynamic _getDataValue(DocumentSnapshot doc, String key) {
     final data = doc.data() as Map<String, dynamic>?;
     try { return data?[key]; } catch (e) { return null; }
   }

  factory FoodMenu.toObject(DocumentSnapshot doc) {
    double parsedPrice = 0.0;
    final priceData = _getDataValue(doc, 'price');
    if (priceData is num) { parsedPrice = priceData.toDouble(); }
    final isActiveData = _getDataValue(doc, 'isActive');
    final bool parsedIsActive = (isActiveData is bool) ? isActiveData : true; // Default true

    return FoodMenu(
      id: doc.id,
      isCombo: _getDataValue(doc, 'isCombo') ?? false,
      price: parsedPrice,
      foodList: _getDataValue(doc, 'foodList') != null
          ? List<Map<String, dynamic>>.from(_getDataValue(doc, 'foodList')) : null,
      imgPath: _getDataValue(doc, 'imgPath'),
      isActive: parsedIsActive,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isCombo': isCombo,
      'price': price,
      'foodList': foodList,
      'imgPath': imgPath,
      'isActive': isActive,
    };
  }

   Map<String, dynamic> toFirestoreForStatusUpdate() {
      return { 'isActive': isActive };
   }
}
*/
// --- End FoodMenu Model ---

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  bool _isLoading = false; // General loading state for fetching
  bool _isTogglingStatus = false; // Specific loading state for status toggle
  List<FoodMenu> _menuItems = [];
  String? _errorMessage;
  final FoodMenuController menuController = FoodMenuController();

  // --- Style Constants ---
  static const double _cardPadding = 16.0;
  static const double _cardMargin = 10.0;
  static const double _borderRadius = 12.0;

  @override
  void initState() {
    super.initState();
    _fetchMenuItems(isInitialLoad: true); // Indicate initial load
  }

  // --- Fetch Menu Items ---
  Future<void> _fetchMenuItems({bool isInitialLoad = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true; // Use general loading flag for fetching
      _errorMessage = null;
    });

    try {
      final List<FoodMenu> fetchedItems = await menuController.getAll();
      if (!mounted) return;

      // Sort items: Active first, then by ID/name
      fetchedItems.sort((a, b) {
        if (a.isActive == b.isActive)
          return a.id.compareTo(b.id); // Or compare a name field if you add one
        return a.isActive ? -1 : 1; // Active items come first
      });

      setState(() {
        _menuItems = fetchedItems;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final errorMsg = "Failed to fetch menu: $e";
      setState(() {
        _errorMessage = errorMsg;
        _menuItems = [];
        _isLoading = false;
      });
      _showSnackBar(errorMsg, isError: true);
    }
  }

  // --- Show Snackbar ---
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError ? Colors.redAccent.shade700 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(10.0),
      ),
    );
  }

  // --- Delete Menu Item ---
  Future<void> _deleteMenu(FoodMenu menuItem) async {
    if (_isLoading || _isTogglingStatus) return; // Prevent action while loading

    bool confirmDelete =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
              title: const Text('Confirm Deletion'),
              content: Text(
                'Are you sure you want to delete "${menuItem.id}"?',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  child: const Text('Delete'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmDelete && mounted) {
      setState(() => _isLoading = true); // Use general loading for delete
      try {
        bool success = await menuController.deleteItem(menuItem.id);
        if (!mounted) return;
        if (success) {
          _showSnackBar('"${menuItem.id}" deleted successfully.');
          // Optimistic UI update
          setState(
            () => _menuItems.removeWhere((item) => item.id == menuItem.id),
          );
        } else {
          _showSnackBar('Failed to delete "${menuItem.id}".', isError: true);
          _fetchMenuItems(); // Refresh if backend delete failed but we thought it would work
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Error deleting item: $e', isError: true);
          _fetchMenuItems(); // Refresh fully on error
        }
      } finally {
        if (mounted)
          setState(() => _isLoading = false); // Reset general loading
      }
    }
  }

  // --- Handle Add or Update via Dialog ---
  Future<void> _handleAddOrUpdate({FoodMenu? existingMenu}) async {
    if (_isLoading || _isTogglingStatus) return; // Prevent action while loading

    final FoodMenu? resultMenuItem = await showAddOrUpdateMenuDialog(
      context: context,
      existingMenu: existingMenu, // Pass existing data for editing
    );

    if (resultMenuItem != null && mounted) {
      setState(() => _isLoading = true); // Use general loading
      bool success = false;
      String action = existingMenu == null ? "add" : "update";
      String actionPast = existingMenu == null ? "added" : "updated";

      try {
        if (existingMenu == null) {
          success = await menuController.addItemWithId(resultMenuItem);
        } else {
          // Ensure resultMenuItem includes the original ID for update
          // The dialog should handle passing the ID back correctly
          success = await menuController.updateItem(resultMenuItem);
        }

        if (!mounted) return;
        if (success) {
          _showSnackBar('Menu item ${actionPast} successfully.');
          await _fetchMenuItems(); // Refresh list to show changes/new item
        } else {
          _showSnackBar('Failed to $action item.', isError: true);
        }
      } catch (e) {
        if (mounted)
          _showSnackBar('Error ${action}ing item: $e', isError: true);
      } finally {
        if (mounted)
          setState(() => _isLoading = false); // Reset general loading
      }
    }
  }

  // --- Toggle Active Status ---
  Future<void> _toggleActiveStatus(FoodMenu menuItem) async {
    if (_isTogglingStatus || _isLoading)
      return; // Prevent action if already toggling or loading
    if (!mounted) return;

    final bool originalStatus = menuItem.isActive;
    final bool newStatus = !originalStatus;

    // Optimistic UI update
    setState(() {
      _isTogglingStatus = true; // Start toggle indicator
      // Find the item in the list and update its status locally
      final index = _menuItems.indexWhere((item) => item.id == menuItem.id);
      if (index != -1) {
        _menuItems[index].isActive = newStatus;
      }
    });

    try {
      // Update status in Firestore using the specific controller method
      // Ensure your FoodMenuController has this method or adapt to use updateItem
      bool success = await menuController.updateItem(menuItem);

      if (!mounted) return;

      if (success) {
        _showSnackBar(
          '"${menuItem.id}" status updated to ${newStatus ? 'Active' : 'Inactive'}.',
        );
        // Optionally re-sort after update to maintain active/inactive grouping
        setState(() {
          _menuItems.sort((a, b) {
            if (a.isActive == b.isActive) return a.id.compareTo(b.id);
            return a.isActive ? -1 : 1;
          });
        });
      } else {
        // Revert optimistic UI update if Firestore update failed
        _showSnackBar(
          'Failed to update status for "${menuItem.id}".',
          isError: true,
        );
        setState(() {
          final index = _menuItems.indexWhere((item) => item.id == menuItem.id);
          if (index != -1) {
            _menuItems[index].isActive = originalStatus; // Revert back
          }
        });
      }
    } catch (e) {
      _showSnackBar('Error updating status: $e', isError: true);
      // Revert optimistic UI update on error
      if (mounted) {
        setState(() {
          final index = _menuItems.indexWhere((item) => item.id == menuItem.id);
          if (index != -1) {
            _menuItems[index].isActive = originalStatus; // Revert back
          }
        });
      }
    } finally {
      // Ensure toggle indicator stops, regardless of outcome
      if (mounted) {
        setState(() => _isTogglingStatus = false);
      }
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // --- AppBar ---
      appBar: AppBar(
        title: const Text('Menu Management ✨'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Menu',
            // Disable refresh if any loading is happening
            onPressed:
                (_isLoading || _isTogglingStatus)
                    ? null
                    : () => _fetchMenuItems(isInitialLoad: true),
          ),
        ],
      ),
      // --- Body ---
      body: _buildBody(theme), // Extracted body logic
      // --- Floating Action Button ---
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Add Menu Item',
        // Disable FAB if any loading is happening
        onPressed:
            (_isLoading || _isTogglingStatus)
                ? null
                : () => _handleAddOrUpdate(),
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: const Text('Add Item'),
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        elevation: 6.0,
      ),
    );
  }

  // --- Body Building Logic ---
  Widget _buildBody(ThemeData theme) {
    // Determine if the overlay should be shown
    bool showLoadingOverlay =
        (_isLoading && _menuItems.isNotEmpty) || _isTogglingStatus;

    // Initial loading state (shimmer)
    if (_isLoading && _menuItems.isEmpty) return _buildShimmerList();
    // Error state when list is empty
    if (_errorMessage != null && _menuItems.isEmpty)
      return _buildErrorState(theme);
    // Empty state when loaded but no items
    if (!_isLoading && _menuItems.isEmpty) return _buildEmptyState(theme);

    // --- List View with Potential Overlay ---
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _fetchMenuItems(isInitialLoad: true),
          color: theme.colorScheme.secondary,
          child: _buildAnimatedMenuList(theme), // Your animated list
        ),
        // Loading overlay for subsequent fetches OR status toggling
        if (showLoadingOverlay)
          Positioned.fill(
            // Ensure overlay covers the whole stack area
            child: Container(
              // Slightly different opacity for toggle?
              color:
                  _isTogglingStatus
                      ? Colors.black.withOpacity(0.15)
                      : Colors.black.withOpacity(0.2),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- Empty State Widget ---
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_food_outlined, size: 80, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text(
            'No menu items yet!',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Tap the + button below to add your first dish or combo.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Error State Widget ---
  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 80,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Load Failed.',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Could not load menu data.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed:
                  (_isLoading || _isTogglingStatus)
                      ? null
                      : () => _fetchMenuItems(isInitialLoad: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Shimmer Loading Placeholder ---
  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80), // Avoid FAB
        itemCount: 6, // Number of shimmer items
        itemBuilder:
            (_, __) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _cardMargin,
                vertical: _cardMargin / 2,
              ),
              child: Card(
                // Shimmer card structure
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_borderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(
                    _cardPadding / 2,
                  ).copyWith(right: 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Image placeholder
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Text content placeholder
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: double.infinity,
                              height: 16.0,
                              color: Colors.white,
                            ), // Title line
                            const SizedBox(height: 6),
                            Container(
                              width: 80,
                              height: 14.0,
                              color: Colors.white,
                            ), // Price line
                          ],
                        ),
                      ),
                      // Action buttons placeholder
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ), // Placeholder for switch/icon
                          const SizedBox(height: 4),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ), // Placeholder for icon
                          const SizedBox(height: 4),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ), // Placeholder for icon
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }

  // --- Animated Menu List ---
  Widget _buildAnimatedMenuList(ThemeData theme) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.only(
          bottom: 90,
          top: 5,
        ), // Padding for FAB and top spacing
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final menuItem = _menuItems[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375), // Animation duration
            child: SlideAnimation(
              // Slide animation for list items
              verticalOffset: 40.0,
              child: FadeInAnimation(
                // Fade-in animation
                // Pass the specific item loading state (_isTogglingStatus) to the card builder
                child: _buildMenuCard(menuItem, theme, _isTogglingStatus),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Fancy Menu Item Card ---
  Widget _buildMenuCard(FoodMenu menuItem, ThemeData theme, bool isToggling) {
    final bool isAComboWithItems =
        menuItem.isCombo &&
        menuItem.foodList != null &&
        menuItem.foodList!.isNotEmpty;
    final colorScheme = theme.colorScheme;
    final bool isActive = menuItem.isActive; // Get current active status

    // Apply opacity to the entire card if inactive
    return Opacity(
      opacity: isActive ? 1.0 : 0.65, // Dim inactive items
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: _cardMargin,
          vertical: _cardMargin / 2,
        ),
        elevation: isActive ? 3.0 : 1.0, // Reduce elevation if inactive
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          // Add a subtle border to inactive items
          side: BorderSide(
            color:
                isActive
                    ? Colors.transparent
                    : theme.disabledColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // Disable tap interaction while a status toggle is in progress
          onTap:
              isToggling
                  ? null
                  : () => _handleAddOrUpdate(existingMenu: menuItem),
          child: Padding(
            // Adjust padding
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center items vertically
              children: [
                // --- Placeholder Image Section ---
                // Placeholder for actual image loading using imgPath if available
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    // Use a less prominent color if inactive
                    color: colorScheme.secondaryContainer.withOpacity(
                      isActive ? 0.3 : 0.1,
                    ),
                  ),
                  child: Icon(
                    menuItem.isCombo
                        ? Icons.fastfood_outlined
                        : Icons.local_pizza_outlined,
                    size: 35,
                    // Use disabled color for icon if inactive
                    color:
                        isActive ? colorScheme.secondary : theme.disabledColor,
                  ),
                ),
                const SizedBox(width: 12),

                // --- Text Content Section ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Name & Status Indicator Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            // Allow text to take space but prevent overflow
                            child: Text(
                              menuItem.id, // Use ID as name (or a 'name' field)
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                // Dim text color if inactive
                                color:
                                    isActive
                                        ? theme.textTheme.titleMedium?.color
                                        : theme.disabledColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status Chip
                          Chip(
                            label: Text(isActive ? 'Active' : 'Inactive'),
                            labelStyle: theme.textTheme.labelSmall?.copyWith(
                              // Use distinct colors for status text
                              color:
                                  isActive
                                      ? Colors.green.shade900
                                      : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                            // Use distinct background colors for status
                            backgroundColor:
                                isActive
                                    ? Colors.green.shade100.withOpacity(0.8)
                                    : Colors.grey.shade300.withOpacity(0.8),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            visualDensity:
                                VisualDensity.compact, // Make chip smaller
                            side: BorderSide.none, // Remove border
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Price (Dim if inactive)
                      Text(
                        currencyFormatter.format(
                          menuItem.price,
                        ), // Use formatter if you have one
                        style: theme.textTheme.titleSmall?.copyWith(
                          color:
                              isActive
                                  ? colorScheme.primary
                                  : theme.disabledColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Combo Items List (Apply opacity if inactive)
                      if (isAComboWithItems)
                        Opacity(
                          opacity:
                              isActive ? 1.0 : 0.7, // Slightly dim combo items
                          child: _buildComboItemsList(menuItem, theme),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4), // Space before actions
                // --- Action Buttons Section ---
                Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Align actions vertically
                  children: [
                    // --- Active Status Toggle Switch ---
                    SizedBox(
                      // Constrain height for better alignment
                      height: 40,
                      child: Transform.scale(
                        // Make switch slightly smaller
                        scale: 0.85,
                        alignment: Alignment.center,
                        child: Switch(
                          value: isActive,
                          activeColor: Colors.green, // Active color
                          inactiveThumbColor:
                              Colors.grey.shade600, // Inactive thumb
                          inactiveTrackColor: Colors.grey.shade400.withOpacity(
                            0.5,
                          ), // Inactive track
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          // Disable switch during toggle operation or general loading
                          onChanged:
                              (isToggling || _isLoading)
                                  ? null
                                  : (bool value) {
                                    _toggleActiveStatus(menuItem);
                                  },
                        ),
                      ),
                    ),

                    // Edit Button (Disable if toggling)
                    SizedBox(
                      height: 36,
                      child: IconButton(
                        icon: Icon(
                          Icons.edit_note_outlined,
                          color:
                              (isToggling || _isLoading)
                                  ? Colors.grey
                                  : Colors.blue.shade600,
                        ),
                        tooltip: 'Edit Item',
                        visualDensity: VisualDensity.compact,
                        // Disable if toggling or general loading
                        onPressed:
                            (isToggling || _isLoading)
                                ? null
                                : () =>
                                    _handleAddOrUpdate(existingMenu: menuItem),
                      ),
                    ),

                    // Delete Button (Disable if toggling)
                    SizedBox(
                      height: 36,
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_forever_outlined,
                          color:
                              (isToggling || _isLoading)
                                  ? Colors.grey
                                  : Colors.redAccent.shade400,
                        ),
                        tooltip: 'Delete Item',
                        visualDensity: VisualDensity.compact,
                        // Disable if toggling or general loading
                        onPressed:
                            (isToggling || _isLoading)
                                ? null
                                : () => _deleteMenu(menuItem),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper for Combo Items List ---
  Widget _buildComboItemsList(FoodMenu menuItem, ThemeData theme) {
    // Use theme context for styling consistency
    final hintColor = theme.hintColor;
    final bodySmallStyle = theme.textTheme.bodySmall?.copyWith(
      color: hintColor,
    );
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: hintColor,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Includes:', style: labelStyle),
          const SizedBox(height: 2),
          // Map foodList items to Text widgets
          ...menuItem.foodList!
              .map((foodItemMap) {
                // Safe access to map values with defaults
                final String foodName =
                    foodItemMap['foodName']?.toString() ?? 'Unknown Item';
                final String quantity =
                    foodItemMap['quantity']?.toString() ?? '?';
                final String foodInfo = "$foodName: $quantity";

                return Padding(
                  padding: const EdgeInsets.only(left: 4.0, top: 1.0),
                  child: Text(
                    '• $foodInfo',
                    style: bodySmallStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              })
              .take(2), // Limit displayed items (adjust as needed)
          // Show ellipsis if more items exist
          if (menuItem.foodList!.length > 2)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, top: 1.0),
              child: Text('...', style: bodySmallStyle),
            ),
        ],
      ),
    );
  }

  // --- Currency Formatter (Add if needed for price) ---
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );
} // End of _MenuManagementScreenState
