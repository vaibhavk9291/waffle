import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/billing/domain/bill.dart';
import '../../features/settings/domain/shop_settings.dart';

class PrinterService {
  static final PrinterService instance = PrinterService._internal();
  PrinterService._internal();

  /// Generate thermal ESC/POS receipt as PDF (standard 58mm or 80mm format)
  Future<Uint8List> generateReceiptPdf({
    required ShopSettings settings,
    required Bill bill,
    String? cashierName,
  }) async {
    final pdf = pw.Document();
    final is80mm = settings.paperWidthMm == 80;
    final pageFormat = is80mm
        ? const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm)
        : const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 3 * PdfPageFormat.mm);

    final fontBold = await PdfGoogleFonts.plusJakartaSansBold();
    final fontNormal = await PdfGoogleFonts.plusJakartaSansRegular();

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              // Header
              pw.Text(
                settings.shopName.toUpperCase(),
                style: pw.TextStyle(font: fontBold, fontSize: 13),
                textAlign: pw.TextAlign.center,
              ),
              if (settings.address.isNotEmpty)
                pw.Text(
                  settings.address,
                  style: pw.TextStyle(font: fontNormal, fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              if (settings.phone.isNotEmpty)
                pw.Text(
                  'Tel: ${settings.phone}',
                  style: pw.TextStyle(font: fontNormal, fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              if (settings.gstin != null && settings.gstin!.isNotEmpty)
                pw.Text(
                  'GSTIN: ${settings.gstin}',
                  style: pw.TextStyle(font: fontNormal, fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              pw.Divider(thickness: 0.5, height: 8),

              // Bill Meta
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bill No: #${bill.billNo}', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                  pw.Text(
                    DateFormat('dd/MM/yy HH:mm').format(bill.createdAt),
                    style: pw.TextStyle(font: fontNormal, fontSize: 8),
                  ),
                ],
              ),
              if (cashierName != null)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Text('Cashier: $cashierName', style: pw.TextStyle(font: fontNormal, fontSize: 8)),
                  ],
                ),
              pw.Divider(thickness: 0.5, height: 8),

              // Item rows
              pw.Row(
                children: [
                  pw.Expanded(flex: 5, child: pw.Text('Item', style: pw.TextStyle(font: fontBold, fontSize: 8))),
                  pw.Expanded(flex: 2, child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontBold, fontSize: 8))),
                  pw.Expanded(flex: 3, child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 8))),
                ],
              ),
              pw.Divider(thickness: 0.2, height: 4),

              ...bill.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Text(
                          item.productName,
                          style: pw.TextStyle(font: fontNormal, fontSize: 8),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          '${item.qty}x${item.unitPrice}',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(font: fontNormal, fontSize: 7),
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'Rs.${item.lineTotal}',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(font: fontBold, fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.Divider(thickness: 0.5, height: 8),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: pw.TextStyle(font: fontNormal, fontSize: 8)),
                  pw.Text('Rs.${bill.subtotal}', style: pw.TextStyle(font: fontNormal, fontSize: 8)),
                ],
              ),
              if (bill.discount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount:', style: pw.TextStyle(font: fontNormal, fontSize: 8)),
                    pw.Text('- Rs.${bill.discount}', style: pw.TextStyle(font: fontNormal, fontSize: 8)),
                  ],
                ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GRAND TOTAL:', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                  pw.Text('Rs.${bill.total}', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Mode:', style: pw.TextStyle(font: fontNormal, fontSize: 8)),
                  pw.Text(bill.paymentMode.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 8)),
                ],
              ),

              pw.Divider(thickness: 0.5, height: 8),

              // Footer
              pw.Text(
                settings.receiptFooter,
                style: pw.TextStyle(font: fontNormal, fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Print receipt via system/thermal printer
  Future<void> printReceipt({
    required ShopSettings settings,
    required Bill bill,
    String? cashierName,
  }) async {
    final pdfBytes = await generateReceiptPdf(
      settings: settings,
      bill: bill,
      cashierName: cashierName,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Bill_${bill.billNo}',
    );
  }
}
