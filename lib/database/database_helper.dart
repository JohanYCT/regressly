import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Clase encargada de gestionar toda la base de datos SQLite.
///
/// Implementa el patrón Singleton para asegurar:
/// - Una sola instancia de la base de datos
/// - Evitar múltiples conexiones abiertas
///
/// Responsabilidades:
/// - Crear la base de datos
/// - Actualizar su estructura (migraciones)
/// - Ejecutar operaciones CRUD
class DatabaseHelper {

  /// Instancia única global (Singleton)
  static final DatabaseHelper instance = DatabaseHelper._init();

  /// Referencia interna de la base de datos
  static Database? _database;

  /// Constructor privado
  DatabaseHelper._init();

  // ============================
  // 🔌 CONEXIÓN A BASE DE DATOS
  // ============================

  /// Getter que retorna la instancia de la base de datos.
  ///
  /// Si no existe, la crea.
  Future<Database> get database async {

    /// Si ya está inicializada, la retorna
    if (_database != null) return _database!;

    /// Si no, la inicializa
    _database = await _initDB('regressly.db');

    return _database!;
  }

  /// Inicializa la base de datos SQLite.
  ///
  /// Parámetros:
  /// - filePath → nombre del archivo de la base de datos
  Future<Database> _initDB(String filePath) async {

    /// Obtiene la ruta del sistema donde se guardan las BD
    final dbPath = await getDatabasesPath();

    /// Construye la ruta completa del archivo
    final path = join(dbPath, filePath);

    /// Abre (o crea) la base de datos
    return await openDatabase(

      path,

      /// Versión de la base de datos
      /// IMPORTANTE: cambiar este número permite hacer migraciones
      version: 2,

      /// Se ejecuta cuando la BD se crea por primera vez
      onCreate: _createDB,

      /// Se ejecuta cuando la versión cambia
      onUpgrade: _onUpgrade,
    );
  }

  // ============================
  // 🏗️ CREACIÓN DE TABLAS
  // ============================

  /// Crea las tablas iniciales de la base de datos.
  Future<void> _createDB(Database db, int version) async {

    // ============================
    // 📊 TABLA: REGISTROS
    // ============================

    /// Almacena la producción diaria
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

    // ============================
    // ⚙️ TABLA: FINCA
    // ============================

    /// Almacena configuración del usuario/finca
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

  // ============================
  // 🔄 MIGRACIÓN DE BASE DE DATOS
  // ============================

  /// Maneja actualizaciones de la base de datos sin perder información.
  ///
  /// Se ejecuta cuando cambia el número de versión.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {

    /// Si la versión anterior es menor a 2,
    /// se crea la tabla nueva "finca"
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

  // =====================================================
  // 📥 CRUD - REGISTROS DE PRODUCCIÓN
  // =====================================================

  /// Inserta un nuevo registro de producción.
  ///
  /// Retorna el ID del registro insertado.
  Future<int> insertRegistro(Map<String, dynamic> registro) async {

    final db = await database;

    return await db.insert('registros', registro);
  }

  /// Obtiene todos los registros ordenados por fecha descendente.
  Future<List<Map<String, dynamic>>> queryAllRegistros() async {

    final db = await database;

    return await db.query(
      'registros',
      orderBy: 'fecha DESC',
    );
  }

  /// Obtiene un registro específico por fecha.
  ///
  /// Retorna:
  /// - Map → si existe
  /// - null → si no existe
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

  /// Actualiza un registro existente.
  ///
  /// Requiere que el Map incluya el campo 'id'.
  Future<int> updateRegistro(Map<String, dynamic> registro) async {

    final db = await database;

    return await db.update(
      'registros',
      registro,
      where: 'id = ?',
      whereArgs: [registro['id']],
    );
  }

  /// Elimina un registro por ID.
  Future<int> deleteRegistro(int id) async {

    final db = await database;

    return await db.delete(
      'registros',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =====================================================
  // ⚙️ CRUD - CONFIGURACIÓN DE FINCA
  // =====================================================

  /// Obtiene la configuración de la finca.
  ///
  /// Nota:
  /// - Se asume que solo existe UNA configuración
  Future<Map<String, dynamic>?> getFinca() async {

    final db = await database;

    final result = await db.query('finca');

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  /// Inserta o actualiza la configuración de la finca.
  ///
  /// Lógica:
  /// - Si no existe → INSERT
  /// - Si ya existe → UPDATE
  ///
  /// Esto evita duplicados y mantiene un único registro.
  Future<void> insertOrUpdateFinca(Map<String, dynamic> fincaData) async {

    final db = await database;

    /// Verifica si ya existe configuración
    final existing = await db.query('finca');

    if (existing.isEmpty) {

      /// Inserta nueva configuración
      await db.insert('finca', fincaData);

    } else {

      /// Actualiza la existente
      await db.update(
        'finca',
        fincaData,
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }
}