import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/pressure_provider.dart';

class Pomiary extends ConsumerStatefulWidget{
  
  const Pomiary({super.key});

  @override
  ConsumerState<Pomiary> createState() => _PomiaryState();
}

class _PomiaryState extends ConsumerState<Pomiary> {
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _noteController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime? _selectedDateTime; // zmienna przechowująca wybraną datę wstecz

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _noteController.dispose();
    _dateController.dispose;
    super.dispose();
  }

  // Funkcja otwierająca systemowy kalendarz
  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000), // najstarsza możliwa data do wybrania
      lastDate: now, // blokujemy wybieranie dat z przyszłości
    );

    if (pickedDate == null) return;
    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return; // Jeśli użytkownik zamknął zegarek

    // 3. Połączenie dnia i godziny w jeden obiekt DateTime
    final fullDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _selectedDateTime = fullDateTime;
      // Wyświetlamy użytkownikowi ładny, pełny format: Data + Godzina
      _dateController.text = DateFormat('dd-MM-yyyy – HH:mm').format(fullDateTime);
    });
  }

  void _submitPressure() {
    final systolic = int.tryParse(_systolicController.text) ?? 0;
    final diastolic = int.tryParse(_diastolicController.text) ?? 0;

    // Prosta walidacja, żeby użytkownik nie wpisał bzdur
    if (systolic <= 0 || diastolic <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proszę podać poprawne wartości ciśnienia!')),
      );
      return;
    }

    ref.read(pressureProvider.notifier).addPressure(
      systolic,
      diastolic,
      _noteController.text.isEmpty ? null : _noteController.text,
      createdAt: _selectedDateTime,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pomiar został zapisany')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Dodaj pomiar"),
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
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
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
                          keyboardType: TextInputType.number, // Tylko klawiatura numeryczna
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        '/',
                        style: TextStyle(fontSize: 36, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),

                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _diastolicController,
                        keyboardType: TextInputType.number, // Tylko klawiatura numeryczna
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
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
                labelText: 'Data pomiaru (domyślnie Teraz)',
                prefixIcon: const Icon(Icons.calendar_today),
                border: const OutlineInputBorder(),
                // Dodajemy przycisk "X", aby wyczyścić datę i wrócić do "teraz"
                suffixIcon: _selectedDateTime != null 
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
              onPressed: _submitPressure,
              icon: const Icon(Icons.check),
              label: const Text('Zapisz pomiar'),
            ),
          ],
        ),
      ),
    );
  }
}