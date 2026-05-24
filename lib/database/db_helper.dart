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
      version: 6,
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
    
    if (oldVersion < 3) {
      // Upgrade for Advanced POS features
      await db.execute('ALTER TABLE sales_log ADD COLUMN price_sold REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE sales_log ADD COLUMN quantity INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE sales_log ADD COLUMN customer_id INTEGER DEFAULT NULL');
      await db.execute('ALTER TABLE sales_log ADD COLUMN sale_type TEXT DEFAULT "CASH"');
    }
    
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE inventory ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0');
    }

    if (oldVersion < 5) {
      await db.execute('ALTER TABLE defects ADD COLUMN item_id INTEGER DEFAULT NULL');
    }
    
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE customers ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0');
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
        stock_count INTEGER NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sales_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        price_sold REAL NOT NULL DEFAULT 0.0,
        quantity INTEGER NOT NULL DEFAULT 1,
        customer_id INTEGER DEFAULT NULL,
        sale_type TEXT NOT NULL DEFAULT 'CASH',
        FOREIGN KEY (item_id) REFERENCES inventory (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        total_due REAL NOT NULL DEFAULT 0.0,
        is_archived INTEGER NOT NULL DEFAULT 0
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
        item_id INTEGER DEFAULT NULL,
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
    final result = await db.query('inventory', where: 'is_archived = 0');
    return result.map((json) => InventoryItem.fromMap(json)).toList();
  }

  Future<List<InventoryItem>> searchItems(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'inventory',
      where: '(brand LIKE ? OR model LIKE ?) AND is_archived = 0',
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
    return await db.update(
      'inventory',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> incrementStock(int id, int amount) async {
    final db = await instance.database;
    await db.rawUpdate('UPDATE inventory SET stock_count = stock_count + ? WHERE id = ?', [amount, id]);
  }

  Future<int> logSale({
    required int itemId, 
    required int quantity, 
    required double priceSold, 
    int? customerId, 
    required String type
  }) async {
    final db = await instance.database;
    return await db.insert('sales_log', {
      'item_id': itemId,
      'timestamp': DateTime.now().toIso8601String(),
      'price_sold': priceSold,
      'quantity': quantity,
      'customer_id': customerId,
      'sale_type': type,
    });
  }

  Future<void> undoPastSale(int saleId, int undoQty) async {
    final db = await instance.database;
    
    final saleRes = await db.query('sales_log', where: 'id = ?', whereArgs: [saleId]);
    if (saleRes.isEmpty) return;
    final sale = saleRes.first;
    
    final int quantity = sale['quantity'] as int;
    final double priceSold = sale['price_sold'] as double;
    final String saleType = sale['sale_type'] as String;
    final int? customerId = sale['customer_id'] as int?;
    final int itemId = sale['item_id'] as int;

    if (undoQty > quantity || undoQty <= 0) return;

    final double unitPrice = priceSold / quantity;
    final double refundAmount = unitPrice * undoQty;

    // 1. Auto-refund Khata Ledger if CREDIT
    if (saleType == 'CREDIT' && customerId != null) {
      final customerRes = await db.query('customers', where: 'id = ?', whereArgs: [customerId]);
      if (customerRes.isNotEmpty) {
        final customer = Customer.fromMap(customerRes.first);
        final newDue = customer.totalDue - refundAmount;
        await updateCustomer(customer.copyWith(totalDue: newDue));
        
        final itemRes = await db.query('inventory', where: 'id = ?', whereArgs: [itemId]);
        String details = 'Item';
        if (itemRes.isNotEmpty) {
           final item = InventoryItem.fromMap(itemRes.first);
           details = '${item.brand} ${item.model}';
        }
        
        await insertLedgerTransaction(LedgerTransaction(
          customerId: customerId,
          itemDetails: 'Undo Sale ($undoQty unit): $details',
          amount: refundAmount,
          type: 'PAYMENT', // Represents a reduction in debt
          date: DateTime.now().toIso8601String(),
        ));
      }
    }

    // 2. Restore Stock
    await incrementStock(itemId, undoQty);

    // 3. Update Sales Log
    if (undoQty == quantity) {
      await db.delete('sales_log', where: 'id = ?', whereArgs: [saleId]);
    } else {
      final newQuantity = quantity - undoQty;
      final newPriceSold = priceSold - refundAmount;
      await db.update('sales_log', {
        'quantity': newQuantity,
        'price_sold': newPriceSold,
      }, where: 'id = ?', whereArgs: [saleId]);
    }
  }

  Future<void> sellItem(InventoryItem item, {int quantity = 1, required double priceSold, int? customerId, required String type}) async {
    if (item.stockCount >= quantity) {
      final updatedItem = item.copyWith(stockCount: item.stockCount - quantity);
      await updateItem(updatedItem);
      if (item.id != null) {
        await logSale(
          itemId: item.id!, 
          quantity: quantity, 
          priceSold: priceSold, 
          customerId: customerId, 
          type: type
        );
      }
    }
  }

  Future<void> markPastSaleAsDefective(int saleId, int defectiveQty) async {
    final db = await instance.database;
    
    // 1. Fetch the sale details
    final saleRes = await db.rawQuery('''
      SELECT s.*, i.brand, i.model, i.quality_grade, c.name as customer_name
      FROM sales_log s
      JOIN inventory i ON s.item_id = i.id
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE s.id = ?
    ''', [saleId]);
    
    if (saleRes.isEmpty) return;
    
    final sale = saleRes.first;
    final int customerId = sale['customer_id'] as int? ?? 0;
    final String customerName = sale['customer_name'] as String? ?? 'Anonymous Cash Sale';
    final String saleType = sale['sale_type'] as String;
    final double priceSold = sale['price_sold'] as double;
    final int quantity = sale['quantity'] as int;
    final String itemDetails = '${sale['brand']} ${sale['model']} (${sale['quality_grade']})';

    // Validate quantity
    if (defectiveQty > quantity || defectiveQty <= 0) return;

    final double unitPrice = priceSold / quantity;
    final double refundAmount = unitPrice * defectiveQty;

    // 2. If it was a CREDIT sale, we MUST auto-refund the Khata Ledger
    if (saleType == 'CREDIT' && customerId > 0) {
      final customerRes = await db.query('customers', where: 'id = ?', whereArgs: [customerId]);
      if (customerRes.isNotEmpty) {
        final customer = Customer.fromMap(customerRes.first);
        // Reduce the debt by the refund amount
        final newDue = customer.totalDue - refundAmount;
        await updateCustomer(customer.copyWith(totalDue: newDue));
        
        // Add a ledger transaction so the customer sees the refund
        await insertLedgerTransaction(LedgerTransaction(
          customerId: customerId,
          itemDetails: 'RMA Refund ($defectiveQty unit): $itemDetails',
          amount: refundAmount,
          type: 'PAYMENT', // Represents a reduction in debt
          date: DateTime.now().toIso8601String(),
        ));
      }
    }

    // 3. Log the Defect physically in the Returns Dashboard
    await insertDefect(Defect(
      itemId: sale['item_id'] as int,
      itemDetails: '$itemDetails\\nReturned by: $customerName',
      quantity: defectiveQty,
      dateLogged: DateTime.now().toIso8601String(),
    ));

    // 4. Update the original sale
    if (defectiveQty == quantity) {
      // Full return: Update the original sale to be DEFECTIVE
      await db.update('sales_log', {
        'sale_type': 'DEFECTIVE',
        'price_sold': 0.0,
        'quantity': -defectiveQty.abs(), // Ensure it's negative
      }, where: 'id = ?', whereArgs: [saleId]);
    } else {
      // Partial return: Split the sale
      // A. Reduce the original sale
      final newQuantity = quantity - defectiveQty;
      final newPriceSold = priceSold - refundAmount;
      await db.update('sales_log', {
        'quantity': newQuantity,
        'price_sold': newPriceSold,
      }, where: 'id = ?', whereArgs: [saleId]);

      // B. Create a new DEFECTIVE sale record
      await logSale(
        itemId: sale['item_id'] as int,
        quantity: -defectiveQty.abs(),
        priceSold: 0.0,
        customerId: customerId > 0 ? customerId : null,
        type: 'DEFECTIVE'
      );
    }
    
    // Note: We DO NOT restore stock because the item is defective!
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
        SUM(s.quantity) as total_sold, 
        SUM(s.price_sold) as total_revenue
      FROM sales_log s
      JOIN inventory i ON s.item_id = i.id
      WHERE s.timestamp >= ?
      GROUP BY i.id
      ORDER BY total_sold DESC
    ''', [dateString]);
    
    return result;
  }

  Future<List<Map<String, dynamic>>> getCustomerPurchaseAnalytics(DateTime startDate) async {
    final db = await instance.database;
    final String dateString = startDate.toIso8601String();
    
    return await db.rawQuery('''
      SELECT 
        c.name, 
        SUM(s.quantity) as total_items, 
        SUM(s.price_sold) as total_spent
      FROM sales_log s
      JOIN customers c ON s.customer_id = c.id
      WHERE s.timestamp >= ? AND s.sale_type != 'DEFECTIVE' AND c.is_archived = 0
      GROUP BY c.id
      ORDER BY total_spent DESC
    ''', [dateString]);
  }

  Future<List<Map<String, dynamic>>> getCustomerReturnAnalytics(DateTime startDate) async {
    final db = await instance.database;
    final String dateString = startDate.toIso8601String();
    
    return await db.rawQuery('''
      SELECT 
        c.name, 
        SUM(ABS(s.quantity)) as total_returns
      FROM sales_log s
      JOIN customers c ON s.customer_id = c.id
      WHERE s.timestamp >= ? AND s.sale_type = 'DEFECTIVE' AND c.is_archived = 0
      GROUP BY c.id
      ORDER BY total_returns DESC
    ''', [dateString]);
  }

  Future<List<Map<String, dynamic>>> getTopDebtors() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT name, phone, total_due 
      FROM customers 
      WHERE total_due > 0 AND is_archived = 0
      ORDER BY total_due DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getSalesHistory() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT 
        s.id as sale_id,
        s.item_id,
        i.brand,
        i.model,
        i.quality_grade,
        s.price_sold,
        s.quantity,
        s.sale_type,
        s.timestamp,
        c.name as customer_name
      FROM sales_log s
      JOIN inventory i ON s.item_id = i.id
      LEFT JOIN customers c ON s.customer_id = c.id
      ORDER BY s.timestamp DESC
    ''');
    return result;
  }

  // --- Customers ---
  Future<int> insertCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await instance.database;
    final result = await db.query('customers', where: 'is_archived = 0');
    return result.map((json) => Customer.fromMap(json)).toList();
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<int> archiveCustomer(int customerId) async {
    final db = await instance.database;
    return await db.update('customers', {'is_archived': 1}, where: 'id = ?', whereArgs: [customerId]);
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
