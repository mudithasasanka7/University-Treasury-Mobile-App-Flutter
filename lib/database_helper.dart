import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'treasury.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE items (id INTEGER PRIMARY KEY, name TEXT, available INTEGER DEFAULT 1)",
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    final db = await database;
    return db.query('items');
  }

  Future<void> insertItem(String name) async {
    final db = await database;
    await db.insert('items', {'name': name, 'available': 1});
  }

  Future<void> returnItem(int id) async {
    final db = await database;
    await db.update('items', {'available': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteItem(int id) async {
    final db = await database;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }
}
