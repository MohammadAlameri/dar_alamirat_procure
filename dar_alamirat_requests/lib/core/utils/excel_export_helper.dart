import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class ExcelExportHelper {
  static Future<void> exportRequests({
    required List<dynamic> data,
    required String reportType,
    required String languageCode, // Use 'ar' for Arabic as requested
  }) async {
    // Load translations for the target language
    String jsonString = await rootBundle.loadString('assets/lang/$languageCode.json');
    Map<String, dynamic> translations = json.decode(jsonString);

    String translate(String key) => translations[key] ?? key;

    var excel = Excel.createExcel();
    // Use the default sheet and rename it if possible or just use it
    String sheetName = translate('reports');
    excel.rename('Sheet1', sheetName);
    Sheet sheetObject = excel[sheetName];

    // Headers
    List<String> headers = [
      translate('date'),
      translate('subject'),
      translate('requester'),
      translate('status'),
      translate('total'),
    ];

    // Style for headers
    CellStyle headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#FFC0CB'), // Light pink
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      fontFamily: getFontFamily(languageCode),
    );

    for (var i = 0; i < headers.length; i++) {
      var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Data rows style
    CellStyle dataStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Right,
      fontFamily: getFontFamily(languageCode),
    );

    // Data
    for (var i = 0; i < data.length; i++) {
      final r = data[i];
      final status = r.status.toString();
      final amount = reportType == 'procure' ? (r.totalAmount ?? 0.0) : (r.amount ?? 0.0);
      final requester = r.profile?.fullName ?? '-';
      final date = DateFormat('yyyy-MM-dd').format(r.createdAt);

      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = TextCellValue(date);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = TextCellValue(r.subject ?? '');
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1)).value = TextCellValue(requester);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1)).value = TextCellValue(translate(status));
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1)).value = DoubleCellValue(amount.toDouble());

      // Apply data style
      for (var col = 0; col < 5; col++) {
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1)).cellStyle = dataStyle;
      }
    }

    // Adjust column widths
    sheetObject.setColumnWidth(0, 15);
    sheetObject.setColumnWidth(1, 30);
    sheetObject.setColumnWidth(2, 20);
    sheetObject.setColumnWidth(3, 15);
    sheetObject.setColumnWidth(4, 15);

    // Save and share
    final bytes = excel.save();
    if (bytes != null) {
      final directory = await getTemporaryDirectory();
      String typeLabel = translate(reportType);
      final fileName = "${typeLabel}_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final file = File("${directory.path}/$fileName");
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)], text: translate('reports'));
    }
  }

  static String getFontFamily(String languageCode) {
    if (languageCode == 'ar') {
      return 'Arial'; // Generic for Excel compatibility
    }
    return 'Calibri';
  }
}
