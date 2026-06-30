import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/blog_provider.dart';

class Artykul {
  final String id;
  final String tytul;
  final String opis;
  final String? sciezka;
  final String? content;
  final bool isRead;

  Artykul({
    required this.id,
    required this.tytul,
    required this.opis,
    this.sciezka,
    this.content,
    this.isRead = false,
  });

  Artykul copyWith({
    String? id,
    String? tytul,
    String? opis,
    String? sciezka,
    String? content,
    bool? isRead,
  }) {
    return Artykul(
      id: id ?? this.id,
      tytul: tytul ?? this.tytul,
      opis: opis ?? this.opis,
      sciezka: sciezka ?? this.sciezka,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tytul': tytul,
        'opis': opis,
        'sciezka': sciezka,
        'content': content,
        'isRead': isRead,
      };

  factory Artykul.fromJson(Map<String, dynamic> json) => Artykul(
        id: json['id'] as String,
        tytul: json['tytul'] as String,
        opis: json['opis'] as String,
        sciezka: json['sciezka'] as String?,
        content: json['content'] as String?,
        isRead: json['isRead'] as bool? ?? false,
      );
}

class Blog extends ConsumerStatefulWidget {
  const Blog({super.key});

  @override
  ConsumerState<Blog> createState() => _BlogState();
}

class _BlogState extends ConsumerState<Blog> {
  // funkcja, która czyta plik tekstowy lub zwraca wpisany tekst
  Future<String> wczytajTekst(Artykul wpis) async {
    if (wpis.content != null) {
      return wpis.content!;
    }
    if (wpis.sciezka != null) {
      return await rootBundle.loadString(wpis.sciezka!);
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final wpisy = ref.watch(blogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Blog"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: wpisy.isEmpty
          ? const Center(
              child: Text(
                "Brak artykułów.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12.0), //odstęp od krawędzi ekranu
              itemCount: wpisy.length,
              itemBuilder: (context, index) {
                final wpis = wpisy[index];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8.0), //odstęp między kafelkami
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // zaokrąglone rogi
                  ),
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    leading: IconButton(
                      icon: Icon(
                        wpis.isRead ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: wpis.isRead ? Colors.green : Colors.grey,
                        size: 28,
                      ),
                      onPressed: () {
                        ref.read(blogProvider.notifier).toggleRead(wpis.id);
                      },
                    ),
                    title: Text(
                      wpis.tytul,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        wpis.opis,
                        style: TextStyle(color: Colors.grey[700]),
                      ), // Text
                    ),
                    children: [
                      FutureBuilder<String>(
                        future: wczytajTekst(wpis),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            // co się wyświetla podczas ładowania pliku
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text("Błąd podczas wczytywania artykułu."),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                            child: Text(
                              snapshot.data ?? "",
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.4,
                              ),
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
  }
}