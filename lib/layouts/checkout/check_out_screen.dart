import 'package:flutter/material.dart';

import '../../services/qr_generator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant App UI',
      theme: ThemeData(
        useMaterial3: true, // Using Material 3 design
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ), // Example color scheme
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CheckOutScreen(), // Show the checkout screen directly
      debugShowCheckedModeBanner: false,
    );
  }
}

class CheckOutScreen extends StatefulWidget {
  const CheckOutScreen({super.key});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  int selectedIndex = -1;
  bool showQR = false;

  void updateChoiceChip(int selected) {
    setState(() {
      selectedIndex = selected;
      showQR = selectedIndex == 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout - Table 12'),
        backgroundColor:
            colorScheme
                .surfaceContainerHighest, // A slightly different AppBar color
        elevation: 1,
      ),
      body: SingleChildScrollView(
        // Wrap the entire body content in SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Order Items Section ---
              Text('Order Items', style: textTheme.headlineSmall),
              const SizedBox(height: 8),

              // Wrap the Card with ListView for scrollable items
              Card(
                elevation: 2,
                clipBehavior:
                    Clip.antiAlias, // Ensures decoration respects border radius
                child: ListView(
                  shrinkWrap:
                      true, // Ensure the ListView doesn't take more space than needed
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  children: const [
                    _ItemTile(
                      name: 'Margherita Pizza',
                      quantity: 1,
                      price: 12.99,
                    ),
                    _ItemTile(
                      name: 'Spaghetti Carbonara',
                      quantity: 2,
                      price: 14.50,
                    ),
                    _ItemTile(name: 'Garlic Bread', quantity: 1, price: 5.50),
                    _ItemTile(name: 'Cola', quantity: 3, price: 2.50),
                    _ItemTile(name: 'Mineral Water', quantity: 1, price: 1.50),
                    // Add more placeholder items if needed
                  ],
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
                      _buildSummaryRow(textTheme, 'Subtotal:', '\$56.99'),
                      _buildSummaryRow(textTheme, 'Tax (GST 5%):', '+\$2.85'),
                      _buildSummaryRow(
                        textTheme,
                        'Service Charge (10%):',
                        '+\$5.70',
                      ),
                      _buildSummaryRow(
                        textTheme,
                        'Discount:',
                        '-\$5.00',
                        valueColor: Colors.orange[700],
                      ),
                      const Divider(height: 20),
                      _buildSummaryRow(
                        textTheme,
                        'Grand Total:',
                        '\$60.54',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Payment Method Selection (Visual Only) ---
              Text('Select Payment Method', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  ChoiceChip(
                    label: const Text('Cash'),
                    selected: selectedIndex == 0,
                    onSelected: (selected) {
                      updateChoiceChip(0);
                    },
                    selectedColor: colorScheme.primaryContainer,
                    avatar: Icon(Icons.money, color: Colors.green[700]),
                  ),
                  ChoiceChip(
                    label: const Text('Card'),
                    selected: selectedIndex == 1,
                    onSelected: (selected) {
                      updateChoiceChip(1);
                    },
                    avatar: Icon(Icons.credit_card, color: Colors.blue[700]),
                  ),
                  ChoiceChip(
                    label: const Text('UPI/QR'),
                    selected: selectedIndex == 2,
                    onSelected: (selected) {
                      updateChoiceChip(2);
                    },
                    avatar: Icon(Icons.qr_code, color: Colors.deepPurple[400]),
                  ),
                  ChoiceChip(
                    label: const Text('Online'),
                    selected: selectedIndex == 3,
                    onSelected: (selected) {
                      updateChoiceChip(3);
                    },
                    avatar: Icon(Icons.language, color: Colors.teal[400]),
                  ),
                ],
              ),

              showQR
                  ? const QRGeneratorWidget()
                  : const SizedBox(), // Show QR only if selected

              const SizedBox(height: 16), // Add some space before buttons
              // --- Action Buttons ---
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 8.0,
                ), // Add some bottom padding before buttons
                child: Wrap(
                  spacing: 10.0,
                  alignment: WrapAlignment.center,
                  runSpacing: 10.0,
                  children: [
                    // Apply Discount (Manager only?)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.discount_outlined),
                      label: const Text('Apply Discount'),
                      onPressed: () {
                        /* No-op */
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[800],
                        side: BorderSide(color: Colors.orange[300]!),
                      ),
                    ),

                    // Print Bill/Receipt Button
                    OutlinedButton.icon(
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('Print Bill'),
                      onPressed: () {
                        /* No-op */
                      },
                    ),

                    // Void Order (Manager only)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Void Bill'),
                      onPressed: () {
                        /* No-op */
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.errorContainer),
                      ),
                    ),

                    // Process Payment Button (Primary Action)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.payment),
                      label: const Text('Process Payment'),
                      onPressed: () {
                        /* No-op */
                      },
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

  // Helper widget for summary rows
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

// Helper stateless widget for displaying an item in the list
class _ItemTile extends StatelessWidget {
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
    return ListTile(
      dense: true, // Makes the list tile more compact
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
      subtitle: Text('@ \$${price.toStringAsFixed(2)} each'),
      trailing: Text(
        '\$${itemTotal.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      // You could add InkWell for tap effect if needed later
      // onTap: () { /* No-op */ }
    );
  }
}
