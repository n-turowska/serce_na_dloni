import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'blog.dart';
import 'startowy.dart';
import 'pomiary.dart';
import 'konto.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Serce na Dłoni'),
      routes: {
        '/startowy': (context) => const MyHomePage(title: 'Serce na Dłoni'),
        '/blog': (context) => const Blog(),
        '/pomiary': (context) => const Pomiary(),
        '/konto' : (context) => const Konto(),
      }
    );
  }
}


