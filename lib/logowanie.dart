import 'package:flutter/material.dart';

class Logowanie extends StatefulWidget{
  
    const Logowanie({super.key});

    @override
  State<Logowanie> createState() => _LogowanieState();
}

class _LogowanieState extends State<Logowanie> {

  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _wejdzBezLogowania() {
    // Przechodzimy do ekranu głównego i usuwamy ekran logowania z historii (pushReplacementNamed),
    // dzięki czemu użytkownik po kliknięciu "wstecz" na ekranie głównym nie wróci do logowania.
    Navigator.pushReplacementNamed(context, '/startowy');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Serce na Dłoni"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),

            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Witamy w Serce na Dłoni!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Pole LOGIN
                  TextField(
                    controller: _loginController,
                    decoration: const InputDecoration(
                      labelText: 'Nazwa użytkownika',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pole HASŁO
                  TextField(
                    controller: _passwordController,
                    obscureText: true, // ukrywa wpisywane znaki (kropki)
                    decoration: const InputDecoration(
                      labelText: 'Hasło',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Przycisk Zaloguj (na razie po prostu wpuszcza dalej)
                  FilledButton(
                    onPressed: _wejdzBezLogowania,
                    child: const Text('Zaloguj'),
                  ),
                  
                  const SizedBox(height: 8),
                
                  Text(
                    'Wersja testowa, po prostu kliknij Zaloguj bez podawania danych',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}