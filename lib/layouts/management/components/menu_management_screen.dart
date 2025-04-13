import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Added
import 'package:restaurant_management/controllers/menu_controller.dart';
import 'package:restaurant_management/layouts/management/components/dialogs/menu_update_dialog.dart';
import 'package:restaurant_management/models/menu.dart';
import 'package:shimmer/shimmer.dart'; // Added

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  bool _isLoading = false;
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

  Future<void> _fetchMenuItems({bool isInitialLoad = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      // Only clear list on explicit refresh, not during add/edit/delete updates
      // if (isInitialLoad) {
      //   _menuItems = []; // Keep items visible during updates if desired
      // }
    });

    try {
      final List<FoodMenu> fetchedItems = await menuController.getAll();
      if (mounted) {
        setState(() {
          _menuItems = fetchedItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = "Failed to fetch menu: $e";
        setState(() {
          _errorMessage = errorMsg;
          _menuItems = []; // Clear items on fetch error
          _isLoading = false;
        });
        _showSnackBar(errorMsg, isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar(); // Hide previous snackbar
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
            isError
                ? Colors
                    .redAccent
                    .shade700 // Darker red
                : Colors.green.shade600, // Nicer green
        behavior: SnackBarBehavior.floating, // Make it float
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(10.0),
      ),
    );
  }

  Future<void> _deleteMenu(FoodMenu menuItem) async {
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

    if (confirmDelete) {
      setState(() => _isLoading = true);
      try {
        await menuController.deleteItem(menuItem.id);
        _showSnackBar('"${menuItem.id}" deleted successfully.');
        // Optimistic UI update (remove immediately)
        if (mounted) {
          setState(() {
            _menuItems.removeWhere((item) => item.id == menuItem.id);
            _isLoading = false;
          });
        }
        // Optional: Fetch again to ensure consistency if needed
        // await _fetchMenuItems();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          // If optimistic update failed, refresh the list
          _showSnackBar('Error deleting item: $e', isError: true);
          _fetchMenuItems(); // Refresh to get the correct state
        }
      }
    }
  }

  Future<void> _handleAddOrUpdate({FoodMenu? existingMenu}) async {
    final FoodMenu? resultMenuItem = await showAddOrUpdateMenuDialog(
      context: context,
      existingMenu: existingMenu,
    );

    if (resultMenuItem != null) {
      setState(() => _isLoading = true);
      bool success = false;
      String action = existingMenu == null ? "add" : "update";
      String actionPast = existingMenu == null ? "added" : "updated";

      try {
        if (existingMenu == null) {
          success = await menuController.addItemWithId(resultMenuItem);
        } else {
          success = await menuController.updateItem(resultMenuItem);
        }

        if (success) {
          _showSnackBar('Menu item ${actionPast} successfully.');
          await _fetchMenuItems(); // Refresh list
        } else {
          _showSnackBar('Failed to $action item.', isError: true);
        }
      } catch (e) {
        _showSnackBar('Error ${action}ing item: $e', isError: true);
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // --- Fancy AppBar ---
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
        elevation: 4.0, // Add some shadow
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Menu',
            onPressed:
                _isLoading ? null : () => _fetchMenuItems(isInitialLoad: true),
          ),
        ],
      ),
      body: _buildBody(theme), // Extracted body logic
      // --- Fancy FAB ---
      floatingActionButton: FloatingActionButton.extended(
        // Use extended for text + icon
        tooltip: 'Add Menu Item',
        onPressed: _isLoading ? null : () => _handleAddOrUpdate(),
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: const Text('Add Item'),
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        elevation: 6.0,
        // Optional: Animate appearance
        // child: AnimatedSwitcher(duration: Duration(milliseconds: 300), child: _isLoading ? SizedBox() : Icon(Icons.add)),
      ),
    );
  }

  // --- Body Building Logic ---
  Widget _buildBody(ThemeData theme) {
    if (_isLoading && _menuItems.isEmpty) {
      // --- Shimmer Loading State ---
      return _buildShimmerList();
    } else if (_errorMessage != null && _menuItems.isEmpty) {
      // --- Error State ---
      return _buildErrorState(theme);
    } else if (!_isLoading && _menuItems.isEmpty) {
      // --- Empty State ---
      return _buildEmptyState(theme);
    } else {
      // --- List View (potentially with loading overlay for updates) ---
      return Stack(
        children: [
          // Use RefreshIndicator for pull-to-refresh
          RefreshIndicator(
            onRefresh: () => _fetchMenuItems(isInitialLoad: true),
            color: theme.colorScheme.secondary, // Themed refresh indicator
            child: _buildAnimatedMenuList(theme), // Use animated list
          ),
          // Loading overlay ONLY for actions (add/edit/delete), not initial load
          if (_isLoading && _menuItems.isNotEmpty)
            Container(
              color: Colors.black.withOpacity(0.2), // Softer overlay
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      );
    }
  }

  // --- Empty State Widget ---
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.no_food_outlined, // More relevant icon
            size: 80,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No menu items yet!',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first item.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
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
              Icons.cloud_off_rounded, // Error icon
              size: 80,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong.',
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
                  _isLoading
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
      enabled: true, // Already handled by _isLoading check
      child: ListView.builder(
        itemCount: 6, // Show a few shimmer placeholders
        itemBuilder:
            (_, __) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _cardMargin,
                vertical: _cardMargin / 2,
              ),
              child: Card(
                elevation: 0, // No elevation needed for shimmer placeholder
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_borderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_cardPadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Placeholder for Image
                      Container(
                        width: 50.0,
                        height: 50.0,
                        decoration: BoxDecoration(
                          color: Colors.white, // Background color for shimmer
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Placeholder for Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: double.infinity,
                              height: 16.0,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              height: 12.0,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 100, // Shorter line
                              height: 12.0,
                              color: Colors.white,
                            ),
                          ],
                        ),
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
        padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final menuItem = _menuItems[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400), // Animation duration
            child: SlideAnimation(
              verticalOffset: 50.0, // Start slightly below
              child: FadeInAnimation(
                child: _buildMenuCard(menuItem, theme), // Build the actual card
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Fancy Menu Item Card ---
  Widget _buildMenuCard(FoodMenu menuItem, ThemeData theme) {
    final bool isAComboWithItems =
        menuItem.isCombo &&
        menuItem.foodList != null &&
        menuItem.foodList!.isNotEmpty;
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: _cardMargin,
        vertical: _cardMargin / 2,
      ),
      elevation: 3.0, // Subtle shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        // side: BorderSide(color: theme.dividerColor.withOpacity(0.5)) // Optional border
      ),
      clipBehavior: Clip.antiAlias, // Clip content like image
      child: InkWell(
        // Make card tappable (e.g., for details screen later)
        onTap: () {
          // Optional: Navigate to a detail screen or show more info
          print('Tapped on ${menuItem.id}');
          _handleAddOrUpdate(
            existingMenu: menuItem,
          ); // Or just open edit dialog
        },
        child: Padding(
          padding: const EdgeInsets.all(
            _cardPadding / 2,
          ).copyWith(right: 0), // Less padding on right for buttons
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Placeholder Image ---
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  width: 70,
                  height: 70,
                  color: colorScheme.secondaryContainer.withOpacity(0.3),
                  child: Icon(
                    menuItem.isCombo
                        ? Icons.fastfood_outlined
                        : Icons.local_pizza_outlined, // Different icons
                    size: 35,
                    color: colorScheme.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // --- Text Content ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Name and Combo Chip
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            menuItem.id, // Use actual name if available
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (menuItem.isCombo)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Chip(
                              label: const Text('Combo'),
                              labelStyle: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                              ),
                              backgroundColor: colorScheme.secondaryContainer
                                  .withOpacity(0.7),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Price
                    Text(
                      '\$${menuItem.price.toStringAsFixed(2)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Combo Items List
                    if (isAComboWithItems)
                      _buildComboItemsList(menuItem, theme),
                  ],
                ),
              ),
              // --- Action Buttons ---
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_note_outlined,
                      color: Colors.blue.shade600,
                    ), // Nicer edit icon
                    tooltip: 'Edit Item',
                    visualDensity: VisualDensity.compact, // Make denser
                    onPressed:
                        _isLoading
                            ? null
                            : () => _handleAddOrUpdate(existingMenu: menuItem),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_forever_outlined,
                      color: Colors.redAccent.shade400,
                    ), // Nicer delete icon
                    tooltip: 'Delete Item',
                    visualDensity: VisualDensity.compact,
                    onPressed: _isLoading ? null : () => _deleteMenu(menuItem),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper for Combo Items ---
  Widget _buildComboItemsList(FoodMenu menuItem, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0), // Add space before list
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Includes:',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 2),
          // Limited height list if too many items
          // ConstrainedBox(
          //  constraints: BoxConstraints(maxHeight: 40), // Example limit
          //  child: ListView(
          //    shrinkWrap: true,
          //    children: // ... map ...
          //   )
          // )
          ...menuItem.foodList!
              .map((foodItemMap) {
                final String foodName =
                    foodItemMap['foodName'] ?? 'Unknown Item';
                final dynamic quantity =
                    foodItemMap['quantity'] ?? '?'; // Handle potential null
                final String foodInfo = "$foodName: $quantity";

                return Padding(
                  padding: const EdgeInsets.only(left: 4.0, top: 1.0),
                  child: Text(
                    '• $foodInfo',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              })
              .take(3), // Limit displayed items for brevity, add "..." if more
          if (menuItem.foodList!.length > 3)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, top: 1.0),
              child: Text(
                '...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
