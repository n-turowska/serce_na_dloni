import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'providers/auth_provider.dart';
import 'blog.dart';
import 'admin.dart';
import 'startowy.dart';
import 'pomiary.dart';
import 'konto.dart';
import 'logowanie.dart';
import 'przypomnienia.dart';
import 'rejestracja.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  final container = ProviderContainer();

  await container.read(authProvider.notifier).checkAuth();

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Serce_na_Dloni',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      home: switch (authState) {
        AuthState.authenticated => const MyHomePage(),
        AuthState.unauthenticated => const Logowanie(),
        AuthState.loading => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        AuthState.initial => const _AuthCheckScreen(),
      },

      routes: {
        '/logowanie': (context) => const Logowanie(),
        '/rejestracja': (context) => const Rejestracja(),
        '/startowy': (context) => const MyHomePage(),
        '/blog': (context) => const Blog(),
        '/pomiary': (context) => const Pomiary(),
        '/przypomnienia': (context) => const Przypomnienia(),
        '/konto': (context) => const Konto(),
        '/admin': (context) => const AdminPanel(),
      },
    );
  }
}

class _AuthCheckScreen extends ConsumerStatefulWidget {
  const _AuthCheckScreen();

  @override
  ConsumerState<_AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends ConsumerState<_AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).checkAuth());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
