import 'package:sqflite/sqflite.dart';
import 'package:hcs_app_lap/data/datasources/local/database_helper.dart';

class SyncQueueHelper {
  static const String _tableName = 'sync_queue';

  static Future<void> ensureTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        domain TEXT NOT NULL,
        client_id TEXT NOT NULL,
        date_key TEXT NOT NULL,
        payload TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        last_attempt TEXT,
        error_message TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_retry ON $_tableName(retry_count)',
    );
  }

  static Future<void> enqueue({
    required String domain,
    required String clientId,
    required String dateKey,
    required String payload,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(_tableName, {
      'id': '${domain}_${clientId}_$dateKey',
      'domain': domain,
      'client_id': clientId,
      'date_key': dateKey,
      'payload': payload,
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getPendingItems({
    int limit = 10,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      _tableName,
      where: 'retry_count < ?',
      whereArgs: [5],
      orderBy: 'created_at ASC',
      limit: limit,
    );
  }

  static Future<void> markSuccess(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> markFailure(String id, String error) async {
    final db = await DatabaseHelper.instance.database;
    await db.rawUpdate(
      '''
      UPDATE $_tableName
      SET retry_count = retry_count + 1,
          last_attempt = ?,
          error_message = ?
      WHERE id = ?
      ''',
      [DateTime.now().toIso8601String(), error, id],
    );
  }
}
