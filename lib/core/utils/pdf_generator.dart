import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'formatters.dart';
import 'package:intl/intl.dart';
import '../../services/database/collections/transaction_collection.dart';
import '../../services/database/collections/client_collection.dart';
import '../../services/database/collections/lead_collection.dart';

class PdfGenerator {
  static const _primaryColor = PdfColor.fromInt(0xFF4A0014); // Dark Red
  static const _secondaryColor = PdfColor.fromInt(0xFFD8C3A5); // Tan
  static const _surfaceColor = PdfColors.white; // Keep white for boxes on the tan background
  static const _textColor = PdfColors.black;
  static const _lightText = PdfColor.fromInt(0xFF424242); // Grey800 equivalent

  /// Generates a premium Payment Receipt PDF
  static Future<void> generatePaymentReceipt(TransactionItem t) async {
    final ttf = await PdfGoogleFonts.robotoRegular();
    final ttfBold = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
    );

    final receiptId = t.id.substring(0, 8).toUpperCase();
    final date = '${t.date.day}/${t.date.month}/${t.date.year}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(40),
                color: _primaryColor,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('RCM OS', style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('Founder Operating System', style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                      ],
                    ),
                    pw.Text('PAYMENT RECEIPT', style: pw.TextStyle(color: PdfColors.white, fontSize: 28, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
                  ],
                ),
              ),

              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(40),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Meta Info
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('BILLED TO', style: pw.TextStyle(color: _lightText, fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
                              pw.SizedBox(height: 8),
                              pw.Text(t.clientName ?? 'Direct Client', style: pw.TextStyle(color: _textColor, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text('RECEIPT DETAILS', style: pw.TextStyle(color: _lightText, fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
                              pw.SizedBox(height: 8),
                              pw.Text('Receipt No: #$receiptId', style: const pw.TextStyle(color: _textColor, fontSize: 12)),
                              pw.SizedBox(height: 4),
                              pw.Text('Date: $date', style: const pw.TextStyle(color: _textColor, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 40),

                      // Amount Box
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(24),
                        decoration: pw.BoxDecoration(
                          color: _surfaceColor,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                          border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text('AMOUNT RECEIVED', style: pw.TextStyle(color: _lightText, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 8),
                            pw.Text(AppFormatters.currency(t.amount), style: pw.TextStyle(color: _primaryColor, fontSize: 36, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 40),

                      // Description
                      pw.Text('PAYMENT FOR', style: pw.TextStyle(color: _lightText, fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        children: [
                          pw.Expanded(child: pw.Text(t.description ?? t.category, style: const pw.TextStyle(color: _textColor, fontSize: 14))),
                          pw.Text(AppFormatters.currency(t.amount), style: pw.TextStyle(color: _textColor, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Divider(color: const PdfColor.fromInt(0xFFE2E8F0), height: 32),

                      pw.Spacer(),

                      // Footer
                      pw.Center(
                        child: pw.Column(
                          children: [
                            pw.Text('Thank you for your business!', style: pw.TextStyle(color: _primaryColor, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 8),
                            pw.Text('If you have any questions about this receipt, please contact us.', style: const pw.TextStyle(color: _lightText, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Receipt_$receiptId.pdf');
  }

  /// Generates a premium Project Brief for a Client
  static Future<void> generateClientBrief(ClientItem c) async {
    final ttf = await PdfGoogleFonts.robotoRegular();
    final ttfBold = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(40),
                color: _primaryColor,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('RCM OS', style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('Founder Operating System', style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                      ],
                    ),
                    pw.Text('PROJECT BRIEF', style: pw.TextStyle(color: PdfColors.white, fontSize: 28, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
                  ],
                ),
              ),

              pw.Padding(
                padding: const pw.EdgeInsets.all(40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Client Info
                    pw.Text('CLIENT INFORMATION', style: pw.TextStyle(color: _lightText, fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
                    pw.SizedBox(height: 12),
                    pw.Text(c.name, style: pw.TextStyle(color: _textColor, fontSize: 22, fontWeight: pw.FontWeight.bold)),
                    if (c.businessName != null && c.businessName!.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(c.businessName!, style: pw.TextStyle(color: _lightText, fontSize: 14)),
                    ],
                    pw.SizedBox(height: 16),
                    pw.Row(
                      children: [
                        if (c.email != null && c.email!.isNotEmpty)
                          pw.Expanded(child: pw.Text('Email: ${c.email}', style: const pw.TextStyle(color: _textColor, fontSize: 12))),
                        if (c.phone != null && c.phone!.isNotEmpty)
                          pw.Expanded(child: pw.Text('Phone: ${c.phone}', style: const pw.TextStyle(color: _textColor, fontSize: 12))),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    if (c.website != null && c.website!.isNotEmpty)
                      pw.Text('Website: ${c.website}', style: const pw.TextStyle(color: _textColor, fontSize: 12)),

                    pw.SizedBox(height: 32),

                    // Financial Overview
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(20),
                      decoration: pw.BoxDecoration(
                        color: _surfaceColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('PROJECT VALUE', style: pw.TextStyle(color: _lightText, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 4),
                              pw.Text(AppFormatters.currency(c.projectValue), style: pw.TextStyle(color: _textColor, fontSize: 20, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text('STATUS', style: pw.TextStyle(color: _lightText, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 4),
                              pw.Text(c.status, style: pw.TextStyle(color: _primaryColor, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 32),

                    // Additional Details
                    pw.Text('PROJECT DETAILS', style: pw.TextStyle(color: _lightText, fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
                    pw.SizedBox(height: 12),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Text(
                        c.internalNotes ?? 'No specific requirements or notes have been logged for this project yet. Please update the client profile to populate this section.',
                        style: const pw.TextStyle(color: _textColor, fontSize: 12, lineSpacing: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Brief_${c.name.replaceAll(' ', '_')}.pdf');
  }

  /// Generates a premium Project Brief for a Lead
  static Future<void> generateLeadBrief(LeadItem l) async {
    final ttf = await PdfGoogleFonts.robotoRegular();
    final ttfBold = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(40),
                color: _primaryColor,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('RCM OS', style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('Founder Operating System', style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                      ],
                    ),
                    pw.Text('PROSPECT BRIEF', style: pw.TextStyle(color: PdfColors.white, fontSize: 28, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
                  ],
                ),
              ),

              pw.Padding(
                padding: const pw.EdgeInsets.all(40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Lead Info
                    pw.Text('PROSPECT INFORMATION', style: pw.TextStyle(color: _lightText, fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
                    pw.SizedBox(height: 12),
                    pw.Text(l.name, style: pw.TextStyle(color: _textColor, fontSize: 22, fontWeight: pw.FontWeight.bold)),
                    if (l.company != null && l.company!.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(l.company!, style: pw.TextStyle(color: _lightText, fontSize: 14)),
                    ],
                    pw.SizedBox(height: 16),
                    pw.Row(
                      children: [
                        if (l.email != null && l.email!.isNotEmpty)
                          pw.Expanded(child: pw.Text('Email: ${l.email}', style: const pw.TextStyle(color: _textColor, fontSize: 12))),
                        if (l.phone != null && l.phone!.isNotEmpty)
                          pw.Expanded(child: pw.Text('Phone: ${l.phone}', style: const pw.TextStyle(color: _textColor, fontSize: 12))),
                      ],
                    ),

                    pw.SizedBox(height: 32),

                    // Deal Overview
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(20),
                      decoration: pw.BoxDecoration(
                        color: _surfaceColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('POTENTIAL VALUE', style: pw.TextStyle(color: _lightText, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 4),
                              pw.Text(AppFormatters.currency(l.dealValue), style: pw.TextStyle(color: _textColor, fontSize: 20, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text('STAGE', style: pw.TextStyle(color: _lightText, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 4),
                              pw.Text(l.stage, style: pw.TextStyle(color: _primaryColor, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 32),

                    // Notes
                    pw.Text('NOTES & REQUIREMENTS', style: pw.TextStyle(color: _lightText, fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
                    pw.SizedBox(height: 12),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Text(
                        l.notes ?? 'No specific notes logged for this prospect yet. Update the CRM profile to populate this section.',
                        style: const pw.TextStyle(color: _textColor, fontSize: 12, lineSpacing: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Prospect_${l.name.replaceAll(' ', '_')}.pdf');
  }

  /// Generates a premium Financial Report with charts
  static Future<void> generateFinancialReport({
    required String title,
    required String dateRange,
    required double revenue,
    required double expenses,
    required double profit,
    required Map<String, double> expenseBreakdown,
  }) async {
    final ttf = await PdfGoogleFonts.robotoRegular();
    final ttfBold = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
    );

    final colors = [
      PdfColor.fromHex('#4A0014'), // Primary
      PdfColor.fromHex('#5E1224'), // Lighter
      PdfColor.fromHex('#752535'),
      PdfColor.fromHex('#8C3848'),
      PdfColor.fromHex('#A64D5B'),
      PdfColor.fromHex('#BF6370'),
      PdfColor.fromHex('#D97A85'),
    ];

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _secondaryColor),
          ),
        ),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(40),
              color: _primaryColor,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('RCM OS', style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('Founder Operating System', style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(title.toUpperCase(), style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
                      pw.SizedBox(height: 4),
                      pw.Text(dateRange, style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            pw.Padding(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Executive Summary
                  pw.Text('EXECUTIVE SUMMARY', style: pw.TextStyle(color: _primaryColor, fontSize: 12, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'This report provides a comprehensive overview of the financial performance for the selected period. Total revenue generated was ${AppFormatters.currency(revenue)}, with total expenses amounting to ${AppFormatters.currency(expenses)}. The resulting net profit for this period stands at ${AppFormatters.currency(profit)}.',
                    style: const pw.TextStyle(color: _textColor, fontSize: 11, lineSpacing: 1.5),
                  ),
                  pw.SizedBox(height: 32),

                  // Financial Summary Boxes
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryBox('TOTAL REVENUE', revenue, _primaryColor),
                      pw.SizedBox(width: 16),
                      _buildSummaryBox('TOTAL EXPENSES', expenses, _primaryColor),
                      pw.SizedBox(width: 16),
                      _buildSummaryBox('NET PROFIT', profit, _primaryColor),
                    ],
                  ),

                  pw.SizedBox(height: 40),

                  if (expenseBreakdown.isNotEmpty) ...[
                    pw.Text('EXPENSE BREAKDOWN', style: pw.TextStyle(color: _primaryColor, fontSize: 12, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
                    pw.SizedBox(height: 24),
                    
                    // Chart and Table Row
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Pie Chart
                        pw.SizedBox(
                          width: 200,
                          height: 200,
                          child: pw.Chart(
                            grid: pw.PieGrid(),
                            datasets: expenseBreakdown.entries.toList().asMap().entries.map((e) {
                              final color = colors[e.key % colors.length];
                              return pw.PieDataSet(
                                value: e.value.value,
                                color: color,
                                legend: e.value.key,
                              );
                            }).toList(),
                          ),
                        ),
                        pw.SizedBox(width: 40),
                        
                        // Detailed Table
                        pw.Expanded(
                          child: pw.Table(
                            border: pw.TableBorder.all(color: _primaryColor, width: 1),
                            children: [
                              pw.TableRow(
                                decoration: pw.BoxDecoration(color: _primaryColor),
                                children: [
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8),
                                    child: pw.Text('Category', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8),
                                    child: pw.Text('Amount', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8),
                                    child: pw.Text('%', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                  ),
                                ],
                              ),
                              ...expenseBreakdown.entries.map((e) {
                                final percentage = expenses > 0 ? (e.value / expenses) * 100 : 0;
                                return pw.TableRow(
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8),
                                      child: pw.Text(e.key, style: const pw.TextStyle(color: _textColor, fontSize: 10)),
                                    ),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8),
                                      child: pw.Text(AppFormatters.currency(e.value), textAlign: pw.TextAlign.right, style: const pw.TextStyle(color: _textColor, fontSize: 10)),
                                    ),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8),
                                      child: pw.Text('${percentage.toStringAsFixed(1)}%', textAlign: pw.TextAlign.right, style: const pw.TextStyle(color: _textColor, fontSize: 10)),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  pw.SizedBox(height: 40),

                  // Recommendations Placeholder Box
                  pw.Text('NOTES & RECOMMENDATIONS', style: pw.TextStyle(color: _primaryColor, fontSize: 12, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
                  pw.SizedBox(height: 12),
                  pw.Container(
                    width: double.infinity,
                    height: 150, // Large empty box for manual notes
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: _surfaceColor,
                      border: pw.Border.all(color: _primaryColor, width: 1),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Text(
                      'Use this space for manual annotations, strategic next steps, or specific financial recommendations...',
                      style: pw.TextStyle(color: PdfColors.grey500, fontSize: 10, fontStyle: pw.FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 40),

            // Footer
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: _textColor, width: 0.5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated by RCM OS', style: pw.TextStyle(color: _lightText, fontSize: 9)),
                  pw.Text('Generated on: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}', style: pw.TextStyle(color: _lightText, fontSize: 9)),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final filename = '${title.replaceAll(' ', '_')}_Report.pdf';
    await Printing.sharePdf(bytes: await pdf.save(), filename: filename);
  }

  static pw.Widget _buildSummaryBox(String label, double value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: _surfaceColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(color: _lightText, fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text(AppFormatters.compactNumber(value), style: pw.TextStyle(color: color, fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
