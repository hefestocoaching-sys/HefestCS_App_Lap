// lib/data/datasources/local/database_helper.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/training_interview.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_interview_validator.dart';
import 'package:hcs_app_lap/data/datasources/local/sync_queue_helper.dart';
import 'package:hcs_app_lap/core/utils/json_helpers.dart';
import 'package:hcs_app_lap/core/utils/app_logger.dart';

List<Client> _parseClientsIsolate(List<Map<String, dynamic>> snapshot) {
  return snapshot
      .map((row) {
        try {
          final json = SafeJson.decode(row['json'] as String?);
          if (json == null) return null;
          return Client.fromJson(json);
        } catch (e) {
          debugPrint('Error parsing client ${row['id']}: $e');
          return null;
        }
      })
      .whereType<Client>()
      .toList();
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static const String _dbName = 'hcs_app_lap_v4.db';
  static const int _dbVersion = 6;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final path = await _resolveDbPath(filePath);

    try {
      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
          await _ensureAppStateTable(db);
          await _ensureTrainingInterviewsTable(db);
          await SyncQueueHelper.ensureTable(db);
          await db.execute('PRAGMA journal_mode=WAL');
          await db.execute('PRAGMA foreign_keys=ON');
        },
      );
    } catch (e, stackTrace) {
      logger.error('Database open failed', e, stackTrace);
      rethrow;
    }
  }

  Future<String> _resolveDbPath(String filePath) async {
    final basePath = await getDatabasesPath();
    final defaultPath = join(basePath, filePath);

    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return defaultPath;
    }

    try {
      final supportDir = await getApplicationSupportDirectory();
      final stablePath = join(supportDir.path, filePath);

      final stableFile = File(stablePath);
      if (await stableFile.exists()) {
        return stablePath;
      }

      final legacyFile = File(defaultPath);
      if (await legacyFile.exists()) {
        await Directory(supportDir.path).create(recursive: true);
        await legacyFile.copy(stablePath);
      }

      return stablePath;
    } catch (e) {
      // In test environments or where path_provider isn't available, fall back to default DB path
      return defaultPath;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        json TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0,
        isDeleted INTEGER DEFAULT 0,
        updatedAt TEXT
      )
    ''');
    await _ensureTrainingInterviewsTable(db);
    await _ensureAppStateTable(db);
    await SyncQueueHelper.ensureTable(db);
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_clients_synced ON clients(isSynced)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_clients_deleted ON clients(isDeleted)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_clients_updated ON clients(updatedAt)',
    );
  }

  // Non-destructive upgrade: keep table to avoid data loss.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await _ensureTrainingInterviewsTable(db);
    }
    if (oldVersion < 6) {
      await _ensureTrainingInterviewsTable(db);

      final hasUpdatedAt =
          await _columnExists(db, 'training_interviews', 'updated_at');
      if (!hasUpdatedAt) {
        try {
          await db.execute(
            'ALTER TABLE training_interviews ADD COLUMN updated_at TEXT',
          );
        } catch (e) {
          debugPrint('Column updated_at already exists or error: $e');
        }
      }

      final hasIsSynced =
          await _columnExists(db, 'training_interviews', 'is_synced');
      if (!hasIsSynced) {
        try {
          await db.execute(
            'ALTER TABLE training_interviews ADD COLUMN is_synced INTEGER DEFAULT 0',
          );
        } catch (e) {
          debugPrint('Column is_synced already exists or error: $e');
        }
      }

      await SyncQueueHelper.ensureTable(db);

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_clients_synced ON clients(isSynced)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_clients_deleted ON clients(isDeleted)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_training_interviews_synced '
        'ON training_interviews(is_synced)',
      );
    }
  }

  Future<void> _ensureAppStateTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_state (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> _ensureTrainingInterviewsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS training_interviews (
        id TEXT PRIMARY KEY,
        client_id TEXT NOT NULL,
        version INTEGER NOT NULL,
        status TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        completed_at TEXT,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
      )
    ''');

    final hasIsSynced =
        await _columnExists(db, 'training_interviews', 'is_synced');
    if (!hasIsSynced) {
      try {
        await db.execute(
          'ALTER TABLE training_interviews ADD COLUMN is_synced INTEGER DEFAULT 0',
        );
      } catch (_) {}
    }

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_training_interviews_synced
      ON training_interviews(is_synced)
    ''');
  }

  Future<bool> _columnExists(Database db, String table, String column) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');
    return result.any((row) => row['name'] == column);
  }

  // -------------------------------
  // Internal Helpers
  // -------------------------------

  Map<String, dynamic> _wrapClientJson(Client client) {
    final payload = Map<String, dynamic>.from(client.toJson());
    payload['schemaVersion'] = 1;
    final nowIso = DateTime.now().toIso8601String();
    payload['migratedAt'] = nowIso;
    // Ensure the payload JSON contains the same updatedAt timestamp we store in the DB column
    payload['updatedAt'] = nowIso;
    return {
      "id": client.id,
      "json": jsonEncode(payload),
      "isSynced": 0,
      "isDeleted": 0,
      "updatedAt": nowIso,
    };
  }

  Client _unwrapClientJson(Map<String, dynamic> map) {
    final decoded = SafeJson.decode(map['json'] as String?);
    if (decoded == null) {
      throw const FormatException('Invalid client JSON payload');
    }
    return Client.fromJson(decoded);
  }

  // -------------------------------
  // CRUD
  // -------------------------------

  Future<void> upsertClient(Client client) async {
    final db = await database;
    final batch = db.batch();

    batch.insert(
      'clients',
      _wrapClientJson(client),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final lastInterview = await getActiveTrainingInterview(client.id);
    final newInterview = _buildInterviewFromClient(client, lastInterview);

    batch.insert(
      'training_interviews',
      newInterview.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await batch.commit(noResult: true);
  }

  Future<Client?> getClientById(String id) async {
    final db = await database;
    final result = await db.query(
      'clients',
      where: 'id = ? AND isDeleted = 0',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return _unwrapClientJson(result.first);
  }

  Future<List<Client>> getAllClients() async {
    final db = await database;

    final result = await db.query('clients', where: 'isDeleted = 0');
    if (result.isEmpty) return [];
    return compute(_parseClientsIsolate, result);
  }

  Future<void> softDeleteClient(String id) async {
    final db = await database;
    await db.update(
      'clients',
      {"isDeleted": 1, "updatedAt": DateTime.now().toIso8601String()},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<void> markClientAsSynced(String id) async {
    final db = await database;
    await db.update(
      'clients',
      {"isSynced": 1},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<List<Client>> getUnsyncedClients() async {
    final db = await database;

    final result = await db.query(
      'clients',
      where: 'isSynced = 0 AND isDeleted = 0',
    );

    return result.map(_unwrapClientJson).toList();
  }

  // --- Compat helpers (mantienen API usada en otras capas) ---
  Future<void> insertClient(Client client) => upsertClient(client);

  Future<void> updateClient(Client client) => upsertClient(client);

  Future<void> insertTrainingInterview(TrainingInterview interview) async {
    final db = await database;
    await db.insert(
      'training_interviews',
      interview.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTrainingInterview(TrainingInterview interview) async {
    final db = await database;
    await db.update(
      'training_interviews',
      interview.toMap(),
      where: 'id = ?',
      whereArgs: [interview.id],
    );
  }

  Future<TrainingInterview?> getActiveTrainingInterview(String clientId) async {
    final db = await database;
    late final List<Map<String, Object?>> result;
    try {
      result = await db.query(
        'training_interviews',
        where: 'client_id = ?',
        whereArgs: [clientId],
        orderBy: 'version DESC',
        limit: 1,
      );
    } catch (e, stackTrace) {
      logger.error('Database query failed: training_interviews', e, stackTrace);
      rethrow;
    }

    if (result.isEmpty) return null;
    return TrainingInterview.fromMap(result.first);
  }

  TrainingInterview _buildInterviewFromClient(
    Client client,
    TrainingInterview? last,
  ) {
    final data = Map<String, dynamic>.from(client.training.extra);
    final status = evaluateTrainingInterview(data).name;
    final now = DateTime.now();
    final lastData = last?.data;
    final isSameData =
        lastData != null &&
        const DeepCollectionEquality().equals(data, lastData);
    final version = last == null
        ? 1
        : isSameData
        ? last.version
        : last.version + 1;
    final createdAt = isSameData ? last!.createdAt : now;

    return TrainingInterview(
      id: const Uuid().v4(),
      clientId: client.id,
      version: version,
      status: status,
      data: data,
      createdAt: createdAt,
      updatedAt: now,
      completedAt: status == 'valid' ? now : null,
    );
  }

  // -------------------------------
  // App state (active client)
  // -------------------------------

  static const String _activeClientKey = 'active_client_id';

  Future<void> setActiveClientId(String? id) async {
    final db = await database;
    if (id == null || id.isEmpty) {
      await db.delete(
        'app_state',
        where: 'key = ?',
        whereArgs: [_activeClientKey],
      );
      return;
    }
    await db.insert('app_state', {
      'key': _activeClientKey,
      'value': id,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getActiveClientId() async {
    final db = await database;
    late final List<Map<String, Object?>> result;
    try {
      result = await db.query(
        'app_state',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [_activeClientKey],
        limit: 1,
      );
    } catch (e, stackTrace) {
      logger.error('Database query failed: app_state', e, stackTrace);
      rethrow;
    }
    if (result.isEmpty) return null;
    final value = result.first['value'] as String?;
    if (value == null || value.isEmpty) return null;
    return value;
  }
}
