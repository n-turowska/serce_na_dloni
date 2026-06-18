import '../models/pressure_entry.dart';
import 'database_helper.dart';

class PressureRepository {
  final DatabaseHelper _dbHelper;

  PressureRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  
  Future<List<PressureEntry>> getAllPressures() async {
    final maps = await _dbHelper.getPressures();
    return maps.map((m) => PressureEntry.fromMap(m)).toList();
  }
  
  Future<void> addPressure(PressureEntry entry) async {
    await _dbHelper.insertPressure(entry.toMap());
  }
  
  Future<void> deletePressure(String id) async {
    await _dbHelper.deletePressure(id);
  }
  
  Future<void> updatePressure(PressureEntry entry) async {
    await _dbHelper.updatePressure(entry.id, entry.toMap());
  }
}
