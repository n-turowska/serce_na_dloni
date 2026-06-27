import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pressure_entry.dart';
import '../data/pressure_repository.dart';

class PressureNotifier extends StateNotifier<List<PressureEntry>> {
  final PressureRepository _repository;
  PressureNotifier(this._repository) : super([]) {
    loadPressures();
  }

  Future<void> loadPressures() async {
    try {
      final entries = await _repository.getAllPressures();
      state = entries;
    } catch (e) {
      state = [];
    }
  }

  Future<void> addPressure(
    int systolic,
    int diastolic,
    String? note, {
    DateTime? createdAt,
  }) async {
    try {
      final savedEntry = await _repository.addPressure(
        systolic,
        diastolic,
        note,
        createdAt: createdAt,
      );

      state = [savedEntry, ...state];
    } catch (e) {
      await loadPressures();
    }
  }

  Future<void> deletePressure(String id) async {
    await _repository.deletePressure(id);
    state = state.where((e) => e.id != id).toList();
  }

  void updatePressure(
    String id,
    int systolic,
    int diastolic,
    String? note,
  ) async {
    final updated = state
        .firstWhere((e) => e.id == id)
        .copyWith(systolic: systolic, diastolic: diastolic, note: note);
    await _repository.updatePressure(updated);
    state = state.map((e) => e.id == id ? updated : e).toList();
  }
}

final pressureProvider =
    StateNotifierProvider.autoDispose<PressureNotifier, List<PressureEntry>>((
      ref,
    ) {
      final repository = PressureRepository();
      return PressureNotifier(repository);
    });

final pressureStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final pressures = ref.watch(pressureProvider);
  // Calculate and return stats map
  if (pressures.isEmpty) {
    return {
      'totalEntries': 0,
      'averageSystolic': 0.0,
      'highestSystolic': 0,
      'lowestSystolic': 0,
      'averageDiastolic': 0.0,
      'highestDiastolic': 0,
      'lowestDiastolic': 0,
    };
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
