import 'dart:async';
import 'dart:io' show Platform;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_log.dart';
import '../models/workout_log.dart';
import '../models/water_log.dart';
import '../models/weight_log.dart';
import '../models/workout_session.dart';

class DbService {
  sql.Database? _sqliteDb;
  pg.Connection? _postgresDb;
  bool _usePostgres = false;
  String _currentConnString = '';

  // Helper to parse PostgreSQL URI
  Map<String, dynamic>? _parsePostgresUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final userInfo = uri.userInfo.split(':');
      return {
        'host': uri.host,
        'port': uri.port == 0 ? 5432 : uri.port,
        'database': uri.path.startsWith('/') ? uri.path.substring(1) : uri.path,
        'username': userInfo[0],
        'password': userInfo.length > 1 ? userInfo[1] : '',
      };
    } catch (e) {
      return null;
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final connStr = prefs.getString('trackfit_postgres_conn') ?? '';
    _currentConnString = connStr;

    if (connStr.isNotEmpty) {
      final params = _parsePostgresUrl(connStr);
      if (params != null) {
        try {
          _postgresDb = await pg.Connection.open(
            pg.Endpoint(
              host: params['host'],
              port: params['port'],
              database: params['database'],
              username: params['username'],
              password: params['password'],
            ),
            settings: const pg.ConnectionSettings(
              sslMode: pg.SslMode.disable,
            ),
          ).timeout(const Duration(seconds: 4));
          _usePostgres = true;
          return;
        } catch (e) {
          _usePostgres = false;
        }
      }
    }

    // Fallback to SQLite
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      sql.databaseFactory = databaseFactoryFfi;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, "trackfit.db");
    _sqliteDb = await sql.openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE food_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            food_name TEXT,
            quantity REAL,
            calories REAL,
            protein REAL,
            carbs REAL,
            fiber REAL,
            fat REAL,
            meal_type TEXT,
            serving_unit TEXT,
            created_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE workout_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            exercise_name TEXT,
            weight REAL,
            reps INTEGER,
            set_number INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE water_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            amount INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE weight_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            weight REAL,
            body_fat REAL
          )
        ''');
        await db.execute('''
          CREATE TABLE workout_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            duration INTEGER,
            energy REAL,
            notes TEXT
          )
        ''');
      },
    );
    _usePostgres = false;
  }

  bool get isPostgresMode => _usePostgres;

  // ─── FOOD LOGS ─────────────────────────────────────────────────────────────
  Future<List<FoodLog>> getFoodLogs(String date) async {
    if (_usePostgres && _postgresDb != null) {
      try {
        final result = await _postgresDb!.execute(
          pg.Sql.named('SELECT id, date, food_name, quantity, calories, protein, carbs, fiber, fat, meal_type, serving_unit, created_at FROM food_logs WHERE date = @date'),
          parameters: {'date': date},
        );
        return result.map((row) {
          String dateStr = row[1] is DateTime
              ? "${(row[1] as DateTime).year}-${(row[1] as DateTime).month.toString().padLeft(2, '0')}-${(row[1] as DateTime).day.toString().padLeft(2, '0')}"
              : row[1].toString();
          return FoodLog(
            id: row[0] as int?,
            date: dateStr,
            foodName: row[2] as String,
            quantity: (row[3] as num).toDouble(),
            calories: (row[4] as num).toDouble(),
            protein: (row[5] as num).toDouble(),
            carbs: (row[6] as num).toDouble(),
            fiber: (row[7] as num).toDouble(),
            fat: (row[8] as num).toDouble(),
            mealType: row[9] as String,
            servingUnit: row[10] as String,
            createdAt: row[11]?.toString(),
          );
        }).toList();
      } catch (e) {
        // fallback
      }
    }

    final List<Map<String, dynamic>> maps = await _sqliteDb!.query(
      'food_logs',
      where: 'date = ?',
      whereArgs: [date],
    );
    return maps.map((m) => FoodLog.fromJson(m)).toList();
  }

  Future<int> insertFoodLog(FoodLog log) async {
    if (_usePostgres && _postgresDb != null) {
      try {
        final res = await _postgresDb!.execute(
          pg.Sql.named('INSERT INTO food_logs (date, food_name, quantity, calories, protein, carbs, fiber, fat, meal_type, serving_unit, created_at) '
              'VALUES (@date, @food_name, @quantity, @calories, @protein, @carbs, @fiber, @fat, @meal_type, @serving_unit, @created_at) RETURNING id'),
          parameters: {
            'date': log.date,
            'food_name': log.foodName,
            'quantity': log.quantity,
            'calories': log.calories,
            'protein': log.protein,
            'carbs': log.carbs,
            'fiber': log.fiber,
            'fat': log.fat,
            'meal_type': log.mealType,
            'serving_unit': log.servingUnit,
            'created_at': log.createdAt ?? DateTime.now().toIso8601String(),
          },
        );
        return res[0][0] as int;
      } catch (e) {
        // fallback
      }
    }
    return await _sqliteDb!.insert('food_logs', log.toJson());
  }

  Future<void> deleteFoodLog(int id) async {
    if (_usePostgres && _postgresDb != null) {
      try {
        await _postgresDb!.execute(
          pg.Sql.named('DELETE FROM food_logs WHERE id = @id'),
          parameters: {'id': id},
        );
        return;
      } catch (e) {
        // fallback
      }
    }
    await _sqliteDb!.delete('food_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FoodLog>> getAllFoodLogs() async {
    if (_usePostgres && _postgresDb != null) {
      try {
        final result = await _postgresDb!.execute(
          'SELECT id, date, food_name, quantity, calories, protein, carbs, fiber, fat, meal_type, serving_unit FROM food_logs ORDER BY date ASC'
        );
        return result.map((row) {
          String dateStr = row[1] is DateTime
              ? "${(row[1] as DateTime).year}-${(row[1] as DateTime).month.toString().padLeft(2, '0')}-${(row[1] as DateTime).day.toString().padLeft(2, '0')}"
              : row[1].toString();
          return FoodLog(
            id: row[0] as int?,
            date: dateStr,
            foodName: row[2] as String,
            quantity: (row[3] as num).toDouble(),
            calories: (row[4] as num).toDouble(),
            protein: (row[5] as num).toDouble(),
            carbs: (row[6] as num).toDouble(),
            fiber: (row[7] as num).toDouble(),
            fat: (row[8] as num).toDouble(),
            mealType: row[9] as String,
            servingUnit: row[10] as String,
          );
        }).toList();
      } catch (e) {
        // fallback
      }
    }
    final List<Map<String, dynamic>> maps = await _sqliteDb!.query(
      'food_logs',
      orderBy: 'date ASC',
    );
    return maps.map((m) => FoodLog.fromJson(m)).toList();
  }

  // ─── WORKOUT LOGS ──────────────────────────────────────────────────────────
  Future<List<WorkoutLog>> getWorkoutLogs(String date) async {
    if (_usePostgres && _postgresDb != null) {
      try {
        final result = await _postgresDb!.execute(
          pg.Sql.named('SELECT id, date, exercise_name, weight, reps, set_number FROM workouts WHERE date = @date ORDER BY set_number ASC'),
          parameters: {'date': date},
        );
        return result.map((row) {
          String dateStr = row[1] is DateTime
              ? "${(row[1] as DateTime).year}-${(row[1] as DateTime).month.toString().padLeft(2, '0')}-${(row[1] as DateTime).day.toString().padLeft(2, '0')}"
              : row[1].toString();
          return WorkoutLog(
            id: row[0] as int?,
            date: dateStr,
            exerciseName: row[2] as String,
            weight: (row[3] as num).toDouble(),
            reps: row[4] as int,
            setNumber: row[5] as int,
          );
        }).toList();
      } catch (e) {
        // fallback
      }
    }
    final List<Map<String, dynamic>> maps = await _sqliteDb!.query(
      'workout_logs',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'set_number ASC',
    );
    return maps.map((m) => WorkoutLog.fromJson(m)).toList();
  }

  Future<int> insertWorkoutLog(WorkoutLog log) async {
    if (_usePostgres && _postgresDb != null) {
      try {
        final res = await _postgresDb!.execute(
          pg.Sql.named('INSERT INTO workouts (date, exercise_name, weight, reps, set_number) '
              'VALUES (@date, @exercise_name, @weight, @reps, @set_number) RETURNING id'),
          parameters: {
            'date': log.date,
            'exercise_name': log.exerciseName,
            'weight': log.weight,
            'reps': log.reps,
            'set_number': log.setNumber,
          },
        );
        return res[0][0] as int;
      } catch (e) {
        // fallback
      }
    }
    return await _sqliteDb!.insert('workout_logs', log.toJson());
  }

  Future<void> deleteWorkoutLog(int id) async {
    if (_usePostgres && _postgresDb != null) {
      try {
        await _postgresDb!.execute(
          pg.Sql.named('DELETE FROM workouts WHERE id = @id'),
          parameters: {'id': id},
        );
        return;
      } catch (e) {
        // fallback
      }
    }
    await _sqliteDb!.delete('workout_logs', where: 'id = ?', whereArgs: [id]);
  }

  // ─── WATER LOGS ─────────────────────────────────────────────────────────────
  Future<List<WaterLog>> getWaterLogs(String date) async {
    if (_usePostgres && _postgresDb != null) {
      try {
        final result = await _postgresDb!.execute(
          pg.Sql.named('SELECT id, date, amount_ml FROM water_logs WHERE date = @date'),
          parameters: {'date': date},
        );
        return result.map((row) {
          String dateStr = row[1] is DateTime
              ? "${(row[1] as DateTime).year}-${(row[1] as DateTime).month.toString().padLeft(2, '0')}-${(row[1] as DateTime).day.toString().padLeft(2, '0')}"
              : row[1].toString();
          return WaterLog(
            id: row[0] as int?,
            date: dateStr,
            amount: row[2] as int,
          );
        }).toList();
      } catch (e) {
        // fallback
      }
    }
    final List<Map<String, dynamic>> maps = await _sqliteDb!.query(
      'water_logs',
      where: 'date = ?',
      whereArgs: [date],
    );
    return maps.map((m) => WaterLog.fromJson(m)).toList();
  }

  Future<int> insertWaterLog(WaterLog log) async {
    if (_usePostgres && _postgresDb != null) {
      try {
        final res = await _postgresDb!.execute(
          pg.Sql.named('INSERT INTO water_logs (date, amount_ml) VALUES (@date, @amount) RETURNING id'),
          parameters: {
            'date': log.date,
            'amount': log.amount,
          },
        );
        return res[0][0] as int;
      } catch (e) {
        // fallback
      }
    }
    return await _sqliteDb!.insert('water_logs', log.toJson());
  }

  Future<void> deleteWaterLog(int id) async {
    if (_usePostgres && _postgresDb != null) {
      try {
        await _postgresDb!.execute(
          pg.Sql.named('DELETE FROM water_logs WHERE id = @id'),
          parameters: {'id': id},
        );
        return;
      } catch (e) {
        // fallback
      }
    }
    await _sqliteDb!.delete('water_logs', where: 'id = ?', whereArgs: [id]);
  }

  // ─── WEIGHT LOGS ─────────────────────────────────────────────────────────────
  Future<WeightLog?> getWeightLog(String date) async {
    if (_usePostgres && _postgresDb != null) {
      try {
        final result = await _postgresDb!.execute(
          pg.Sql.named('SELECT id, date, weight, body_fat FROM weight_logs WHERE date = @date LIMIT 1'),
          parameters: {'date': date},
        );
        if (result.isNotEmpty) {
          final row = result.first;
          String dateStr = row[1] is DateTime
              ? "${(row[1] as DateTime).year}-${(row[1] as DateTime).month.toString().padLeft(2, '0')}-${(row[1] as DateTime).day.toString().padLeft(2, '0')}"
              : row[1].toString();
          return WeightLog(
            id: row[0] as int?,
            date: dateStr,
            weight: (row[2] as num).toDouble(),
            bodyFat: row[3] != null ? (row[3] as num).toDouble() : null,
          );
        }
        return null;
      } catch (e) {
        // fallback
      }
    }
    final List<Map<String, dynamic>> maps = await _sqliteDb!.query(
      'weight_logs',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return WeightLog.fromJson(maps.first);
    }
    return null;
  }

  Future<int> insertWeightLog(WeightLog log) async {
    if (_usePostgres && _postgresDb != null) {
      try {
        final res = await _postgresDb!.execute(
          pg.Sql.named(
            'INSERT INTO weight_logs (date, weight, body_fat) VALUES (@date, @weight, @body_fat) '
            'ON CONFLICT (date) DO UPDATE SET weight = EXCLUDED.weight, body_fat = EXCLUDED.body_fat '
            'RETURNING id',
          ),
          parameters: {
            'date': log.date,
            'weight': log.weight,
            'body_fat': log.bodyFat,
          },
        );
        return res[0][0] as int;
      } catch (e) {
        // fallback
      }
    }
    final existing = await getWeightLog(log.date);
    if (existing != null) {
      await _sqliteDb!.update(
        'weight_logs',
        log.toJson(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return existing.id!;
    }
    return await _sqliteDb!.insert('weight_logs', log.toJson());
  }

  // ─── WORKOUT SESSIONS ──────────────────────────────────────────────────────
  Future<WorkoutSession?> getWorkoutSession(String date) async {
    if (_usePostgres && _postgresDb != null) {
      try {
        final result = await _postgresDb!.execute(
          pg.Sql.named('SELECT id, date, duration_minutes, energy_level, notes FROM workout_sessions WHERE date = @date LIMIT 1'),
          parameters: {'date': date},
        );
        if (result.isNotEmpty) {
          final row = result.first;
          String dateStr = row[1] is DateTime
              ? "${(row[1] as DateTime).year}-${(row[1] as DateTime).month.toString().padLeft(2, '0')}-${(row[1] as DateTime).day.toString().padLeft(2, '0')}"
              : row[1].toString();
          return WorkoutSession(
            id: row[0] as int?,
            date: dateStr,
            duration: row[2] as int,
            energy: (row[3] as num).toDouble(),
            notes: row[4] as String? ?? '',
          );
        }
        return null;
      } catch (e) {
        // fallback
      }
    }

    final List<Map<String, dynamic>> maps = await _sqliteDb!.query(
      'workout_sessions',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return WorkoutSession.fromJson(maps.first);
    }
    return null;
  }

  Future<int> insertWorkoutSession(WorkoutSession session) async {
    if (_usePostgres && _postgresDb != null) {
      try {
        final res = await _postgresDb!.execute(
          pg.Sql.named(
            'INSERT INTO workout_sessions (date, duration_minutes, energy_level, notes) VALUES (@date, @duration, @energy, @notes) '
            'ON CONFLICT (date) DO UPDATE SET duration_minutes = EXCLUDED.duration_minutes, energy_level = EXCLUDED.energy_level, notes = EXCLUDED.notes '
            'RETURNING id',
          ),
          parameters: {
            'date': session.date,
            'duration': session.duration,
            'energy': session.energy.toInt(),
            'notes': session.notes,
          },
        );
        return res[0][0] as int;
      } catch (e) {
        // fallback
      }
    }

    final existing = await getWorkoutSession(session.date);
    if (existing != null) {
      await _sqliteDb!.update(
        'workout_sessions',
        session.toJson(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return existing.id!;
    }
    return await _sqliteDb!.insert('workout_sessions', session.toJson());
  }

  Future<void> deleteWorkoutSession(int id) async {
    if (_usePostgres && _postgresDb != null) {
      try {
        await _postgresDb!.execute(
          pg.Sql.named('DELETE FROM workout_sessions WHERE id = @id'),
          parameters: {'id': id},
        );
        return;
      } catch (e) {
        // fallback
      }
    }
    await _sqliteDb!.delete('workout_sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<WorkoutSession>> getAllWorkoutSessions() async {
    if (_usePostgres && _postgresDb != null) {
      try {
        final result = await _postgresDb!.execute(
          'SELECT id, date, duration_minutes, energy_level, notes FROM workout_sessions ORDER BY date ASC'
        );
        return result.map((row) {
          String dateStr = row[1] is DateTime
              ? "${(row[1] as DateTime).year}-${(row[1] as DateTime).month.toString().padLeft(2, '0')}-${(row[1] as DateTime).day.toString().padLeft(2, '0')}"
              : row[1].toString();
          return WorkoutSession(
            id: row[0] as int?,
            date: dateStr,
            duration: row[2] as int,
            energy: (row[3] as num).toDouble(),
            notes: row[4] as String? ?? '',
          );
        }).toList();
      } catch (e) {
        // fallback
      }
    }

    final List<Map<String, dynamic>> maps = await _sqliteDb!.query(
      'workout_sessions',
      orderBy: 'date ASC',
    );
    return maps.map((m) => WorkoutSession.fromJson(m)).toList();
  }

  // ─── HISTORY DATA ──────────────────────────────────────────────────────────
  Future<List<WeightLog>> getWeightHistory() async {
    if (_usePostgres && _postgresDb != null) {
      try {
        final result = await _postgresDb!.execute(
          'SELECT id, date, weight, body_fat FROM weight_logs ORDER BY date ASC'
        );
        return result.map((row) {
          String dateStr = row[1] is DateTime
              ? "${(row[1] as DateTime).year}-${(row[1] as DateTime).month.toString().padLeft(2, '0')}-${(row[1] as DateTime).day.toString().padLeft(2, '0')}"
              : row[1].toString();
          return WeightLog(
            id: row[0] as int?,
            date: dateStr,
            weight: (row[2] as num).toDouble(),
            bodyFat: row[3] != null ? (row[3] as num).toDouble() : null,
          );
        }).toList();
      } catch (e) {
        // fallback
      }
    }
    final List<Map<String, dynamic>> maps = await _sqliteDb!.query(
      'weight_logs',
      orderBy: 'date ASC',
    );
    return maps.map((m) => WeightLog.fromJson(m)).toList();
  }

  Future<List<WaterLog>> getWaterHistory() async {
    if (_usePostgres && _postgresDb != null) {
      try {
        final result = await _postgresDb!.execute(
          'SELECT id, date, amount_ml FROM water_logs ORDER BY date ASC'
        );
        return result.map((row) {
          String dateStr = row[1] is DateTime
              ? "${(row[1] as DateTime).year}-${(row[1] as DateTime).month.toString().padLeft(2, '0')}-${(row[1] as DateTime).day.toString().padLeft(2, '0')}"
              : row[1].toString();
          return WaterLog(
            id: row[0] as int?,
            date: dateStr,
            amount: row[2] as int,
          );
        }).toList();
      } catch (e) {
        // fallback
      }
    }
    final List<Map<String, dynamic>> maps = await _sqliteDb!.query(
      'water_logs',
      orderBy: 'date ASC',
    );
    return maps.map((m) => WaterLog.fromJson(m)).toList();
  }

  Future<List<WorkoutLog>> getAllWorkoutSets() async {
    if (_usePostgres && _postgresDb != null) {
      try {
        final result = await _postgresDb!.execute(
          'SELECT id, date, exercise_name, weight, reps, set_number FROM workouts ORDER BY date ASC'
        );
        return result.map((row) {
          String dateStr = row[1] is DateTime
              ? "${(row[1] as DateTime).year}-${(row[1] as DateTime).month.toString().padLeft(2, '0')}-${(row[1] as DateTime).day.toString().padLeft(2, '0')}"
              : row[1].toString();
          return WorkoutLog(
            id: row[0] as int?,
            date: dateStr,
            exerciseName: row[2] as String,
            weight: (row[3] as num).toDouble(),
            reps: row[4] as int,
            setNumber: row[5] as int,
          );
        }).toList();
      } catch (e) {
        // fallback
      }
    }
    final List<Map<String, dynamic>> maps = await _sqliteDb!.query(
      'workout_logs',
      orderBy: 'date ASC',
    );
    return maps.map((m) => WorkoutLog.fromJson(m)).toList();
  }

  // ─── CLEAR / RESET DATA ──────────────────────────────────────────────────
  Future<void> resetAllData() async {
    if (_usePostgres && _postgresDb != null) {
      try {
        await _postgresDb!.execute('TRUNCATE TABLE food_logs, workouts, water_logs, weight_logs, workout_sessions RESTART IDENTITY');
        return;
      } catch (e) {
        // fallback
      }
    }
    if (_sqliteDb != null) {
      await _sqliteDb!.delete('food_logs');
      await _sqliteDb!.delete('workout_logs');
      await _sqliteDb!.delete('water_logs');
      await _sqliteDb!.delete('weight_logs');
      await _sqliteDb!.delete('workout_sessions');
    }
  }

  // Close connection
  Future<void> close() async {
    await _sqliteDb?.close();
    await _postgresDb?.close();
  }
}
