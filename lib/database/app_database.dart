import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../core/app_constants.dart';
import '../models/app_record.dart';

class AppDatabase {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final root = await getDatabasesPath();
    _database = await openDatabase(
      p.join(root, AppConstants.databaseName),
      version: AppConstants.databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE records (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            date TEXT NOT NULL,
            title TEXT NOT NULL,
            body TEXT NOT NULL DEFAULT '',
            start_at TEXT,
            end_at TEXT,
            done INTEGER NOT NULL DEFAULT 0,
            meta TEXT NOT NULL DEFAULT '{}',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_records_type_date ON records(type, date)');
        await db.execute('CREATE INDEX idx_records_date ON records(date)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Reserved for additive schema migrations.
        }
      },
    );
    return _database!;
  }

  Future<List<AppRecord>> getAll() async {
    final db = await database;
    final rows = await db.query('records', orderBy: 'date DESC, created_at DESC');
    return rows.map(AppRecord.fromMap).toList();
  }

  Future<void> upsert(AppRecord record) async {
    final db = await database;
    await db.insert('records', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    final db = await database;
    await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> replaceAll(List<AppRecord> records) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('records');
      final batch = txn.batch();
      for (final record in records) {
        batch.insert('records', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
