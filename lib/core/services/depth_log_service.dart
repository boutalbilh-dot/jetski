import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/depth_sample.dart';

class DepthLogService {
  static const retentionDuration = Duration(days: 7);

  Database? _db;

  Future<void> open() async {
    if (_db != null) return;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'jetski_depth_log.db'),
      version: 1,
      onConfigure: _configure,
      onCreate: _migrate,
    );
    await _trimToRetention();
  }

  /// In-memory variant for tests. Each call gets a private connection
  /// (singleInstance: false), so parallel test files don't share state via
  /// sqflite_ffi's shared `:memory:` cache.
  Future<void> openInMemory() async {
    if (_db != null) return;
    _db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      singleInstance: false,
      onConfigure: _configure,
      onCreate: _migrate,
    );
  }

  Future<void> _configure(Database db) async {
    // WAL gives better concurrent-write throughput on disk-backed DBs;
    // on in-memory DBs the PRAGMA is a harmless no-op.
    await db.execute('PRAGMA journal_mode=WAL');
  }

  Future<void> _migrate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DepthSample.tableName} (
        ${DepthSample.colTimestamp} INTEGER NOT NULL,
        ${DepthSample.colDepth}     REAL    NOT NULL,
        ${DepthSample.colLat}       REAL,
        ${DepthSample.colLng}       REAL,
        ${DepthSample.colSource}    TEXT    NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_depth_samples_timestamp '
      'ON ${DepthSample.tableName}(${DepthSample.colTimestamp})',
    );
  }

  Future<void> _trimToRetention() async {
    final cutoff = DepthSample.encodeTimestamp(
      DateTime.now().toUtc().subtract(retentionDuration),
    );
    await _db!.delete(
      DepthSample.tableName,
      where: '${DepthSample.colTimestamp} < ?',
      whereArgs: [cutoff],
    );
  }

  Future<void> add(DepthSample s) async {
    await _requireDb().insert(DepthSample.tableName, s.toMap());
  }

  /// Persist many samples in a single transaction. Far cheaper than N×add()
  /// when the depth source emits at 5–10 Hz.
  Future<void> addAll(List<DepthSample> samples) async {
    if (samples.isEmpty) return;
    final db = _requireDb();
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final s in samples) {
        batch.insert(DepthSample.tableName, s.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<DepthSample>> all() async {
    final rows = await _requireDb().query(
      DepthSample.tableName,
      orderBy: '${DepthSample.colTimestamp} ASC',
    );
    return rows.map(DepthSample.fromMap).toList();
  }

  Future<List<DepthSample>> range({required DateTime from, required DateTime to}) async {
    final rows = await _requireDb().query(
      DepthSample.tableName,
      where: '${DepthSample.colTimestamp} >= ? AND ${DepthSample.colTimestamp} <= ?',
      whereArgs: [
        DepthSample.encodeTimestamp(from),
        DepthSample.encodeTimestamp(to),
      ],
      orderBy: '${DepthSample.colTimestamp} ASC',
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
