import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/pressure_provider.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/pressure_pdf_service.dart';

class Konto extends ConsumerStatefulWidget {
  const Konto({super.key});

  @override
  ConsumerState<Konto> createState() => _KontoState();
}

class _KontoState extends ConsumerState<Konto> {
  DateTime? _dateFrom;
  DateTime? _dateTo;

  Future<void> _edytujDaneUzytkownika(UserProfile? user) async {
    final firstNameController = TextEditingController(
      text: user?.firstName ?? '',
    );
    final lastNameController = TextEditingController(
      text: user?.lastName ?? '',
    );
    final formKey = GlobalKey<FormState>();

    try {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Edytuj dane'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Imię',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Podaj imię'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nazwisko',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Podaj nazwisko'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Zapisz'),
            ),
          ],
        ),
      );

      if (shouldSave != true) return;

      await ref
          .read(authServiceProvider)
          .saveUserNames(
            firstName: firstNameController.text.trim(),
            lastName: lastNameController.text.trim(),
          );
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dane zostały zapisane')));
      }
    } finally {
      firstNameController.dispose();
      lastNameController.dispose();
    }
  }

  // funkcja wywołująca kalendarz
  Future<DateTime?> _wyborDaty(
    BuildContext context,
    DateTime? initialDate,
  ) async {
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

  void _wyborZakresu(BuildContext context, _PdfExportType exportType) {
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                    title: const Text(
                      'Data od:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(formatDaty.format(_dateFrom!)),
                    trailing: const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF6750A4),
                    ),
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
                    title: const Text(
                      'Data do:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(formatDaty.format(_dateTo!)),
                    trailing: const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF6750A4),
                    ),
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
              actionsPadding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
                top: 8,
              ),
              actions: [
                // WIELKI, FIOLETOWY PRZYCISK NA CAŁĄ SZEROKOŚĆ POD KALENDARZEM
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6750A4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _pobierzPDF(_dateFrom!, _dateTo!, exportType);
                    },
                    child: Text(
                      exportType.confirmButtonText,
                      style: TextStyle(fontSize: 16),
                    ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  Future<void> _pobierzPDF(
    DateTime odDaty,
    DateTime doDaty,
    _PdfExportType exportType,
  ) async {
    final wszystkieWpisy = ref.read(pressureProvider);
    final user = await ref.read(userProfileProvider.future);
    final pdfService = PressurePdfService();

    try {
      switch (exportType) {
        case _PdfExportType.table:
          await pdfService.saveMeasurementsReport(
            entries: wszystkieWpisy,
            user: user,
            dateFrom: odDaty,
            dateTo: doDaty,
          );
        case _PdfExportType.chart:
          await pdfService.saveChartReport(
            entries: wszystkieWpisy,
            user: user,
            dateFrom: odDaty,
            dateTo: doDaty,
          );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plik PDF został zapisany do folderu Pobrane'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on PressurePdfEmptyRangeException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Brak pomiarów w wybranym okresie! PDF nie został utworzony.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd zapisu pliku: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final wpisy = ref.watch(pressureProvider);
    final liczbaWpisow = wpisy.length;
    final statystykiZakresow = _PressureRangeStats.fromEntries(wpisy);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Konto"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Twoje Dane",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        profile.maybeWhen(
                          data: (user) => IconButton(
                            tooltip: 'Edytuj dane',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _edytujDaneUzytkownika(user),
                          ),
                          orElse: () => IconButton(
                            tooltip: 'Edytuj dane',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _edytujDaneUzytkownika(null),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    const Divider(), // pozioma kreska oddzielająca
                    const SizedBox(height: 8),

                    profile.when(
                      data: (user) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Imię: ${user.firstName?.isNotEmpty == true ? user.firstName : 'brak danych'}",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Nazwisko: ${user.lastName?.isNotEmpty == true ? user.lastName : 'brak danych'}",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Email: ${user.email?.isNotEmpty == true ? user.email : 'brak danych'}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text(
                        'Nie udało się wczytać danych użytkownika',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Divider(), // pozioma kreska oddzielająca
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Liczba wszystkich wpisów',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '$liczbaWpisow',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/przypomnienia');
              },
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Przypomnienia'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
              ),
            ),

            const SizedBox(height: 12),

            _PressureRangeStatsCard(stats: statystykiZakresow),

            const SizedBox(height: 12),

            // GUZIK POBIERZ SWOJE DANE
            ElevatedButton.icon(
              onPressed: () => _wyborZakresu(context, _PdfExportType.table),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Pobierz pomiary ciśnienia (PDF)"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () => _wyborZakresu(context, _PdfExportType.chart),
              icon: const Icon(Icons.show_chart),
              label: const Text("Pobierz wykres ciśnienia (PDF)"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
              ),
            ),

            const SizedBox(height: 12),

            // GUZIK WYLOGUJ
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(notificationServiceProvider).cancelReminder();
                await ref
                    .read(notificationServiceProvider)
                    .cancelAllMedicationReminders();
                await ref.read(authProvider.notifier).logout();

                ref.invalidate(pressureProvider);
                ref.invalidate(userProfileProvider);

                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/logowanie',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                "Wyloguj się",
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PdfExportType {
  table('Zatwierdź i pobierz PDF'),
  chart('Zatwierdź i pobierz wykres');

  const _PdfExportType(this.confirmButtonText);

  final String confirmButtonText;
}

enum _PressureRange { low, normal, high }

class _PressureRangeStats {
  const _PressureRangeStats({
    required this.low,
    required this.normal,
    required this.high,
  });

  final int low;
  final int normal;
  final int high;

  int get total => low + normal + high;

  factory _PressureRangeStats.fromEntries(Iterable<dynamic> entries) {
    var low = 0;
    var normal = 0;
    var high = 0;

    for (final entry in entries) {
      switch (_classifyPressure(entry.systolic, entry.diastolic)) {
        case _PressureRange.low:
          low++;
        case _PressureRange.normal:
          normal++;
        case _PressureRange.high:
          high++;
      }
    }

    return _PressureRangeStats(low: low, normal: normal, high: high);
  }

  static _PressureRange _classifyPressure(int systolic, int diastolic) {
    if (systolic < 90 || diastolic < 60) {
      return _PressureRange.low;
    }
    if (systolic >= 140 || diastolic >= 90) {
      return _PressureRange.high;
    }
    return _PressureRange.normal;
  }
}

class _PressureRangeStatsCard extends StatelessWidget {
  const _PressureRangeStatsCard({required this.stats});

  static const _lowColor = Color(0xFF3B82F6);
  static const _normalColor = Color(0xFF22C55E);
  static const _highColor = Color(0xFFEF4444);

  final _PressureRangeStats stats;

  @override
  Widget build(BuildContext context) {
    final segments = [
      _PieSegment(color: _lowColor, value: stats.low),
      _PieSegment(color: _normalColor, value: stats.normal),
      _PieSegment(color: _highColor, value: stats.high),
    ];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statystyka zakresów ciśnienia',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Podział wszystkich zapisanych pomiarów według wartości skurczowej i rozkurczowej.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final chart = Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: CustomPaint(
                      painter: _PressurePieChartPainter(segments, stats.total),
                    ),
                  ),
                );

                final legend = Column(
                  children: [
                    _PressureLegendRow(
                      color: _lowColor,
                      label: 'Niskie',
                      range: 'poniżej 90/60 mmHg',
                      count: stats.low,
                      total: stats.total,
                    ),
                    const SizedBox(height: 10),
                    _PressureLegendRow(
                      color: _normalColor,
                      label: 'Normalne',
                      range: '90-139 / 60-89 mmHg',
                      count: stats.normal,
                      total: stats.total,
                    ),
                    const SizedBox(height: 10),
                    _PressureLegendRow(
                      color: _highColor,
                      label: 'Podwyższone',
                      range: 'od 140/90 mmHg',
                      count: stats.high,
                      total: stats.total,
                    ),
                  ],
                );

                if (constraints.maxWidth < 360) {
                  return Column(
                    children: [chart, const SizedBox(height: 16), legend],
                  );
                }

                return Row(
                  children: [
                    chart,
                    const SizedBox(width: 20),
                    Expanded(child: legend),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PressureLegendRow extends StatelessWidget {
  const _PressureLegendRow({
    required this.color,
    required this.label,
    required this.range,
    required this.count,
    required this.total,
  });

  final Color color;
  final String label;
  final String range;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : ((count / total) * 100).round();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$percent% ($count)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                range,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PieSegment {
  const _PieSegment({required this.color, required this.value});

  final Color color;
  final int value;
}

class _PressurePieChartPainter extends CustomPainter {
  const _PressurePieChartPainter(this.segments, this.total);

  final List<_PieSegment> segments;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final chartRect = rect.deflate(2);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.butt;

    if (total == 0) {
      paint.color = Colors.grey.shade300;
      canvas.drawCircle(rect.center, size.shortestSide / 2 - 2, paint);
      return;
    }

    var startAngle = -math.pi / 2;
    for (final segment in segments.where((segment) => segment.value > 0)) {
      final sweepAngle = (segment.value / total) * math.pi * 2;
      paint.color = segment.color;
      canvas.drawArc(chartRect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PressurePieChartPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.segments != segments;
  }
}
