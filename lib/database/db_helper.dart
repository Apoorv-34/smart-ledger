import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/inventory_item.dart';
import '../models/customer.dart';
import '../models/ledger_transaction.dart';
import '../models/defect.dart';
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ashok_services.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE customers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT NOT NULL,
          total_due REAL NOT NULL DEFAULT 0.0
        )
      ''');

      await db.execute('''
        CREATE TABLE ledger (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id INTEGER NOT NULL,
          item_details TEXT NOT NULL,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          date TEXT NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES customers (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE defects (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_details TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          date_logged TEXT NOT NULL,
          status TEXT NOT NULL
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        quality_grade TEXT NOT NULL,
        wholesale_price REAL NOT NULL,
        retail_price REAL NOT NULL,
        stock_count INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES inventory (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        total_due REAL NOT NULL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE ledger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        item_details TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE defects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_details TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        date_logged TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertItem(InventoryItem item) async {
    final db = await instance.database;
    return await db.insert('inventory', item.toMap());
  }

  Future<List<InventoryItem>> getAllItems() async {
    final db = await instance.database;
    final result = await db.query('inventory');
    return result.map((json) => InventoryItem.fromMap(json)).toList();
  }

  Future<List<InventoryItem>> searchItems(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'inventory',
      where: 'brand LIKE ? OR model LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return result.map((json) => InventoryItem.fromMap(json)).toList();
  }

  Future<int> updateItem(InventoryItem item) async {
    final db = await instance.database;
    return await db.update(
      'inventory',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await instance.database;
    return await db.delete(
      'inventory',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> logSale(int itemId) async {
    final db = await instance.database;
    await db.insert('sales_log', {
      'item_id': itemId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> sellItem(InventoryItem item) async {
    if (item.stockCount > 0) {
      final updatedItem = item.copyWith(stockCount: item.stockCount - 1);
      await updateItem(updatedItem);
      if (item.id != null) {
        await logSale(item.id!);
      }
    }
  }

  Future<void> insertDummyData() async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM inventory'));
    if (count == 0) {
      await insertItem(InventoryItem(brand: 'Apple', model: 'iPhone 13 Mini', qualityGrade: 'Original', wholesalePrice: 2500, retailPrice: 2800, stockCount: 5));
      await insertItem(InventoryItem(brand: 'Samsung', model: 'Galaxy S21', qualityGrade: 'OLED', wholesalePrice: 3000, retailPrice: 3300, stockCount: 2));
      await insertItem(InventoryItem(brand: 'OnePlus', model: 'Nord 2', qualityGrade: 'Incell', wholesalePrice: 1200, retailPrice: 1500, stockCount: 10));
    }
  }

  Future<List<Map<String, dynamic>>> getSalesAnalytics(DateTime startDate) async {
    final db = await instance.database;
    final String dateString = startDate.toIso8601String();
    
    final result = await db.rawQuery('''
      SELECT 
        i.brand, 
        i.model, 
        i.quality_grade, 
        COUNT(s.id) as total_sold, 
        SUM(i.retail_price) as total_revenue
      FROM sales_log s
      JOIN inventory i ON s.item_id = i.id
      WHERE s.timestamp >= ?
      GROUP BY i.id
      ORDER BY total_sold DESC
    ''', [dateString]);
    
    return result;
  }

  // --- Customers ---
  Future<int> insertCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await instance.database;
    final result = await db.query('customers');
    return result.map((json) => Customer.fromMap(json)).toList();
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  // --- Ledger ---
  Future<int> insertLedgerTransaction(LedgerTransaction txn) async {
    final db = await instance.database;
    
    // Update customer total due
    final customerRes = await db.query('customers', where: 'id = ?', whereArgs: [txn.customerId]);
    if (customerRes.isNotEmpty) {
      final customer = Customer.fromMap(customerRes.first);
      double newDue = customer.totalDue;
      if (txn.type == 'CREDIT') {
        newDue += txn.amount;
      } else if (txn.type == 'PAYMENT') {
        newDue -= txn.amount;
      }
      await updateCustomer(customer.copyWith(totalDue: newDue));
    }

    return await db.insert('ledger', txn.toMap());
  }

  Future<List<LedgerTransaction>> getLedgerForCustomer(int customerId) async {
    final db = await instance.database;
    final result = await db.query('ledger', where: 'customer_id = ?', whereArgs: [customerId], orderBy: 'date DESC');
    return result.map((json) => LedgerTransaction.fromMap(json)).toList();
  }

  // --- Defects ---
  Future<int> insertDefect(Defect defect) async {
    final db = await instance.database;
    return await db.insert('defects', defect.toMap());
  }

  Future<List<Defect>> getAllDefects() async {
    final db = await instance.database;
    final result = await db.query('defects', orderBy: 'date_logged DESC');
    return result.map((json) => Defect.fromMap(json)).toList();
  }

  Future<int> updateDefectStatus(int id, String status) async {
    final db = await instance.database;
    return await db.update('defects', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }
}
