import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/inventory_count_model.dart';

class InventoryReportPdfService {
  /// Generate PDF for a single inventory count report
  static Future<File> generateInventoryCountPdf(
    InventoryCountModel report,
  ) async {
    final pdf = pw.Document();

    // Load Arabic font
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFontBold,
        ),
        build: (context) => [
          // Header
          _buildHeader(report),
          pw.SizedBox(height: 20),

          // Summary Section
          _buildSummary(report),
          pw.SizedBox(height: 20),

          // Products Table
          _buildProductsTable(report),
          pw.SizedBox(height: 20),

          // Footer
          _buildFooter(),
        ],
      ),
    );

    // Save and share PDF
    return await _savePdf(pdf, report);
  }

  /// Generate PDF for multiple reports (filtered view)
  static Future<File> generateMultipleReportsPdf(
    List<InventoryCountModel> reports,
    DateTime? startDate,
    DateTime? endDate,
    String? branchName,
  ) async {
    final pdf = pw.Document();

    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    // Calculate totals
    final totalSales = reports.fold<double>(
      0,
      (sum, report) => sum + report.totalSalesValue,
    );
    final totalActualValue = reports.fold<double>(
      0,
      (sum, report) => sum + report.totalActualValue,
    );

    // Summary page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFontBold,
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildMultiReportHeader(startDate, endDate, branchName),
            pw.SizedBox(height: 20),
            _buildOverallSummary(reports.length, totalSales, totalActualValue),
            pw.SizedBox(height: 20),
            pw.Text(
              'ملخص التقارير',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildReportsList(reports),
            pw.Spacer(),
            _buildFooter(),
          ],
        ),
      ),
    );

    // Add a separate page for each report
    for (var report in reports) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(
            base: arabicFont,
            bold: arabicFontBold,
          ),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(report),
              pw.SizedBox(height: 20),
              _buildSummary(report),
              pw.SizedBox(height: 20),
              pw.Expanded(child: _buildProductsTable(report)),
              pw.SizedBox(height: 20),
              _buildFooter(),
            ],
          ),
        ),
      );
    }

    return await _saveMultiPdf(pdf, startDate, endDate, branchName);
  }

  // ==================== Single Report Components ====================

  static pw.Widget _buildHeader(InventoryCountModel report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'تقرير الجرد اليومي',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('الفرع: ${report.branchName}'),
                  pw.Text('الموظف: ${report.employeeName}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                      'التاريخ: ${DateFormat('yyyy-MM-dd').format(report.date)}'),
                  pw.Text(
                      'الوقت: ${DateFormat('HH:mm').format(report.updatedAt)}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummary(InventoryCountModel report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'الملخص الإجمالي',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCard(
                  'عدد المنتجات', '${report.items.length}', PdfColors.blue),
              _buildSummaryCard(
                  'إجمالي المبيعات',
                  '${report.totalSalesValue.toStringAsFixed(2)} ريال',
                  PdfColors.green),
              _buildSummaryCard(
                  'القيمة الفعلية',
                  '${report.totalActualValue.toStringAsFixed(2)} ريال',
                  PdfColors.orange),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCard(
      String title, String value, PdfColor color) {
    // Use light background colors based on the main color
    PdfColor backgroundColor;
    if (color == PdfColors.blue) {
      backgroundColor = PdfColors.blue50;
    } else if (color == PdfColors.green) {
      backgroundColor = PdfColors.green50;
    } else if (color == PdfColors.orange) {
      backgroundColor = PdfColors.orange50;
    } else {
      backgroundColor = PdfColors.grey100;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProductsTable(InventoryCountModel report) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        7: const pw.FlexColumnWidth(2.5), // Barcode
        6: const pw.FlexColumnWidth(4), // Product Name
        5: const pw.FlexColumnWidth(2), // Opening Balance
        4: const pw.FlexColumnWidth(2), // Received
        3: const pw.FlexColumnWidth(2), // Damaged
        2: const pw.FlexColumnWidth(2), // Sales Qty
        1: const pw.FlexColumnWidth(2.5), // Sales Value
        0: const pw.FlexColumnWidth(2), // Closing Inventory
      },
      children: [
        // Header (RTL: right to left)
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.green100),
          children: [
            _buildTableCell('جرد', isHeader: true),
            _buildTableCell('قيمه البيع', isHeader: true),
            _buildTableCell('كميه البيع', isHeader: true),
            _buildTableCell('التالف', isHeader: true),
            _buildTableCell('الوارد', isHeader: true),
            _buildTableCell('رصيد افتتاحي', isHeader: true),
            _buildTableCell('الصنف', isHeader: true),
            _buildTableCell('باركود', isHeader: true),
          ],
        ),
        // Data rows
        ...report.items.map((item) {
          // Opening Balance (from previous day or adjusted)
          final openingBalance = item.openingBalance;

          // Received from central branch
          final receivedQty = item.receivedQuantity;

          // Damaged quantity
          final damagedQty = item.damagedQuantity;

          // Sales = (Opening + Received - Damaged) - Actual
          final salesQty = item.expectedQuantity - item.actualQuantity;

          // Sales Value
          final salesValue = salesQty * item.unitPrice;

          // Closing Inventory (Actual counted quantity)
          final closingInventory = item.actualQuantity;

          return pw.TableRow(
            children: [
              _buildTableCell('$closingInventory'),
              _buildTableCell('${salesValue.toStringAsFixed(2)} ريال'),
              _buildTableCell('$salesQty'),
              _buildTableCell('$damagedQty'),
              _buildTableCell('$receivedQty'),
              _buildTableCell('$openingBalance'),
              _buildTableCell(item.productName),
              _buildTableCell("${item.barcode}"),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  // ==================== Multiple Reports Components ====================

  static pw.Widget _buildMultiReportHeader(
    DateTime? startDate,
    DateTime? endDate,
    String? branchName,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'تقارير الجرد الشاملة',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
          pw.SizedBox(height: 10),
          if (startDate != null && endDate != null)
            pw.Text(
                'الفترة: ${DateFormat('yyyy-MM-dd').format(startDate)} - ${DateFormat('yyyy-MM-dd').format(endDate)}'),
          if (branchName != null) pw.Text('الفرع: $branchName'),
          pw.Text(
              'تاريخ الإصدار: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
        ],
      ),
    );
  }

  static pw.Widget _buildOverallSummary(
      int count, double sales, double actualValue) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryCard('إجمالي الجرود', '$count', PdfColors.blue),
          _buildSummaryCard('إجمالي المبيعات',
              '${sales.toStringAsFixed(2)} ريال', PdfColors.green),
          _buildSummaryCard('القيمة الفعلية',
              '${actualValue.toStringAsFixed(2)} ريال', PdfColors.orange),
        ],
      ),
    );
  }

  static pw.Widget _buildReportsList(List<InventoryCountModel> reports) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.green100),
          children: [
            _buildTableCell('المبيعات', isHeader: true),
            _buildTableCell('القيمة الفعلية', isHeader: true),
            _buildTableCell('الموظف', isHeader: true),
            _buildTableCell('الفرع', isHeader: true),
            _buildTableCell('التاريخ', isHeader: true),
          ],
        ),
        ...reports.map((report) {
          return pw.TableRow(
            children: [
              _buildTableCell(
                  '${report.totalSalesValue.toStringAsFixed(2)} ريال'),
              _buildTableCell(
                  '${report.totalActualValue.toStringAsFixed(2)} ريال'),
              _buildTableCell(report.employeeName),
              _buildTableCell(report.branchName),
              _buildTableCell(DateFormat('yyyy-MM-dd').format(report.date)),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('نظام إدارة مخزون هلا للمخابز',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text('تم الإنشاء بواسطة النظام',
              style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // ==================== Save & Share ====================

  static Future<File> _savePdf(
      pw.Document pdf, InventoryCountModel report) async {
    final output = await getTemporaryDirectory();
    final fileName =
        'تقرير_جرد_${report.branchName}_${DateFormat('yyyy-MM-dd').format(report.date)}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<File> _saveMultiPdf(
    pw.Document pdf,
    DateTime? startDate,
    DateTime? endDate,
    String? branchName,
  ) async {
    final output = await getTemporaryDirectory();
    final dateRange = startDate != null && endDate != null
        ? '${DateFormat('yyyy-MM-dd').format(startDate)}_${DateFormat('yyyy-MM-dd').format(endDate)}'
        : DateFormat('yyyy-MM-dd').format(DateTime.now());
    final branch = branchName ?? 'كل_الفروع';
    final fileName = 'تقارير_الجرد_${branch}_$dateRange.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
