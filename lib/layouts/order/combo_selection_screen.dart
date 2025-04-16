// lib/layouts/employee/combo_selection_screen.dart

// External Packages
import 'package:cloud_firestore/cloud_firestore.dart';
// Flutter Core & UI
import 'package:flutter/material.dart';
import 'package:restaurant_management/controllers/bill_controller.dart';
import 'package:restaurant_management/controllers/menu_controller.dart';
import 'package:restaurant_management/controllers/table_controller.dart';
import 'package:restaurant_management/layouts/menu/menu_screen.dart';
import 'package:restaurant_management/models/bill.dart';
import 'package:restaurant_management/models/menu.dart';
import 'package:restaurant_management/models/table.dart';
import 'package:shimmer/shimmer.dart'; // For loading shimmer

class ComboSelectionScreen extends StatefulWidget {
  // *** Use tableId (String) from Firestore documents ***
  final String tableId;

  const ComboSelectionScreen({super.key, required this.tableId});

  @override
  State<ComboSelectionScreen> createState() => _ComboSelectionScreenState();
}

class _ComboSelectionScreenState extends State<ComboSelectionScreen> {
  // --- Controllers ---
  final TableController _tableController = TableController();
  final FoodMenuController _menuController = FoodMenuController();
  final BillController _billController = BillController();

  // --- State Variables ---
  RestaurantTable? _currentTableData; // Store fetched table data
  List<FoodMenu> _availableCombos =
      []; // Store fetched combos from 'menu' collection
  bool _isLoading = true; // Start in loading state
  bool _isSaving = false; // Track saving operations
  String? _errorMessage; // Store error messages for display

  // --- Selection State (initialized during loading) ---
  String? selectedMealType; // 'buffet' or 'order'
  bool mealTypeLocked = false;
  String? selectedBuffetComboId; // Store the ID of the selected FoodMenu combo
  int buffetQuantity = 1; // Default quantity
  bool useDrinkCombo = true; // Default for drink package
  bool buffetOptionsLocked = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Load data when the screen initializes
  }

  // --- Load initial table data AND available combos ---
  Future<void> _loadInitialData() async {
    if (!mounted) return; // Check if the widget is still in the tree
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _availableCombos = []; // Clear previous combos if retrying
    });

    String? initialError; // Track errors across fetches

    try {
      // Fetch table data and all menu items concurrently
      final results = await Future.wait([
        _tableController.getItem(widget.tableId), // Fetch Table Data by ID
        _menuController.getAllActive(), // Fetch All Menu Items
      ]);

      if (!mounted) return; // Check again after asynchronous operations

      // --- Process Table Data ---
      final tableData = results[0] as RestaurantTable?;
      if (tableData == null) {
        initialError = 'Table ${widget.tableId} not found.';
      } else {
        _currentTableData = tableData; // Store fetched data

        // Optimization: If 'order' type is already locked, navigate immediately
        if (tableData.mealType == 'order' &&
            (tableData.mealTypeLocked ?? false)) {
          // Use microtask to schedule navigation after build cycle
          Future.microtask(() => _navigateToMenu(passedBuffetComboId: null));
          return; // Exit early, don't update state for UI rendering
        }

        // Pre-fill state from existing table data
        selectedMealType = tableData.mealType; // Could be null
        mealTypeLocked = tableData.mealTypeLocked ?? false;
        selectedBuffetComboId = tableData.buffetCombo; // Load saved combo ID
        buffetQuantity = tableData.buffetQuantity ?? 1;
        useDrinkCombo =
            tableData.useDrinkCombo ?? true; // Default to true if null
        buffetOptionsLocked = tableData.buffetOptionsLocked ?? false;
      }

      // --- Process Menu Data ---
      final allMenuItems = results[1] as List<FoodMenu>;
      // Filter menu items to get only those marked as combos
      _availableCombos = allMenuItems.where((item) => item.isCombo).toList();
      // Optional: Sort combos alphabetically by ID/name
      _availableCombos.sort((a, b) => a.id.compareTo(b.id));

      // --- Set Default Combo if needed ---
      if (tableData != null &&
          selectedBuffetComboId == null &&
          _availableCombos.isNotEmpty) {
        // If no combo was saved on the table, default to the first fetched combo
        selectedBuffetComboId = _availableCombos.first.id;
      } else if (tableData != null && selectedBuffetComboId != null) {
        // Ensure the saved combo ID still exists in the available list
        if (!_availableCombos.any((c) => c.id == selectedBuffetComboId)) {
          print(
            "Warning: Saved combo ID '$selectedBuffetComboId' not found in current menu. Resetting.",
          );
          // Reset to the first available combo or null if none exist
          selectedBuffetComboId =
              _availableCombos.isNotEmpty ? _availableCombos.first.id : null;
          // Optionally update the table data in Firestore here if you want to auto-correct invalid saved combos
        }
      }
    } catch (e) {
      print("Error loading initial data: $e");
      initialError = 'Error loading details. Please try again.';
    } finally {
      // Update state based on loading outcome, only if still mounted
      if (mounted) {
        setState(() {
          _errorMessage = initialError; // Set error message if one occurred
          _isLoading = false; // Finish loading state
        });
      }
    }
  }

  // --- Save meal type choice ---
  Future<void> _confirmAndLockMealType() async {
    // Prevent action if no meal type selected, no table data, or already saving
    if (selectedMealType == null || _currentTableData == null || _isSaving)
      return;
    if (!mounted) return; // Ensure widget is mounted

    setState(() => _isSaving = true); // Indicate saving process

    // Update local object first (optimistic UI update)
    _currentTableData!.mealType = selectedMealType;
    _currentTableData!.mealTypeLocked = true;

    try {
      // Attempt to update the item in Firestore
      bool success = await _tableController.updateItem(_currentTableData!);
      if (!mounted) return; // Check again after async operation

      if (success) {
        // Update UI state on successful save
        setState(() {
          mealTypeLocked = true; // Reflect locked state visually
          _isSaving = false; // Saving complete
          // If 'order' was just locked, navigate immediately
          if (selectedMealType == 'order') {
            _navigateToMenu(passedBuffetComboId: null);
          }
        });
        _showSnackBar('Meal type confirmed!'); // Show success feedback
      } else {
        // Revert local changes if Firestore update failed
        _currentTableData!.mealTypeLocked = false;
        _currentTableData!.mealType =
            null; // Or revert to previous state if tracked
        setState(() => _isSaving = false); // Saving complete (failed)
        _showSnackBar(
          'Failed to save meal type.',
          isError: true,
        ); // Show error feedback
      }
    } catch (e) {
      // Revert local changes on exception
      _currentTableData!.mealTypeLocked = false;
      _currentTableData!.mealType = null;
      if (!mounted) return;
      setState(() => _isSaving = false); // Saving complete (failed)
      _showSnackBar(
        'Error saving meal type: $e',
        isError: true,
      ); // Show error feedback
    }
  }

  // --- Save final choices and navigate ---
  Future<void> _confirmAndProceedToMenu() async {
    // Prevent action if missing data or already saving
    if (selectedMealType == null || _currentTableData == null || _isSaving)
      return;
    // Ensure a buffet combo is selected if meal type is buffet and combos are available
    if (selectedMealType == 'buffet' &&
        selectedBuffetComboId == null &&
        _availableCombos.isNotEmpty) {
      _showSnackBar('Please select a buffet combo.', isError: true);
      return;
    }
    if (!mounted) return;

    setState(() => _isSaving = true); // Indicate saving process

    // --- 1. Prepare Table Data Update ---
    // Update local object with final selections before saving
    _currentTableData!.isOccupied = true; // Ensure table is marked occupied
    _currentTableData!.openedAt ??=
        Timestamp.now(); // Set opened time if not already set
    _currentTableData!.mealTypeLocked = true;
    _currentTableData!.buffetOptionsLocked =
        true; // Lock everything on final confirm
    _currentTableData!.useDrinkCombo = useDrinkCombo;

    String? finalBuffetComboId =
        null; // To pass to MenuScreen and for order item

    if (selectedMealType == 'buffet') {
      _currentTableData!.buffetCombo =
          selectedBuffetComboId; // Save selected combo ID
      _currentTableData!.buffetQuantity = buffetQuantity;
      finalBuffetComboId =
          selectedBuffetComboId; // Set combo ID for order item & navigation
    } else {
      // 'order' type
      _currentTableData!.buffetCombo = null; // Clear buffet fields
      _currentTableData!.buffetQuantity = null;
    }

    // --- 2. Attempt to Save Table Data ---
    bool tableUpdateSuccess = false;
    bool buffetOrderSuccess = true; // Default to true if not buffet type

    try {
      tableUpdateSuccess = await _tableController.updateItem(
        _currentTableData!,
      );

      if (!mounted) return; // Check mount status after await

      if (!tableUpdateSuccess) {
        // If table update failed, show error and stop
        _showSnackBar('Failed to save table configuration.', isError: true);
        setState(() => _isSaving = false);
        return;
      }

      // --- 3. Add Buffet Combo as Order Item (if applicable) ---
      if (tableUpdateSuccess &&
          selectedMealType == 'buffet' &&
          finalBuffetComboId != null) {
        buffetOrderSuccess = await _addBuffetOrderToBill(
          finalBuffetComboId,
          buffetQuantity,
        );
        if (!mounted) return; // Check again

        if (!buffetOrderSuccess) {
          // If adding the buffet order failed, show error and stop (table data WAS saved though)
          // Optionally: Attempt to revert table data? More complex.
          _showSnackBar(
            'Failed to add buffet combo to the bill. Please add manually.',
            isError: true,
          );
          // We still might want to navigate, but inform the user. Let's prevent navigation for now.
          setState(() => _isSaving = false);
          return;
        }
      }

      // --- 4. Navigate Only if Everything Succeeded ---
      if (tableUpdateSuccess && buffetOrderSuccess) {
        // Navigate to the MenuScreen after successful save and potential order add
        _navigateToMenu(passedBuffetComboId: finalBuffetComboId);
        // No need to set _isSaving = false as we are navigating away
      }
      // else: Errors were handled and state was updated above
    } catch (e) {
      print("Error during confirm/proceed: $e");
      if (!mounted) return;
      // Revert lock state on general exception (optional)
      _currentTableData!.buffetOptionsLocked = false;
      _currentTableData!.mealTypeLocked =
          false; // Might need more nuanced revert
      setState(() => _isSaving = false);
      _showSnackBar('An unexpected error occurred: $e', isError: true);
    } finally {
      // Ensure saving state is reset if we didn't navigate away due to an error handled above
      if (mounted && !(tableUpdateSuccess && buffetOrderSuccess)) {
        setState(() => _isSaving = false);
      }
    }
  }

  // --- Helper Function to Add Buffet Order Item ---
  Future<bool> _addBuffetOrderToBill(String comboId, int quantity) async {
    if (_currentTableData == null) return false; // Should not happen here

    String? billId;
    int? tableNumber = int.tryParse(
      widget.tableId.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (tableNumber == null) {
      print("Error adding buffet order: Invalid table ID format.");
      return false;
    }

    try {
      // 1. Find or Create Bill ID
      Bill? openBill = await _billController.getOpenBillByTableNumber(
        tableNumber,
      );
      if (openBill == null) {
        DocumentReference? billRef = await _billController.addBill(tableNumber);
        if (billRef != null) {
          billId = billRef.id;
        } else {
          throw Exception('Failed to create a new bill for buffet order.');
        }
      } else {
        billId = openBill.id!;
      }

      // 2. Get Combo Details (Price)
      // Find the selected combo in the already fetched list
      final selectedCombo = _availableCombos.firstWhere(
        (c) => c.id == comboId,
        // Provide a default if somehow not found (shouldn't happen if selection logic is right)
        orElse:
            () => FoodMenu(id: comboId, imgPath: "", isCombo: true, price: 0.0),
      );

      // 3. Format the Order Item
      final orderItem = {
        'name': selectedCombo.id,
        'quantity': quantity, // Use the selected buffet quantity
        'unitPrice': selectedCombo.price,
      };

      // 4. Add to Bill's Subcollection
      return await _billController.addOrderToBill(billId, [
        orderItem,
      ]); // Pass as a list
    } catch (e) {
      print("Error adding buffet order item to bill: $e");
      return false;
    }
  }

  // --- Navigation Helper (remains the same) ---
  void _navigateToMenu({required String? passedBuffetComboId}) {
    // ... (implementation as before) ...
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => MenuScreen(
              tableId: widget.tableId,
              buffetCombo: passedBuffetComboId, // Pass the ID
            ),
      ),
    );
  }

  // --- UI Helpers ---
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return; // Don't show snackbar if widget is disposed
    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar(); // Remove previous snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating, // Make it float
        margin: const EdgeInsets.all(10), // Add margin
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ), // Rounded corners
      ),
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Configure Order - Table ${widget.tableId}'),
        backgroundColor: theme.colorScheme.surface, // Use surface color
        elevation: 1,
      ),
      body:
          _isLoading
              ? _buildLoadingShimmer() // Show shimmer effect while loading data
              : _errorMessage != null
              ? _buildErrorState() // Show error message if loading failed
              : _buildMainContent(theme, colorScheme), // Build main UI content
      // Show bottom button only after meal type is locked and not currently saving/loading/error
      bottomNavigationBar:
          (mealTypeLocked && !_isSaving && !_isLoading && _errorMessage == null)
              ? _buildConfirmAndProceedButton(theme)
              : null,
    );
  }

  // --- Loading State UI (Shimmer Effect) ---
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300, // Base color for shimmer
      highlightColor: Colors.grey.shade100, // Highlight color
      child: SingleChildScrollView(
        // Allow scrolling even for shimmer placeholders
        physics:
            const NeverScrollableScrollPhysics(), // Prevent scrolling during shimmer
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder for "Step 1" title
            Container(
              width: 150,
              height: 24.0,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 4),
            ),
            const SizedBox(height: 12),
            // Placeholders for Meal Type cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Placeholder for "Step 2" title or Confirm button area
            Container(
              width: 200,
              height: 24.0,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 4),
            ),
            const SizedBox(height: 12),
            // Placeholder for Buffet/Order Options Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Placeholder for "Select Buffet Combo" title
                  Container(
                    width: 180,
                    height: 20.0,
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 16),
                  // Placeholder for combo selection cards
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(
                      3,
                      (_) => Container(
                        width: 100,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Placeholder for divider
                  Container(
                    width: double.infinity,
                    height: 1.0,
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 16),
                  // Placeholder for "Buffet Guests" title
                  Container(
                    width: 150,
                    height: 20.0,
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 12),
                  // Placeholder for quantity selector
                  Container(
                    width: 200,
                    height: 40,
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 16),
                  // Placeholder for divider
                  Container(
                    width: double.infinity,
                    height: 1.0,
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 16),
                  // Placeholder for Drink switch
                  Container(
                    width: double.infinity,
                    height: 50,
                    color: Colors.grey.shade200,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Error State UI ---
  Widget _buildErrorState() {
    final theme = Theme.of(context);
    return Center(
      // Center the error content
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use minimum space
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: theme.colorScheme.error,
              size: 48,
            ), // Error icon
            const SizedBox(height: 16),
            Text(
              // Error title
              'Load Failed',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              // Error message details
              _errorMessage ?? 'Could not load table details.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              // Retry button
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _loadInitialData, // Call load function again on press
            ),
          ],
        ),
      ),
    );
  }

  // --- Main Content Area Builder ---
  Widget _buildMainContent(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      // Make content scrollable
      // Add padding, leaving space at the bottom for the navigation bar button
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align content to the start
        children: [
          // --- 1. Meal Type Selection Section ---
          _buildSectionTitle(theme, 'Step 1: Choose Meal Type'),
          const SizedBox(height: 12),
          _buildMealTypeSelector(
            theme,
            colorScheme,
          ), // Meal type cards (Buffet/A La Carte)
          // --- 2. Conditional Options Area (Step 2 onwards) ---
          // Uses AnimatedSwitcher for smooth transition when mealTypeLocked changes
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350), // Transition duration
            // Define fade and size transition
            transitionBuilder:
                (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1.0,
                    child: child,
                  ),
                ),
            // Conditionally show further options OR the confirm button for meal type
            child:
                mealTypeLocked
                    ? _buildOptionsArea(
                      theme,
                      colorScheme,
                    ) // Show Step 2+ content if locked
                    : _buildConfirmMealTypeButton(
                      theme,
                    ), // Show confirm button if not locked
          ),
        ],
      ),
    );
  }

  // --- Section Title Helper ---
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 4.0,
        top: 8.0,
      ), // Add some top padding too
      child: Text(
        title,
        // Use titleLarge style for section titles
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // --- Meal Type Selection UI ---
  Widget _buildMealTypeSelector(ThemeData theme, ColorScheme colorScheme) {
    // Use Stack to overlay lock icon when mealTypeLocked is true
    return Stack(
      children: [
        Row(
          // Row for Buffet and A La Carte options
          children: [
            Expanded(
              // Buffet card takes available space
              child: _buildTypeCard(
                theme: theme,
                colorScheme: colorScheme,
                label: 'Buffet',
                icon: Icons.restaurant_menu_rounded, // Specific icon for buffet
                value: 'buffet',
                groupValue: selectedMealType, // Current selection
                isSelected: selectedMealType == 'buffet', // Check if selected
                // Disable tap if meal type is locked
                onTap:
                    mealTypeLocked
                        ? null
                        : () => setState(() => selectedMealType = 'buffet'),
              ),
            ),
            const SizedBox(width: 12), // Spacing between cards
            Expanded(
              // A La Carte card takes available space
              child: _buildTypeCard(
                theme: theme,
                colorScheme: colorScheme,
                label: 'A La Carte',
                icon: Icons.menu_book_rounded, // Specific icon for menu/order
                value: 'order',
                groupValue: selectedMealType,
                isSelected: selectedMealType == 'order',
                // Disable tap if meal type is locked
                onTap:
                    mealTypeLocked
                        ? null
                        : () => setState(() => selectedMealType = 'order'),
              ),
            ),
          ],
        ),
        // --- Lock Overlay ---
        // Display overlay only if meal type is locked
        if (mealTypeLocked)
          Positioned.fill(
            // Cover the entire Row area
            child: Container(
              decoration: BoxDecoration(
                // Semi-transparent black background
                color: Colors.black.withOpacity(0.15),
                // Match the card border radius
                borderRadius: BorderRadius.circular(12),
              ),
              // Centered lock icon
              child: Icon(
                Icons.lock_outline_rounded,
                color: Colors.white.withOpacity(0.7),
                size: 40,
              ),
            ),
          ),
      ],
    );
  }

  // --- Custom Card for Meal Type ---
  Widget _buildTypeCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String label,
    required IconData icon,
    required String value,
    required String? groupValue, // Currently selected value
    required bool isSelected, // Is this card selected?
    required VoidCallback? onTap, // Action on tap (null if disabled)
  }) {
    // Define colors based on selection state for better visual feedback
    final selectedColor = colorScheme.primary;
    final unselectedColor =
        colorScheme.surfaceVariant; // Use surface variant for unselected
    final selectedContentColor = colorScheme.onPrimary;
    final unselectedContentColor = colorScheme.onSurfaceVariant;

    return Card(
      elevation: isSelected ? 4 : 1, // More elevation when selected
      margin: EdgeInsets.zero, // Control spacing with SizedBox outside
      color: isSelected ? selectedColor : unselectedColor, // Dynamic background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Consistent border radius
        // Dynamic border based on selection
        side: BorderSide(
          color:
              isSelected ? selectedColor : colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 1.5 : 1, // Thicker border when selected
        ),
      ),
      child: InkWell(
        // Make the card tappable
        onTap: onTap, // Use the provided tap callback
        borderRadius: BorderRadius.circular(
          12,
        ), // Match shape for ripple effect
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          child: Column(
            // Arrange icon and text vertically
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                // Display icon
                icon,
                color:
                    isSelected
                        ? selectedContentColor
                        : unselectedContentColor, // Dynamic icon color
                size: 32,
              ),
              const SizedBox(height: 8), // Spacing
              Text(
                // Display label
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color:
                      isSelected
                          ? selectedContentColor
                          : unselectedContentColor, // Dynamic text color
                  fontWeight: FontWeight.w600, // Slightly bolder text
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Confirm Meal Type Button ---
  Widget _buildConfirmMealTypeButton(ThemeData theme) {
    // Only show if a type is selected AND it's not yet locked
    if (selectedMealType == null || mealTypeLocked) {
      return const SizedBox.shrink(); // Return empty space otherwise
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 12.0), // Add padding
      child: Center(
        // Center the button
        child: ElevatedButton.icon(
          // Show loading indicator inside button if saving
          icon:
              _isSaving
                  ? Container(
                    width: 20,
                    height: 20,
                    padding: const EdgeInsets.all(2.0),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Icon(Icons.check_circle_outline),
          label: Text(_isSaving ? 'Confirming...' : 'Confirm Meal Type'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: theme.textTheme.titleMedium, // Use slightly larger text
          ),
          // Disable button while saving
          onPressed: _isSaving ? null : _confirmAndLockMealType,
        ),
      ),
    );
  }

  // --- Area for Buffet/Order Options (Shown after Meal Type Lock) ---
  Widget _buildOptionsArea(ThemeData theme, ColorScheme colorScheme) {
    // This area appears after Step 1 is confirmed
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            theme,
            'Step 2: Configure Details',
          ), // Section title
          const SizedBox(height: 12),
          // Conditionally display options based on the selected meal type
          if (selectedMealType == 'buffet')
            _buildBuffetOptionsSection(
              theme,
              colorScheme,
            ), // Show buffet config

          if (selectedMealType == 'order')
            _buildOrderOptionsSection(
              theme,
              colorScheme,
            ), // Show A La Carte config
        ],
      ),
    );
  }

  // --- Buffet Specific Options ---
  Widget _buildBuffetOptionsSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      // Group buffet options within a styled Card
      elevation: 1,
      // Use a slightly different background for visual separation
      color: theme.cardColor, // Or colorScheme.surfaceContainerLow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          // Stack allows overlaying the lock icon if needed
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title for combo selection
                Text(
                  'Select Buffet Combo:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Display combo selection cards or empty message
                _availableCombos.isEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'No buffet combos currently available.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ),
                    )
                    : Wrap(
                      // Arrange combo cards in a Wrap for responsiveness
                      spacing: 10, // Horizontal space between cards
                      runSpacing: 10, // Vertical space between cards
                      children:
                          _availableCombos.map((combo) {
                            // Map fetched combos to cards
                            return _buildComboCard(
                              theme: theme,
                              colorScheme: colorScheme,
                              comboId:
                                  combo.id, // Pass the Firestore document ID
                              // Use combo.id as name for now. Add a 'name' field to FoodMenu model for better display.
                              comboName: combo.id,
                              isSelected:
                                  selectedBuffetComboId ==
                                  combo.id, // Check if this combo is selected
                              // Disable tap if options are locked
                              onTap:
                                  buffetOptionsLocked
                                      ? null
                                      : () => setState(
                                        () => selectedBuffetComboId = combo.id,
                                      ), // Update selected ID
                            );
                          }).toList(),
                    ),
                const Divider(height: 24, thickness: 0.5), // Visual separator
                // Title for quantity selection
                Text(
                  'Buffet Guests:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildQuantitySelector(
                  theme,
                  colorScheme,
                ), // Quantity +/- buttons and display
                const Divider(height: 24, thickness: 0.5), // Visual separator
                // Drink combo switch
                _buildDrinkComboSwitch(
                  theme,
                  colorScheme,
                  isBuffet: true,
                ), // Pass isBuffet=true
              ],
            ),
            // --- Lock Overlay for Buffet Options ---
            // Display overlay only if options are locked
            if (buffetOptionsLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(
                      0.15,
                    ), // Semi-transparent overlay
                    borderRadius: BorderRadius.circular(12), // Match card shape
                  ),
                  // Centered lock icon
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white.withOpacity(0.7),
                    size: 40,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Custom Card for Buffet Combo Selection ---
  Widget _buildComboCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String comboId, // Firestore document ID
    required String comboName, // Display name (currently ID)
    required bool isSelected,
    required VoidCallback? onTap, // Tap callback (null if disabled)
  }) {
    // Define colors based on selection state
    final selectedColor =
        colorScheme.tertiaryContainer; // Use tertiary color for selected combo
    final unselectedColor =
        colorScheme.surfaceContainerHighest; // Brighter surface for unselected
    final selectedContentColor = colorScheme.onTertiaryContainer;
    final unselectedContentColor = colorScheme.onSurfaceVariant;

    return InkWell(
      // Make the card tappable
      onTap: onTap,
      borderRadius: BorderRadius.circular(8), // Rounded corners for tap effect
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ), // Internal padding
        decoration: BoxDecoration(
          color:
              isSelected
                  ? selectedColor
                  : unselectedColor, // Dynamic background
          borderRadius: BorderRadius.circular(8),
          // Dynamic border
          border: Border.all(
            color:
                isSelected
                    ? colorScheme.tertiary
                    : colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 1.5 : 1, // Thicker border if selected
          ),
        ),
        child: Text(
          comboName, // Display the combo name/ID
          style: theme.textTheme.titleSmall?.copyWith(
            // Dynamic text color and weight
            color: isSelected ? selectedContentColor : unselectedContentColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // --- Quantity Selector UI ---
  Widget _buildQuantitySelector(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start, // Align controls to the left
      children: [
        // Decrease Button (-)
        SizedBox(
          // Constrain button size for consistent look
          width: 40,
          height: 40,
          child: OutlinedButton(
            // Disable if options locked or quantity is already 1
            onPressed:
                buffetOptionsLocked || buffetQuantity <= 1
                    ? null
                    : () =>
                        setState(() => buffetQuantity--), // Decrease quantity
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero, // Remove default padding
              shape: const CircleBorder(), // Make it circular
              side: BorderSide(
                color: colorScheme.outline.withOpacity(0.5),
              ), // Standard border
              // Grey out icon when disabled
              disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
            ),
            child: const Icon(Icons.remove, size: 18),
          ),
        ),
        // Quantity Display
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          ), // Space around number
          child: Text(
            '$buffetQuantity', // Display current quantity
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Increase Button (+)
        SizedBox(
          // Constrain button size
          width: 40,
          height: 40,
          child: OutlinedButton(
            // Disable if options locked
            onPressed:
                buffetOptionsLocked
                    ? null
                    : () =>
                        setState(() => buffetQuantity++), // Increase quantity
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
              side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
              disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
            ),
            child: const Icon(Icons.add, size: 18),
          ),
        ),
      ],
    );
  }

  // --- A La Carte Specific Options ---
  Widget _buildOrderOptionsSection(ThemeData theme, ColorScheme colorScheme) {
    // Group A La Carte options within a styled Card
    return Card(
      elevation: 1,
      color: theme.cardColor, // Or colorScheme.surfaceContainerLow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        // Less bottom padding as there's less content
        padding: const EdgeInsets.only(
          top: 16.0,
          left: 16.0,
          right: 16.0,
          bottom: 8.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title (optional, could be simpler)
            Text(
              'Add-ons:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 0), // Less space before switch
            // Drink combo switch (reused)
            _buildDrinkComboSwitch(theme, colorScheme, isBuffet: false),
            const SizedBox(height: 12),
            // Informational text
            Center(
              child: Text(
                'Items will be added on the next screen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // --- Drink Combo Switch (Used by both Buffet and Order) ---
  Widget _buildDrinkComboSwitch(
    ThemeData theme,
    ColorScheme colorScheme, {
    required bool isBuffet,
  }) {
    // Determine if the switch should be disabled
    // For buffet, disable if buffetOptionsLocked is true
    // For A La Carte, it's currently never locked *at this stage*
    final bool isDisabled = isBuffet ? buffetOptionsLocked : false;

    // Use SwitchListTile for label, subtitle, and switch alignment
    return SwitchListTile(
      title: Text(
        // Main label
        'Include Drink Package',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        // Descriptive subtitle
        'Unlimited soft drinks & iced tea', // Customize as needed
        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
      ),
      value: useDrinkCombo, // Current state of the switch
      // Update state on change, only if not disabled
      onChanged:
          isDisabled ? null : (value) => setState(() => useDrinkCombo = value),
      activeColor: colorScheme.primary, // Color when switch is ON
      contentPadding:
          EdgeInsets.zero, // Remove default padding for tighter layout
      visualDensity: VisualDensity.compact, // Reduce vertical space
    );
  }

  // --- Bottom Confirm Button ---
  Widget _buildConfirmAndProceedButton(ThemeData theme) {
    // This button appears at the bottom when meal type is locked
    return Container(
      // Add padding and background matching the scaffold
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 12.0,
      ), // Account for safe area
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        // Add a subtle shadow to separate from content
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -4), // Shadow above the container
          ),
        ],
      ),
      // Use ElevatedButton for the main action
      child: ElevatedButton(
        // Disable button if currently saving
        onPressed: _isSaving ? null : _confirmAndProceedToMenu,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              Colors.green.shade600, // Use a distinct success color
          foregroundColor: Colors.white, // Text color
          padding: const EdgeInsets.symmetric(vertical: 14), // Button padding
          // Style for button text
          textStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          minimumSize: const Size(
            double.infinity,
            50,
          ), // Make button full width
        ),
        // Show loading indicator inside button OR text
        child:
            _isSaving
                ? const SizedBox(
                  // Container for spinner
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
                : const Text('Confirm & Proceed to Menu'), // Button text
      ),
    );
  }
}
