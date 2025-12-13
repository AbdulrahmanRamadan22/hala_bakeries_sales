import 'dart:io';
import 'package:flutter/services.dart';
import 'package:hala_bakeries_sales/features/employee/data/models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfService {
  Future<void> generateReportPdf(List<TransactionModel> transactions) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm', 'ar');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: font,
        ),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Center(child: pw.Text('تقرير العمليات', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              headers: ['التاريخ', 'العملية', 'المنتج', 'الكمية', 'الموظف'],
              data: transactions.map((t) {
                return [
                  dateFormat.format(t.timestamp),
                  _getTransactionTypeArabic(t.type),
                  t.productId, // Ideally replace with product name if available
                  t.quantity.toString(),
                  t.userId, // Ideally replace with employee name if available
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
              cellAlignment: pw.Alignment.center,
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'تقرير العمليات');
  }

  String _getTransactionTypeArabic(TransactionType type) {
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
}
