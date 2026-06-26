import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../providers/pressure_provider.dart';

class Konto extends ConsumerStatefulWidget{
  
  const Konto({super.key});

  @override
  ConsumerState<Konto> createState() => _KontoState();
}

class _KontoState extends ConsumerState<Konto> {
  DateTime? _dateFrom;
  DateTime? _dateTo;

  // funkcja wywołująca kalendarz
  Future<DateTime?> _wyborDaty(BuildContext context, DateTime? initialDate) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6750A4),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  void _wyborZakresu(BuildContext context) {
    // Resetujemy daty przed otwarciem okienka, żeby startowało od czysta lub domyślnych wartości
    _dateFrom = DateTime.now().subtract(const Duration(days: 7));
    _dateTo = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final formatDaty = DateFormat('dd-MM-yyyy');

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Wybierz zakres pomiarów',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Wybierz przedział czasowy, z którego chcesz wyeksportować swoje pomiary ciśnienia.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // DATA OD
                  ListTile(
                    title: const Text('Data od:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text(formatDaty.format(_dateFrom!)),
                    trailing: const Icon(Icons.calendar_today, color: Color(0xFF6750A4)),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.grey, width: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () async {
                      final picked = await _wyborDaty(context, _dateFrom);
                      if (picked != null) {
                        setDialogState(() {
                          _dateFrom = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // DATA DO
                  ListTile(
                    title: const Text('Data do:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text(formatDaty.format(_dateTo!)),
                    trailing: const Icon(Icons.calendar_today, color: Color(0xFF6750A4)),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.grey, width: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () async {
                      final picked = await _wyborDaty(context, _dateTo);
                      if (picked != null) {
                        setDialogState(() {
                          _dateTo = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
              actions: [
                // WIELKI, FIOLETOWY PRZYCISK NA CAŁĄ SZEROKOŚĆ POD KALENDARZEM
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6750A4), // Wasz fiolet
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx); // Zamykamy okienko
                      _pobierzPDF(_dateFrom!, _dateTo!); // Generujemy PDF
                    },
                    child: const Text('Zatwierdź i pobierz PDF', style: TextStyle(fontSize: 16)),
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // przycisk anulowania na samym dole
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6750A4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Anuluj', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pobierzPDF(DateTime odDaty, DateTime doDaty) async {
     final wszystkieWpisy = ref.read(pressureProvider);

    final doDatyKoniecDnia = DateTime(doDaty.year, doDaty.month, doDaty.day, 23, 59, 59);
    final przefiltrowaneWpisy = wszystkieWpisy.where((wpis) {
      return wpis.createdAt.isAfter(odDaty) && wpis.createdAt.isBefore(doDatyKoniecDnia);
    }).toList();

    przefiltrowaneWpisy.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (przefiltrowaneWpisy.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Brak pomiarów w wybranym okresie! PDF nie został utworzony.')),
        );
      }
      return;
    }

    // budujemy plik PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Raport ciśnienia krwi',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Okres: ${DateFormat('dd-MM-yyyy').format(odDaty)} do ${DateFormat('yyyy-MM-dd').format(doDaty)}',
                  style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                ),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 16),
                
                pw.ListView.builder(
                  itemCount: przefiltrowaneWpisy.length,
                  itemBuilder: (pw.Context context, int index) {
                    final wpis = przefiltrowaneWpisy[index];
                    final dataStr = DateFormat('dd-MM-yyyy HH:mm').format(wpis.createdAt);
                    final notatkaStr = wpis.note ?? 'Brak notatki';
                    
                    // [Data-Godzina Notatka Ciśnienie: systolic/diastolic]
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Text(
                        '$dataStr $notatkaStr, Ciśnienie: ${wpis.systolic}/${wpis.diastolic}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );

    // zapisujemy plik do pliku Dokumenty w telefonie
    try {
      Directory? documentsDir;
      
      if (Platform.isAndroid) {
        documentsDir = Directory('/storage/emulated/0/Download');
        if (!await documentsDir.exists()) {
          documentsDir = await getExternalStorageDirectory(); // fallback
        }
      } else if (Platform.isIOS) {
        documentsDir = await getApplicationDocumentsDirectory();
      }

      final String nazwaPliku = 'raport_cisnienia_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final File file = File('${documentsDir!.path}/$nazwaPliku');

      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plik PDF został zapisany do folderu Pobrane'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd zapisu pliku: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Konto"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Twoje Dane",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ), 
                    ), 

                    SizedBox(height: 12),
                    Divider(), // pozioma kreska oddzielająca
                    SizedBox(height: 12),
                    Text("Imię: Jan", style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Text("Nazwisko: Kowalski", style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Text("Wiek: 45 lat", style: TextStyle(fontSize: 16)),
                  ],
                ),
             ),
            ),

            const SizedBox(height: 12),

            // GUZIK POBIERZ SWOJE DANE
            ElevatedButton.icon(
              onPressed: () => _wyborZakresu(context),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Pobierz swoje dane (PDF)"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
              ),
            ),

            const SizedBox(height: 12),

            //GUZIK WYLOGUJ
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/logowanie');
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text("Wyloguj się", style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                side: const BorderSide(color: Colors.red),
              ), // styleFrom
            ),

          ],
        ),
      ),
    );
  }
}