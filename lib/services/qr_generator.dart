import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting amount
import 'package:restaurant_management/controllers/bank_controller.dart';
import 'package:restaurant_management/models/bank.dart';

class QRGeneratorWidget extends StatefulWidget {
  final int amount; // Amount remains required

  const QRGeneratorWidget({super.key, required this.amount});

  @override
  State<QRGeneratorWidget> createState() => _QRGeneratorWidgetState();
}

class _QRGeneratorWidgetState extends State<QRGeneratorWidget> {
  final BankController _bankController = BankController();
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN', // Use Vietnamese locale for VND
    symbol: '₫', // VND symbol
    decimalDigits: 0, // No decimals for VND typically
  );

  // State variables
  List<Bank> _banks = [];
  Bank? _selectedBank; // Holds the currently selected bank account
  bool _isLoading = true;
  String? _errorMessage;
  String? _qrDataUrl; // Holds the generated QR URL

  @override
  void initState() {
    super.initState();
    _fetchBanks();
  }

  Future<void> _fetchBanks() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _banks = [];
      _selectedBank = null; // Reset selection on fetch
      _qrDataUrl = null; // Clear previous QR
    });

    try {
      final fetchedBanks = await _bankController.getAll();
      if (!mounted) return;

      setState(() {
        _banks = fetchedBanks;
        _isLoading = false;
        // If only one bank account exists, pre-select it
        if (_banks.length == 1) {
          _selectedBank = _banks.first;
          _generateQrData(); // Generate QR for the pre-selected bank
        }
      });
    } catch (e) {
      print("Error fetching banks: $e");
      if (!mounted) return;
      setState(() {
        _errorMessage = "Could not load bank accounts.";
        _isLoading = false;
      });
    }
  }

  void _generateQrData() {
    if (_selectedBank == null) {
      setState(() {
        _qrDataUrl = null; // Clear QR if no bank is selected
      });
      return;
    }

    // Generate unique info for each transaction attempt if needed
    String info = "TT HoaDon ${DateTime.now().millisecondsSinceEpoch}";

    // Construct the URL using selected bank details
    // Ensure properties exist and are not null in your Bank model!
    final url =
        "https://img.vietqr.io/image/"
        "${_selectedBank!.bankCode}-${_selectedBank!.accountNumber}-compact2.png"
        "?amount=${widget.amount}"
        "&addInfo=${Uri.encodeComponent(info)}"
        "&accountName=${Uri.encodeComponent(_selectedBank!.accountName)}";

    setState(() {
      _qrDataUrl = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 30),
            const SizedBox(height: 8),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _fetchBanks, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_banks.isEmpty) {
      return const Center(child: Text('No bank accounts configured.'));
    }

    // --- Main Content: Dropdown + QR Code ---
    return Column(
      mainAxisAlignment: MainAxisAlignment.start, // Align content to start
      crossAxisAlignment:
          CrossAxisAlignment.stretch, // Stretch children horizontally
      children: [
        // --- Bank Selection Dropdown ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: DropdownButtonFormField<Bank>(
            value: _selectedBank,
            isExpanded: true, // Make dropdown take available width
            decoration: InputDecoration(
              labelText: 'Select Bank Account',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10.0,
              ),
            ),
            hint: const Text('Choose an account...'),
            items:
                _banks.map((Bank bank) {
                  return DropdownMenuItem<Bank>(
                    value: bank,
                    // Display relevant info in the dropdown list
                    child: Text(
                      "${bank.accountName} - ${bank.accountNumber}",
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
            onChanged: (Bank? newValue) {
              setState(() {
                _selectedBank = newValue;
                _generateQrData(); // Generate new QR when selection changes
              });
            },
            validator:
                (value) => value == null ? 'Please select an account' : null,
          ),
        ),

        const SizedBox(height: 20),

        // --- QR Code Display (only if bank selected and URL generated) ---
        if (_selectedBank != null && _qrDataUrl != null)
          Column(
            children: [
              Text(
                "Scan QR to pay: ${currencyFormatter.format(widget.amount)}",
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Image.network(
                _qrDataUrl!,
                // Add loading/error builders for the image itself
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    heightFactor: 2, // Adjust size while loading
                    child: CircularProgressIndicator(),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Could not load QR code',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          )
        else if (_selectedBank != null && _qrDataUrl == null)
          // Handle case where generation might fail silently (shouldn't happen)
          const Center(child: Text("Generating QR..."))
        else
          // Prompt to select an account if none is chosen yet
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                "Please select a bank account above to generate the QR code.",
              ),
            ),
          ),
      ],
    );
  }
}
