import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pressure_entry.dart';
import '../data/pressure_repository.dart';

class PressureNotifier extends StateNotifier<List<PressureEntry>> { 
  final PressureRepository _repository;
  PressureNotifier(this._repository) : super([]){
    loadPressures;
  }

  Future<void> loadPressures() async {
    List<PressureEntry> loadedPressures = await _repository.getAllPressures();

    if(loadedPressures.isEmpty){
    final przykladoweWpisy = [
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
      ];

      for (var wpis in przykladoweWpisy) {
        await _repository.addPressure(wpis.systolic, wpis.diastolic, wpis.note);
      }
    }
    state = await _repository.getAllPressures();
  }

  Future<void> addPressure(int systolic, int diastolic, String? note, {DateTime? createdAt}) async {
    final newEntry = PressureEntry(
      systolic: systolic,
      diastolic: diastolic,
      note: note,
      createdAt: createdAt,
    );
    await _repository.addPressure(newEntry.systolic, newEntry.diastolic, newEntry.note);
    state = [newEntry, ...state];
  }
  
  Future<void> deletePressure(String id) async {
    await _repository.deletePressure(id);
    state = state.where((e) => e.id != id).toList();
  }
   
  // updatePressure
  void updatePressure(String id, int systolic, int diastolic, String? note) async {
    final updated =
      state.firstWhere((e) => e.id == id).copyWith(systolic: systolic, diastolic: diastolic, note:note);
    await _repository.updatePressure(updated);
    state = state.map((e) => e.id == id ?  updated : e).toList();
  }
}

final pressureProvider = StateNotifierProvider<PressureNotifier, List<PressureEntry>>((ref) {
  final repository = PressureRepository();
  return PressureNotifier(repository);
});

final pressureStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final pressures = ref.watch(pressureProvider);
  // Calculate and return stats map
  if (pressures.isEmpty) {
    return {'totalEntries': 0, 'averageSystolic': 0.0, 'highestSystolic': 0, 'lowestSystolic': 0,
              'averageDiastolic': 0.0, 'highestDiastolic': 0, 'lowestDiastolic': 0};
  }
  final systolics = pressures.map((m) => m.systolic).toList();
  final diastolics = pressures.map((m) => m.diastolic).toList();
  return {
    'totalEntries': pressures.length,
    'averageSystolic': systolics.reduce((a, b) => a + b) / systolics.length,
    'highestSystolic': systolics.reduce((a, b) => a > b ? a : b),
    'lowestSystolic': systolics.reduce((a, b) => a < b ? a : b),
    'averageDiastolic': diastolics.reduce((a, b) => a + b) / systolics.length,
    'highestDiastolic': diastolics.reduce((a, b) => a > b ? a : b),
    'lowestDiastolic': diastolics.reduce((a, b) => a < b ? a : b),
  };
});