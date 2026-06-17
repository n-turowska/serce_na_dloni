import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class Artykul {
  final String tytul;
  final String opis;
  final String sciezka;

  Artykul({
    required this.tytul,
    required this.opis,
    required this.sciezka,
  });
}

class Blog extends StatefulWidget{
  
    const Blog({super.key});

    @override
  State<Blog> createState() => _BlogState();
}

class _BlogState extends State<Blog> {
  final List<Artykul> wpisy = [
    Artykul(
      tytul: "Tytuł",
      opis: " Opis",
      sciezka: "wpisy/artykul1.txt",
    ),
    Artykul(
      tytul: "Tytuł",
      opis: " Opis",
      sciezka: "wpisy/artykul2.txt",
    ),
    Artykul(
      tytul: "Tytuł",
      opis: " Opis",
      sciezka: "wpisy/artykul3.txt",
    ),
    Artykul(
      tytul: "Tytuł",
      opis: " Opis",
      sciezka: "wpisy/artykul4.txt",
    ),
    Artykul(
      tytul: "Tytuł",
      opis: " Opis",
      sciezka: "wpisy/artykul5.txt",
    ),
  ];

  // funkcja, która czyta plik tekstowy
  Future<String> wczytajTekst(String sciezka) async {
    return await rootBundle.loadString(sciezka);
  }

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
            margin: const EdgeInsets.symmetric(vertical: 8.0), //odstęp między kafelkami
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // zaokrąglone rogi
            ),

            child:ExpansionTile(
              shape:const Border(),
              collapsedShape: const Border(),

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
                  future: wczytajTekst(wpis.sciezka),
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