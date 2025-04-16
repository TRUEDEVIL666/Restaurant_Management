// lib/layouts/menu/menu_screen.dart

import 'dart:async'; // Import async library for StreamSubscription

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_management/controllers/bill_controller.dart';
import 'package:restaurant_management/controllers/menu_controller.dart';
import 'package:restaurant_management/models/bill.dart';
import 'package:restaurant_management/models/menu.dart';
import 'package:restaurant_management/services/firebase_storage_service.dart';
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
  // --- Controllers & Services ---
  final FoodMenuController _menuController = FoodMenuController();
  final BillController _billController = BillController();
  final FirebaseStorageService _storageService =
      FirebaseStorageService(); // <-- Instance of storage service

  // --- State Variables ---
  List<FoodMenu> _orderableItems = [];
  Map<String, int> _selectedQuantities = {};
  bool _isLoadingMenu = true;
  String? _menuErrorMessage;
  bool _isSubmittingOrder = false;
  bool _isRequestingCheckout = false;
  int? _parsedTableNumber;
  StreamSubscription? _billSubscription;
  String? _currentBillStatus;
  bool _hasNavigatedOnRequest = false;

  // --- Formatting ---
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
  );

  @override
  void initState() {
    super.initState();
    _parseTableNumber();
    _loadMenuItems();
    _listenToBillStatus();
  }

  @override
  void dispose() {
    _billSubscription?.cancel();
    super.dispose();
  }

  // --- ( _parseTableNumber, _loadMenuItems, _listenToBillStatus functions remain the same ) ---
  // --- Parse Table Number ---
  void _parseTableNumber() {
    _parsedTableNumber = int.tryParse(
      widget.tableId.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (_parsedTableNumber == null) {
      print("Error: Could not parse table number from ID: ${widget.tableId}");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showSnackBar('Invalid Table ID format.', isError: true);
          Navigator.of(context).pop();
        }
      });
    }
  }

  // --- Load Orderable Menu Items ---
  Future<void> _loadMenuItems() async {
    if (_parsedTableNumber == null) return;
    if (!mounted) return;
    setState(() {
      _isLoadingMenu = true;
      _menuErrorMessage = null;
    });
    try {
      final allItems = await _menuController.getAllActive();
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
    if (_parsedTableNumber == null) return;
    _billSubscription?.cancel();
    _billSubscription = _billController
        .getBillStreamByTableNumber(_parsedTableNumber!)
        .listen(
          (bill) {
            if (!mounted) return;
            final newStatus = bill?.status;
            print(
              "Bill Status Update Received: $newStatus for Table ${widget.tableId}",
            );
            setState(() {
              _currentBillStatus = newStatus;
            });

            if (newStatus == 'requested' && !_hasNavigatedOnRequest) {
              _hasNavigatedOnRequest = true;
              _showSnackBar(
                'Checkout already requested. Exiting order screen.',
                isError: false,
              );
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) Navigator.of(context).pop();
              });
            }
          },
          onError: (error) {
            print("Error in bill stream listener: $error");
            // Handle stream error if needed
          },
        );
  }

  // --- ( _updateQuantity function remains the same ) ---
  void _updateQuantity(String itemId, int change) {
    if (_currentBillStatus == 'requested') return;
    setState(() {
      final currentQuantity = _selectedQuantities[itemId] ?? 0;
      final newQuantity = currentQuantity + change;
      if (newQuantity <= 0) {
        _selectedQuantities.remove(itemId);
      } else {
        _selectedQuantities[itemId] = newQuantity;
      }
    });
  }

  // --- ( _submitOrder function remains the same, ensure it uses item.id for name/menuItemId ) ---
  Future<void> _submitOrder() async {
    if (_selectedQuantities.isEmpty ||
        _currentBillStatus == 'requested' ||
        _parsedTableNumber == null)
      return;
    if (!mounted) return;
    setState(() => _isSubmittingOrder = true);

    String? billId;
    int tableNumber = _parsedTableNumber!;

    try {
      // Find/Create Bill
      Bill? openBill = await _billController.getOpenBillByTableNumber(
        tableNumber,
      );
      if (openBill == null) {
        // Add check for requested bill maybe?
        DocumentReference? billRef = await _billController.addBill(tableNumber);
        if (billRef != null) {
          billId = billRef.id;
        } else {
          throw Exception('Failed to create a new bill.');
        }
      } else {
        billId = openBill.id!;
      }

      // Format order items
      final orderItemsToSubmit =
          _selectedQuantities.entries.map((entry) {
            final itemId = entry.key;
            final quantity = entry.value;
            final menuItem = _orderableItems.firstWhere(
              (item) => item.id == itemId,
              orElse:
                  () => FoodMenu(
                    id: itemId,
                    imgPath: null,
                    isCombo: false,
                    price: 0.0,
                  ), // Include imgPath in default
            );
            return {
              'menuItemId': menuItem.id,
              'name': menuItem.id, // Use ID as name for now
              'quantity': quantity,
              'unitPrice': menuItem.price,
            };
          }).toList();

      // Add order to bill
      bool success = await _billController.addOrderToBill(
        billId,
        orderItemsToSubmit,
      );

      if (!mounted) return;

      if (success) {
        _showSnackBar('Order submitted successfully!');
        setState(() {
          _selectedQuantities.clear();
        });
      } else {
        _showSnackBar(
          'Failed to submit order. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      print("Error submitting order: $e");
      if (mounted) _showSnackBar('Error submitting order: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmittingOrder = false);
    }
  }

  // --- ( _requestCheckout function remains the same ) ---
  Future<void> _requestCheckout() async {
    if (_currentBillStatus == 'requested' ||
        _isSubmittingOrder ||
        _isRequestingCheckout ||
        _parsedTableNumber == null)
      return;
    if (!mounted) return;
    setState(() => _isRequestingCheckout = true);

    int tableNumber = _parsedTableNumber!;

    try {
      // Assuming findLatestBillForTable exists or adapt to getOpenBillByTableNumber
      Bill? relevantBill = await _billController.getOpenBillByTableNumber(
        tableNumber,
      ); // Simplified find

      if (relevantBill != null &&
          relevantBill.id != null &&
          relevantBill.status == 'open') {
        bool success = await _billController.updateBillStatus(
          relevantBill.id!,
          'requested',
        );
        if (!mounted) return;
        if (!success) {
          _showSnackBar('Failed to request checkout.', isError: true);
        }
        // Let listener handle navigation/feedback
      } else if (relevantBill?.status == 'requested') {
        _showSnackBar(
          'Checkout has already been requested for this table.',
          isError: false,
        );
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
      if (mounted)
        _showSnackBar('Error requesting checkout: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isRequestingCheckout = false);
    }
  }

  // --- ( _showSnackBar function remains the same ) ---
  void _showSnackBar(String message, {bool isError = false}) {
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

  // --- ( Build Method remains the same structure ) ---
  @override
  Widget build(BuildContext context) {
    // ... (theme, totalItems, checkoutRequested setup) ...
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalItems = _selectedQuantities.values.fold(0, (sum, q) => sum + q);
    final bool checkoutRequested = _currentBillStatus == 'requested';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order - Table ${widget.tableId}'),
        elevation: 1,
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
      body: _buildBodyContent(theme, colorScheme),
      bottomNavigationBar: _buildBottomActionBar(
        theme,
        totalItems,
        checkoutRequested,
      ),
    );
  }

  // --- ( _buildBodyContent, _buildLoadingShimmerGrid, _buildErrorState, _buildEmptyState builders remain the same ) ---
  Widget _buildBodyContent(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoadingMenu) return _buildLoadingShimmerGrid();
    if (_menuErrorMessage != null) return _buildErrorState();
    if (_orderableItems.isEmpty) return _buildEmptyState(theme);

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 180).floor().clamp(2, 4);

    return GridView.builder(
      padding: const EdgeInsets.all(12.0).copyWith(bottom: 80),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        childAspectRatio: 0.7, // Keep aspect ratio for cards
      ),
      itemCount: _orderableItems.length,
      itemBuilder: (context, index) {
        final item = _orderableItems[index];
        // Pass the storage service instance to the card builder
        return _buildDishCard(theme, colorScheme, item, _storageService);
      },
    );
  }

  Widget _buildLoadingShimmerGrid() {
    /* ... */
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 180).floor().clamp(2, 4);
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: GridView.builder(
        padding: const EdgeInsets.all(12.0),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          childAspectRatio: 0.7, // Match aspect ratio
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias, // Ensure clipping
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 120,
                  color: Colors.white,
                ), // Image placeholder
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
                          margin: const EdgeInsets.only(bottom: 4),
                        ), // Name
                        Container(
                          width: 60,
                          height: 12,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 6),
                        ), // Price
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
            Text('Load Failed' /*...*/),
            const SizedBox(height: 8),
            Text(_menuErrorMessage ?? 'Could not load menu items.' /*...*/),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _loadMenuItems,
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
          Text('No Orderable Items' /*...*/),
          const SizedBox(height: 8),
          Text(
            'The menu currently has no items available for individual ordering.' /*...*/,
          ),
        ],
      ),
    );
  }

  // --- Dish Card Widget (UPDATED with FutureBuilder for Image) ---
  Widget _buildDishCard(
    ThemeData theme,
    ColorScheme colorScheme,
    FoodMenu item,
    FirebaseStorageService storageService, // Pass service instance
  ) {
    final itemId = item.id;
    final name = item.id; // Use ID as name for now
    final price = item.price;
    final imgPath = item.imgPath; // Get image path from model
    final quantity = _selectedQuantities[itemId] ?? 0;
    final isSelected = quantity > 0;
    final bool isBillRequested = _currentBillStatus == 'requested';

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
            // --- Image Section with FutureBuilder ---
            Container(
              height: 120, // Fixed height
              color: Colors.grey.shade200, // Background placeholder
              child:
                  (imgPath == null || imgPath.isEmpty)
                      // If no imgPath, show default icon immediately
                      ? const Center(
                        child: Icon(
                          Icons.fastfood_outlined,
                          size: 40,
                          color: Colors.grey,
                        ),
                      )
                      // If imgPath exists, use FutureBuilder to get URL
                      : FutureBuilder<String>(
                        future: storageService.getImage(
                          imgPath,
                        ), // Call service method
                        builder: (context, snapshot) {
                          // --- Loading State ---
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          // --- Error State ---
                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            print(
                              "Error loading image $imgPath: ${snapshot.error}",
                            );
                            return const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 40,
                                color: Colors.grey,
                              ),
                            );
                          }
                          // --- Success State ---
                          final imageUrl = snapshot.data!;
                          // Use CachedNetworkImage for performance and caching
                          return CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    size: 40,
                                    color: Colors.redAccent,
                                  ),
                                ),
                          );
                        },
                      ),
            ),

            // --- Content Section (remains the same) ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Item Name
                    Text(
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
                      currencyFormatter.format(price),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    // Quantity Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          /* Decrease */
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
                          onPressed:
                              quantity > 0 && !isBillRequested
                                  ? () => _updateQuantity(itemId, -1)
                                  : null,
                        ),
                        Padding(
                          /* Quantity */
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            '$quantity',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          /* Increase */
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

  // --- Bottom Action Bar (remains the same) ---
  Widget _buildBottomActionBar(
    ThemeData theme,
    int totalItems,
    bool checkoutRequested,
  ) {
    /* ... (implementation from previous example) ... */
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
                        isLabelVisible: totalItems > 0 && !checkoutRequested,
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
                disabledBackgroundColor: Colors.grey.shade400,
              ),
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
                        : Colors.blueAccent.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                disabledBackgroundColor: Colors.grey.shade400,
              ),
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
