import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../database/collections/client_collection.dart';
import '../database/collections/invoice_collection.dart';
import '../settings_service.dart';
import 'dart:io';

class InvoiceGeneratorService {
  static Future<pw.Document> generate(
    InvoiceItem invoice,
    ClientItem client,
    SettingsService settings,
  ) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#4A0014');
    final secondaryColor = PdfColor.fromHex('#D8C3A5');
    final textOnPrimary = PdfColors.white;
    final textOnSecondary = PdfColors.black;
    final textDark = PdfColors.black;
    final textLight = PdfColors.grey700;

    // Load QR Image if available
    pw.MemoryImage? qrImage;
    final qrPath =
        (invoice.qrCodeImagePath != null && invoice.qrCodeImagePath!.isNotEmpty)
        ? invoice.qrCodeImagePath!
        : settings.paymentQrCodePath;
    if (qrPath.isNotEmpty) {
      try {
        final file = File(qrPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          qrImage = pw.MemoryImage(bytes);
        }
      } catch (e) {
        // Ignored
      }
    }

    final deliverables = client.deliverables.isNotEmpty
        ? client.deliverables
        : ['Service deliverables'];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // Header Block
            pw.Row(
              children: [
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    color: primaryColor,
                    padding: const pw.EdgeInsets.all(16),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          settings.agencyName.isEmpty
                              ? 'AGENCY NAME'
                              : settings.agencyName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: textOnPrimary,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Social Media Marketing Agency',
                          style: pw.TextStyle(
                            color: textOnPrimary,
                            fontSize: 10,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _buildContactLine(settings),
                          style: pw.TextStyle(
                            color: textOnPrimary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    color: secondaryColor,
                    padding: const pw.EdgeInsets.all(16),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: textOnSecondary,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Invoice #: INV-${invoice.id.substring(0, 6).toUpperCase()}',
                          style: pw.TextStyle(
                            color: textOnSecondary,
                            fontSize: 10,
                          ),
                        ),
                        pw.Text(
                          'Date: ${DateFormat('dd/MM/yyyy').format(invoice.issueDate)}',
                          style: pw.TextStyle(
                            color: textOnSecondary,
                            fontSize: 10,
                          ),
                        ),
                        pw.Text(
                          'Due Date: ${DateFormat('dd/MM/yyyy').format(invoice.dueDate)}',
                          style: pw.TextStyle(
                            color: textOnSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Bill To & Service Period Block
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400, width: 1),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILL TO',
                          style: pw.TextStyle(
                            color: secondaryColor,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          client.businessName ?? client.name,
                          style: pw.TextStyle(
                            color: textDark,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          client.name,
                          style: pw.TextStyle(color: textDark, fontSize: 10),
                        ),
                        if (client.address != null &&
                            client.address!.isNotEmpty)
                          pw.Text(
                            client.address!,
                            style: pw.TextStyle(color: textDark, fontSize: 10),
                          ),
                        pw.Text(
                          '${client.phone ?? ''} | ${client.email ?? ''}',
                          style: pw.TextStyle(color: textDark, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        top: const pw.BorderSide(
                          color: PdfColors.grey400,
                          width: 1,
                        ),
                        bottom: const pw.BorderSide(
                          color: PdfColors.grey400,
                          width: 1,
                        ),
                        right: const pw.BorderSide(
                          color: PdfColors.grey400,
                          width: 1,
                        ),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SERVICE PERIOD',
                          style: pw.TextStyle(
                            color: secondaryColor,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Month: ${invoice.duration}',
                          style: pw.TextStyle(
                            color: textDark,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        pw.Text(
                          'PAYMENT TYPE',
                          style: pw.TextStyle(
                            color: secondaryColor,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          invoice.paymentType,
                          style: pw.TextStyle(color: textDark, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Line Items Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primaryColor),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Description',
                        style: pw.TextStyle(
                          color: textOnPrimary,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Period',
                        style: pw.TextStyle(
                          color: textOnPrimary,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Unit Rate',
                        style: pw.TextStyle(
                          color: textOnPrimary,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Amount',
                        style: pw.TextStyle(
                          color: textOnPrimary,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                // Main Service Row
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        invoice.serviceName,
                        style: pw.TextStyle(color: textDark, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '1 month',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(color: textDark, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Rs.${invoice.baseAmount.toStringAsFixed(0)}',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(color: textDark, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Rs.${invoice.baseAmount.toStringAsFixed(0)}',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(color: textDark, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                // Deliverables Rows
                ...deliverables.map((deliverable) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          deliverable,
                          style: pw.TextStyle(color: textDark, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Included',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(color: textDark, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '—',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(color: textDark, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '—',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(color: textDark, fontSize: 10),
                        ),
                      ),
                    ],
                  );
                }),

                // Subtotal
                pw.TableRow(
                  children: [
                    pw.Container(),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Subtotal',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          color: textDark,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.Container(),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Rs.${invoice.baseAmount.toStringAsFixed(0)}',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(color: textDark, fontSize: 10),
                      ),
                    ),
                  ],
                ),

                // Advance Payment
                pw.TableRow(
                  children: [
                    pw.Container(),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Amount Already Paid\n(${invoice.amountPaidPreviously > 0 && invoice.totalAmount > 0 ? ((invoice.amountPaidPreviously / invoice.totalAmount) * 100).toStringAsFixed(0) : '0'}%)',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(color: textDark, fontSize: 10),
                      ),
                    ),
                    pw.Container(),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Rs.${invoice.amountPaidPreviously.toStringAsFixed(0)}',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(color: textDark, fontSize: 10),
                      ),
                    ),
                  ],
                ),

                // Remaining Balance
                pw.TableRow(
                  children: [
                    pw.Container(),
                    pw.Container(
                      color: primaryColor,
                      padding: const pw.EdgeInsets.all(8),
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'Remaining Balance\npayable on\n[${DateFormat('dd/MM/yyyy').format(invoice.dueDate)}]',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          color: textOnPrimary,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.Container(color: primaryColor),
                    pw.Container(
                      color: secondaryColor,
                      padding: const pw.EdgeInsets.all(8),
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'Rs.${_clampedRemaining(invoice.totalAmount, invoice.amountPaidPreviously).toStringAsFixed(0)}',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          color: textOnSecondary,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Payment Instructions
            pw.Text(
              'Payment Instructions',
              style: pw.TextStyle(
                color: textDark,
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F9F9F9'),
                      border: pw.Border.all(color: PdfColors.grey300, width: 1),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Bank Transfer',
                          style: pw.TextStyle(
                            color: textDark,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Account Name: ${settings.bankAccountName.isEmpty ? '[Your Bank Account Name]' : settings.bankAccountName}',
                          style: pw.TextStyle(color: textDark, fontSize: 10),
                        ),
                        pw.Text(
                          'Account No: ${settings.bankAccountNumber.isEmpty ? '[Your Account Number]' : settings.bankAccountNumber}',
                          style: pw.TextStyle(color: textDark, fontSize: 10),
                        ),
                        pw.Text(
                          'IFSC Code: ${settings.bankIfscCode.isEmpty ? '[Your IFSC Code]' : settings.bankIfscCode}',
                          style: pw.TextStyle(color: textDark, fontSize: 10),
                        ),
                        pw.Text(
                          'Bank: ${settings.bankName.isEmpty ? '[Your Bank Name]' : settings.bankName}',
                          style: pw.TextStyle(color: textDark, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F9F9F9'),
                      border: pw.Border(
                        top: const pw.BorderSide(
                          color: PdfColors.grey300,
                          width: 1,
                        ),
                        bottom: const pw.BorderSide(
                          color: PdfColors.grey300,
                          width: 1,
                        ),
                        right: const pw.BorderSide(
                          color: PdfColors.grey300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'UPI',
                          style: pw.TextStyle(
                            color: textDark,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'UPI ID: ${settings.upiId.isEmpty ? '[Your UPI ID]' : settings.upiId}',
                          style: pw.TextStyle(color: textDark, fontSize: 10),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Send payment screenshot to WhatsApp or email after transfer.',
                          style: pw.TextStyle(color: textLight, fontSize: 9),
                        ),
                        if (qrImage != null) ...[
                          pw.SizedBox(height: 8),
                          pw.Container(
                            height: 60,
                            width: 60,
                            child: pw.Image(qrImage),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 40),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Thank you for your business. We look forward to delivering exceptional results for your brand.',
                style: pw.TextStyle(color: textLight, fontSize: 9),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static String _buildContactLine(SettingsService settings) {
    final email = settings.agencyEmail.isEmpty ? 'email@example.com' : settings.agencyEmail;
    final phone = settings.agencyPhone.isEmpty ? '+91-XXXXXXXXXX' : settings.agencyPhone;
    return '$email | $phone';
  }

  static double _clampedRemaining(double total, double paid) {
    final remaining = total - paid;
    return remaining < 0 ? 0 : remaining;
  }
}
