import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:hala_bakeries_sales/features/employee/data/models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache for names to avoid repeated Firestore queries
  final Map<String, String> _productNameCache = {};
  final Map<String, String> _branchNameCache = {};
  final Map<String, String> _userNameCache = {};

  Future<File> generatePdf(List<TransactionModel> transactions) async {
    final pdf = pw.Document();
    
    // Use Cairo Bold for better Arabic text rendering
    final fontBold = await PdfGoogleFonts.cairoBold();
    final fontRegular = await PdfGoogleFonts.cairoRegular();
    
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm', 'ar');
    final now = DateTime.now();

    // Pre-fetch all names for better performance
    await _prefetchNames(transactions);

    // Calculate overall stats
    double totalReceived = 0;
    double totalDamaged = 0;
    double totalSales = 0;

    // Calculate branch-level stats
    Map<String, Map<String, double>> branchStats = {};
    Map<String, double> branchCurrentStock = {};

    for (var transaction in transactions) {
      // Initialize branch stats if not exists
      if (!branchStats.containsKey(transaction.branchId)) {
        branchStats[transaction.branchId] = {
          'damaged': 0.0,
          'sales': 0.0,
        };
      }

      // Overall totals
      switch (transaction.type) {
        case TransactionType.receive:
          totalReceived += transaction.quantity;
          break;
        case TransactionType.damage:
          totalDamaged += transaction.quantity;
          branchStats[transaction.branchId]!['damaged'] = 
            (branchStats[transaction.branchId]!['damaged'] ?? 0) + transaction.quantity;
          break;
        case TransactionType.sale:
          totalSales += transaction.quantity;
          branchStats[transaction.branchId]!['sales'] = 
            (branchStats[transaction.branchId]!['sales'] ?? 0) + transaction.quantity;
          break;
        default:
          break;
      }

      // Track current stock per branch (use latest afterStock value)
      String key = '${transaction.branchId}_${transaction.productId}';
      branchCurrentStock[key] = transaction.afterStock;
    }

    // Calculate total current stock per branch
    Map<String, double> branchTotalStock = {};
    branchCurrentStock.forEach((key, stock) {
      String branchId = key.split('_')[0];
      branchTotalStock[branchId] = (branchTotalStock[branchId] ?? 0) + stock;
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(20),
        
        // Page header
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 20),
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(width: 2, color: PdfColors.blue700),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'صفحة ${context.pageNumber} من ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'تقرير العمليات',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'تاريخ التقرير: ${dateFormat.format(now)}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        build: (context) => [
          // Overall Summary Section with better styling
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.Border.all(color: PdfColors.blue300, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ملخص إجمالي',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 10),
                pw.Divider(color: PdfColors.blue200, thickness: 1),
                pw.SizedBox(height: 10),
                _buildSummaryRow('إجمالي الاستلام', totalReceived.toStringAsFixed(0), PdfColors.green700, fontRegular),
                _buildSummaryRow('إجمالي التالف', totalDamaged.toStringAsFixed(0), PdfColors.red700, fontRegular),
                _buildSummaryRow('إجمالي المبيعات', totalSales.toStringAsFixed(0), PdfColors.orange700, fontRegular),
                _buildSummaryRow('إجمالي المخزون الحالي', branchTotalStock.values.fold(0.0, (a, b) => a + b).toStringAsFixed(0), PdfColors.blue700, fontRegular),
                _buildSummaryRow('عدد العمليات', transactions.length.toString(), PdfColors.purple700, fontRegular),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Branch-level breakdown with improved table
          if (branchStats.isNotEmpty) ...[ 
            pw.Text(
              'تفصيل حسب الفرع',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue700),
                  children: [
                    _buildTableHeader('اسم الفرع', fontBold),
                    _buildTableHeader('التالف', fontBold),
                    _buildTableHeader('المبيعات', fontBold),
                    _buildTableHeader('المخزون الحالي', fontBold),
                  ],
                ),
                // Data rows with alternating colors
                ...branchStats.entries.map((entry) {
                  final index = branchStats.keys.toList().indexOf(entry.key);
                  final bgColor = index % 2 == 0 ? PdfColors.grey100 : PdfColors.white;
                  final branchName = _getBranchName(entry.key);
                  
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bgColor),
                    children: [
                      _buildTableCell(branchName, fontRegular),
                      _buildTableCell((entry.value['damaged'] ?? 0).toStringAsFixed(0), fontRegular),
                      _buildTableCell((entry.value['sales'] ?? 0).toStringAsFixed(0), fontRegular),
                      _buildTableCell((branchTotalStock[entry.key] ?? 0).toStringAsFixed(0), fontRegular),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
          ],
          
          // Transactions Table with improved design
          pw.Text(
            'تفاصيل العمليات',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(1.2),
              5: const pw.FlexColumnWidth(1.2),
              6: const pw.FlexColumnWidth(1.2),
              7: const pw.FlexColumnWidth(2),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue700),
                children: [
                  _buildTableHeader('المنتج', fontBold),
                  _buildTableHeader('الفرع', fontBold),
                  _buildTableHeader('الموظف', fontBold),
                  _buildTableHeader('النوع', fontBold),
                  _buildTableHeader('الكمية', fontBold),
                  _buildTableHeader('قبل', fontBold),
                  _buildTableHeader('بعد', fontBold),
                  _buildTableHeader('التاريخ', fontBold),
                ],
              ),
              // Data rows with alternating colors
              ...transactions.asMap().entries.map((entry) {
                final index = entry.key;
                final t = entry.value;
                final bgColor = index % 2 == 0 ? PdfColors.grey100 : PdfColors.white;
                
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bgColor),
                  children: [
                    _buildTableCell(_getProductName(t.productId), fontRegular),
                    _buildTableCell(_getBranchName(t.branchId), fontRegular),
                    _buildTableCell(_getUserName(t.userId), fontRegular),
                    _buildTableCell(_getTypeArabic(t.type), fontRegular, _getTypeColor(t.type)),
                    _buildTableCell(t.quantity.toStringAsFixed(0), fontRegular),
                    _buildTableCell(t.beforeStock.toStringAsFixed(0), fontRegular),
                    _buildTableCell(t.afterStock.toStringAsFixed(0), fontRegular),
                    _buildTableCell(dateFormat.format(t.timestamp), fontRegular, null, 9),
                  ],
                );
              }),
            ],
          ),
          
          // Notes section if any transaction has notes
          if (transactions.any((t) => t.notes.isNotEmpty)) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'ملاحظات',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 10),
            ...transactions.where((t) => t.notes.isNotEmpty).map((t) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 5),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                border: pw.Border.all(color: PdfColors.amber300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                '${_getProductName(t.productId)} - ${dateFormat.format(t.timestamp)}: ${t.notes}',
                style: pw.TextStyle(fontSize: 9, font: fontRegular),
                textDirection: pw.TextDirection.rtl,
              ),
            )),
          ],
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<File> generateExcel(List<TransactionModel> transactions) async {
    final excel = Excel.createExcel();
    final sheet = excel['التقرير'];

    // Pre-fetch all names
    await _prefetchNames(transactions);

    // Calculate overall stats
    double totalReceived = 0;
    double totalDamaged = 0;
    double totalSales = 0;

    // Calculate branch-level stats
    Map<String, Map<String, double>> branchStats = {};
    Map<String, double> branchCurrentStock = {};

    for (var transaction in transactions) {
      // Initialize branch stats if not exists
      if (!branchStats.containsKey(transaction.branchId)) {
        branchStats[transaction.branchId] = {
          'damaged': 0.0,
          'sales': 0.0,
        };
      }

      // Overall totals
      switch (transaction.type) {
        case TransactionType.receive:
          totalReceived += transaction.quantity;
          break;
        case TransactionType.damage:
          totalDamaged += transaction.quantity;
          branchStats[transaction.branchId]!['damaged'] = 
            (branchStats[transaction.branchId]!['damaged'] ?? 0) + transaction.quantity;
          break;
        case TransactionType.sale:
          totalSales += transaction.quantity;
          branchStats[transaction.branchId]!['sales'] = 
            (branchStats[transaction.branchId]!['sales'] ?? 0) + transaction.quantity;
          break;
        default:
          break;
      }

      // Track current stock per branch (use latest afterStock value)
      String key = '${transaction.branchId}_${transaction.productId}';
      branchCurrentStock[key] = transaction.afterStock;
    }

    // Calculate total current stock per branch
    Map<String, double> branchTotalStock = {};
    branchCurrentStock.forEach((key, stock) {
      String branchId = key.split('_')[0];
      branchTotalStock[branchId] = (branchTotalStock[branchId] ?? 0) + stock;
    });

    // Add overall summary
    sheet.appendRow([TextCellValue('ملخص إجمالي')]);
    sheet.appendRow([TextCellValue('إجمالي الاستلام'), DoubleCellValue(totalReceived)]);
    sheet.appendRow([TextCellValue('إجمالي التالف'), DoubleCellValue(totalDamaged)]);
    sheet.appendRow([TextCellValue('إجمالي المبيعات'), DoubleCellValue(totalSales)]);
    sheet.appendRow([TextCellValue('إجمالي المخزون الحالي'), DoubleCellValue(branchTotalStock.values.fold(0.0, (a, b) => a + b))]);
    sheet.appendRow([TextCellValue('عدد العمليات'), IntCellValue(transactions.length)]);
    sheet.appendRow([]);

    // Add branch-level breakdown
    if (branchStats.isNotEmpty) {
      sheet.appendRow([TextCellValue('تفصيل حسب الفرع')]);
      sheet.appendRow([
        TextCellValue('اسم الفرع'),
        TextCellValue('التالف'),
        TextCellValue('المبيعات'),
        TextCellValue('المخزون الحالي'),
      ]);
      
      for (var entry in branchStats.entries) {
        sheet.appendRow([
          TextCellValue(_getBranchName(entry.key)),
          DoubleCellValue(entry.value['damaged'] ?? 0),
          DoubleCellValue(entry.value['sales'] ?? 0),
          DoubleCellValue(branchTotalStock[entry.key] ?? 0),
        ]);
      }
      sheet.appendRow([]);
    }

    // Add transaction details headers
    sheet.appendRow([TextCellValue('تفاصيل العمليات')]);
    sheet.appendRow([
      TextCellValue('التاريخ'),
      TextCellValue('النوع'),
      TextCellValue('المنتج'),
      TextCellValue('الفرع'),
      TextCellValue('الموظف'),
      TextCellValue('الكمية'),
      TextCellValue('قبل'),
      TextCellValue('بعد'),
      TextCellValue('الملاحظات'),
    ]);

    // Add data
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm', 'ar');
    for (var transaction in transactions) {
      sheet.appendRow([
        TextCellValue(dateFormat.format(transaction.timestamp)),
        TextCellValue(_getTypeArabic(transaction.type)),
        TextCellValue(_getProductName(transaction.productId)),
        TextCellValue(_getBranchName(transaction.branchId)),
        TextCellValue(_getUserName(transaction.userId)),
        DoubleCellValue(transaction.quantity),
        DoubleCellValue(transaction.beforeStock),
        DoubleCellValue(transaction.afterStock),
        TextCellValue(transaction.notes.isEmpty ? '-' : transaction.notes),
      ]);
    }

    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/report_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      
      final fileBytes = excel.save();
      if (fileBytes == null) {
        throw Exception('Failed to encode Excel file');
      }
      
      await file.writeAsBytes(fileBytes);
      return file;
    } catch (e) {
      print('Excel Export Error: $e');
      rethrow;
    }
  }

  // Helper method to pre-fetch all names for better performance
  Future<void> _prefetchNames(List<TransactionModel> transactions) async {
    final productIds = transactions.map((t) => t.productId).toSet();
    final branchIds = transactions.map((t) => t.branchId).toSet();
    final userIds = transactions.map((t) => t.userId).toSet();

    // Fetch products
    for (var id in productIds) {
      if (!_productNameCache.containsKey(id)) {
        try {
          final doc = await _firestore.collection('products').doc(id).get();
          if (doc.exists) {
            _productNameCache[id] = doc.data()?['name'] ?? 'غير متوفر';
          } else {
            _productNameCache[id] = 'غير متوفر';
          }
        } catch (e) {
          _productNameCache[id] = 'خطأ';
        }
      }
    }

    // Fetch branches
    for (var id in branchIds) {
      if (!_branchNameCache.containsKey(id)) {
        try {
          final doc = await _firestore.collection('branches').doc(id).get();
          if (doc.exists) {
            _branchNameCache[id] = doc.data()?['name'] ?? 'غير متوفر';
          } else {
            _branchNameCache[id] = 'غير متوفر';
          }
        } catch (e) {
          _branchNameCache[id] = 'خطأ';
        }
      }
    }

    // Fetch users
    for (var id in userIds) {
      if (!_userNameCache.containsKey(id)) {
        try {
          final doc = await _firestore.collection('users').doc(id).get();
          if (doc.exists) {
            _userNameCache[id] = doc.data()?['name'] ?? 'غير متوفر';
          } else {
            _userNameCache[id] = 'غير متوفر';
          }
        } catch (e) {
          _userNameCache[id] = 'خطأ';
        }
      }
    }
  }

  String _getProductName(String productId) {
    return _productNameCache[productId] ?? productId;
  }

  String _getBranchName(String branchId) {
    return _branchNameCache[branchId] ?? branchId;
  }

  String _getUserName(String userId) {
    return _userNameCache[userId] ?? userId;
  }

  String _getTypeArabic(TransactionType type) {
    switch (type) {
      case TransactionType.receive:
        return 'استلام';
      case TransactionType.damage:
        return 'تالف';
      case TransactionType.sale:
        return 'بيع';
      case TransactionType.adjustment:
        return 'تعديل';
      case TransactionType.openingBalance:
        return 'رصيد افتتاحي';
    }
  }

  PdfColor _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.receive:
        return PdfColors.green700;
      case TransactionType.damage:
        return PdfColors.red700;
      case TransactionType.sale:
        return PdfColors.orange700;
      case TransactionType.adjustment:
        return PdfColors.blue700;
      case TransactionType.openingBalance:
        return PdfColors.purple700;
    }
  }

  // Helper widgets for PDF
  pw.Widget _buildSummaryRow(String label, String value, PdfColor color, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                font: font,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, font: font),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableHeader(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          font: font,
        ),
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(String text, pw.Font font, [PdfColor? textColor, double? fontSize]) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize ?? 9,
          font: font,
          color: textColor ?? PdfColors.black,
        ),
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
