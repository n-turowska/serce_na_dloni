import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../utils/emailValidator.dart';

class Logowanie extends ConsumerStatefulWidget {
  const Logowanie({super.key});

  @override
  ConsumerState<Logowanie> createState() => _LogowanieState();
}

class _LogowanieState extends ConsumerState<Logowanie> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/startowy', (route) => false);
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
              child: Form(
                key: _formKey,

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Witamy w Serce na Dłoni!',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Pole LOGIN
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) {
                          return 'Proszę podać email';
                        }
                        if (email.toLowerCase() == adminUsername) {
                          return null;
                        }
                        if (!isValidEmail(email)) {
                          return 'Wprowadź poprawny adres email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Pole HASŁO
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true, // ukrywa wpisywane znaki (kropki)
                      decoration: const InputDecoration(
                        labelText: 'Hasło',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Proszę podać hasło';
                        }
                        if (value.length < 6) {
                          return 'Hasło musi mieć minimum 6 znaków';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : FilledButton(
                            onPressed:
                                _login, // Wywołuje oficjalne logowanie przez API
                            child: const Text('Zaloguj się'),
                          ),

                    const SizedBox(height: 8),

                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Nie masz jeszcze konta?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/rejestracja');
                      },
                      icon: const Icon(
                        Icons.person_add,
                        color: Color(0xFF6750A4),
                      ),
                      label: const Text(
                        'Zarejestruj się',
                        style: TextStyle(
                          color: Color(0xFF6750A4),
                          fontWeight: FontWeight.bold,
                        ),
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
