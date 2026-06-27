import '../models/pressure_entry.dart';
import '../services/auth_service.dart';
import '../services/pressure_api_service.dart';
import 'database_helper.dart';

class PressureRepository {
  final DatabaseHelper _dbHelper;
  final PressureApiService _apiService;
  final AuthService _authService;

  PressureRepository({
    DatabaseHelper? dbHelper,
    PressureApiService? apiService,
    AuthService? authService,
  }) : _dbHelper = dbHelper ?? DatabaseHelper.instance,
       _apiService = apiService ?? PressureApiService(),
       _authService = authService ?? AuthService();

  Future<String> _getCurrentUserEmail() async {
    final email = await _authService.getCurrentEmail();
    if (email == null || email.isEmpty) {
      throw AuthException('Brak zalogowanego użytkownika.');
    }
    return email;
  }

  Future<List<PressureEntry>> getAllPressures() async {
    final userEmail = await _getCurrentUserEmail();

    try {
      final pressures = await _apiService.getPressures();
      final localMaps = await _dbHelper.getPressures(userEmail: userEmail);
      final localEntries = localMaps.map((map) => PressureEntry.fromMap(map));
      final localById = {for (final entry in localEntries) entry.id: entry};
      final serverIds = pressures.map((entry) => entry.id).toSet();

      final merged = pressures.map((entry) {
        final localEntry = localById[entry.id];
        return localEntry ?? entry;
      }).toList();
      merged.addAll(
        localById.values.where((entry) => !serverIds.contains(entry.id)),
      );

      for (final entry in merged) {
        await _dbHelper.insertPressure(entry.toMap(), userEmail: userEmail);
      }

      return merged;
    } catch (e) {
      // API failed — fall back to local database
      final maps = await _dbHelper.getPressures(userEmail: userEmail);
      return maps.map((m) => PressureEntry.fromMap(m)).toList();
    }
  }

  Future<PressureEntry> addPressure(
    int systolic,
    int diastolic,
    String? note, {
    DateTime? createdAt,
  }) async {
    final userEmail = await _getCurrentUserEmail();

    try {
      final entry = await _apiService.createPressure(
        systolic,
        diastolic,
        note,
        createdAt: createdAt,
      );
      await _dbHelper.insertPressure(entry.toMap(), userEmail: userEmail);
      return entry;
    } catch (e) {
      // API failed — save locally only
      final entry = PressureEntry(
        systolic: systolic,
        diastolic: diastolic,
        note: note,
        createdAt: createdAt,
      );
      await _dbHelper.insertPressure(entry.toMap(), userEmail: userEmail);
      return entry;
    }
  }

  Future<void> deletePressure(String id) async {
    final userEmail = await _getCurrentUserEmail();

    try {
      // Próba usunięcia z API
      await _apiService.deletePressure(id);
      // Jeśli się udału, usuwamy też lokalnie
      await _dbHelper.deletePressure(id, userEmail: userEmail);
    } catch (e) {
      // API failed — usuwamy tylko lokalnie
      await _dbHelper.deletePressure(id, userEmail: userEmail);
    }
  }

  Future<void> updatePressure(PressureEntry entry) async {
    final userEmail = await _getCurrentUserEmail();

    try {
      // Próba aktualizacji w API
      await _apiService.updatePressure(
        entry.id,
        entry.systolic,
        entry.diastolic,
        entry.note,
        createdAt: entry.createdAt,
      );
      // Jeśli się udało, aktualizujemy lokalną bazę danych
      await _dbHelper.updatePressure(
        entry.id,
        entry.toMap(),
        userEmail: userEmail,
      );
    } catch (e) {
      // API failed — aktualizujemy tylko lokalnie
      await _dbHelper.updatePressure(
        entry.id,
        entry.toMap(),
        userEmail: userEmail,
      );
    }
  }
}
