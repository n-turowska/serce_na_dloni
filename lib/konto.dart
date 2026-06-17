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
      body: Text("To twoje konto"),

    );
  }
}