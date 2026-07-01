import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'blog.dart';
import 'providers/blog_provider.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';

class AdminPanel extends ConsumerWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (user) {
        if (user.privilege != Privilege.Admin) {
          // Display Brak uprawnień and a button to navigate back
          return Scaffold(
            appBar: AppBar(
              title: const Text("Brak Uprawnień"),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              centerTitle: true,
              automaticallyImplyLeading: false,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.gpp_bad, size: 80, color: Colors.red),
                    const SizedBox(height: 24),
                    const Text(
                      "Brak uprawnień",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Ta strefa jest przeznaczona wyłącznie dla administratorów systemu.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Wróć"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const AdminDashboardScreen();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Wystąpił błąd: $err"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Wróć"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  void _pokazEdycjeWpisu(BuildContext context, WidgetRef ref, [Artykul? wpis]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EdycjaWpisuDialog(wpis: wpis),
    );
  }

  void _potwierdzUsuniecie(BuildContext context, WidgetRef ref, Artykul wpis) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Usuń artykuł"),
        content: Text("Czy na pewno chcesz usunąć artykuł \"${wpis.tytul}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Anuluj"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(blogProvider.notifier).removeWpis(wpis.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Artykuł został usunięty.")),
                );
              }
            },
            child: const Text("Usuń", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wpisy = ref.watch(blogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel Administratora"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: wpisy.isEmpty
          ? const Center(
              child: Text(
                "Brak artykułów. Dodaj nowy przyciskiem +",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: wpisy.length,
              itemBuilder: (context, index) {
                final wpis = wpisy[index];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      wpis.tytul,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        wpis.opis,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: "Edytuj wpis",
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () =>
                              _pokazEdycjeWpisu(context, ref, wpis),
                        ),
                        IconButton(
                          tooltip: "Usuń wpis",
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _potwierdzUsuniecie(context, ref, wpis),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pokazEdycjeWpisu(context, ref),
        tooltip: "Dodaj artykuł",
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EdycjaWpisuDialog extends StatefulWidget {
  final Artykul? wpis;

  const _EdycjaWpisuDialog({this.wpis});

  @override
  State<_EdycjaWpisuDialog> createState() => _EdycjaWpisuDialogState();
}

class _EdycjaWpisuDialogState extends State<_EdycjaWpisuDialog> {
  late final TextEditingController _tytulController;
  late final TextEditingController _opisController;
  late final TextEditingController _trescController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tytulController = TextEditingController(text: widget.wpis?.tytul ?? "");
    _opisController = TextEditingController(text: widget.wpis?.opis ?? "");
    _trescController = TextEditingController();

    if (widget.wpis != null) {
      if (widget.wpis!.content != null) {
        _trescController.text = widget.wpis!.content!;
      } else if (widget.wpis!.sciezka != null) {
        _trescController.text = "...wczytywanie...";
        DefaultAssetBundle.of(context)
            .loadString(widget.wpis!.sciezka!)
            .then((val) {
              if (mounted) {
                setState(() {
                  _trescController.text = val;
                });
              }
            })
            .catchError((_) {
              if (mounted) {
                setState(() {
                  _trescController.text = "";
                });
              }
            });
      }
    }
  }

  @override
  void dispose() {
    _tytulController.dispose();
    _opisController.dispose();
    _trescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.wpis == null ? "Dodaj Nowy Wpis" : "Edytuj Wpis"),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _tytulController,
                  decoration: const InputDecoration(
                    labelText: "Tytuł artykułu",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? "Podaj tytuł"
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _opisController,
                  decoration: const InputDecoration(
                    labelText: "Krótki opis / zajawka",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? "Podaj krótki opis"
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _trescController,
                  decoration: const InputDecoration(
                    labelText: "Pełna treść artykułu",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 10,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? "Podaj treść artykułu"
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Anuluj"),
        ),
        Consumer(
          builder: (context, ref, child) {
            return FilledButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                final tytul = _tytulController.text.trim();
                final opis = _opisController.text.trim();
                final tresc = _trescController.text.trim();

                Navigator.pop(context);

                if (widget.wpis == null) {
                  await ref
                      .read(blogProvider.notifier)
                      .addWpis(tytul, opis, tresc);
                } else {
                  await ref
                      .read(blogProvider.notifier)
                      .editWpis(widget.wpis!.id, tytul, opis, tresc);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.wpis == null
                            ? "Pomyślnie dodano artykuł!"
                            : "Pomyślnie zapisano zmiany!",
                      ),
                    ),
                  );
                }
              },
              child: const Text("Zapisz"),
            );
          },
        ),
      ],
    );
  }
}
