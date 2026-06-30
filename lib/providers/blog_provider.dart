import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../blog.dart';

class BlogNotifier extends StateNotifier<List<Artykul>> {
  BlogNotifier() : super([]) {
    _loadBlogi();
  }

  static const _spKey = 'blog_entries';

  Future<void> _loadBlogi() async {
    final sp = await SharedPreferences.getInstance();
    final data = sp.getString(_spKey);
    if (data == null) {
      final domyslne = [
        Artykul(
          id: "artykul1",
          tytul: "Tytuł",
          opis: " Opis",
          sciezka: "wpisy/artykul1.txt",
        ),
        Artykul(
          id: "artykul2",
          tytul: "Tytuł",
          opis: " Opis",
          sciezka: "wpisy/artykul2.txt",
        ),
        Artykul(
          id: "artykul3",
          tytul: "Tytuł",
          opis: " Opis",
          sciezka: "wpisy/artykul3.txt",
        ),
        Artykul(
          id: "artykul4",
          tytul: "Tytuł",
          opis: " Opis",
          sciezka: "wpisy/artykul4.txt",
        ),
        Artykul(
          id: "artykul5",
          tytul: "Tytuł",
          opis: " Opis",
          sciezka: "wpisy/artykul5.txt",
        ),
      ];
      state = domyslne;
      await _saveToPrefs(domyslne);
    } else {
      final List<dynamic> decoded = jsonDecode(data);
      state = decoded
          .map((e) => Artykul.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _saveToPrefs(List<Artykul> lista) async {
    final sp = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(lista.map((e) => e.toJson()).toList());
    await sp.setString(_spKey, jsonStr);
  }

  Future<void> addWpis(String tytul, String opis, String content) async {
    final nowy = Artykul(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tytul: tytul,
      opis: opis,
      content: content,
    );
    final nowaLista = [...state, nowy];
    state = nowaLista;
    await _saveToPrefs(nowaLista);
  }

  Future<void> editWpis(
    String id,
    String tytul,
    String opis,
    String content,
  ) async {
    final nowaLista = state.map((wpis) {
      if (wpis.id == id) {
        return wpis.copyWith(
          tytul: tytul,
          opis: opis,
          content: content,
          sciezka: null, // Clear the file path since it now has custom database content
        );
      }
      return wpis;
    }).toList();
    state = nowaLista;
    await _saveToPrefs(nowaLista);
  }

  Future<void> removeWpis(String id) async {
    final nowaLista = state.where((wpis) => wpis.id != id).toList();
    state = nowaLista;
    await _saveToPrefs(nowaLista);
  }

  Future<void> toggleRead(String id) async {
    final nowaLista = state.map((wpis) {
      if (wpis.id == id) {
        return wpis.copyWith(isRead: !wpis.isRead);
      }
      return wpis;
    }).toList();
    state = nowaLista;
    await _saveToPrefs(nowaLista);
  }
}

final blogProvider = StateNotifierProvider<BlogNotifier, List<Artykul>>((ref) {
  return BlogNotifier();
});
