import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Servicio centralizado para gestionar la base de datos SQLite.
/// Implementa patrón Singleton para garantizar una única instancia.
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  /// Obtiene la instancia de la base de datos.
  /// Si no existe, la inicializa.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos SQLite.
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'vector.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crea las tablas iniciales de la base de datos.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE routes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        progress REAL DEFAULT 0.0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE stops (
        id TEXT PRIMARY KEY,
        route_id TEXT NOT NULL,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        status TEXT NOT NULL,
        stop_order INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE CASCADE
      )
    ''');

    // Crear índices para optimización
    await db.execute(
      'CREATE INDEX idx_stops_route_id ON stops(route_id)',
    );
    await db.execute(
      'CREATE INDEX idx_stops_order ON stops(route_id, stop_order)',
    );
  }

  /// Maneja las migraciones de la base de datos.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implementar migraciones futuras aquí
    // Ejemplo:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE stops ADD COLUMN priority INTEGER DEFAULT 0');
    // }
  }

  /// Cierra la base de datos.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
