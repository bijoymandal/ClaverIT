import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contact.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pro_dialer.db');
    return await openDatabase(
      path,
      version: 2, // Incremented version
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create the table to match your Contact model fields
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phoneNumber TEXT,
        designation TEXT,
        organization TEXT,
        expertise TEXT,
        location TEXT,
        email TEXT,
        note TEXT,
        profileImagePath TEXT
      )
    ''');
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE contacts ADD COLUMN email TEXT DEFAULT ""');
    }
  }

  // 1. Insert (Create)
  Future<int> insertContact(Contact contact) async {
    Database db = await database;
    return await db.insert('contacts', contact.toMap());
  }

  // 1.5 Batch Insert
  Future<void> insertContactsBatch(List<Contact> contacts) async {
    Database db = await database;
    Batch batch = db.batch();
    for (var contact in contacts) {
      batch.insert('contacts', contact.toMap());
    }
    await batch.commit(noResult: true);
  }

  // 2. Get All (Read)
  Future<List<Contact>> getAllContacts() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('contacts');
    return List.generate(maps.length, (i) {
      return Contact.fromMap(maps[i]);
    });
  }

  // 3. Get Single Contact by Phone (Critical for Incoming Call Screen)
  Future<Contact?> getContactByPhone(String phoneNumber) async {
    Database db = await database;
    // We clean the phone number logic slightly to match matches
    // (This is simple matching; in real apps, you'd normalize +91, etc.)
    final List<Map<String, dynamic>> maps = await db.query(
      'contacts',
      where: 'phoneNumber LIKE ?',
      whereArgs: ['%$phoneNumber%'], // partial match or exact match
    );

    if (maps.isNotEmpty) {
      return Contact.fromMap(maps.first);
    }
    return null; // Not found
  }

  // 4. Search (For the Contacts Screen search bar)
  Future<List<Contact>> searchContacts(String query) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contacts',
      where: 'name LIKE ? OR phoneNumber LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => Contact.fromMap(maps[i]));
  }

  // 5. Delete
  Future<void> deleteContact(int id) async {
    Database db = await database;
    await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  // 6. Update
  Future<int> updateContact(Contact contact) async {
    Database db = await database;
    return await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }
}
