import 'package:flutter/material.dart';

class Blog extends StatefulWidget{
  
    const Blog({super.key});

    @override
  State<Blog> createState() => _BlogState();
}

class _BlogState extends State<Blog> {
  final List<Map<String, String>> wpisy = [
    {//tak wygląda przykładowy wpis
    "tytuł": "Tytuł wpisu",
    "tekst": "Treść wpisu",
    },

    {
    "tytuł": "Tytuł wpisu",
    "tekst": "Treść wpisu",
    }
  ];

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Blog"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0), //odstęp od krawędzi ekranu
        itemCount: wpisy.length,
        itemBuilder: (context, index) {
          final wpis = wpisy[index];

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8.0), // Odstęp między kafelkami
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Zaokrąglone rogi kafelka
            ),

            child:ListTile(
              contentPadding: const EdgeInsets.all(16.0),

              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              title: Text(
                wpis["tytuł"] ?? "Brak tytułu", 
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  wpis["tekst"] ?? "Brak opisu", 
                  style: TextStyle(color: Colors.grey[700]),
                ), // Text
              ),

              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Tutaj też bezpiecznie bez wykrzyknika
                print("Kliknięto artykuł: ${wpis['tytul'] ?? 'Nieznany'}");
              },
            ),
          );
        },
      ),
    );
  }
}