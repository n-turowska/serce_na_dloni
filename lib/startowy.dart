import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/pressure_provider.dart';
import '../models/pressure_entry.dart';
import 'pomiary.dart';

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends ConsumerState<MyHomePage> {
  
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(pressureProvider.notifier).loadPressures();
    });
  }

  @override
  Widget build(BuildContext context) {
  
    final pressures = ref.watch(pressureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pressure Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: pressures.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_neutral, size: 64, color: Colors.black),
                  SizedBox(height: 16),
                  Text(
                    'No mood entries yet',
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add your first entry',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: pressures.length,
              itemBuilder: (context, index) {
                final entry = pressures[index];
                return Card( margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(
                    entry.note ?? 'No note',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: entry.note == null
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : null,
                      fontStyle: entry.note == null ? FontStyle.italic : null,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('MMM d, yyyy – HH:mm').format(entry.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),);
              },
            ),
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.inversePrimary,
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // PIERWSZY BUTTON: BLOG
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/blog');
              },
              child: const Text("Blog"),
            ),
          
            const SizedBox(width: 20),

            // DRUGI BUTTON: DODAJ POMIAR
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/pomiary');
              },
              icon: const Icon(Icons.add), // Ikona plusa
              label: const Text("Pomiar"),
            ),
            
            const SizedBox(width: 20), // Odstęp między przyciskami
            
            // TRZECI BUTTON: KONTO
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/konto');
              },
              child: const Text("Konto"),
            )
          ], // children
        ),
      ),
    );
  }
}
