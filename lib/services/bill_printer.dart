import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:restaurant_management/models/bill.dart';
import 'package:restaurant_management/models/components/order.dart';

class BillPrinter {
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'd',
  );
  final DateFormat dateTimeFormatter = DateFormat('dd/MM/yyyy hh:mm a');

  Future<void> printBill({
    required BuildContext context, // Pass context for potential error display
    required Bill bill,
    required List<BillOrder> orders,
    required double subtotal,
    required double taxAmount,
    required double serviceChargeAmount,
    required double discountAmount,
    required double grandTotal,
    String? restaurantName,
    String? restaurantAddress,
    String? restaurantPhone,
    String? footerMessage,
  }) async {
    try {
      final pdf = await _generatePdf(
        bill: bill,
        orders: orders,
        subtotal: subtotal,
        taxAmount: taxAmount,
        serviceChargeAmount: serviceChargeAmount,
        discountAmount: discountAmount,
        grandTotal: grandTotal,
        restaurantName:
            restaurantName ?? "Your Restaurant Name", // Provide default
        restaurantAddress: restaurantAddress,
        restaurantPhone: restaurantPhone,
        footerMessage:
            footerMessage ?? "Thank You! Please Come Again!", // Provide default
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf,
        name:
            'Bill_Table_${bill.tableNumber}_${bill.id?.substring(0, 5) ?? ""}',
        format: PdfPageFormat.roll80, // Hint for the print dialog
      );
    } catch (e) {
      print("Error generating or printing PDF: $e");
      // Show error message to the user using the passed context
      if (context.mounted) {
        // Check if context is still valid
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Printing failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<Uint8List> _generatePdf({
    required Bill bill,
    required List<BillOrder> orders,
    required double subtotal,
    required double taxAmount,
    required double serviceChargeAmount,
    required double discountAmount,
    required double grandTotal,
    required String restaurantName,
    String? restaurantAddress,
    String? restaurantPhone,
    required String footerMessage,
  }) async {
    final pdf = pw.Document(author: 'Restaurant Management App');

    // --- Use Default PDF Fonts (Helvetica) ---
    final baseTextStyle = pw.TextStyle(fontSize: 8);
    final boldTextStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 8,
    );
    final largeBoldTextStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 10,
    );
    final headerTextStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 12,
    );

    final allItems = orders.expand((order) => order.items).toList();

    // Define margins for the page content
    const double sideMarginValue = 3 * PdfPageFormat.mm;
    const double topBottomMarginValue = 5 * PdfPageFormat.mm;

    pdf.addPage(
      // --- Use pw.Page ---
      pw.Page(
        // Use the roll80 format directly
        pageFormat: PdfPageFormat.roll80.copyWith(
          marginTop: topBottomMarginValue,
          marginBottom: topBottomMarginValue,
          marginLeft: sideMarginValue,
          marginRight: sideMarginValue,
        ),
        build: (pw.Context context) {
          // Wrap all content in a single Column
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- Restaurant Header ---
              pw.Center(child: pw.Text(restaurantName, style: headerTextStyle)),
              if (restaurantAddress != null && restaurantAddress.isNotEmpty)
                pw.SizedBox(height: 2),
              if (restaurantAddress != null && restaurantAddress.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    restaurantAddress,
                    style: baseTextStyle,
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              if (restaurantPhone != null && restaurantPhone.isNotEmpty)
                pw.SizedBox(height: 1),
              if (restaurantPhone != null && restaurantPhone.isNotEmpty)
                pw.Center(
                  child: pw.Text('Tel: $restaurantPhone', style: baseTextStyle),
                ),
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Text('RECEIPT', style: largeBoldTextStyle)),
              pw.SizedBox(height: 8),

              // --- Bill Information ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Table: ${bill.tableNumber}', style: boldTextStyle),
                  pw.Text(
                    dateTimeFormatter.format(bill.timestamp.toDate()),
                    style: baseTextStyle,
                  ),
                ],
              ),
              pw.Text(
                'Bill No: ${bill.id?.substring(0, 8) ?? 'N/A'}',
                style: baseTextStyle.copyWith(fontSize: 7),
              ),
              pw.Divider(height: 10, thickness: 0.5),

              // --- Items Header ---
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text('Item', style: boldTextStyle),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'Qty',
                      style: boldTextStyle,
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Price',
                      style: boldTextStyle,
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Total',
                      style: boldTextStyle,
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
              pw.Divider(
                height: 5,
                thickness: 0.5,
                borderStyle: pw.BorderStyle.dashed,
              ),

              // --- Item List ---
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children:
                    allItems.map((item) {
                      final String name = item.name?.toString() ?? 'Unknown';
                      final int quantity =
                          (item.quantity is num)
                              ? (item.quantity as num).toInt()
                              : 0;
                      final double price =
                          (item.unitPrice is num)
                              ? (item.unitPrice as num).toDouble()
                              : 0.0;
                      final double total = price * quantity;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 5,
                              child: pw.Text(name, style: baseTextStyle),
                            ),
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text(
                                quantity.toString(),
                                style: baseTextStyle,
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                currencyFormatter.format(price),
                                style: baseTextStyle,
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                currencyFormatter.format(total),
                                style: baseTextStyle,
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
              pw.Divider(height: 10, thickness: 0.5),

              // --- Totals Section ---
              _buildPdfTotalRow(
                'Subtotal:',
                currencyFormatter.format(subtotal),
                baseTextStyle,
                boldTextStyle,
              ),
              if (taxAmount > 0)
                _buildPdfTotalRow(
                  'Tax:',
                  '+${currencyFormatter.format(taxAmount)}',
                  baseTextStyle,
                  boldTextStyle,
                ),
              if (serviceChargeAmount > 0)
                _buildPdfTotalRow(
                  'Service:',
                  '+${currencyFormatter.format(serviceChargeAmount)}',
                  baseTextStyle,
                  boldTextStyle,
                ),
              if (discountAmount > 0)
                _buildPdfTotalRow(
                  'Discount:',
                  '-${currencyFormatter.format(discountAmount)}',
                  baseTextStyle,
                  boldTextStyle,
                ),
              pw.Divider(height: 10, thickness: 0.5),
              _buildPdfTotalRow(
                'TOTAL:',
                currencyFormatter.format(grandTotal),
                largeBoldTextStyle,
                largeBoldTextStyle,
              ),

              // --- Footer ---
              pw.SizedBox(height: 15),
              pw.Center(
                child: pw.Text(
                  footerMessage,
                  style: baseTextStyle,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 5),
            ],
          );
        }, // End build function for pw.Page
      ), // End pw.Page
    ); // End pdf.addPage

    // Save the PDF document to bytes
    return pdf.save();
  }

  // Helper for PDF total rows
  pw.Widget _buildPdfTotalRow(
    String label,
    String value,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: labelStyle),
          pw.Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
