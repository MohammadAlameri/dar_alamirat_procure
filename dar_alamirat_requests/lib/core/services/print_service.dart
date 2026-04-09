import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../features/expense_request/domain/entities/expense_request.dart';
import '../../features/purchase_request/domain/entities/purchase_request.dart';
import '../../features/purchase_request/domain/entities/request_item.dart';

class PrintService {
  static Future<pw.Font> _loadFont() async {
    return pw.Font.ttf(await rootBundle.load("assets/google_fonts/Cairo-Regular.ttf"));
  }

  static Future<pw.Font> _loadBoldFont() async {
    return pw.Font.ttf(await rootBundle.load("assets/google_fonts/Cairo-Bold.ttf"));
  }

  static String _toHijri(DateTime date) {
    final hijri = HijriCalendar.fromDate(date);
    return "${hijri.hYear}/${hijri.hMonth.toString().padLeft(2, '0')}/${hijri.hDay.toString().padLeft(2, '0')} هـ";
  }

  static Future<void> printExpenseRequest(ExpenseRequest exp) async {
    final font = await _loadFont();
    final boldFont = await _loadBoldFont();
    final pdf = pw.Document();

    final hijriDate = _toHijri(exp.createdAt);
    final gregorianDate = DateFormat('yyyy/MM/dd').format(exp.createdAt);

    final managerApproval = exp.logs.where((l) => l.action == 'manager_approved').firstOrNull;
    final financeApproval = exp.logs.where((l) => l.action == 'finance_approved').firstOrNull;
    final gmApproval = exp.logs.where((l) => l.action == 'gm_approved').firstOrNull;
    final paidApproval = exp.logs.where((l) => l.action == 'paid').firstOrNull;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginTop: 1 * PdfPageFormat.cm,
          marginBottom: 1 * PdfPageFormat.cm,
          marginLeft: 1 * PdfPageFormat.cm,
          marginRight: 1 * PdfPageFormat.cm,
        ),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.5)),
                  padding: const pw.EdgeInsets.all(5),
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    children: [
                      pw.Container(
                        alignment: pw.Alignment.center,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(width: 1.5)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 5),
                        margin: const pw.EdgeInsets.only(bottom: 5),
                        child: pw.Column(
                          children: [
                            pw.Text('DAR ALAMIRAT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                            pw.Text('دار الاميرات', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),
                      pw.Text('نموذج طلب صرف مصاريف', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('التاريخ: $hijriDate', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text('Date: $gregorianDate', style: const pw.TextStyle(fontSize: 9), textDirection: pw.TextDirection.ltr),
                        ],
                      ),
                    ],
                  ),
                ),

                // Employee Info
                _buildSectionTitle('بيانات الموظف مقدم الطلب'),
                _buildTable([
                  _buildRow([
                    _tableCell('اسم الموظف', isLabel: true, flex: 1),
                    _tableCell(exp.profile?.fullName ?? '', flex: 2),
                    _tableCell('المسمى الوظيفي', isLabel: true, flex: 1),
                    _tableCell(exp.profile?.jobTitle ?? '', flex: 2),
                  ]),
                  _buildRow([
                    _tableCell('الإدارة / القسم', isLabel: true, flex: 1),
                    _tableCell(exp.profile?.department ?? '', flex: 2),
                    _tableCell('رقم الطلب', isLabel: true, flex: 1),
                    _tableCell('#${exp.id.substring(0, 8).toUpperCase()}', flex: 2),
                  ]),
                ]),
                pw.SizedBox(height: 8),

                // Expense Details
                _buildSectionTitle('تفاصيل المصروف'),
                _buildTable([
                  _buildRow([
                    _tableCell('الموضوع', isLabel: true, flex: 1),
                    _tableCell(exp.subject, flex: 5),
                  ]),
                  _buildRow([
                    _tableCell('البيان', isLabel: true, flex: 1),
                    _tableCell(exp.statement, flex: 5, minHeight: 30),
                  ]),
                  _buildRow([
                    _tableCell('المبلغ المطلوب', isLabel: true, flex: 1),
                    _tableCell('${exp.amount.toStringAsFixed(2)} ريال', isBold: true, flex: 2),
                    _tableCell('أعلى مستوى اعتماد', isLabel: true, flex: 1),
                    _tableCell(_getLevelLabel(exp.highestApprovalLevel), flex: 2),
                  ]),
                ]),
                pw.SizedBox(height: 8),

                // Signatures
                _buildSignatureSection('الموظف مقدم الطلب :', [
                  'الاسم: ${exp.profile?.fullName ?? ''}',
                  'الوظيفة: ${exp.profile?.jobTitle ?? ''}',
                  'التوقيع: .....................',
                  'التاريخ: $hijriDate',
                ]),

                _buildSignatureSection('اعتماد المدير المباشر :', [
                  'الاسم: ${managerApproval?.profile?.fullName ?? ''}',
                  'التوقيع: .....................',
                  'التاريخ: ${managerApproval != null ? _toHijri(managerApproval.createdAt) : ''}',
                ], comments: managerApproval?.comments),

                if (exp.highestApprovalLevel == 'finance' || exp.highestApprovalLevel == 'general_manager')
                  _buildSignatureSection('الإدارة المالية :', [
                    'الاسم: ${financeApproval?.profile?.fullName ?? ''}',
                    'التوقيع: .....................',
                    'التاريخ: ${financeApproval != null ? _toHijri(financeApproval.createdAt) : ''}',
                  ], comments: financeApproval?.comments),

                if (exp.highestApprovalLevel == 'general_manager')
                  _buildSignatureSection('اعتماد المدير العام :', [
                    'الاسم: ${gmApproval?.profile?.fullName ?? ''}',
                    'التوقيع: .....................',
                    'التاريخ: ${gmApproval != null ? _toHijri(gmApproval.createdAt) : ''}',
                  ], comments: gmApproval?.comments),

                _buildSignatureSection('محاسب العهدة (الصرف) :', [
                  'الاسم: ${paidApproval?.profile?.fullName ?? ''}',
                  'المبلغ المصروف: ${exp.amount.toStringAsFixed(2)} ريال',
                  'التوقيع: .....................',
                  'التاريخ: ${paidApproval != null ? _toHijri(paidApproval.createdAt) : ''}',
                ], comments: paidApproval?.comments),

                // Instructions
                pw.SizedBox(height: 8),
                pw.Text('تعليمات يجب مراعاتها :', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text('1. لن يُقبل أي طلب صرف مصاريف غير مستوفي للبيانات المذكورة أعلاه.', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('2. يجب تقديم المستندات المؤيدة للمبلغ المطلوب (فواتير، ايصالات، ..الخ).', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('3. الصرف على حسب مستوى الاعتماد المحدد في الطلب.', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('4. يتم صرف المبلغ من العهدة بعد اكتمال جميع الاعتمادات المطلوبة.', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static String _getLevelLabel(String level) {
    switch (level) {
      case 'manager': return 'المدير المباشر';
      case 'finance': return 'الادارة المالية';
      case 'general_manager': return 'المدير العام';
      default: return level;
    }
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey200,
        border: pw.Border(
          top: pw.BorderSide(),
          left: pw.BorderSide(),
          right: pw.BorderSide(),
          bottom: pw.BorderSide(),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _buildTable(List<pw.Widget> rows) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(children: rows),
    );
  }

  static pw.Widget _buildRow(List<pw.Widget> children) {
    return pw.Row(
      children: children,
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    );
  }

  static pw.Widget _tableCell(String text, {bool isLabel = false, bool isBold = false, int flex = 1, double? minHeight, PdfColor? color}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        constraints: minHeight != null ? pw.BoxConstraints(minHeight: minHeight) : null,
        decoration: pw.BoxDecoration(
          color: color,
          border: const pw.Border(left: pw.BorderSide()),
        ),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: (isLabel || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  static pw.Widget _tableCellForTable(String text, {bool isLabel = false, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        maxLines: 3,
        overflow: pw.TextOverflow.clip,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: (isLabel || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildSignatureSection(String title, List<dynamic> lines, {String? comments, bool isColumn = false}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4),
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          if (isColumn)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: lines.map((l) => (l is pw.Widget) ? l : pw.Text(l.toString(), style: const pw.TextStyle(fontSize: 9))).toList(),
            )
          else
            pw.Wrap(
              spacing: 15,
              runSpacing: 2,
              children: lines.map((l) => (l is pw.Widget) ? l : pw.Text(l.toString(), style: const pw.TextStyle(fontSize: 9))).toList(),
            ),
          if (comments != null && comments.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text('ملاحظات: $comments', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            ),
        ],
      ),
    );
  }

  static Future<void> printPurchaseRequest(PurchaseRequest req) async {
    final font = await _loadFont();
    final boldFont = await _loadBoldFont();
    final pdf = pw.Document();

    final hijriDate = _toHijri(req.createdAt);

    final managerApproval = req.logs.where((l) => l.action == 'manager_approved').firstOrNull;
    final itApproval = req.logs.where((l) => l.action == 'it_approved').firstOrNull;
    final financeApproval = req.logs.where((l) => l.action == 'finance_approved').firstOrNull;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginTop: 1 * PdfPageFormat.cm,
          marginBottom: 1 * PdfPageFormat.cm,
          marginLeft: 1 * PdfPageFormat.cm,
          marginRight: 1 * PdfPageFormat.cm,
        ),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          final rtlWrap = (pw.Widget child) => pw.Directionality(textDirection: pw.TextDirection.rtl, child: child);
          
          return [
            rtlWrap(pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.5)),
                  padding: const pw.EdgeInsets.all(5),
                  margin: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Column(
                    children: [
                      pw.Container(
                        alignment: pw.Alignment.center,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(width: 1.5)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        margin: const pw.EdgeInsets.only(bottom: 3),
                        child: pw.Column(
                          children: [
                            pw.Text('DAR ALAMIRAT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                            pw.Text('دار الاميرات', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),
                      pw.Text('نموذج طلب شــــــراء', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        children: [
                          pw.Text('الموضوع :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.SizedBox(width: 5),
                          pw.Expanded(child: pw.Text(req.subject, style: const pw.TextStyle(fontSize: 10))),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text('مبررات الاحتياج :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.SizedBox(width: 5),
                          pw.Expanded(child: pw.Text(req.justification ?? '', style: const pw.TextStyle(fontSize: 10))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )),

            // Items Table
            rtlWrap(pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                // Table is LTR naturally, so we define widths left-to-right to match our reversed children
                0: const pw.FlexColumnWidth(3), // Guarantee
                1: const pw.FlexColumnWidth(3), // Country
                2: const pw.FlexColumnWidth(3), // Total price
                3: const pw.FlexColumnWidth(3), // Unit price
                4: const pw.FlexColumnWidth(2), // Qty
                5: const pw.FlexColumnWidth(2), // Unit
                6: const pw.FlexColumnWidth(6), // Specs
                7: const pw.FlexColumnWidth(1), // # Index
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _tableCellForTable('* مدة الضمان', isLabel: true),
                    _tableCellForTable('* بلد الصناعة', isLabel: true),
                    _tableCellForTable('* السعر الإجمالي', isLabel: true),
                    _tableCellForTable('* سعر الوحدة', isLabel: true),
                    _tableCellForTable('الكمية', isLabel: true),
                    _tableCellForTable('الوحدة', isLabel: true),
                    _tableCellForTable('المواصفات المطلوبة', isLabel: true),
                    _tableCellForTable('م', isLabel: true),
                  ],
                ),
                ...req.items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      _tableCellForTable(item.warrantyPeriod ?? ''),
                      _tableCellForTable(item.countryOfOrigin ?? ''),
                      _tableCellForTable((item.quantity * item.unitPrice).toStringAsFixed(2)),
                      _tableCellForTable(item.unitPrice.toStringAsFixed(2)),
                      _tableCellForTable('${item.quantity}'),
                      _tableCellForTable(item.unit ?? ''),
                      _tableCellForTable('${item.productName}${item.specifications != null ? ' - ${item.specifications}' : ''}'),
                      _tableCellForTable('${i + 1}'),
                    ],
                  );
                }),
              ],
            )),

            rtlWrap(pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildSignatureSection('الموظف طالب الاحتياج :', [
                  'الاسم: ${req.profile?.fullName ?? ''}',
                  'الوظيفة: ${req.profile?.jobTitle ?? ''}',
                  'التوقيع: .....................',
                  'التاريخ: $hijriDate',
                ]),

                _buildSignatureSection('اعتماد مسؤول الجهة الطالبة :', [
                   'الاسم: ${managerApproval?.profile?.fullName ?? ''}',
                   'الوظيفة: ${managerApproval?.profile?.jobTitle ?? ''}',
                   'التوقيع: .....................',
                   'التاريخ: ${managerApproval != null ? _toHijri(managerApproval.createdAt) : ''}',
                ]),

                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 5),
                  padding: const pw.EdgeInsets.all(5),
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('إفادة ادارة المشتريات او قسم IT :', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text('بعد مراجعة المخزون لدينا تبين عدم توفر ما هو مطلوب أعلاه وعلى ذلك جرى التوقيع والتاكد من صحة الاحتياج للمشتريات اعلاه.', style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('اسم المسؤول: ${itApproval?.profile?.fullName ?? ''}', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text('التوقيع: .....................', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text('التاريخ: ${itApproval != null ? _toHijri(itApproval.createdAt) : ''}', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 3,
                            child: pw.Container(
                              decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('أسماء الموردين المقترحين', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                                  pw.Text(req.suggestedSuppliers ?? '', style: const pw.TextStyle(fontSize: 8)),
                                ],
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Container(
                              decoration: pw.BoxDecoration(border: const pw.Border(top: pw.BorderSide(width: 0.5), bottom: pw.BorderSide(width: 0.5), left: pw.BorderSide(width: 0.5))),
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('إجمالي رقماً: ${req.totalAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                                  pw.Text('إجمالي كتابة: ${req.amountInWords ?? ''}', style: const pw.TextStyle(fontSize: 8)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                _buildSignatureSection('إدارة التخطيط والميزانية – الارتباطات :', [
                  pw.Row(children: [
                    pw.Text('البند يسمح ( ', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(req.budgetLineItem != null ? 'X' : '  ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text(' )  البند لا يسمح (   )', style: const pw.TextStyle(fontSize: 9)),
                  ]),
                  'المبلغ: ( ${req.totalAmount.toStringAsFixed(2)} - ${req.amountInWords ?? ''} ) ريال',
                  'رقم البند: ${req.budgetLineItem ?? ''}   رقم الارتباط: ${req.commitmentNumber ?? ''}   الموظف: ............   التوقيع: ............',
                ], isColumn: true),

                _buildSignatureSection('الإدارة المالية :', [
                  'الاسم: ${financeApproval?.profile?.fullName ?? ''}',
                  'التوقيع: .....................',
                  'التاريخ: ${financeApproval != null ? _toHijri(financeApproval.createdAt) : ''}',
                ]),

                pw.SizedBox(height: 5),
                pw.Text('تعليمات يجب مراعاتها :', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text('1. سوف يعاد إلى الجهة الطالبة أي طلب شراء غير مستوفي للبيانات المذكورة أعلاه.', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('2. التسعير يتم على نفس طلب الشراء .', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('3. يجب ذكر بلد الصنع والاسم التجاري للمنشأ + مدة الضمان .', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('4. يجب تحديد حجم العبوه المطلوبة او توضع للصنف الواحد الكمية حسب العبوة بما يوافق الكمية المحددة .', style: const pw.TextStyle(fontSize: 8)),
              ],
            )),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> printReceipt(PurchaseRequest req) async {
    final font = await _loadFont();
    final boldFont = await _loadBoldFont();
    final pdf = pw.Document();

    final dateObj = req.staffReceivingDate ?? DateTime.now();
    final daysAr = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    final dayOfWeek = daysAr[dateObj.weekday % 7];
    final hijriDate = _toHijri(dateObj);
    final gregorianDate = DateFormat('dd/MM/yyyy').format(dateObj);
    final timeStr = DateFormat('HH:mm').format(dateObj);

    final isAccepted = req.staffAcceptanceStatus == 'accepted';
    final isRejected = req.staffAcceptanceStatus == 'rejected';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginTop: 1 * PdfPageFormat.cm,
          marginBottom: 1 * PdfPageFormat.cm,
          marginLeft: 1 * PdfPageFormat.cm,
          marginRight: 1 * PdfPageFormat.cm,
        ),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('دار الاميرات', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                      pw.Text('DAR ALAMIRAT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                      pw.SizedBox(height: 5),
                      pw.Text('استلام عهدة اصل', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('التاريخ: .... / .... / .... 14هـ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text('التاريخ: ${DateFormat('yyyy/MM/dd').format(req.createdAt)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Receiver Info
                _buildSectionTitle('بيانات المستلم'),
                _buildTable([
                  _buildRow([
                    _tableCell('اسم الموظف', isLabel: true, flex: 1),
                    _tableCell(req.profile?.fullName ?? '', flex: 2),
                    _tableCell('الإدارة', isLabel: true, flex: 1),
                    _tableCell(req.profile?.department ?? '', flex: 1),
                    _tableCell('المسمى الوظيفي', isLabel: true, flex: 1),
                    _tableCell(req.profile?.jobTitle ?? '', flex: 1),
                  ]),
                ]),
                pw.SizedBox(height: 10),

                // Items
                _buildSectionTitle('بيانات العهدة'),
                _buildTable([
                  _buildRow([
                    _tableCell('ملاحظة', isLabel: true, flex: 5, color: PdfColors.grey200),
                    _tableCell('الكمية', isLabel: true, flex: 2, color: PdfColors.grey200),
                    _tableCell('النوع', isLabel: true, flex: 3, color: PdfColors.grey200),
                    _tableCell('الوصف', isLabel: true, flex: 10, color: PdfColors.grey200),
                    _tableCell('م', isLabel: true, flex: 1, color: PdfColors.grey200),
                  ]),
                  ...req.items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return _buildRow([
                      _tableCell(item.specifications ?? '', flex: 5),
                      _tableCell('${item.quantity}', flex: 2),
                      _tableCell('-', flex: 3),
                      _tableCell('${item.productName} ${item.brandModel != null ? '(${item.brandModel})' : ''}', flex: 10),
                      _tableCell('${i + 1}', flex: 1),
                    ]);
                  }),
                ]),
                pw.SizedBox(height: 10),

                // Declaration
                _buildSectionTitle('إقرار'),
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'أقر أنا الموقع أدناه بأنني استلمت العُهد الموضحة أعلاه في يوم/ $dayOfWeek الموافق $gregorianDate / $hijriDate في تمام الساعة $timeStr بحالة صالحة للاستخدام وأتعهد بالمحافظة عليها وان لا أتنازل عنها لأي شخص آخر وسأقوم بإعادتها عند طلبها أو عند ترك العمل أو دفع قيمة ما تسببت في تلفه وسأكون عرضة للمسائلة في حين مخالفتي للإقرار.',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 15),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('المستلم/ ${req.profile?.fullName ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text('التوقيع/ ...........................................', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                // Delivery Officer
                _buildSectionTitle('خاص بمسؤول التسليم والاستلام'),
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.RichText(
                            text: pw.TextSpan(
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                              children: [
                                pw.TextSpan(text: 'أ- تم استلام العُهد بحالة التسليم. ( '),
                                pw.TextSpan(text: isAccepted ? 'X' : '  ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                pw.TextSpan(text: ' ) نعم'),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 40),
                          pw.RichText(
                            text: pw.TextSpan(
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                              children: [
                                pw.TextSpan(text: '( '),
                                pw.TextSpan(text: isRejected ? 'X' : '  ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                pw.TextSpan(text: ' ) لا، للأسباب التالية :'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (isRejected && req.staffRejectionReason != null)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 3),
                          child: pw.Text(req.staffRejectionReason!, style: const pw.TextStyle(fontSize: 9)),
                        ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('تم استلام العُهد في يوم/ $dayOfWeek', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text('الموافق $gregorianDate / $hijriDate', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text('في تمام الساعة $timeStr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                      pw.SizedBox(height: 15),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('مسؤول التسليم: ...................................', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text('التوقيع: ...................................', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text('الأصل: ملف الموظف | نسخة: المستلم | نسخة: إدارة تقنية المعلومات', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> printExpenseReceipt(ExpenseRequest exp) async {
    final font = await _loadFont();
    final boldFont = await _loadBoldFont();
    final pdf = pw.Document();

    final dateObj = exp.createdAt;
    final daysAr = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    final dayOfWeek = daysAr[dateObj.weekday % 7];
    final hijriDate = _toHijri(dateObj);
    final gregorianDate = DateFormat('dd/MM/yyyy').format(dateObj);
    final timeStr = DateFormat('HH:mm').format(dateObj);

    final paidApproval = exp.logs.where((l) => l.action == 'paid').firstOrNull;
    final accountantName = paidApproval?.profile?.fullName ?? '...........................................';
    final isPaid = exp.status == 'completed' || paidApproval != null;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginTop: 1 * PdfPageFormat.cm,
          marginBottom: 1 * PdfPageFormat.cm,
          marginLeft: 1 * PdfPageFormat.cm,
          marginRight: 1 * PdfPageFormat.cm,
        ),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('دار الاميرات', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                      pw.Text('DAR ALAMIRAT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                      pw.SizedBox(height: 10),
                      pw.Text('سند استلام مبلغ مصاريف', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('التاريخ: .... / .... / .... 14هـ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text('التاريخ: ${DateFormat('yyyy/MM/dd').format(exp.createdAt)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Employee Info
                _buildSectionTitle('بيانات المستلم'),
                _buildTable([
                  _buildRow([
                    _tableCell('اسم الموظف', isLabel: true, flex: 1),
                    _tableCell(exp.profile?.fullName ?? '', flex: 2),
                    _tableCell('الإدارة', isLabel: true, flex: 1),
                    _tableCell(exp.profile?.department ?? '', flex: 1),
                    _tableCell('المسمى الوظيفي', isLabel: true, flex: 1),
                    _tableCell(exp.profile?.jobTitle ?? '', flex: 1),
                  ]),
                ]),
                pw.SizedBox(height: 10),

                // Expense Details
                _buildSectionTitle('تفاصيل المصروف'),
                _buildTable([
                  _buildRow([
                    _tableCell('الموضوع', isLabel: true, flex: 1),
                    _tableCell(exp.subject, flex: 3),
                  ]),
                  _buildRow([
                    _tableCell('البيان', isLabel: true, flex: 1),
                    _tableCell(exp.statement, flex: 3),
                  ]),
                  _buildRow([
                    _tableCell('المبلغ', isLabel: true, flex: 1),
                    _tableCell('${exp.amount.toStringAsFixed(2)} ريال', isBold: true, flex: 1),
                    _tableCell('رقم الطلب', isLabel: true, flex: 1),
                    _tableCell('#${exp.id.substring(0, 8).toUpperCase()}', flex: 1),
                  ]),
                ]),
                pw.SizedBox(height: 10),

                // Declaration
                _buildSectionTitle('إقرار باستلام المبلغ'),
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  padding: const pw.EdgeInsets.all(12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'أقر أنا الموقع أدناه / ${exp.profile?.fullName ?? ''} بأنني استلمت مبلغ وقدره ${exp.amount.toStringAsFixed(2)} ريال وذلك بموجب طلب صرف مصاريف رقم #${exp.id.substring(0, 8).toUpperCase()} عن ${exp.subject} وذلك في يوم / $dayOfWeek الموافق $gregorianDate / $hijriDate في تمام الساعة $timeStr.',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('وأتعهد بصرف المبلغ في الغرض المخصص له وتقديم المستندات المؤيدة خلال المدة المحددة.', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 15),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('المستلم/ ${exp.profile?.fullName ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text('التوقيع/ ...........................................', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                // Payment Officer
                _buildSectionTitle('خاص بمسؤول الصرف (محاسب العهدة)'),
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  padding: const pw.EdgeInsets.all(12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          children: [
                            pw.TextSpan(text: 'تم صرف المبلغ بحالة ( '),
                            pw.TextSpan(text: isPaid ? 'X' : '  ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.TextSpan(text: ' ) نعم'),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('تم الصرف في يوم/ ${paidApproval != null ? daysAr[paidApproval.createdAt.weekday % 7] : '............'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text('الموافق ${paidApproval != null ? DateFormat('yyyy/MM/dd').format(paidApproval.createdAt) : '.... / .... / ....'} / ${paidApproval != null ? _toHijri(paidApproval.createdAt) : '.... / .... / .... هـ'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                      pw.SizedBox(height: 15),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('مسؤول الصرف: $accountantName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text('التوقيع: ...........................................', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text('الأصل: ملف الموظف | نسخة: المستلم | نسخة: الإدارة المالية', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
