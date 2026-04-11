import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../features/expense_request/domain/entities/expense_request.dart';
import '../../features/purchase_request/domain/entities/purchase_request.dart';

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
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginTop: 1 * PdfPageFormat.cm,
          marginBottom: 1 * PdfPageFormat.cm,
          marginLeft: 1 * PdfPageFormat.cm,
          marginRight: 1 * PdfPageFormat.cm,
        ),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          pw.Widget rtlWrap(pw.Widget child) => pw.Directionality(textDirection: pw.TextDirection.rtl, child: child);
          
          return [
            rtlWrap(pw.Container(
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
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text('دار الاميرات', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                            pw.SizedBox(width: 10),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(4),
                              decoration: pw.BoxDecoration(color: PdfColors.blue700),
                              child: pw.Text('DA', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                            ),
                          ],
                        ),
                        pw.Text('DAR ALAMIRAT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, letterSpacing: 2, color: PdfColors.blue700)),
                      ],
                    ),
                  ),
                  pw.Text('نموذج طلب صرف مصاريف', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('التاريخ: ', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(hijriDate.replaceAll('هـ', '').trim(), style: const pw.TextStyle(fontSize: 9), textDirection: pw.TextDirection.ltr),
                          pw.SizedBox(width: 2),
                          pw.Text('هـ', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('Date: ', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(gregorianDate, style: const pw.TextStyle(fontSize: 9), textDirection: pw.TextDirection.ltr),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            )),
            rtlWrap(_buildSectionTitle('بيانات الموظف مقدم الطلب')),
            rtlWrap(_buildTable([
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
            ])),
            pw.SizedBox(height: 8),
            rtlWrap(_buildSectionTitle('تفاصيل المصروف')),
            rtlWrap(_buildTable([
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
            ])),
            pw.SizedBox(height: 8),
            rtlWrap(_buildSignatureSection('الموظف مقدم الطلب :', [
              'الاسم: ${exp.profile?.fullName ?? ''}',
              'الوظيفة: ${exp.profile?.jobTitle ?? ''}',
              'التوقيع: .....................',
              'التاريخ: $hijriDate',
            ])),
            rtlWrap(_buildSignatureSection('اعتماد المدير المباشر :', [
              'الاسم: ${managerApproval?.profile?.fullName ?? ''}',
              'التوقيع: .....................',
              'التاريخ: ${managerApproval != null ? _toHijri(managerApproval.createdAt) : ''}',
            ], comments: managerApproval?.comments)),
            if (exp.highestApprovalLevel == 'finance' || exp.highestApprovalLevel == 'general_manager')
              rtlWrap(_buildSignatureSection('الإدارة المالية :', [
                'الاسم: ${financeApproval?.profile?.fullName ?? ''}',
                'التوقيع: .....................',
                'التاريخ: ${financeApproval != null ? _toHijri(financeApproval.createdAt) : ''}',
              ], comments: financeApproval?.comments)),
            if (exp.highestApprovalLevel == 'general_manager')
              rtlWrap(_buildSignatureSection('اعتماد المدير العام :', [
                'الاسم: ${gmApproval?.profile?.fullName ?? ''}',
                'التوقيع: .....................',
                'التاريخ: ${gmApproval != null ? _toHijri(gmApproval.createdAt) : ''}',
              ], comments: gmApproval?.comments)),
            rtlWrap(_buildSignatureSection('محاسب العهدة (الصرف) :', [
              'الاسم: ${paidApproval?.profile?.fullName ?? ''}',
              'المبلغ المصروف: ${exp.amount.toStringAsFixed(2)} ريال',
              'التوقيع: .....................',
              'التاريخ: ${paidApproval != null ? _toHijri(paidApproval.createdAt) : ''}',
            ], comments: paidApproval?.comments)),
            pw.SizedBox(height: 8),
            rtlWrap(pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('تعليمات يجب مراعاتها :', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text('1. لن يُقبل أي طلب صرف مصاريف غير مستوفي للبيانات المذكورة أعلاه.', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('2. يجب تقديم المستندات المؤيدة للمبلغ المطلوب (فواتير، ايصالات، ..الخ).', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('3. الصرف على حسب مستوى الاعتماد المحدد في الطلب.', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('4. يتم صرف المبلغ من العهدة بعد اكتمال جميع الاعتمادات المطلوبة.', style: const pw.TextStyle(fontSize: 8)),
              ],
            )),
          ];
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
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        constraints: pw.BoxConstraints(minHeight: minHeight ?? 18),
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
              children: lines.map((l) => _buildLine(l)).toList(),
            )
          else
            pw.Wrap(
              spacing: 15,
              runSpacing: 2,
              children: lines.map((l) => _buildLine(l)).toList(),
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

  static pw.Widget _buildLine(dynamic l) {
    if (l is pw.Widget) return l;
    final s = l.toString();
    if (s.contains('التاريخ:')) {
      final parts = s.split('التاريخ:');
      String dateText = parts[1].trim();
      bool isHijri = dateText.contains('هـ');
      String cleanDate = dateText.replaceAll('هـ', '').trim();

      return pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('${parts[0]}التاريخ: ', style: const pw.TextStyle(fontSize: 9)),
          pw.Text(cleanDate, style: const pw.TextStyle(fontSize: 9), textDirection: pw.TextDirection.ltr),
          if (isHijri) pw.SizedBox(width: 2),
          if (isHijri) pw.Text('هـ', style: const pw.TextStyle(fontSize: 9)),
        ],
      );
    }
    return pw.Text(s, style: const pw.TextStyle(fontSize: 9));
  }

  static pw.Widget _approvalBadge() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.green, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
      ),
      child: pw.Text(
        'تم الاعتماد',
        style: pw.TextStyle(color: PdfColors.green, fontSize: 8, fontWeight: pw.FontWeight.bold),
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
          pw.Widget rtlWrap(pw.Widget child) => pw.Directionality(textDirection: pw.TextDirection.rtl, child: child);
          
          return [
            rtlWrap(pw.Container(
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
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('مبررات الاحتياج :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.SizedBox(width: 5),
                      pw.Expanded(
                        child: pw.Text(
                          req.justification ?? '', 
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),

            // Items Table - Direct child for splitting
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
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
                    rtlWrap(_tableCellForTable('* مدة الضمان', isLabel: true)),
                    rtlWrap(_tableCellForTable('* بلد الصناعة', isLabel: true)),
                    rtlWrap(_tableCellForTable('* السعر الإجمالي', isLabel: true)),
                    rtlWrap(_tableCellForTable('* سعر الوحدة', isLabel: true)),
                    rtlWrap(_tableCellForTable('الكمية', isLabel: true)),
                    rtlWrap(_tableCellForTable('الوحدة', isLabel: true)),
                    rtlWrap(_tableCellForTable('المواصفات المطلوبة', isLabel: true)),
                    rtlWrap(_tableCellForTable('م', isLabel: true)),
                  ],
                ),
                ...req.items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      rtlWrap(_tableCellForTable(item.warrantyPeriod ?? '')),
                      rtlWrap(_tableCellForTable(item.countryOfOrigin ?? '')),
                      rtlWrap(_tableCellForTable((item.quantity * item.unitPrice).toStringAsFixed(2))),
                      rtlWrap(_tableCellForTable(item.unitPrice.toStringAsFixed(2))),
                      rtlWrap(_tableCellForTable('${item.quantity}')),
                      rtlWrap(_tableCellForTable(item.unit ?? '')),
                      rtlWrap(_tableCellForTable('${item.productName}${item.specifications != null ? ' - ${item.specifications}' : ''}')),
                      rtlWrap(_tableCellForTable('${i + 1}')),
                    ],
                  );
                }),
              ],
            ),

            rtlWrap(pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildSignatureSection('الموظف طالب الاحتياج :', [
                  'الاسم: ${req.profile?.fullName ?? ''}',
                  'الوظيفة: ${req.profile?.jobTitle ?? ''}',
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text('التوقيع: ', style: const pw.TextStyle(fontSize: 9)),
                      _approvalBadge(),
                      pw.SizedBox(width: 20),
                      _buildLine('التاريخ: $hijriDate'),
                    ],
                  ),
                ]),
                _buildSignatureSection('اعتماد مسؤول الجهة الطالبة :', [
                   'الاسم: ${managerApproval?.profile?.fullName ?? ''}',
                   'الوظيفة: ${managerApproval?.profile?.jobTitle ?? ''}',
                   pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text('التوقيع: ', style: const pw.TextStyle(fontSize: 9)),
                      if (managerApproval != null) _approvalBadge(),
                      pw.SizedBox(width: 20),
                      _buildLine('التاريخ: ${managerApproval != null ? _toHijri(managerApproval.createdAt) : ''}'),
                    ],
                  ),
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
                          pw.Row(
                            children: [
                              pw.Text('التوقيع: ', style: const pw.TextStyle(fontSize: 9)),
                              if (itApproval != null) _approvalBadge(),
                              pw.SizedBox(width: 20),
                              _buildLine('التاريخ: ${itApproval != null ? _toHijri(itApproval.createdAt) : ''}'),
                            ],
                          ),
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
                  'رقم البند: ${req.budgetLineItem ?? ''}   رقم الارتباط: ${req.commitmentNumber ?? ''}',
                  pw.Row(
                    children: [
                      pw.Text('الموظف: ${financeApproval?.profile?.fullName ?? ''}', style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(width: 20),
                      pw.Text('التوقيع: ', style: const pw.TextStyle(fontSize: 9)),
                      if (financeApproval != null) _approvalBadge(),
                      pw.SizedBox(width: 20),
                      _buildLine('التاريخ: ${financeApproval != null ? _toHijri(financeApproval.createdAt) : ''}'),
                    ],
                  ),
                ], isColumn: true),
                _buildSignatureSection('الإدارة المالية :', [
                  'الاسم: ${financeApproval?.profile?.fullName ?? ''}',
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text('التوقيع: ', style: const pw.TextStyle(fontSize: 9)),
                      if (financeApproval != null) _approvalBadge(),
                      pw.SizedBox(width: 20),
                      _buildLine('التاريخ: ${financeApproval != null ? _toHijri(financeApproval.createdAt) : ''}'),
                    ],
                  ),
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
    final gregorianDate = DateFormat('yyyy/MM/dd').format(dateObj);
    final timeStr = DateFormat('HH:mm').format(dateObj);

    final isAccepted = req.staffAcceptanceStatus == 'accepted';
    final isRejected = req.staffAcceptanceStatus == 'rejected';
    final itApproval = req.logs.where((l) => l.action == 'it_approved' || l.action == 'purchased').firstOrNull;

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
          pw.Widget rtlWrap(pw.Widget child) => pw.Directionality(textDirection: pw.TextDirection.rtl, child: child);

          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header match Purchase Request
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.5)),
                  padding: const pw.EdgeInsets.all(5),
                  margin: const pw.EdgeInsets.only(bottom: 3),
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
                      pw.Text('استلام عهدة أصل', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        children: [
                          pw.Text('الموضوع :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.SizedBox(width: 5),
                          pw.Expanded(child: pw.Text(req.subject, style: const pw.TextStyle(fontSize: 10))),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                // Dates
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('التاريخ: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        pw.Text(hijriDate.replaceAll(' هـ', '').trim(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textDirection: pw.TextDirection.ltr),
                        pw.Text(' هـ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ],
                    ),
                    pw.Text('Date: $gregorianDate', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Receiver Info - using pw.Table
                pw.Container(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200, border: pw.Border(top: pw.BorderSide(), left: pw.BorderSide(), right: pw.BorderSide())),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: pw.Text('بيانات المستلم', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(1),
                    4: const pw.FlexColumnWidth(4),
                    5: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(children: [
                      rtlWrap(_tableCellForTable(req.profile?.jobTitle ?? '')),
                      rtlWrap(_tableCellForTable('المسمى الوظيفي', isLabel: true)),
                      rtlWrap(_tableCellForTable(req.profile?.department ?? '')),
                      rtlWrap(_tableCellForTable('الإدارة', isLabel: true)),
                      rtlWrap(_tableCellForTable(req.profile?.fullName ?? '')),
                      rtlWrap(_tableCellForTable('اسم الموظف', isLabel: true)),
                    ]),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Custody Data
                pw.Container(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200, border: pw.Border(top: pw.BorderSide(), left: pw.BorderSide(), right: pw.BorderSide())),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: pw.Text('بيانات العهدة', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(5),
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(4),
                    4: const pw.FlexColumnWidth(4),
                    5: const pw.FlexColumnWidth(8),
                    6: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        rtlWrap(_tableCellForTable('ملاحظة', isLabel: true)),
                        rtlWrap(_tableCellForTable('النوع', isLabel: true)),
                        rtlWrap(_tableCellForTable('الكمية', isLabel: true)),
                        rtlWrap(_tableCellForTable('مدة الضمان', isLabel: true)),
                        rtlWrap(_tableCellForTable('بلد الصناعة', isLabel: true)),
                        rtlWrap(_tableCellForTable('الوصف', isLabel: true)),
                        rtlWrap(_tableCellForTable('م', isLabel: true)),
                      ],
                    ),
                    ...req.items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return pw.TableRow(children: [
                        rtlWrap(_tableCellForTable(item.specifications ?? '')),
                        rtlWrap(_tableCellForTable(item.unit ?? '-')),
                        rtlWrap(_tableCellForTable('${item.quantity}')),
                        rtlWrap(_tableCellForTable(item.warrantyPeriod ?? '')),
                        rtlWrap(_tableCellForTable(item.countryOfOrigin ?? '')),
                        rtlWrap(_tableCellForTable('${item.productName}${item.brandModel != null ? ' (${item.brandModel})' : ''}')),
                        rtlWrap(_tableCellForTable('${i + 1}')),
                      ]);
                    }),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Declaration
                pw.Container(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200, border: pw.Border(top: pw.BorderSide(), left: pw.BorderSide(), right: pw.BorderSide())),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: pw.Text('إقرار', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'أقر أنا الموقع أدناه بأنني استلمت العُهد الموضحة أعلاه في يوم/ $dayOfWeek الموافق $hijriDate الموافق $gregorianDate في تمام الساعة $timeStr بحالة صالحة للاستخدام وأتعهد بالمحافظة عليها وان لا أتنازل عنها لأي شخص آخر وسأقوم بإعادتها عند طلبها أو عند ترك العمل أو دفع قيمة ما تسببت في تلفه وسأكون عرضة للمسائلة في حين مخالفتي للإقرار.',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.SizedBox(height: 15),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('المستلم/ ${req.profile?.fullName ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.Row(
                            children: [
                              pw.Text('التوقيع/ ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                              if (isAccepted) _approvalBadge(),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                // Handover Section
                pw.Container(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200, border: pw.Border(top: pw.BorderSide(), left: pw.BorderSide(), right: pw.BorderSide())),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: pw.Text('خاص بمسؤول التسليم والاستلام', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'أ- تم استلام العُهد بحالة التسليم. ( ${isAccepted ? "X" : "   "} ) نعم          ( ${isRejected ? "X" : "   "} ) لا، للأسباب التالية :',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                      ),
                      pw.SizedBox(height: 5),
                      if (isRejected && req.staffRejectionReason != null)
                        pw.Text(req.staffRejectionReason!, style: const pw.TextStyle(fontSize: 8))
                      else
                        pw.Text('...................................................................................................................................................', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('تم استلام العُهد في يوم/ $dayOfWeek', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text(hijriDate, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textDirection: pw.TextDirection.rtl),
                              pw.Text(' الموافق ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                              pw.Text(gregorianDate, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textDirection: pw.TextDirection.ltr),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('في تمام الساعة $timeStr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.SizedBox(height: 15),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('مسؤول التسليم: ${itApproval?.profile?.fullName ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.Row(
                            children: [
                              pw.Text('التوقيع: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                              if (isAccepted) _approvalBadge(),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.Text('الأصل: ملف الموظف | نسخة: المستلم | نسخة: إدارة تقنية المعلومات', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
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
    final gregorianDate = DateFormat('yyyy/MM/dd').format(dateObj);
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
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text('دار الاميرات', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                          pw.SizedBox(width: 10),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(4),
                            decoration: pw.BoxDecoration(color: PdfColors.blue700),
                            child: pw.Text('DA', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                          ),
                        ],
                      ),
                      pw.Text('DAR ALAMIRAT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, letterSpacing: 2, color: PdfColors.blue700)),
                      pw.SizedBox(height: 8),
                      pw.Text('سند استلام مبلغ مصاريف', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                // Dates
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('التاريخ: .... / .... / .... 14هـ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('التاريخ: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        pw.Text(DateFormat('yyyy/MM/dd').format(exp.createdAt), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textDirection: pw.TextDirection.ltr),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Receiver Info - using pw.Table
                pw.Container(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200, border: pw.Border(top: pw.BorderSide(), left: pw.BorderSide(), right: pw.BorderSide())),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: pw.Text('بيانات المستلم', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(4),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(2),
                    4: const pw.FlexColumnWidth(2),
                    5: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(children: [
                      _tableCellForTable('اسم الموظف', isLabel: true),
                      _tableCellForTable(exp.profile?.fullName ?? ''),
                      _tableCellForTable('الإدارة', isLabel: true),
                      _tableCellForTable(exp.profile?.department ?? ''),
                      _tableCellForTable('المسمى الوظيفي', isLabel: true),
                      _tableCellForTable(exp.profile?.jobTitle ?? ''),
                    ]),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Expense Details - using pw.Table
                pw.Container(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200, border: pw.Border(top: pw.BorderSide(), left: pw.BorderSide(), right: pw.BorderSide())),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: pw.Text('تفاصيل المصروف', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(3),
                  },
                  children: [
                    pw.TableRow(children: [
                      _tableCellForTable('الموضوع', isLabel: true),
                      _tableCellForTable(exp.subject),
                    ]),
                    pw.TableRow(children: [
                      _tableCellForTable('البيان', isLabel: true),
                      _tableCellForTable(exp.statement),
                    ]),
                  ],
                ),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(children: [
                      _tableCellForTable('المبلغ', isLabel: true),
                      _tableCellForTable('${exp.amount.toStringAsFixed(2)} ريال', isBold: true),
                      _tableCellForTable('رقم الطلب', isLabel: true),
                      _tableCellForTable('#${exp.id.substring(0, 8).toUpperCase()}'),
                    ]),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Declaration
                pw.Container(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200, border: pw.Border(top: pw.BorderSide(), left: pw.BorderSide(), right: pw.BorderSide())),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: pw.Text('إقرار باستلام المبلغ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'أقر أنا الموقع أدناه / ${exp.profile?.fullName ?? ''} بأنني استلمت مبلغ وقدره ${exp.amount.toStringAsFixed(2)} ريال وذلك بموجب طلب صرف مصاريف رقم #${exp.id.substring(0, 8).toUpperCase()} عن ${exp.subject} وذلك في يوم / $dayOfWeek الموافق $gregorianDate / $hijriDate في تمام الساعة $timeStr.',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('وأتعهد بصرف المبلغ في الغرض المخصص له وتقديم المستندات المؤيدة خلال المدة المحددة.', style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 15),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('المستلم/ ${exp.profile?.fullName ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.Text('التوقيع/ ...........................................', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                // Accountant Section
                pw.Container(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200, border: pw.Border(top: pw.BorderSide(), left: pw.BorderSide(), right: pw.BorderSide())),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: pw.Text('خاص بمسؤول الصرف (محاسب العهدة)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'تم صرف المبلغ بحالة ( ${isPaid ? "X" : "   "} ) نعم',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('تم الصرف في يوم/ ${paidApproval != null ? daysAr[paidApproval.createdAt.weekday % 7] : '............'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text('الموافق ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                              pw.Text(paidApproval != null ? DateFormat('yyyy/MM/dd').format(paidApproval.createdAt) : '.... / .... / ....', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textDirection: pw.TextDirection.ltr),
                              pw.Text(' / ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                              pw.Text(paidApproval != null ? _toHijri(paidApproval.createdAt).replaceAll('هـ', '').trim() : '.... / .... / ....', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textDirection: pw.TextDirection.ltr),
                              pw.SizedBox(width: 2),
                              pw.Text('هـ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 15),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('مسؤول الصرف: $accountantName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.Text('التوقيع: ...........................................', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.Text('الأصل: ملف الموظف | نسخة: المستلم | نسخة: الإدارة المالية', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
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
