import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Center(
        child: Text("Witaj w aplikacji Serce na Dłoni!"),
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