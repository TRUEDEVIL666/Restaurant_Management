import 'package:flutter/material.dart';

class QRGeneratorWidget extends StatelessWidget {
  final int amount;
  final String bankCode, accountNumber, accountName;

  const QRGeneratorWidget({
    super.key,
    required this.amount,
    required this.bankCode,
    required this.accountNumber,
    required this.accountName,
  });

  @override
  Widget build(BuildContext context) {
    String info = "Thanh toan hoa don ${DateTime.now().millisecondsSinceEpoch}";

    final qrData =
        "https://img.vietqr.io/image/"
        "$bankCode-$accountNumber-compact2.png"
        "?amount=$amount"
        "&addInfo=${Uri.encodeComponent(info)}"
        "&accountName=${Uri.encodeComponent(accountName)}";

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Quét để thanh toán: ${amount.toString()} VND"),
        SizedBox(height: 20),
        Image.network(qrData),
      ],
    );
  }
}
