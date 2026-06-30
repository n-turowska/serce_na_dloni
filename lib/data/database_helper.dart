import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../services/pressure_encryption_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final PressureEncryptionService _encryptionService =
      PressureEncryptionService();

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
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE pressure_entries(
      id TEXT PRIMARY KEY,
      user_hash TEXT NOT NULL,
      encrypted_payload TEXT NOT NULL
    )
  ''');
    await db.execute(
      'CREATE INDEX idx_pressure_entries_user_hash ON pressure_entries(user_hash)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE pressure_entries ADD COLUMN user_email TEXT',
      );
    }

    if (oldVersion < 3) {
      await _migratePressureEntriesToEncryptedPayload(db);
    }
  }

  Future<void> insertPressure(
    Map<String, dynamic> pressure, {
    required String userEmail,
  }) async {
    final db = await database;
    final userHash = await _encryptionService.userHash(userEmail);
    final encryptedPayload = await _encryptionService.encryptMap(pressure);

    await db.insert('pressure_entries', {
      'id': pressure['id'],
      'user_hash': userHash,
      'encrypted_payload': encryptedPayload,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  // ConflictAlgorithm.replace means: if an entry with the same id already
  // exists, replace it instead of throwing an error.

  Future<List<Map<String, dynamic>>> getPressures({
    required String userEmail,
  }) async {
    final db = await database;
    final userHash = await _encryptionService.userHash(userEmail);
    final result = await db.query(
      'pressure_entries',
      columns: ['encrypted_payload'],
      where: 'user_hash = ?',
      whereArgs: [userHash],
    );

    final pressures = <Map<String, dynamic>>[];
    for (final row in result) {
      pressures.add(
        await _encryptionService.decryptMap(row['encrypted_payload'] as String),
      );
    }

    pressures.sort((a, b) {
      final createdAtA = DateTime.parse(a['created_at'] as String);
      final createdAtB = DateTime.parse(b['created_at'] as String);
      return createdAtB.compareTo(createdAtA);
    });

    return pressures;
  }

  Future<void> deletePressure(String id, {required String userEmail}) async {
    final db = await database;
    final userHash = await _encryptionService.userHash(userEmail);
    await db.delete(
      'pressure_entries',
      where: 'id = ? AND user_hash = ?',
      whereArgs: [id, userHash],
    );
  }

  Future<void> updatePressure(
    String id,
    Map<String, dynamic> pressure, {
    required String userEmail,
  }) async {
    final db = await database;
    final userHash = await _encryptionService.userHash(userEmail);
    final encryptedPayload = await _encryptionService.encryptMap(pressure);
    await db.update(
      'pressure_entries',
      {'id': id, 'user_hash': userHash, 'encrypted_payload': encryptedPayload},
      where: 'id = ? AND user_hash = ?',
      whereArgs: [id, userHash],
    );
  }

  Future<void> _migratePressureEntriesToEncryptedPayload(Database db) async {
    await db.execute('''
      CREATE TABLE pressure_entries_encrypted(
        id TEXT PRIMARY KEY,
        user_hash TEXT NOT NULL,
        encrypted_payload TEXT NOT NULL
      )
    ''');

    final columns = await db.rawQuery('PRAGMA table_info(pressure_entries)');
    final hasUserEmail = columns.any(
      (column) => column['name'] == 'user_email',
    );
    final rows = await db.query('pressure_entries');

    for (final row in rows) {
      final userEmail = hasUserEmail ? row['user_email'] as String? : null;
      if (userEmail == null || userEmail.trim().isEmpty) {
        continue;
      }

      final payload = {
        'id': row['id'],
        'systolic': row['systolic'],
        'diastolic': row['diastolic'],
        'note': row['note'],
        'created_at': row['created_at'],
      };

      await db.insert('pressure_entries_encrypted', {
        'id': row['id'],
        'user_hash': await _encryptionService.userHash(userEmail),
        'encrypted_payload': await _encryptionService.encryptMap(payload),
      });
    }

    await db.execute('DROP TABLE pressure_entries');
    await db.execute(
      'ALTER TABLE pressure_entries_encrypted RENAME TO pressure_entries',
    );
    await db.execute(
      'CREATE INDEX idx_pressure_entries_user_hash ON pressure_entries(user_hash)',
    );
  }
}
