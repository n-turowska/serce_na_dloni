import 'package:flutter/material.dart';

class Pomiary extends StatefulWidget{
  
    const Pomiary({super.key});

    @override
  State<Pomiary> createState() => _PomiaryState();
}

class _PomiaryState extends State<Pomiary> {

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Dodaj pomiar"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Text("Pomiar 1"),

    );
  }
}