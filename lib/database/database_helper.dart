import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('regressly.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // CAMBIADO: version 2 para crear nueva tabla
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // NUEVO: para actualizar BD existente
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabla de registros
    await db.execute('''
      CREATE TABLE registros(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT UNIQUE,
        litros_manana REAL,
        litros_tarde REAL,
        litros_total REAL,
        observaciones TEXT,
        created_at TEXT
      )
    ''');

    // NUEVA: Tabla de finca/configuración
    await db.execute('''
      CREATE TABLE finca(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_productor TEXT,
        nombre_finca TEXT,
        ubicacion TEXT,
        numero_vacas INTEGER,
        precio_litro REAL
      )
    ''');
  }

  // NUEVO: Para actualizar BD existente sin perder datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE finca(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre_productor TEXT,
          nombre_finca TEXT,
          ubicacion TEXT,
          numero_vacas INTEGER,
          precio_litro REAL
        )
      ''');
    }
  }

  // ========== MÉTODOS PARA REGISTROS ==========
  Future<int> insertRegistro(Map<String, dynamic> registro) async {
    final db = await database;
    return await db.insert('registros', registro);
  }

  Future<List<Map<String, dynamic>>> queryAllRegistros() async {
    final db = await database;
    return await db.query(
      'registros',
      orderBy: 'fecha DESC',
    );
  }

  Future<Map<String, dynamic>?> getRegistroPorFecha(String fecha) async {
    final db = await database;
    final result = await db.query(
      'registros',
      where: 'fecha = ?',
      whereArgs: [fecha],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> updateRegistro(Map<String, dynamic> registro) async {
    final db = await database;
    return await db.update(
      'registros',
      registro,
      where: 'id = ?',
      whereArgs: [registro['id']],
    );
  }

  Future<int> deleteRegistro(int id) async {
    final db = await database;
    return await db.delete(
      'registros',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== NUEVOS MÉTODOS PARA FINCA ==========
  Future<Map<String, dynamic>?> getFinca() async {
    final db = await database;
    final result = await db.query('finca');
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<void> insertOrUpdateFinca(Map<String, dynamic> fincaData) async {
    final db = await database;
    final existing = await db.query('finca');

    if (existing.isEmpty) {
      await db.insert('finca', fincaData);
    } else {
      await db.update('finca', fincaData, where: 'id = ?', whereArgs: [existing.first['id']]);
    }
  }
}