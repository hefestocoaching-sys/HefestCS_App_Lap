// lib/data/datasources/local/database_helper.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/utils/deep_merge.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static const String _dbName = 'hcs_app_lap_v4.db';
  static const int _dbVersion = 4;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final path = await _resolveDbPath(filePath);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await _ensureAppStateTable(db);
      },
    );
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
    await _ensureAppStateTable(db);
  }

  // Non-destructive upgrade: keep table to avoid data loss.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Intentionally no-op. Data is stored as JSON payloads in a single table.
  }

  Future<void> _ensureAppStateTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_state (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
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
    final decoded = jsonDecode(map["json"]);
    return Client.fromJson(decoded);
  }

  // -------------------------------
  // CRUD
  // -------------------------------

  Future<void> upsertClient(Client client) async {
    final db = await database;

    // BLINDAJE CRÍTICO: Hacer merge de extra antes de guardar
    // Esto asegura que NO se pierdan datos clínicos en actualizaciones parciales
    Client clientToSave = client;

    // Intentar obtener cliente previo para hacer merge de extra
    try {
      final clientId = client.id;
      if (clientId.isNotEmpty) {
        final existing = await getClientById(clientId);
        if (existing != null) {
          // Hacer DEEP merge: preservar existing.extra, sobrescribir con client.extra nuevo
          // Esto preserva Maps anidados como mevByMuscle, mrvByMuscle, targetSetsByMuscle
          final mergedExtra = deepMerge(
            existing.training.extra,
            client.training.extra,
          );

          // Importante: conservar el training NUEVO (client.training) y solo mergear el extra
          final mergedTraining = client.training.copyWith(extra: mergedExtra);

          // Crear Client con Training actualizado
          clientToSave = client.copyWith(training: mergedTraining);

          // 🔍 VALIDACIÓN: Confirmar merge
          debugPrint('💾 SQLite upsert - training.extra merge:');
          debugPrint(
            '   yearsTrainingContinuous: ${mergedExtra['yearsTrainingContinuous']}',
          );
          debugPrint(
            '   sessionDurationMinutes: ${mergedExtra['sessionDurationMinutes']}',
          );
          debugPrint(
            '   restBetweenSetsSeconds: ${mergedExtra['restBetweenSetsSeconds']}',
          );
          debugPrint('   avgSleepHours: ${mergedExtra['avgSleepHours']}');
        }
      }
    } catch (_) {
      // Si falla la lectura, usar cliente tal como viene (no es crítico)
    }

    await db.insert(
      'clients',
      _wrapClientJson(clientToSave),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

    return result.map(_unwrapClientJson).toList();
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
    final result = await db.query(
      'app_state',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_activeClientKey],
      limit: 1,
    );
    if (result.isEmpty) return null;
    final value = result.first['value'] as String?;
    if (value == null || value.isEmpty) return null;
    return value;
  }
}
