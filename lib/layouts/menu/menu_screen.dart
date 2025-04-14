// lib/layouts/menu/menu_screen.dart

import 'dart:async'; // Import async library for StreamSubscription

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_management/controllers/bill_controller.dart';
import 'package:restaurant_management/controllers/menu_controller.dart';
import 'package:restaurant_management/models/bill.dart';
import 'package:restaurant_management/models/menu.dart';
import 'package:shimmer/shimmer.dart';

// --- (Placeholder MenuScreen - REMOVE WHEN YOU HAVE THE REAL ONE) ---
// class MenuScreen extends StatelessWidget { ... } // Keep your placeholder if needed
// --- End Placeholder ---

class MenuScreen extends StatefulWidget {
  final String tableId;
  final String? buffetCombo;

  const MenuScreen({super.key, required this.tableId, this.buffetCombo});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // --- Controllers ---
  final FoodMenuController _menuController = FoodMenuController();
  final BillController _billController = BillController();

  // --- State ---
  List<FoodMenu> _orderableItems = [];
  Map<String, int> _selectedQuantities = {};
  bool _isLoadingMenu = true; // Separate loading state for menu items
  String? _menuErrorMessage;
  bool _isSubmittingOrder = false;
  bool _isRequestingCheckout = false;
  int? _parsedTableNumber; // Store parsed table number

  // --- Real-time Bill State ---
  StreamSubscription? _billSubscription; // To manage the stream listener
  String? _currentBillStatus; // Store the latest bill status
  bool _hasNavigatedOnRequest = false; // Flag to prevent multiple navigations

  // --- Formatting ---
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
  );

  @override
  void initState() {
    super.initState();
    _parseTableNumber(); // Parse table number early
    _loadMenuItems();
    _listenToBillStatus(); // Start listening to bill status
  }

  @override
  void dispose() {
    _billSubscription?.cancel(); // IMPORTANT: Cancel subscription on dispose
    super.dispose();
  }

  // --- Parse Table Number ---
  void _parseTableNumber() {
    _parsedTableNumber = int.tryParse(
      widget.tableId.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (_parsedTableNumber == null) {
      print("Error: Could not parse table number from ID: ${widget.tableId}");
      // Handle this error appropriately, maybe show an error message immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showSnackBar('Invalid Table ID format.', isError: true);
          Navigator.of(context).pop(); // Navigate back if ID is invalid
        }
      });
    }
  }

  // --- Load Orderable Menu Items ---
  Future<void> _loadMenuItems() async {
    // Only proceed if table number parsing was successful
    if (_parsedTableNumber == null) return;
    if (!mounted) return;
    setState(() {
      _isLoadingMenu = true;
      _menuErrorMessage = null;
    });
    // ... (rest of the loading logic remains the same) ...
    try {
      final allItems = await _menuController.getAll();
      if (!mounted) return;
      setState(() {
        _orderableItems = allItems.where((item) => !item.isCombo).toList();
        _orderableItems.sort((a, b) => a.id.compareTo(b.id));
        _isLoadingMenu = false;
      });
    } catch (e) {
      print("Error loading menu items: $e");
      if (!mounted) return;
      setState(() {
        _menuErrorMessage = "Could not load menu items.";
        _isLoadingMenu = false;
      });
    }
  }

  // --- Listen to Bill Status Changes ---
  void _listenToBillStatus() {
    if (_parsedTableNumber == null)
      return; // Don't listen if table number is invalid

    _billSubscription?.cancel(); // Cancel previous subscription if any
    _billSubscription = _billController
        // Use the flexible status stream for robustness
        .getBillStreamByTableNumber(_parsedTableNumber!)
        .listen(
          (bill) {
            // IMPORTANT: Check if the widget is still mounted before updating state
            if (!mounted) return;

            final newStatus = bill?.status;
            print(
              "Bill Status Update Received: $newStatus for Table ${widget.tableId}",
            );

            // Update the status in the state to redraw UI elements
            setState(() {
              _currentBillStatus = newStatus;
            });

            // Check if the status is 'requested' and navigate back if needed
            if (newStatus == 'requested' && !_hasNavigatedOnRequest) {
              _hasNavigatedOnRequest =
                  true; // Set flag to prevent multiple pops
              _showSnackBar(
                'Checkout already requested. Exiting order screen.',
                isError: false,
              );
              // Use a short delay before popping to allow snackbar to be seen (optional)
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) {
                  Navigator.of(
                    context,
                  ).pop(); // Navigate back to the previous screen
                }
              });
            }
          },
          onError: (error) {
            print("Error in bill stream listener: $error");
            if (!mounted) return;
            // Optionally update UI to show stream error, though _errorMessage handles load errors
            // setState(() { _currentBillStatus = 'error'; });
          },
        );
  }

  // --- Update Quantity of a Selected Item ---
  void _updateQuantity(String itemId, int change) {
    // Don't allow changes if bill is already requested
    if (_currentBillStatus == 'requested') return;
    setState(() {
      // ... (rest of quantity logic remains the same) ...
      final currentQuantity = _selectedQuantities[itemId] ?? 0;
      final newQuantity = currentQuantity + change;
      if (newQuantity <= 0) {
        _selectedQuantities.remove(itemId);
      } else {
        _selectedQuantities[itemId] = newQuantity;
      }
    });
  }

  // --- Find or Create Bill and Submit Order ---
  Future<void> _submitOrder() async {
    if (_selectedQuantities.isEmpty) {
      /* ... (show snackbar) ... */
      return;
    }
    // Prevent submission if bill is already requested or table number invalid
    if (_currentBillStatus == 'requested' || _parsedTableNumber == null) return;
    if (!mounted) return;
    setState(() => _isSubmittingOrder = true);

    String? billId;
    // Use the parsed table number
    int tableNumber = _parsedTableNumber!;

    try {
      // 1. Find existing open bill or create a new one
      Bill? openBill = await _billController.getOpenBillByTableNumber(
        tableNumber,
      );

      if (openBill == null) {
        // Check if a requested bill exists before creating new (edge case)
        Bill? requestedBill = await _billController
            .getRequestedBillByTableNumber(
              tableNumber,
            ); // Need to add this method to controller if desired
        if (requestedBill != null) {
          billId = requestedBill.id!;
          print("Warning: Adding order to an already 'requested' bill.");
        } else {
          DocumentReference? billRef = await _billController.addBill(
            tableNumber,
          );
          if (billRef != null) {
            billId = billRef.id;
          } else {
            throw Exception('Failed to create a new bill.');
          }
        }
      } else {
        billId = openBill.id!; // Use existing open bill ID
      }

      // 2. Format order items (remains the same)
      final orderItemsToSubmit =
          _selectedQuantities.entries.map((entry) {
            final itemId = entry.key;
            final quantity = entry.value;
            final menuItem = _orderableItems.firstWhere(
              (item) => item.id == itemId,
              orElse: () => FoodMenu(id: itemId, isCombo: false, price: 0.0),
            );
            return {
              'menuItemId': menuItem.id,
              'name': menuItem.id,
              'quantity': quantity,
              'unitPrice': menuItem.price,
            };
          }).toList();

      // 3. Add order to the bill's subcollection
      bool success = await _billController.addOrderToBill(
        billId,
        orderItemsToSubmit,
      );

      if (!mounted) return; // Check mount status again

      if (success) {
        _showSnackBar('Order submitted successfully!');
        setState(() {
          _selectedQuantities.clear();
        }); // Clear selection
      } else {
        _showSnackBar(
          'Failed to submit order. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      print("Error submitting order: $e");
      if (!mounted) return;
      _showSnackBar('Error submitting order: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmittingOrder = false);
      }
    }
  }

  // --- Request Checkout ---
  Future<void> _requestCheckout() async {
    // Prevent action if already requested, saving, loading, or invalid table number
    if (_currentBillStatus == 'requested' ||
        _isSubmittingOrder ||
        _isRequestingCheckout ||
        _parsedTableNumber == null)
      return;
    if (!mounted) return;
    setState(() => _isRequestingCheckout = true);

    int tableNumber = _parsedTableNumber!;

    try {
      // Find the bill (could be 'open' or another status if logic allows)
      // Using flexible stream method's logic is safer here: find latest relevant bill
      Bill? relevantBill = await _billController.getOpenBillByTableNumber(
        tableNumber,
      ); // Needs implementation in controller

      if (relevantBill != null &&
          relevantBill.id != null &&
          relevantBill.status == 'open') {
        // Only allow requesting if the status is currently 'open'
        bool success = await _billController.updateBillStatus(
          relevantBill.id!,
          'requested',
        );
        // The stream listener (_listenToBillStatus) will handle the UI update and navigation
        if (!mounted) return;
        if (!success) {
          // Show error only if update failed, success triggers stream update
          _showSnackBar('Failed to request checkout.', isError: true);
        }
        // No need to show success snackbar here, let listener handle feedback/navigation
      } else if (relevantBill?.status == 'requested') {
        _showSnackBar(
          'Checkout has already been requested for this table.',
          isError: false,
        );
        // Trigger navigation just in case the listener hasn't fired yet (or if screen loaded in this state)
        if (!_hasNavigatedOnRequest) {
          _hasNavigatedOnRequest = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
      } else {
        _showSnackBar(
          'No active bill found to request checkout.',
          isError: true,
        );
      }
    } catch (e) {
      print("Error requesting checkout: $e");
      if (!mounted) return;
      _showSnackBar('Error requesting checkout: $e', isError: true);
    } finally {
      if (mounted) {
        setState(
          () => _isRequestingCheckout = false,
        ); // Stop button loading indicator
      }
    }
  }
  // Note: Need to add findLatestBillForTable and getBillByRequestedStatus to BillController if using those checks

  // --- UI Helpers ---
  void _showSnackBar(String message, {bool isError = false}) {
    // ... (implementation remains the same) ...
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalItems = _selectedQuantities.values.fold(0, (sum, q) => sum + q);
    // Determine if buttons should be globally disabled based on status
    final bool checkoutRequested = _currentBillStatus == 'requested';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order - Table ${widget.tableId}'),
        elevation: 1,
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
      // IMPORTANT: Use a builder directly under Scaffold if listening for status
      // OR use the _currentBillStatus state variable updated by the listener
      body: _buildBodyContent(theme, colorScheme),
      bottomNavigationBar: _buildBottomActionBar(
        theme,
        totalItems,
        checkoutRequested,
      ),
    );
  }

  // --- Body Content Builder ---
  Widget _buildBodyContent(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoadingMenu) return _buildLoadingShimmerGrid();
    if (_menuErrorMessage != null) return _buildErrorState();
    if (_orderableItems.isEmpty) return _buildEmptyState(theme);

    // --- Display the Menu Grid ---
    // ... (Grid setup logic remains the same) ...
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 180).floor().clamp(2, 4);

    return GridView.builder(
      padding: const EdgeInsets.all(12.0).copyWith(
        bottom: 80,
      ), // Add bottom padding for FAB overlap avoidance if needed
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        childAspectRatio: 0.7,
      ),
      itemCount: _orderableItems.length,
      itemBuilder: (context, index) {
        final item = _orderableItems[index];
        return _buildDishCard(theme, colorScheme, item);
      },
    );
  }

  // --- Loading, Error, Empty States (Implementations remain the same) ---
  Widget _buildLoadingShimmerGrid() {
    /* ... */
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 180).floor().clamp(2, 4);
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: GridView.builder(
        padding: const EdgeInsets.all(12.0),
        physics:
            const NeverScrollableScrollPhysics(), // Disable scroll during shimmer
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          childAspectRatio: 0.7,
        ),
        itemCount: 8, // Number of shimmer placeholders
        itemBuilder: (context, index) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image placeholder
                Container(
                  height: 120, // Adjust height
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white,
                        ), // Name
                        const SizedBox(height: 6),
                        Container(
                          width: 60,
                          height: 12,
                          color: Colors.white,
                        ), // Price
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 30,
                          color: Colors.white,
                        ), // Quantity controls
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    /* ... */
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: theme.colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Load Failed',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _menuErrorMessage ??
                  'Could not load menu items.', // Use specific error message
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _loadMenuItems, // Retry loading menu items
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    /* ... */
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.no_food_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Orderable Items',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The menu currently has no items available for individual ordering.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ],
      ),
    );
  }

  // --- Dish Card Widget ---
  Widget _buildDishCard(
    ThemeData theme,
    ColorScheme colorScheme,
    FoodMenu item,
  ) {
    // ... (Card implementation remains largely the same, but check disable logic) ...
    final itemId = item.id;
    final name = item.id; // Use ID as name for now
    final price = item.price;
    final imageUrl =
        'https://source.unsplash.com/featured/?food,${Uri.encodeComponent(name)}';
    final quantity = _selectedQuantities[itemId] ?? 0;
    final isSelected = quantity > 0;
    final bool isBillRequested =
        _currentBillStatus == 'requested'; // Check status

    return Card(
      elevation: isSelected ? 4.0 : 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isSelected
                ? BorderSide(color: colorScheme.primary, width: 1.5)
                : BorderSide(color: colorScheme.outline.withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Opacity(
        // Fade items slightly if checkout requested
        opacity: isBillRequested ? 0.6 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Image Section ---
            Container(
              /* ... image setup ... */
              height: 120,
              color: Colors.grey.shade200,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  /* ... */
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder:
                    (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.fastfood_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
              ),
            ),

            // --- Content Section ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Item Name
                    Text(
                      /* ... */
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Item Price
                    Text(
                      /* ... */
                      currencyFormatter.format(price),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    // Quantity Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Decrease Button
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle_outline,
                            size: 24,
                            color:
                                quantity > 0
                                    ? colorScheme.error
                                    : Colors.grey.shade400,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          // Disable if 0 OR if checkout requested
                          onPressed:
                              quantity > 0 && !isBillRequested
                                  ? () => _updateQuantity(itemId, -1)
                                  : null,
                        ),
                        // Quantity Display
                        Padding(
                          /* ... */
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            '$quantity',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Increase Button
                        IconButton(
                          icon: Icon(
                            Icons.add_circle_outline,
                            size: 24,
                            color:
                                isBillRequested
                                    ? Colors.grey.shade400
                                    : colorScheme.primary,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          // Disable if checkout requested
                          onPressed:
                              !isBillRequested
                                  ? () => _updateQuantity(itemId, 1)
                                  : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Bottom Action Bar (UPDATED with status check) ---
  Widget _buildBottomActionBar(
    ThemeData theme,
    int totalItems,
    bool checkoutRequested,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Submit Order Button
          Expanded(
            child: ElevatedButton.icon(
              icon:
                  _isSubmittingOrder
                      ? Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(right: 8),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Badge(
                        label: Text(totalItems.toString()),
                        isLabelVisible:
                            totalItems > 0 &&
                            !checkoutRequested, // Hide badge if requested
                        backgroundColor: theme.colorScheme.secondary,
                        child: const Icon(Icons.check_circle_outline_rounded),
                      ),
              label: Text(
                _isSubmittingOrder ? 'Submitting...' : 'Submit Order',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                // Grey out if disabled
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              // Disable if no items, submitting, requesting, OR checkout already requested
              onPressed:
                  totalItems == 0 ||
                          _isSubmittingOrder ||
                          _isRequestingCheckout ||
                          checkoutRequested
                      ? null
                      : _submitOrder,
            ),
          ),
          const SizedBox(width: 12),
          // Request Checkout Button
          Expanded(
            child: ElevatedButton.icon(
              icon:
                  _isRequestingCheckout
                      ? Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(right: 8),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.receipt_long_outlined),
              // Change text and style based on status
              label: Text(
                checkoutRequested
                    ? 'Requested'
                    : (_isRequestingCheckout
                        ? 'Requesting...'
                        : 'Request Checkout'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    checkoutRequested
                        ? Colors.orange.shade600
                        : Colors
                            .blueAccent
                            .shade400, // Different color when requested
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                // Grey out if disabled
                disabledBackgroundColor: Colors.grey.shade400,
                // Change disabled foreground color if needed
                // disabledForegroundColor: Colors.white70,
              ),
              // Disable if submitting, requesting, OR checkout already requested
              onPressed:
                  _isSubmittingOrder ||
                          _isRequestingCheckout ||
                          checkoutRequested
                      ? null
                      : _requestCheckout,
            ),
          ),
        ],
      ),
    );
  }
}
