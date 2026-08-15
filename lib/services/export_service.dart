import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/member.dart';
import '../models/payment.dart';
import '../utils/date_utils.dart';
import '../utils/web_download.dart' if (dart.library.html) '../utils/web_download_web.dart';

class ExportService {
  static Future<void> exportToExcel({
    required String reportTitle,
    required List<Member> newMembers,
    required List<Payment> payments,
    required List<Member> unpaidMembers,
    required List<Member> allMembers,
  }) async {
    final excel = Excel.createExcel();
    
    // 1. New Members Sheet
    final sheet1 = excel['New Members'];
    excel.setDefaultSheet('New Members');
    sheet1.appendRow([TextCellValue('Name'), TextCellValue('Mobile'), TextCellValue('Shift'), TextCellValue('Joining Date'), TextCellValue('Base Fee')]);
    for (var m in newMembers) {
      sheet1.appendRow([
        TextCellValue(m.name),
        TextCellValue(m.mobile),
        TextCellValue(m.shift),
        TextCellValue(AppDateUtils.formatDate(m.joiningDate)),
        TextCellValue(m.feeAmount.toString()),
      ]);
    }

    // 2. Payments Sheet
    final sheet2 = excel['Payments'];
    sheet2.appendRow([TextCellValue('Member Name'), TextCellValue('Date'), TextCellValue('Amount')]);
    for (var p in payments) {
      final member = allMembers.firstWhere((m) => m.id == p.memberId, orElse: () => Member(id: '', name: 'Unknown', mobile: '', address: '', joiningDate: DateTime.now(), membershipDuration: 0, feeAmount: 0, totalBilled: 0, shift: ''));
      sheet2.appendRow([
        TextCellValue(member.name),
        TextCellValue(AppDateUtils.formatDate(p.paymentDate)),
        TextCellValue(p.amount.toString()),
      ]);
    }

    // 3. Unpaid Dues Sheet
    final sheet3 = excel['Unpaid Dues'];
    sheet3.appendRow([TextCellValue('Name'), TextCellValue('Mobile'), TextCellValue('Pending Amount')]);
    for (var m in unpaidMembers) {
      final memberPayments = payments.where((p) => p.memberId == m.id);
      final totalPaid = memberPayments.fold(0.0, (sum, p) => sum + p.amount);
      final pending = m.totalBilled - totalPaid;
      sheet3.appendRow([
        TextCellValue(m.name),
        TextCellValue(m.mobile),
        TextCellValue(pending.toString()),
      ]);
    }

    // Save
    final bytes = excel.save();
    if (bytes != null) {
      await _saveAndShareFile(bytes, '$reportTitle.xlsx');
    }
  }

  static Future<void> exportToPdf({
    required String reportTitle,
    required List<Member> newMembers,
    required List<Payment> payments,
    required List<Member> unpaidMembers,
    required List<Member> allMembers,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Surbhi Gym - $reportTitle', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            
            // New Members
            pw.Text('New Members', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Name', 'Mobile', 'Shift', 'Joined'],
              data: newMembers.map((m) => [m.name, m.mobile, m.shift, AppDateUtils.formatDate(m.joiningDate)]).toList(),
            ),
            pw.SizedBox(height: 30),

            // Payments
            pw.Text('Payments Collected', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Member Name', 'Date', 'Amount'],
              data: payments.map((p) {
                final member = allMembers.firstWhere((m) => m.id == p.memberId, orElse: () => Member(id: '', name: 'Unknown', mobile: '', address: '', joiningDate: DateTime.now(), membershipDuration: 0, feeAmount: 0, totalBilled: 0, shift: ''));
                return [member.name, AppDateUtils.formatDate(p.paymentDate), AppDateUtils.formatCurrency(p.amount)];
              }).toList(),
            ),
            pw.SizedBox(height: 30),

            // Unpaid Dues
            pw.Text('Unpaid Dues', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Name', 'Mobile', 'Pending Amount'],
              data: unpaidMembers.map((m) {
                final memberPayments = payments.where((p) => p.memberId == m.id);
                final totalPaid = memberPayments.fold(0.0, (sum, p) => sum + p.amount);
                final pending = m.totalBilled - totalPaid;
                return [m.name, m.mobile, AppDateUtils.formatCurrency(pending)];
              }).toList(),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    
    if (kIsWeb) {
      await _saveAndShareFile(bytes, '$reportTitle.pdf');
    } else {
      await Printing.sharePdf(bytes: bytes, filename: '$reportTitle.pdf');
    }
  }

  static Future<void> generateInvoicePdf({
    required Member member,
    required Payment payment,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Surbhi Gym - Payment Receipt', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Date: ${AppDateUtils.formatDate(payment.paymentDate)}'),
              pw.Text('Receipt No: ${payment.id}'),
              pw.SizedBox(height: 20),
              pw.Text('Member Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Name: ${member.name}'),
              pw.Text('ID: ${member.id}'),
              pw.Text('Mobile: ${member.mobile}'),
              pw.SizedBox(height: 20),
              pw.Text('Payment Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Amount Paid: ${payment.amount.toStringAsFixed(0)}'),
              pw.Text('Payment Method: ${payment.paymentMethod}'),
              if (payment.notes != null && payment.notes!.isNotEmpty)
                pw.Text('Notes: ${payment.notes}'),
              pw.SizedBox(height: 40),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text('Thank you!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final fileName = 'Invoice_${payment.id}.pdf';
    
    if (kIsWeb) {
      await _saveAndShareFile(bytes, fileName);
    } else {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    }
  }

  static Future<void> _saveAndShareFile(List<int> bytes, String fileName) async {
    if (kIsWeb) {
      downloadFileOnWeb(bytes, fileName);
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
    }
  }
}
