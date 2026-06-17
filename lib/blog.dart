import 'package:flutter/material.dart';

class Blog extends StatefulWidget{
  
    const Blog({super.key});

    @override
  State<Blog> createState() => _BlogState();
}

class _BlogState extends State<Blog> {

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Blog"),
      ),
      body: Text("Wpis 1"),

    );
  }
}