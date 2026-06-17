import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pressure_entry.dart';

class PressureNotifier extends StateNotifier<List<PressureEntry>> { 
  
  PressureNotifier() : super([
    PressureEntry(
      id: '1', 
      systolic: 120, 
      diastolic: 80, 
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      note: 'Pomiar poranny',
    ),
    PressureEntry(
      id: '2', 
      systolic: 135, 
      diastolic: 85, 
      createdAt: DateTime.now(),
      note: 'Po kawie',
    ),
  ]);

  // addPressure
  void addPressure({required int systolic, required int diastolic, String? note}) {
    //tu trzeba jeszcze uwzględnić wpis starego pomiaru - ktoś wpisuje datę w formacie: "2026-06-10 08:30:00"
    final newEntry = PressureEntry(
      systolic: systolic,
      diastolic: diastolic,
      note: note,
    );

    state = [newEntry, ...state];
  }
   

  // deletePressure
  void deletePressure(String id) {
    state = state.where((e) => e.id != id).toList();
  }
   

  // updatePressure
  void updatePressure(String id, int systolic, int diastolic, String? note) {
    state = state.map((e) => e.id == id ? e.copyWith(systolic: systolic, diastolic: diastolic, note: note) : e).toList();
  }
  
}