import 'dart:io';
import 'package:excel/excel.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/inventory_count_model.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class InventoryReportExcelService {
  static Future<File> generateInventoryReportExcel(List<InventoryCountModel> reports) async {
    final excel = Excel.createExcel();
    // Rename the default sheet instead of creating a new one to avoid empty sheets
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.rename(defaultSheet, 'Inventory Report');
    }
    
    final sheet = excel['Inventory Report'];

    // Define styles
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#4CAF50'),
      fontColorHex: ExcelColor.white,
    );

    final subHeaderStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#E0E0E0'),
    );

    // Add main headers
    sheet.appendRow([
      TextCellValue('تقرير الجرد'),
      TextCellValue(''), 
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('تاريخ التقرير: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
    ]);

    // Iterate through reports
    for (var report in reports) {
      // Branch and Employee Info Row
      sheet.appendRow([
        TextCellValue('الفرع: ${report.branchName}'),
        TextCellValue(''),
        TextCellValue('الموظف: ${report.employeeName}'),
        TextCellValue(''),
        TextCellValue('التاريخ: ${DateFormat('yyyy-MM-dd').format(report.date)}'),
        TextCellValue(''),
        TextCellValue(''),
      ]);
      
      // Table Headers for this report
      // Requested Order: Barcode || Product Name || Opening || Received || Damaged || Sales Qty || Sales Value || Actual
      final headerRow = [
        TextCellValue('باركود'),
        TextCellValue('اسم الصنف'),
        TextCellValue('رصيد افتتاحي'),
        TextCellValue('الوارد'),
        TextCellValue('التالف'),
        TextCellValue('كمية البيع'),
        TextCellValue('قيمة البيع'),
        TextCellValue('الجرد (الفعلي)'),
      ];
      
      sheet.appendRow(headerRow);
      
      // Add items
      for (var item in report.items) {
        final variance = item.expectedQuantity - item.actualQuantity;
        // Sales Qty = Expected - Actual (if positive, it's sales)
        // Generally "Sales Qty" in this context usually means the difference if it's considered sales.
        // Assuming standard logic: Sales = Variance
        
        final salesQty = variance; 
        // Note: If salesQty is negative, it means surplus (increase). 
        // User asked for "Sales Qty", usually implies the sold amount. We will put the variance here.
        
        // Sales Value
        final salesValue = salesQty * item.unitPrice;

        sheet.appendRow([
          TextCellValue(item.barcode),
          TextCellValue(item.productName),
          IntCellValue(item.openingBalance),
          IntCellValue(item.receivedQuantity),
          IntCellValue(item.damagedQuantity),
          IntCellValue(salesQty),
          DoubleCellValue(salesValue),
          IntCellValue(item.actualQuantity),
        ]);
      }
      
      // Add spacing between reports
      sheet.appendRow([TextCellValue('')]);
      sheet.appendRow([TextCellValue('')]);
    }

    // Save file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'inventory_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    final fileBytes = excel.save();
    
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes, flush: true);
    }
    
    return file;
  }
}
