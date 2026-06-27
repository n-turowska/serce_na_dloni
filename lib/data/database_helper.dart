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
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE pressure_entries(
      id TEXT PRIMARY KEY,
      systolic INTEGER NOT NULL,
      diastolic INTEGER NOT NULL,
      note TEXT,
      created_at TEXT NOT NULL,
      user_email TEXT
    )
  ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE pressure_entries ADD COLUMN user_email TEXT',
      );
    }
  }

  Future<void> insertPressure(
    Map<String, dynamic> pressure, {
    required String userEmail,
  }) async {
    final db = await database;
    final pressureWithUser = {...pressure, 'user_email': userEmail};

    await db.insert(
      'pressure_entries',
      pressureWithUser,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  // ConflictAlgorithm.replace means: if an entry with the same id already
  // exists, replace it instead of throwing an error.

  Future<List<Map<String, dynamic>>> getPressures({
    required String userEmail,
  }) async {
    final db = await database;
    final result = await db.query(
      'pressure_entries',
      where: 'user_email = ?',
      whereArgs: [userEmail],
      orderBy: 'created_at DESC',
    );

    return result;
  }

  Future<void> deletePressure(String id, {required String userEmail}) async {
    final db = await database;
    await db.delete(
      'pressure_entries',
      where: 'id = ? AND user_email = ?',
      whereArgs: [id, userEmail],
    );
  }

  Future<void> updatePressure(
    String id,
    Map<String, dynamic> pressure, {
    required String userEmail,
  }) async {
    final db = await database;
    final pressureWithUser = {...pressure, 'user_email': userEmail};
    await db.update(
      'pressure_entries',
      pressureWithUser,
      where: 'id = ? AND user_email = ?',
      whereArgs: [id, userEmail],
    );
  }
}
