import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/remote.dart';
import '../models/remote_button.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'universal_remote.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE remotes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE buttons(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id INTEGER,
        label TEXT,
        color INTEGER,
        icon_code TEXT,
        ir_code TEXT,
        FOREIGN KEY(remote_id) REFERENCES remotes(id) ON DELETE CASCADE
      )
    ''');
  }

  // Remote CRUD
  Future<int> insertRemote(Remote remote) async {
    final db = await database;
    return await db.insert('remotes', remote.toMap());
  }

  Future<List<Remote>> getRemotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('remotes', orderBy: "id DESC");
    return List.generate(maps.length, (i) => Remote.fromMap(maps[i]));
  }

  Future<int> deleteRemote(int id) async {
    final db = await database;
    return await db.delete('remotes', where: 'id = ?', whereArgs: [id]);
  }

  // Button CRUD
  Future<int> insertButton(RemoteButton button) async {
    final db = await database;
    return await db.insert('buttons', button.toMap());
  }

  Future<List<RemoteButton>> getButtonsForRemote(int remoteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'buttons',
      where: 'remote_id = ?',
      whereArgs: [remoteId],
    );
    return List.generate(maps.length, (i) => RemoteButton.fromMap(maps[i]));
  }

  Future<int> updateButtonIrCode(int buttonId, String irCode) async {
    final db = await database;
    return await db.update(
      'buttons',
      {'ir_code': irCode},
      where: 'id = ?',
      whereArgs: [buttonId],
    );
  }

  Future<int> deleteButton(int id) async {
    final db = await database;
    return await db.delete('buttons', where: 'id = ?', whereArgs: [id]);
  }
}
