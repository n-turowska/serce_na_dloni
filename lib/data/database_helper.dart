import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
     final dbPath = await getDatabasesPath();
     final path = join(dbPath, 'pressures.db');
     return await openDatabase(path, version: 1, onCreate: _onCreate);
  }
  
  Future<void> _onCreate(Database db, int version) async {
     await db.execute('''
    CREATE TABLE pressure_entries(
      id TEXT PRIMARY KEY,
      systolic INTEGER NOT NULL,
      diastolic INTEGER NOT NULL,
      note TEXT,
      created_at TEXT NOT NULL
    )
  ''');
  }

  Future<void> insertPressure(Map<String, dynamic> pressure) async {
       final db = await database;
       print('--- SQLITE INSERT: $pressure');

       await db.insert(
         'pressure_entries',
         pressure,
         conflictAlgorithm: ConflictAlgorithm.replace,
       );
     }
  // ConflictAlgorithm.replace means: if an entry with the same id already
  // exists, replace it instead of throwing an error.

  Future<List<Map<String, dynamic>>> getPressures() async {
    final db = await database;
    final result = await db.query('pressure_entries', orderBy: 'created_at DESC');

    print('--- SQLITE FETCHED ENTRIES COUNT: ${result.length}');
    return result;
  }
  
  Future<void> deletePressure(String id) async {
    final db = await database;
    await db.delete('pressure_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updatePressure(String id, Map<String, dynamic> pressure) async {
    final db = await database;
    await db.update(
    'pressure_entries',
    pressure,
    where: 'id = ?',
    whereArgs: [id],
  );
  }
}
