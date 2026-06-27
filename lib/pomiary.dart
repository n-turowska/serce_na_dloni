import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/pressure_entry.dart';
import '../providers/pressure_provider.dart';

class Pomiary extends ConsumerStatefulWidget {
  const Pomiary({super.key, this.initialEntry});

  final PressureEntry? initialEntry;

  @override
  ConsumerState<Pomiary> createState() => _PomiaryState();
}

class _PomiaryState extends ConsumerState<Pomiary> {
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _noteController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime? _selectedDateTime; // zmienna przechowująca wybraną datę wstecz
  bool get _isEditing => widget.initialEntry != null;

  @override
  void initState() {
    super.initState();

    final entry = widget.initialEntry;
    if (entry != null) {
      _systolicController.text = entry.systolic.toString();
      _diastolicController.text = entry.diastolic.toString();
      _noteController.text = entry.note ?? '';
      _selectedDateTime = entry.createdAt;
      _dateController.text = DateFormat(
        'dd-MM-yyyy – HH:mm',
      ).format(entry.createdAt);
    }
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // Funkcja otwierająca systemowy kalendarz
  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initialDateTime = _selectedDateTime ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime.isAfter(now) ? now : initialDateTime,
      firstDate: DateTime(2000), // najstarsza możliwa data do wybrania
      lastDate: now, // blokujemy wybieranie dat z przyszłości
    );

    if (pickedDate == null) return;
    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
    );

    if (pickedTime == null) return;

    final fullDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _selectedDateTime = fullDateTime;
      _dateController.text = DateFormat(
        'dd-MM-yyyy – HH:mm',
      ).format(fullDateTime);
    });
  }

  Future<void> _submitPressure() async {
    final systolic = int.tryParse(_systolicController.text) ?? 0;
    final diastolic = int.tryParse(_diastolicController.text) ?? 0;
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    if (systolic <= 0 || diastolic <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proszę podać poprawne wartości ciśnienia!'),
        ),
      );
      return;
    }

    try {
      final notifier = ref.read(pressureProvider.notifier);
      final entry = widget.initialEntry;

      if (entry == null) {
        await notifier.addPressure(
          systolic,
          diastolic,
          note,
          createdAt: _selectedDateTime,
        );
      } else {
        await notifier.updatePressure(
          entry.id,
          systolic,
          diastolic,
          note,
          _selectedDateTime ?? entry.createdAt,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się zapisać pomiaru. Spróbuj ponownie.'),
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Pomiar został zaktualizowany'
                : 'Pomiar został zapisany',
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edytuj pomiar" : "Dodaj pomiar"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20.0,
                  horizontal: 16.0,
                ),
                child: Column(
                  children: [
                    Text(
                      'Podaj wyniki pomiaru ciśnienia:\n skurczowe / rozkurczowe',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          child: TextField(
                            controller: _systolicController,
                            keyboardType: TextInputType
                                .number, // Tylko klawiatura numeryczna
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            '/',
                            style: TextStyle(
                              fontSize: 36,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        SizedBox(
                          width: 90,
                          child: TextField(
                            controller: _diastolicController,
                            keyboardType: TextInputType
                                .number, // Tylko klawiatura numeryczna
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _dateController,
              readOnly: true, //wymuszamy kliknięcie
              onTap: _pickDateTime,
              decoration: InputDecoration(
                labelText: _isEditing
                    ? 'Data pomiaru'
                    : 'Data pomiaru (domyślnie Teraz)',
                prefixIcon: const Icon(Icons.calendar_today),
                border: const OutlineInputBorder(),
                // Dodajemy przycisk "X", aby wyczyścić datę i wrócić do "teraz"
                suffixIcon: !_isEditing && _selectedDateTime != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _selectedDateTime = null;
                            _dateController.clear();
                          });
                        },
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Notatka (opcjonalnie)',
                hintText: 'Np. Pomiar po śniadaniu...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: () => _submitPressure(),
              icon: const Icon(Icons.check),
              label: Text(_isEditing ? 'Zapisz zmiany' : 'Zapisz pomiar'),
            ),
          ],
        ),
      ),
    );
  }
}
