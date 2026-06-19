import '../models/pressure_entry.dart';
import '../services/pressure_api_service.dart';
import 'database_helper.dart';

class PressureRepository {
  final DatabaseHelper _dbHelper;
  final PressureApiService _apiService;

  PressureRepository({DatabaseHelper? dbHelper, PressureApiService? apiService})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _apiService = apiService ?? PressureApiService();


  Future<List<PressureEntry>> getAllPressures() async {
    try { 
      final pressures = await _apiService.getPressures();
      return pressures;
    } catch (e) {
      // API failed — fall back to local database
      final maps = await _dbHelper.getPressures();
      return maps.map((m) => PressureEntry.fromMap(m)).toList();
    }
  }
  
  Future<PressureEntry> addPressure(int systolic, int diastolic, String? note) async {
  try {
    final entry = await _apiService.createPressure(systolic, diastolic, note); 
    await _dbHelper.insertPressure(entry.toMap()); 
    return entry;
  } catch (e) {
    // API failed — save locally only
    final entry = PressureEntry(systolic: systolic, diastolic: diastolic, note: note); 
    await _dbHelper.insertPressure(entry.toMap());
    return entry;
  }
}
  
  Future<void> deletePressure(String id) async {
    await _dbHelper.deletePressure(id);
  }
  
  Future<void> updatePressure(PressureEntry entry) async {
    await _dbHelper.updatePressure(entry.id, entry.toMap());
  }
}
