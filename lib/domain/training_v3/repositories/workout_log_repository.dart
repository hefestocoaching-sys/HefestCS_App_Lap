// ignore_for_file: unused_import

// lib/domain/training_v3/repositories/workout_log_repository.dart

import 'package:hcs_app_lap/core/utils/app_logger.dart';
import 'package:hcs_app_lap/domain/training_v3/models/workout_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/set_log.dart';
import 'package:hcs_app_lap/data/datasources/local/database_helper.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'dart:convert';

/// Repositorio de logs de entrenamiento — implementación SQLite.
///
/// Persiste WorkoutLog como JSON en la tabla `workout_logs` de SQLite.
/// Esta tabla se crea en database_helper.dart si no existe.
///
/// SSOT de verdad: SQLite local, sin dependencia de Firestore.
class WorkoutLogRepository {
  static const _table = 'workout_logs';

  /// Guarda un WorkoutLog en SQLite.
  static Future<String> saveLog(WorkoutLog log) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(_table, {
        'id': log.id,
        'userId': log.userId,
        'programId': log.programId,
        'plannedSessionId': log.plannedSessionId,
        'startTime': log.startTime.toIso8601String(),
        'json': jsonEncode(log.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      logger.debug('WorkoutLog saved', {'logId': log.id});
      return log.id;
    } catch (e) {
      logger.error('WorkoutLog save failed', {'error': e.toString()});
      rethrow;
    }
  }

  /// Obtiene logs de un usuario, ordenados por fecha desc.
  static Future<List<WorkoutLog>> getLogsByUser({
    required String userId,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;

      String where = 'userId = ?';
      final args = <dynamic>[userId];

      if (startDate != null) {
        where += ' AND startTime >= ?';
        args.add(startDate.toIso8601String());
      }
      if (endDate != null) {
        where += ' AND startTime <= ?';
        args.add(endDate.toIso8601String());
      }

      final rows = await db.query(
        _table,
        where: where,
        whereArgs: args,
        orderBy: 'startTime DESC',
        limit: limit,
      );

      return rows
          .map((row) {
            try {
              final json =
                  jsonDecode(row['json'] as String) as Map<String, dynamic>;
              return WorkoutLog.fromJson(json);
            } catch (e) {
              logger.error('WorkoutLog parse error', {'row': row});
              return null;
            }
          })
          .whereType<WorkoutLog>()
          .toList();
    } catch (e) {
      logger.error('WorkoutLog query failed', {'error': e.toString()});
      return [];
    }
  }

  static Future<List<WorkoutLog>> getLogsByProgram({
    required String programId,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        _table,
        where: 'programId = ?',
        whereArgs: [programId],
        orderBy: 'startTime DESC',
      );
      return rows
          .map((row) {
            try {
              return WorkoutLog.fromJson(
                jsonDecode(row['json'] as String) as Map<String, dynamic>,
              );
            } catch (_) {
              return null;
            }
          })
          .whereType<WorkoutLog>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<WorkoutLog>> getWeekLogs({
    required String userId,
    required DateTime weekStart,
  }) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return getLogsByUser(
      userId: userId,
      startDate: weekStart,
      endDate: weekEnd,
    );
  }

  static Future<List<WorkoutLog>> getMonthLogs({required String userId}) async {
    final now = DateTime.now();
    final monthStart = now.subtract(const Duration(days: 30));
    return getLogsByUser(userId: userId, startDate: monthStart, endDate: now);
  }

  static Future<WorkoutLog?> getLastLog({required String userId}) async {
    final logs = await getLogsByUser(userId: userId, limit: 1);
    return logs.isNotEmpty ? logs.first : null;
  }

  static Future<void> updateLog(WorkoutLog log) async {
    await saveLog(log); // upsert
  }

  static Future<void> deleteLog(String logId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(_table, where: 'id = ?', whereArgs: [logId]);
    } catch (e) {
      logger.error('WorkoutLog delete failed', {'error': e.toString()});
    }
  }

  static Future<int> countLogs({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final logs = await getLogsByUser(
      userId: userId,
      limit: 1000,
      startDate: startDate,
      endDate: endDate,
    );
    return logs.length;
  }

  static Future<bool> hasLogForSession({
    required String plannedSessionId,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        _table,
        where: 'plannedSessionId = ?',
        whereArgs: [plannedSessionId],
        limit: 1,
      );
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
