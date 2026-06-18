import 'package:flutter/material.dart';

class Konto extends StatefulWidget{
  
    const Konto({super.key});

    @override
  State<Konto> createState() => _KontoState();
}

class _KontoState extends State<Konto> {

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
          ],
        ),
      ),
    );
  }
}