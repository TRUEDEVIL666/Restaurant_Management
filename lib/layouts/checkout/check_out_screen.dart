import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_management/controllers/bill_controller.dart';
import 'package:restaurant_management/controllers/table_controller.dart';
import 'package:restaurant_management/models/bill.dart';
import 'package:restaurant_management/models/components/order.dart';
import 'package:restaurant_management/services/bill_printer.dart';
import 'package:restaurant_management/services/qr_generator.dart';

class CheckOutScreen extends StatefulWidget {
  final int tableIndex; // Using index as per original code

  const CheckOutScreen({super.key, required this.tableIndex});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  final BillController _billController = BillController();
  final TableController _tableController = TableController();
  final BillPrinter _billPrinter = BillPrinter(); // Instance of printer service
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );

  // --- State Variables ---
  bool _isLoading = true;
  Bill? _bill;
  List<BillOrder> _orders = [];
  double _subtotal = 0.0;
  double _taxAmount = 0.0;
  double _serviceChargeAmount = 0.0;
  double _discountAmount = 0.0;
  double _grandTotal = 0.0;
  String? _errorMessage;
  int selectedIndex = -1;
  bool showQR = false;
  bool _isProcessingPayment = false;
  bool _isPrinting = false;

  // --- Constants ---
  static const double TAX_RATE = 0.05;
  static const double SERVICE_CHARGE_RATE = 0.10;

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
      _discountAmount = 0.0;
      _isProcessingPayment = false;
      _isPrinting = false;
      selectedIndex = -1;
      showQR = false;
    });

    try {
      // *** Adjust bill fetching method as needed for your workflow ***
      // Fetching 'open' bill here. Manager might fetch 'requested'.
      final fetchedBill = await _billController.getRequestedBillByTableNumber(
        widget.tableIndex,
      );

      if (!mounted) return;
      if (fetchedBill == null) {
        setState(() {
          _errorMessage = 'No open bill found for Table ${widget.tableIndex}.';
          _isLoading = false;
        });
        return;
      }
      _bill = fetchedBill;

      final fetchedOrders = await _billController.getOrdersForBill(_bill!.id!);
      if (!mounted) return;
      _orders = fetchedOrders;

      final calculatedSubtotal = await _billController.getTotalBillCost(
        _bill!.id!,
      );
      if (!mounted) return;
      _subtotal = calculatedSubtotal;

      _taxAmount = _subtotal * TAX_RATE;
      _serviceChargeAmount = _subtotal * SERVICE_CHARGE_RATE;
      _grandTotal =
          _subtotal + _taxAmount + _serviceChargeAmount - _discountAmount;

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

  Future<void> _processPayment() async {
    if (_bill == null ||
        _bill!.id == null ||
        selectedIndex == -1 ||
        _isProcessingPayment ||
        _isPrinting)
      return;
    setState(() => _isProcessingPayment = true);
    bool success = false;
    try {
      // Ensure updateBillTotal exists and works
      bool totalUpdated = await _billController.updateBillTotal(
        _bill!.id!,
        _grandTotal,
      );
      bool statusUpdated = false, tableCheckedOut = false;
      if (totalUpdated)
        statusUpdated = await _billController.updateBillStatus(
          _bill!.id!,
          'paid',
        );
      if (statusUpdated)
        tableCheckedOut = await _tableController.checkOutTable(
          widget.tableIndex.toString(),
        ); // Pass int

      success = totalUpdated && statusUpdated && tableCheckedOut;

      if (!mounted) return;
      if (success) {
        _showSnackBar('Payment successful! Bill closed.');
        Navigator.of(context).pop();
      } else {
        String errorMsg = 'Failed to complete checkout process.';
        // Add more specific errors if needed
        _showSnackBar(errorMsg, isError: true);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error processing payment: $e', isError: true);
      success = false;
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _printBill() async {
    if (_bill == null || _isLoading || _isPrinting || _isProcessingPayment)
      return;
    setState(() => _isPrinting = true);
    _showSnackBar('Preparing bill for printing...');
    try {
      await _billPrinter.printBill(
        context: context,
        bill: _bill!,
        orders: _orders,
        subtotal: _subtotal,
        taxAmount: _taxAmount,
        serviceChargeAmount: _serviceChargeAmount,
        discountAmount: _discountAmount,
        grandTotal: _grandTotal,
        restaurantName: "My Awesome Restaurant",
        restaurantAddress: "123 Food Street",
        restaurantPhone: "555-1234",
        footerMessage: "Thank you for eating here!",
      );
    } catch (e) {
      /* Error shown by printBill */
      print("Print failed in UI: $e");
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout - Table ${widget.tableIndex}'),
        backgroundColor: colorScheme.surfaceContainerHighest,
        elevation: 1,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? _buildErrorState()
              : _bill == null
              ? Center(
                child: Text('No bill found for Table ${widget.tableIndex}.'),
              )
              : _buildCheckOutContent(textTheme, colorScheme),
    );
  }

  Widget _buildCheckOutContent(TextTheme textTheme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Order Items', style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          _buildOrderItemsList(textTheme),
          const SizedBox(height: 16),
          _buildSummaryCard(textTheme, colorScheme),
          const SizedBox(height: 16),
          Text('Select Payment Method', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildPaymentChoiceChips(colorScheme),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder:
                (child, animation) =>
                    SizeTransition(sizeFactor: animation, child: child),
            child:
                showQR
                    ? QRGeneratorWidget(amount: _grandTotal.toInt())
                    : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          _buildActionButtons(textTheme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Load Failed',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Could not load details.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _loadBillData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsList(TextTheme textTheme) {
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child:
          _orders.isEmpty
              ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('No items found for this bill.')),
              )
              : ListView.separated(
                // Use Separated for dividers
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: _orders.expand((o) => o.items).length,
                itemBuilder: (context, index) {
                  final allItems =
                      _orders.expand((order) => order.items).toList();
                  final item = allItems[index];
                  return _ItemTile(
                    name: item.name ?? 'Unknown',
                    quantity:
                        (item.quantity is num)
                            ? (item.quantity as num).toInt()
                            : 0,
                    price:
                        (item.unitPrice is num)
                            ? (item.unitPrice as num).toDouble()
                            : 0.0,
                    currencyFormatter: currencyFormatter,
                  );
                },
                separatorBuilder:
                    (context, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 16,
                      endIndent: 16,
                    ), // Add dividers
              ),
    );
  }

  Widget _buildSummaryCard(TextTheme textTheme, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bill Summary', style: textTheme.titleLarge),
            const Divider(height: 20),
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
            if (_discountAmount > 0)
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
    );
  }

  Widget _buildPaymentChoiceChips(ColorScheme colorScheme) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        ChoiceChip(
          label: const Text('Cash'),
          selected: selectedIndex == 0,
          onSelected: (s) => updateChoiceChip(0),
          avatar: Icon(
            Icons.money_rounded,
            color:
                selectedIndex == 0 ? colorScheme.onPrimary : Colors.green[700],
          ),
          selectedColor: colorScheme.primary,
          labelStyle: TextStyle(
            color:
                selectedIndex == 0
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
          ),
          checkmarkColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        ChoiceChip(
          label: const Text('UPI/QR'),
          selected: selectedIndex == 1,
          onSelected: (s) => updateChoiceChip(1),
          avatar: Icon(
            Icons.qr_code_scanner_rounded,
            color:
                selectedIndex == 1
                    ? colorScheme.onPrimary
                    : Colors.deepPurple[400],
          ),
          selectedColor: colorScheme.primary,
          labelStyle: TextStyle(
            color:
                selectedIndex == 1
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
          ),
          checkmarkColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ],
    );
  }

  Widget _buildActionButtons(TextTheme textTheme, ColorScheme colorScheme) {
    bool canProcessPayment =
        _bill != null &&
        selectedIndex != -1 &&
        !_isLoading &&
        !_isProcessingPayment &&
        !_isPrinting;
    bool canPrint =
        _bill != null /*&& _orders.isNotEmpty*/ &&
        !_isLoading &&
        !_isPrinting &&
        !_isProcessingPayment; // Allow printing empty bill summary?

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Column(
        children: [
          Wrap(
            spacing: 10.0,
            alignment: WrapAlignment.center,
            runSpacing: 10.0,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.discount_outlined),
                label: const Text('Discount'),
                onPressed:
                    _isLoading || _isPrinting || _isProcessingPayment
                        ? null
                        : () {
                          /* TODO */
                        },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange[800],
                  side: BorderSide(color: Colors.orange[300]!),
                ),
              ),
              OutlinedButton.icon(
                icon:
                    _isPrinting
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.print_outlined),
                label: Text(_isPrinting ? 'Printing...' : 'Print Bill'),
                onPressed: canPrint ? _printBill : null,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Void Bill'),
                onPressed:
                    _isLoading || _isPrinting || _isProcessingPayment
                        ? null
                        : () {
                          /* TODO */
                        },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.errorContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon:
                _isProcessingPayment
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.payment_rounded),
            label: Text(
              _isProcessingPayment ? 'Processing...' : 'Process Payment',
            ),
            onPressed: canProcessPayment ? _processPayment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              minimumSize: const Size(double.infinity, 50),
              disabledBackgroundColor: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    TextTheme textTheme,
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    final style =
        isTotal
            ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
            : textTheme.bodyMedium;
    final valueStyle = style?.copyWith(
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      color: valueColor,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: valueStyle)],
      ),
    );
  }
}

// --- Helper stateless widget for displaying an item in the list ---
class _ItemTile extends StatelessWidget {
  final String name;
  final int quantity;
  final double price;
  final NumberFormat currencyFormatter;

  const _ItemTile({
    Key? key,
    required this.name,
    required this.quantity,
    required this.price,
    required this.currencyFormatter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemTotal = price * quantity;
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 15,
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Text(
          quantity.toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
      title: Text(name, style: theme.textTheme.bodyMedium),
      subtitle: Text('@ ${currencyFormatter.format(price)} each'),
      trailing: Text(
        currencyFormatter.format(itemTotal),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
