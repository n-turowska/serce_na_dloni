import 'package:flutter/material.dart';

class Rejestracja extends StatefulWidget {
  const Rejestracja({super.key});

  @override
  State<Rejestracja> createState() => _RejestracjaState();
}

class _RejestracjaState extends State<Rejestracja> {
  final _formKey = GlobalKey<FormState>();
  
  // Kontrolery dla nowych pól tekstowych
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _zalozKontoMock() {
    if (!_formKey.currentState!.validate()) return;

    print('--- KLIKNIĘTO: ZAŁÓŻ KONTO (Wersja testowa) ---');
    print('Imię: ${_firstNameController.text}');
    print('Nazwisko: ${_lastNameController.text}');
    print('Email: ${_emailController.text}');
    print('Hasło: [UKRYTE - długość: ${_passwordController.text.length} znaków]');
    print('---------------------------------------------');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rejestracja testowa pomyślna! Witamy.')),
    );

    // Przekierowanie na ekran startowy po założeniu konta
    Navigator.pushReplacementNamed(context, '/startowy');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stwórz konto"),
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Dołącz do Serce na Dłoni',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Pole: IMIĘ
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Imię',
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Podaj swoje imię' : null,
                    ),
                    const SizedBox(height: 16),

                    // Pole: NAZWISKO
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nazwisko',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Podaj swoje nazwisko' : null,
                    ),
                    const SizedBox(height: 16),

                    // Pole: EMAIL
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Adres Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Podaj adres email' : null,
                    ),
                    const SizedBox(height: 16),

                    // Pole: HASŁO
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Utwórz hasło',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) return 'Wpisz hasło';
                        if (value.length < 6) return 'Minimum 6 znaków';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // PRZYCISK: ZAŁÓŻ KONTO I ZALOGUJ SIĘ
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6750A4), // Fiolet motywu
                        ),
                        onPressed: _zalozKontoMock,
                        child: const Text(
                          'Załóż konto i zaloguj się',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Powrót do logowania
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Masz już konto? Zaloguj się', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}