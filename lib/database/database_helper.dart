import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {

  // Nombre de la base de datos
  static final _databaseName = "produccion.db";

  // Versión de la base de datos
  static final _databaseVersion = 1;

  // Nombre de la tabla
  static final table = 'produccion';

  // Columna
  static final columnId = 'id';
  static final columnLitros = 'litros';

  // Singleton (una sola instancia de la BD)
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  // Obtener la base de datos (si no existe, la crea)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializar la base de datos
  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // Crear la tabla
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnLitros REAL NOT NULL
      )
    ''');
  }

  // Insertar datos
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  // Obtener todos los datos
  Future<List<Map<String, dynamic>>> queryAll() async {
    Database db = await instance.database;
    return await db.query(table);
  }
}