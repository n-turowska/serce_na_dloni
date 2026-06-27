import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/pressure_entry.dart';
import 'auth_service.dart';

class PressurePdfService {
  static const _pageMargin = pw.EdgeInsets.only(
    left: 64,
    right: 56,
    top: 60,
    bottom: 48,
  );

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _timeFormat = DateFormat('HH:mm');

  Future<String> saveMeasurementsReport({
    required List<PressureEntry> entries,
    required UserProfile user,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    final filteredEntries = _filterEntries(entries, dateFrom, dateTo);
    if (filteredEntries.isEmpty) {
      throw const PressurePdfEmptyRangeException();
    }

    final pdf = await _createDocument();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: _pageMargin,
        build: (context) => [
          ..._buildHeader(
            title: 'Raport pomiarów ciśnienia',
            user: user,
            dateFrom: dateFrom,
            dateTo: dateTo,
          ),
          pw.TableHelper.fromTextArray(
            headers: [
              'Data pomiaru',
              'Godzina pomiaru',
              'Wynik pomiaru',
              'Notatka',
            ],
            data: filteredEntries.map((entry) {
              return [
                _dateFormat.format(entry.createdAt),
                _timeFormat.format(entry.createdAt),
                '${entry.systolic}/${entry.diastolic}',
                entry.note?.trim().isNotEmpty == true
                    ? entry.note!.trim()
                    : '-',
              ];
            }).toList(),
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
            cellAlignment: pw.Alignment.center,
            cellAlignments: const {3: pw.Alignment.centerLeft},
            headerStyle: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 3,
            ),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 3,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.15),
              1: pw.FlexColumnWidth(1.15),
              2: pw.FlexColumnWidth(1.15),
              3: pw.FlexColumnWidth(1.15),
            },
          ),
        ],
      ),
    );

    return _saveDocument(pdf, 'raport_cisnienia');
  }

  Future<String> saveChartReport({
    required List<PressureEntry> entries,
    required UserProfile user,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    final filteredEntries = _filterEntries(entries, dateFrom, dateTo);
    if (filteredEntries.isEmpty) {
      throw const PressurePdfEmptyRangeException();
    }

    final pdf = await _createDocument();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: _pageMargin,
        build: (context) => [
          ..._buildHeader(
            title: 'Wykres pomiarów ciśnienia',
            user: user,
            dateFrom: dateFrom,
            dateTo: dateTo,
          ),
          _buildLegend(),
          pw.SizedBox(height: 14),
          pw.Container(
            height: 360,
            child: _buildPressureChart(filteredEntries),
          ),
        ],
      ),
    );

    return _saveDocument(pdf, 'wykres_cisnienia');
  }

  Future<pw.Document> _createDocument() async {
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Arial.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Arial-Bold.ttf'),
    );

    return pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );
  }

  List<PressureEntry> _filterEntries(
    List<PressureEntry> entries,
    DateTime dateFrom,
    DateTime dateTo,
  ) {
    final start = DateTime(dateFrom.year, dateFrom.month, dateFrom.day);
    final end = DateTime(dateTo.year, dateTo.month, dateTo.day, 23, 59, 59);
    final filtered = entries.where((entry) {
      return !entry.createdAt.isBefore(start) && !entry.createdAt.isAfter(end);
    }).toList();

    filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return filtered;
  }

  List<pw.Widget> _buildHeader({
    required String title,
    required UserProfile user,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) {
    return [
      pw.Text(
        title,
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 14),
      pw.Text(
        'Użytkownik: ${_formatUser(user)}',
        style: const pw.TextStyle(fontSize: 11),
      ),
      pw.SizedBox(height: 14),
      pw.Text(
        'Zakres dat: ${_dateFormat.format(dateFrom)} do ${_dateFormat.format(dateTo)}',
        style: const pw.TextStyle(fontSize: 11),
      ),
      pw.SizedBox(height: 6),
      pw.Divider(thickness: 1, color: PdfColors.black),
      pw.SizedBox(height: 8),
    ];
  }

  String _formatUser(UserProfile user) {
    final firstName = user.firstName?.trim() ?? '';
    final lastName = user.lastName?.trim() ?? '';
    final fullName = [
      if (lastName.isNotEmpty) lastName,
      if (firstName.isNotEmpty) firstName,
    ].join(', ');

    if (fullName.isNotEmpty) {
      return fullName;
    }

    return user.email?.trim().isNotEmpty == true ? user.email!.trim() : '-';
  }

  pw.Widget _buildLegend() {
    return pw.Row(
      children: [
        _buildLegendItem(PdfColors.red700, 'Skurczowe'),
        pw.SizedBox(width: 20),
        _buildLegendItem(PdfColors.blue700, 'Rozkurczowe'),
      ],
    );
  }

  pw.Widget _buildLegendItem(PdfColor color, String label) {
    return pw.Row(
      children: [
        pw.Container(width: 18, height: 8, color: color),
        pw.SizedBox(width: 6),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildPressureChart(List<PressureEntry> entries) {
    final xAxisValues = _buildXAxisValues(entries.length);
    final yAxisValues = _buildYAxisValues(entries);

    return pw.Chart(
      left: pw.Padding(
        padding: const pw.EdgeInsets.only(right: 8),
        child: pw.Transform.rotateBox(
          angle: math.pi / 2,
          child: pw.Text(
            'Ciśnienie (mmHg)',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
      ),
      bottom: pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Text('Data pomiaru', style: const pw.TextStyle(fontSize: 9)),
      ),
      grid: pw.CartesianGrid(
        xAxis: pw.FixedAxis<int>(
          xAxisValues,
          format: (value) => _formatXAxisLabel(value.toInt(), entries),
          textStyle: const pw.TextStyle(fontSize: 7),
          divisions: true,
          divisionsColor: PdfColors.grey300,
          angle: -math.pi / 5,
        ),
        yAxis: pw.FixedAxis<int>(
          yAxisValues,
          format: (value) => value.toInt().toString(),
          textStyle: const pw.TextStyle(fontSize: 8),
          divisions: true,
          divisionsColor: PdfColors.grey300,
        ),
      ),
      datasets: [
        pw.LineDataSet(
          legend: 'Skurczowe',
          color: PdfColors.red700,
          lineColor: PdfColors.red700,
          pointColor: PdfColors.red700,
          data: [
            for (var i = 0; i < entries.length; i++)
              pw.PointChartValue(i.toDouble(), entries[i].systolic.toDouble()),
          ],
        ),
        pw.LineDataSet(
          legend: 'Rozkurczowe',
          color: PdfColors.blue700,
          lineColor: PdfColors.blue700,
          pointColor: PdfColors.blue700,
          data: [
            for (var i = 0; i < entries.length; i++)
              pw.PointChartValue(i.toDouble(), entries[i].diastolic.toDouble()),
          ],
        ),
      ],
    );
  }

  List<int> _buildXAxisValues(int entriesCount) {
    if (entriesCount == 1) {
      return [0, 1];
    }

    const maxLabels = 7;
    final lastIndex = entriesCount - 1;
    final step = math.max(1, (lastIndex / (maxLabels - 1)).ceil());
    final values = <int>{0, lastIndex};

    for (var index = step; index < lastIndex; index += step) {
      values.add(index);
    }

    return values.toList()..sort();
  }

  String _formatXAxisLabel(int index, List<PressureEntry> entries) {
    if (index < 0 || index >= entries.length) {
      return '';
    }

    return DateFormat('dd/MM').format(entries[index].createdAt);
  }

  List<int> _buildYAxisValues(List<PressureEntry> entries) {
    final values = entries
        .expand((entry) => [entry.systolic, entry.diastolic])
        .toList();
    final minPressure = values.reduce(math.min);
    final maxPressure = values.reduce(math.max);
    final start = math.max(0, ((minPressure - 10) / 10).floor() * 10);
    final end = ((maxPressure + 10) / 10).ceil() * 10;
    final step = (end - start) <= 80 ? 10 : 20;

    return [for (var value = start; value <= end; value += step) value];
  }

  Future<String> _saveDocument(pw.Document pdf, String filePrefix) async {
    Directory? documentsDir;

    if (Platform.isAndroid) {
      documentsDir = Directory('/storage/emulated/0/Download');
      if (!await documentsDir.exists()) {
        documentsDir = await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS) {
      documentsDir = await getApplicationDocumentsDirectory();
    } else {
      documentsDir = await getApplicationDocumentsDirectory();
    }

    final fileName =
        '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${documentsDir!.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}

class PressurePdfEmptyRangeException implements Exception {
  const PressurePdfEmptyRangeException();
}
