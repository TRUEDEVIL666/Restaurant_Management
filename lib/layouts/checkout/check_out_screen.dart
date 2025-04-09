import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For currency formatting
import 'package:restaurant_management/models/components/order.dart';

import '../../controllers/bill_controller.dart'; // Adjust path
// Import your models and controller
import '../../models/bill.dart';
import '../../services/qr_generator.dart'; // Assuming this exists

class CheckOutScreen extends StatefulWidget {
  final int tableIndex;

  const CheckOutScreen({super.key, required this.tableIndex});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  final BillController _billController =
      BillController(); // Get controller instance
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
  ); // Currency formatter

  // --- State Variables ---
  bool _isLoading = true; // Start loading initially
  Bill? _bill;
  List<BillOrder> _orders = [];
  double _subtotal = 0.0;
  double _taxAmount = 0.0;
  double _serviceChargeAmount = 0.0;
  double _discountAmount = 0.0; // Placeholder for discount logic
  double _grandTotal = 0.0;
  String? _errorMessage;

  // --- UI State ---
  int selectedIndex = -1; // For payment method
  bool showQR = false;

  // --- Constants (example rates) ---
  static const double TAX_RATE = 0.05; // 5%
  static const double SERVICE_CHARGE_RATE = 0.10; // 10%

  @override
  void initState() {
    super.initState();
    _loadBillData();
  }

  Future<void> _loadBillData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _bill = null;
      _orders = [];
      _subtotal = 0.0;
      _grandTotal = 0.0;
      _taxAmount = 0.0;
      _serviceChargeAmount = 0.0;
    });

    try {
      // 1. Fetch the open bill for the table
      final fetchedBill = await _billController.getOpenBillByTableNumber(
        widget.tableIndex,
      );

      if (fetchedBill == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'No open bill found for Table ${widget.tableIndex}.';
          _isLoading = false;
        });
        return;
      }

      // Ensure widget is still mounted before proceeding
      if (!mounted) return;
      _bill = fetchedBill; // Store the bill object

      // 2. Fetch the orders for this bill
      final fetchedOrders = await _billController.getOrdersForBill(
        _bill!.id ?? '',
      );
      if (!mounted) return;
      _orders = fetchedOrders;

      // 3. Calculate the subtotal (total cost before tax/service)
      // Note: getTotalBillCost calculates the sum of item totals (qty * price)
      final calculatedSubtotal = await _billController.getTotalBillCost(
        _bill!.id ?? '',
      );
      if (!mounted) return;

      // 4. Calculate other amounts
      _subtotal = calculatedSubtotal;
      _taxAmount = _subtotal * TAX_RATE;
      _serviceChargeAmount = _subtotal * SERVICE_CHARGE_RATE;
      // Discount logic would go here if implemented
      _grandTotal =
          _subtotal + _taxAmount + _serviceChargeAmount - _discountAmount;

      // Update state with all fetched/calculated data
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading bill data: $e");
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading bill details. Please try again.';
        _isLoading = false;
      });
      _showSnackBar(_errorMessage!, isError: true);
    }
  }

  void updateChoiceChip(int selected) {
    setState(() {
      selectedIndex = selected;
      showQR = selectedIndex == 1;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
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

  // --- Process Payment Logic ---
  Future<void> _processPayment() async {
    if (_bill == null) {
      _showSnackBar('Cannot process payment: Bill not loaded.', isError: true);
      return;
    }
    if (selectedIndex == -1) {
      _showSnackBar('Please select a payment method.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    bool success = false;
    try {
      // TODO: Update status to 'paid' or 'closed' based on your workflow
      success = await _billController.updateBillStatus(_bill!.id ?? '', 'paid');

      if (success) {
        _showSnackBar('Payment successful! Bill closed.');
        // Optionally navigate back or show a success screen
        if (mounted) Navigator.of(context).pop(); // Example: Go back
      } else {
        _showSnackBar(
          'Failed to update bill status. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error processing payment: $e', isError: true);
      success = false; // Ensure success is false on error
    } finally {
      // Hide loading indicator only if the widget is still mounted
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        // Use fetched bill ID or table number
        title: Text('Checkout - Table ${widget.tableIndex}'),
        backgroundColor: colorScheme.surfaceContainerHighest,
        elevation: 1,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(),
              ) // Show loading indicator
              : _errorMessage != null
              ? Center(
                // Show error message
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadBillData,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
              : _bill ==
                  null // Handle case where bill wasn't found but no error string set (shouldn't happen with current logic, but safe)
              ? Center(
                child: Text(
                  'No open bill found for Table ${widget.tableIndex}.',
                ),
              )
              : SingleChildScrollView(
                // Make content scrollable if bill IS loaded
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Order Items Section ---
                      Text('Order Items', style: textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        child:
                            _orders.isEmpty
                                ? const Padding(
                                  // Show message if no orders
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'No items ordered for this bill yet.',
                                    textAlign: TextAlign.center,
                                  ),
                                )
                                : ListView(
                                  // Use ListView only if orders exist
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(), // Prevent nested scrolling issues
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  // Flatten the list of items from all orders
                                  children:
                                      _orders
                                          .expand((order) => order.items)
                                          .map(
                                            (item) => _ItemTile(
                                              name: item.name,
                                              quantity: item.quantity,
                                              price: item.unitPrice,
                                            ),
                                          )
                                          .toList(),
                                ),
                      ),
                      const SizedBox(height: 16),

                      // --- Summary Section ---
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bill Summary', style: textTheme.titleLarge),
                              const Divider(height: 20),
                              // Use calculated values and formatter
                              _buildSummaryRow(
                                textTheme,
                                'Subtotal:',
                                currencyFormatter.format(_subtotal),
                              ),
                              _buildSummaryRow(
                                textTheme,
                                'Tax (${(TAX_RATE * 100).toStringAsFixed(0)}%):',
                                '+${currencyFormatter.format(_taxAmount)}',
                              ),
                              _buildSummaryRow(
                                textTheme,
                                'Service Charge (${(SERVICE_CHARGE_RATE * 100).toStringAsFixed(0)}%):',
                                '+${currencyFormatter.format(_serviceChargeAmount)}',
                              ),
                              // Keep discount row, value can be dynamic later
                              if (_discountAmount >
                                  0) // Only show if discount applied
                                _buildSummaryRow(
                                  textTheme,
                                  'Discount:',
                                  '-${currencyFormatter.format(_discountAmount)}',
                                  valueColor: Colors.orange[700],
                                ),
                              const Divider(height: 20),
                              _buildSummaryRow(
                                textTheme,
                                'Grand Total:',
                                currencyFormatter.format(_grandTotal),
                                isTotal: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Payment Method Selection ---
                      Text(
                        'Select Payment Method',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        /* ... ChoiceChips ... */
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: [
                          ChoiceChip(
                            label: const Text('Cash'),
                            selected: selectedIndex == 0,
                            onSelected: (s) => updateChoiceChip(0),
                            avatar: Icon(Icons.money, color: Colors.green[700]),
                          ),
                          ChoiceChip(
                            label: const Text('UPI/QR'),
                            selected: selectedIndex == 1,
                            onSelected: (s) => updateChoiceChip(1),
                            avatar: Icon(
                              Icons.qr_code,
                              color: Colors.deepPurple[400],
                            ),
                          ),
                        ],
                      ),

                      if (showQR)
                        const QRGeneratorWidget(), // Use if keyword for cleaner conditional UI

                      const SizedBox(height: 16),
                      // --- Action Buttons ---
                      Padding(
                        /* ... Wrap for Buttons ... */
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Wrap(
                          spacing: 10.0,
                          alignment: WrapAlignment.center,
                          runSpacing: 10.0,
                          children: [
                            // TODO: Implement Discount logic
                            OutlinedButton.icon(
                              icon: const Icon(Icons.discount_outlined),
                              label: const Text('Apply Discount'),
                              onPressed:
                                  _bill == null
                                      ? null
                                      : () {
                                        /* TODO */
                                      },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange[800],
                                side: BorderSide(color: Colors.orange[300]!),
                              ),
                            ),
                            // TODO: Implement Print logic
                            OutlinedButton.icon(
                              icon: const Icon(Icons.print_outlined),
                              label: const Text('Print Bill'),
                              onPressed:
                                  _bill == null
                                      ? null
                                      : () {
                                        /* TODO */
                                      },
                            ),
                            // TODO: Implement Void logic (Update status to 'void'?)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Void Bill'),
                              onPressed:
                                  _bill == null
                                      ? null
                                      : () {
                                        /* TODO */
                                      },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.error,
                                side: BorderSide(
                                  color: colorScheme.errorContainer,
                                ),
                              ),
                            ),
                            // --- Process Payment Button ---
                            ElevatedButton.icon(
                              icon: const Icon(Icons.payment),
                              label: const Text('Process Payment'),
                              // Disable if no bill, no payment method selected, or already loading
                              onPressed:
                                  (_bill == null ||
                                          selectedIndex == -1 ||
                                          _isLoading)
                                      ? null
                                      : _processPayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  // Helper widget for summary rows - remains the same
  Widget _buildSummaryRow(
    TextTheme textTheme,
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    // ... (implementation is the same)
    final style =
        isTotal
            ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
            : textTheme.bodyMedium;
    final valueStyle = style?.copyWith(color: valueColor);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: valueStyle)],
      ),
    );
  }
}

// Helper stateless widget for displaying an item in the list - remains the same
class _ItemTile extends StatelessWidget {
  // ... (implementation is the same)
  final String name;
  final int quantity;
  final double price;
  const _ItemTile({
    Key? key,
    required this.name,
    required this.quantity,
    required this.price,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final itemTotal = price * quantity;
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
    ); // Use formatter here too
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 15,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          quantity.toString(),
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(name),
      subtitle: Text(
        '@ ${currencyFormatter.format(price)} each',
      ), // Format price
      trailing: Text(
        currencyFormatter.format(itemTotal),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ), // Format total
    );
  }
}
