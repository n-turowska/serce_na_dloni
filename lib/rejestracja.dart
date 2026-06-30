import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'utils/emailValidator.dart';

class Rejestracja extends ConsumerStatefulWidget {
  const Rejestracja({super.key});

  @override
  ConsumerState<Rejestracja> createState() => _RejestracjaState();
}

class _RejestracjaState extends ConsumerState<Rejestracja> {
  final _formKey = GlobalKey<FormState>();

  // Kontrolery dla nowych pól tekstowych
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }



  Future<void> _uruchomRejestracje() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .register(
            _emailController.text.trim(),
            _firstNameController.text.trim(),
            _lastNameController.text.trim(),
            _passwordController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konto zostało utworzone!')),
        );
        Navigator.pushReplacementNamed(context, '/startowy');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
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
                      validator: (value) =>
                          value!.isEmpty ? 'Podaj swoje imię' : null,
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
                      validator: (value) =>
                          value!.isEmpty ? 'Podaj swoje nazwisko' : null,
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
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Podaj adres email';
                        }
                        if (!isValidEmail(value)) {
                          return 'Wprowadź poprawny adres email';
                        }
                        return null;
                      },
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
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF6750A4),
                              ),
                              onPressed: _uruchomRejestracje,
                              child: const Text(
                                'Załóż konto i zaloguj się',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),

                    // Powrót do logowania
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Masz już konto? Zaloguj się',
                        style: TextStyle(color: Colors.grey),
                      ),
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
