import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

void main() {
  runApp(const TreasuryApp());
}

class TreasuryApp extends StatelessWidget {
  const TreasuryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Treasury App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ItemListScreen(),
    );
  }
}

class Item {
  int? id;
  String name;
  bool isRented;

  Item({this.id, required this.name, this.isRented = false});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isRented': isRented ? 1 : 0,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'],
      isRented: map['isRented'] == 1,
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'treasury.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE items (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, isRented INTEGER)',
        );
      },
    );
  }

  Future<int> insertItem(Item item) async {
    final db = await database;
    return await db.insert('items', item.toMap());
  }

  Future<List<Item>> getItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('items');
    return List.generate(maps.length, (i) => Item.fromMap(maps[i]));
  }

  Future<int> updateItem(Item item) async {
    final db = await database;
    return await db.update('items', item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }
}

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  _ItemListScreenState createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Item> items = [];

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {
    final loadedItems = await dbHelper.getItems();
    setState(() {
      items = loadedItems;
    });
  }

  void addItem(String name) async {
    if (name.isNotEmpty) {
      await dbHelper.insertItem(Item(name: name));
      loadItems();
    }
  }

  void toggleRentStatus(Item item) async {
    item.isRented = !item.isRented;
    await dbHelper.updateItem(item);
    loadItems();
  }

  void removeItem(int id) async {
    await dbHelper.deleteItem(id);
    loadItems();
  }

  void showAddItemDialog() {
    String newItemName = "";
    showDialog(
      context: this.context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Add Item"),
          content: TextField(
            onChanged: (value) {
              newItemName = value;
            },
            decoration: const InputDecoration(hintText: "Enter item name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                addItem(newItemName);
                Navigator.pop(dialogContext);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Treasury Management")),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            child: ListTile(
              title: Text(item.name),
              subtitle: Text(item.isRented ? "Rented" : "Available"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(item.isRented ? Icons.check_box : Icons.check_box_outline_blank),
                    onPressed: () => toggleRentStatus(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => removeItem(item.id!),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}