import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pressure_provider.dart';

class Pomiary extends ConsumerStatefulWidget{
  
  const Pomiary({super.key});

  @override
  ConsumerState<Pomiary> createState() => _PomiaryState();
}

class _PomiaryState extends ConsumerState<Pomiary> {
  int _systolic = 80;
  int _diastolic = 80;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submitPressure() {
       ref.read(pressureProvider.notifier).addPressure(
        _systolic,
        _diastolic,
        _noteController.text.isEmpty ? null : _noteController.text,
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Podaj wyniki pomiaru ciśnienia',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Text(
              'Systolic: $_systolic',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            Text(
              'Diastolic: $_diastolic',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'How was your day?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submitPressure,
              icon: const Icon(Icons.check),
              label: const Text('Save Entry'),
            ),
          ],
        ),
      ),

    );
  }
}