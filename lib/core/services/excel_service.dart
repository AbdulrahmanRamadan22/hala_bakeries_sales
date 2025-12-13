import 'dart:io';
import 'package:excel/excel.dart';
import 'package:hala_bakeries_sales/features/employee/data/models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExcelService {
  Future<void> generateReportExcel(List<TransactionModel> transactions) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];
    sheetObject.isRTL = true;
    
    // Headers
    sheetObject.appendRow([
      TextCellValue('التاريخ'),
      TextCellValue('نوع العملية'),
      TextCellValue('المنتج'),
      TextCellValue('الكمية'),
      TextCellValue('الموظف'),
      TextCellValue('قبل'),
      TextCellValue('بعد'),
      TextCellValue('ملاحظات'),
    ]);

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm', 'ar');

    for (var t in transactions) {
      sheetObject.appendRow([
        TextCellValue(dateFormat.format(t.timestamp)),
        TextCellValue(_getTransactionTypeArabic(t.type)),
        TextCellValue(t.productId),
        DoubleCellValue(t.quantity),
        TextCellValue(t.userId),
        DoubleCellValue(t.beforeStock),
        DoubleCellValue(t.afterStock),
        TextCellValue(t.notes),
      ]);
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report.xlsx');
    final fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'تقرير العمليات Excel');
    }
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
