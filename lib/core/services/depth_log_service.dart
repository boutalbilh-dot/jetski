import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/depth_sample.dart';

class DepthLogService {
  Database? _db;

  Future<void> open() async {
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'jetski_depth_log.db'),
      version: 1,
      onCreate: _migrate,
    );
  }

  /// In-memory variant for tests.
  Future<void> openInMemory() async {
    _db = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: _migrate);
  }

  Future<void> _migrate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE depth_samples (
        timestamp_ms INTEGER NOT NULL,
        depth_m      REAL    NOT NULL,
        lat          REAL,
        lng          REAL,
        source       TEXT    NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_depth_samples_timestamp ON depth_samples(timestamp_ms)',
    );
  }

  Future<void> add(DepthSample s) async {
    await _requireDb().insert('depth_samples', s.toMap());
  }

  Future<List<DepthSample>> all() async {
    final rows = await _requireDb()
        .query('depth_samples', orderBy: 'timestamp_ms ASC');
    return rows.map(DepthSample.fromMap).toList();
  }

  Future<List<DepthSample>> range({required DateTime from, required DateTime to}) async {
    final rows = await _requireDb().query(
      'depth_samples',
      where: 'timestamp_ms >= ? AND timestamp_ms <= ?',
      whereArgs: [
        from.toUtc().millisecondsSinceEpoch,
        to.toUtc().millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp_ms ASC',
    );
    return rows.map(DepthSample.fromMap).toList();
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Database _requireDb() {
    final db = _db;
    if (db == null) throw StateError('DepthLogService not opened');
    return db;
  }
}
