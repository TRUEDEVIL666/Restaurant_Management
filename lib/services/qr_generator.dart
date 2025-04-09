import 'package:flutter/material.dart';

class QRGeneratorWidget extends StatelessWidget {
  final int amount; // số tiền bill, ví dụ: 500000
  final String bankCode = "VCB";
  final String accountNumber = "1031400903";
  final String accountName = "LUONG CANH PHONG";

  const QRGeneratorWidget({super.key, this.amount = 50000});

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
