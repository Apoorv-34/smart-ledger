import 'package:flutter/foundation.dart';
import '../models/inventory_item.dart';
import '../models/customer.dart';
import '../models/ledger_transaction.dart';
import '../models/defect.dart';
import '../database/db_helper.dart';
import '../utils/price_parser.dart';

class InventoryProvider with ChangeNotifier {
  List<InventoryItem> _items = [];
  List<InventoryItem> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Customer> _customers = [];
  List<Customer> get customers => _customers;

  List<Defect> _defects = [];
  List<Defect> get defects => _defects;

  // --- WEB PREVIEW MOCK DATA ---
  int _mockIdCounter = 4;
  final List<InventoryItem> _mockWebDb = [
    InventoryItem(id: 1, brand: 'Apple', model: 'iPhone 13 Mini', qualityGrade: 'Original', wholesalePrice: 2500, retailPrice: 2800, stockCount: 5),
    InventoryItem(id: 2, brand: 'Samsung', model: 'Galaxy S21', qualityGrade: 'OLED', wholesalePrice: 3000, retailPrice: 3300, stockCount: 2),
    InventoryItem(id: 3, brand: 'OnePlus', model: 'Nord 2', qualityGrade: 'Incell', wholesalePrice: 1200, retailPrice: 1500, stockCount: 10),
  ];
  final List<Map<String, dynamic>> _mockSalesLog = [];

  Future<void> fetchItems() async {
    _isLoading = true;
    notifyListeners();
    
    if (kIsWeb) {
      _items = List.from(_mockWebDb);
    } else {
      _items = await DatabaseHelper.instance.getAllItems();
    }
    
    _isLoading = false;
    notifyListeners();
    
    // Also fetch pro states
    await fetchCustomers();
    await fetchDefects();
  }

  Future<void> searchItems(String query) async {
    _isLoading = true;
    notifyListeners();

    List<InventoryItem> all = kIsWeb ? _mockWebDb : await DatabaseHelper.instance.getAllItems();
    
    if (query.trim().isEmpty) {
      _items = List.from(all);
    } else {
      final lowerQuery = query.toLowerCase();
      final queryWords = lowerQuery.split(' ').where((s) => s.isNotEmpty).toList();
      
      _items = all.where((item) {
         String aliases = '';
         final b = item.brand.toLowerCase();
         if (b == 'apple') aliases = 'iphone iphne mac ipad';
         if (b == 'samsung') aliases = 'galaxy sam';
         if (b == 'xiaomi' || b == 'mi' || b == 'redmi' || b == 'poco') aliases = 'xiaomi mi redmi poco';
         if (b == 'oneplus') aliases = '1+';
         
         final searchableString = '${item.brand} ${item.model} $aliases'.toLowerCase();
         
         for (var word in queryWords) {
            if (!searchableString.contains(word)) return false;
         }
         return true;
      }).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sellItem(InventoryItem item, {int quantity = 1, required double priceSold, int? customerId, required String type}) async {
    if (item.stockCount >= quantity) {
      if (kIsWeb) {
        final index = _mockWebDb.indexWhere((e) => e.id == item.id);
        if (index != -1) {
          _mockWebDb[index] = _mockWebDb[index].copyWith(stockCount: _mockWebDb[index].stockCount - quantity);
          if (item.id != null) {
            _mockSalesLog.add({
              'item_id': item.id,
              'timestamp': DateTime.now().toIso8601String(),
              'price_sold': priceSold,
              'quantity': quantity,
              'customer_id': customerId,
              'sale_type': type,
            });
          }
        }
      } else {
        await DatabaseHelper.instance.sellItem(
          item, 
          quantity: quantity, 
          priceSold: priceSold, 
          customerId: customerId, 
          type: type
        );
      }
      await fetchItems();
    }
  }

  Future<void> undoPastSale(int saleId, int undoQty) async {
    if (kIsWeb) {
      // Mock implementation
    } else {
      await DatabaseHelper.instance.undoPastSale(saleId, undoQty);
      await fetchItems();
    }
  }

  Future<void> markPastSaleAsDefective(int saleId, int defectiveQty) async {
    if (!kIsWeb) {
      await DatabaseHelper.instance.markPastSaleAsDefective(saleId, defectiveQty);
      await fetchItems();
    }
  }

  Future<void> updateItem(InventoryItem item) async {
    if (kIsWeb) {
      final index = _mockWebDb.indexWhere((e) => e.id == item.id);
      if (index != -1) _mockWebDb[index] = item;
    } else {
      await DatabaseHelper.instance.updateItem(item);
    }
    await fetchItems();
  }

  Future<void> addItem(InventoryItem item) async {
    if (kIsWeb) {
      final newItem = item.copyWith(id: _mockIdCounter++);
      _mockWebDb.add(newItem);
    } else {
      await DatabaseHelper.instance.insertItem(item);
    }
    await fetchItems();
  }

  Future<void> deleteItem(int id) async {
    if (kIsWeb) {
      _mockWebDb.removeWhere((e) => e.id == id);
    } else {
      await DatabaseHelper.instance.deleteItem(id);
    }
    await fetchItems();
  }

  Future<void> applyBulkUpdates(List<InventoryItem> updatedItems) async {
    _isLoading = true;
    notifyListeners();

    // Fetch existing items to match against
    List<InventoryItem> existingItems = kIsWeb ? _mockWebDb : await DatabaseHelper.instance.getAllItems();

    for (var incomingItem in updatedItems) {
      InventoryItem? exactMatch; // Matches both model AND quality
      InventoryItem? modelMatch; // Matches model only
      
      final String incNorm = PriceParser.normalizeModel(incomingItem.brand, incomingItem.model);
      
      for (var ex in existingItems) {
         final String exNorm = PriceParser.normalizeModel(ex.brand, ex.model);
         if (incNorm == exNorm) {
            modelMatch = ex; // Found the same phone
            if (incomingItem.qualityGrade == ex.qualityGrade) {
               exactMatch = ex; // Found the exact same quality
               break;
            }
         }
      }

      if (exactMatch != null) {
         // Update existing item instead of creating a new one
         final updatedMatch = exactMatch.copyWith(
           wholesalePrice: incomingItem.wholesalePrice,
           retailPrice: incomingItem.retailPrice,
           stockCount: exactMatch.stockCount + incomingItem.stockCount,
         );
         
         if (kIsWeb) {
           final index = _mockWebDb.indexWhere((e) => e.id == exactMatch!.id);
           if (index != -1) _mockWebDb[index] = updatedMatch;
         } else {
           await DatabaseHelper.instance.updateItem(updatedMatch);
         }
      } else {
         // Insert entirely new item
         // If we found the model, inherit its exact spelling so it groups perfectly on the Dashboard!
         InventoryItem itemToInsert = incomingItem;
         if (modelMatch != null) {
            itemToInsert = incomingItem.copyWith(
               brand: modelMatch.brand,
               model: modelMatch.model,
            );
         }

         if (kIsWeb) {
           _mockWebDb.add(itemToInsert.copyWith(id: _mockIdCounter++));
         } else {
           await DatabaseHelper.instance.insertItem(itemToInsert);
         }
      }
    }

    await fetchItems();
  }

  Future<void> applyBulkStockUpdates(List<InventoryItem> updatedItems) async {
    _isLoading = true;
    notifyListeners();

    List<InventoryItem> existingItems = kIsWeb ? _mockWebDb : await DatabaseHelper.instance.getAllItems();

    for (var incomingItem in updatedItems) {
      InventoryItem? exactMatch; 
      InventoryItem? modelMatch; 
      
      final String incNorm = PriceParser.normalizeModel(incomingItem.brand, incomingItem.model);
      
      for (var ex in existingItems) {
         final String exNorm = PriceParser.normalizeModel(ex.brand, ex.model);
         if (incNorm == exNorm) {
            modelMatch = ex;
            if (incomingItem.qualityGrade == ex.qualityGrade) {
               exactMatch = ex;
               break;
            }
         }
      }

      if (exactMatch != null) {
         // ADD the incoming stock to the existing stock count
         final updatedMatch = exactMatch.copyWith(
           stockCount: exactMatch.stockCount + incomingItem.stockCount,
         );
         
         if (kIsWeb) {
           final index = _mockWebDb.indexWhere((e) => e.id == exactMatch!.id);
           if (index != -1) _mockWebDb[index] = updatedMatch;
         } else {
           await DatabaseHelper.instance.updateItem(updatedMatch);
         }
      } else {
         // Create new item with 0 prices but correct stock
         InventoryItem itemToInsert = incomingItem;
         if (modelMatch != null) {
            itemToInsert = incomingItem.copyWith(
               brand: modelMatch.brand,
               model: modelMatch.model,
            );
         }

         if (kIsWeb) {
           _mockWebDb.add(itemToInsert.copyWith(id: _mockIdCounter++));
         } else {
           await DatabaseHelper.instance.insertItem(itemToInsert);
         }
      }
    }

    await fetchItems();
  }

  Future<Map<String, dynamic>> fetchAnalytics(DateTime startDate) async {
    if (kIsWeb) {
      final String startDateStr = startDate.toIso8601String();
      final validSales = _mockSalesLog.where((log) => (log['timestamp'] as String).compareTo(startDateStr) >= 0).toList();
      
      final Map<int, Map<String, dynamic>> aggregated = {};
      
      for (var sale in validSales) {
        if (sale['sale_type'] == 'DEFECTIVE') continue;
        final int itemId = sale['item_id'];
        final item = _mockWebDb.firstWhere(
          (e) => e.id == itemId, 
          orElse: () => InventoryItem(brand: 'Del', model: 'Del', qualityGrade: '', wholesalePrice: 0, retailPrice: 0, stockCount: 0)
        );
        
        if (item.brand == 'Del') continue;

        if (!aggregated.containsKey(itemId)) {
          aggregated[itemId] = {
            'brand': item.brand,
            'model': item.model,
            'quality_grade': item.qualityGrade,
            'total_sold': 0,
            'total_revenue': 0.0,
          };
        }
        aggregated[itemId]!['total_sold'] = (aggregated[itemId]!['total_sold'] as int) + (sale['quantity'] as int);
        aggregated[itemId]!['total_revenue'] = (aggregated[itemId]!['total_revenue'] as double) + (sale['price_sold'] as double);
      }
      
      final models = aggregated.values.toList();
      models.sort((a, b) => (b['total_sold'] as int).compareTo(a['total_sold'] as int));
      
      return {
        'topModels': models,
        'topSpenders': <Map<String, dynamic>>[],
        'topReturners': <Map<String, dynamic>>[],
        'topDebtors': <Map<String, dynamic>>[],
      };
      
    } else {
      final models = await DatabaseHelper.instance.getSalesAnalytics(startDate);
      final spenders = await DatabaseHelper.instance.getCustomerPurchaseAnalytics(startDate);
      final returners = await DatabaseHelper.instance.getCustomerReturnAnalytics(startDate);
      final debtors = await DatabaseHelper.instance.getTopDebtors();
      
      return {
        'topModels': models,
        'topSpenders': spenders,
        'topReturners': returners,
        'topDebtors': debtors,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getSalesHistory() async {
    if (kIsWeb) return [];
    return await DatabaseHelper.instance.getSalesHistory();
  }

  // --- PRO FEATURES (Customers & Ledger) ---
  Future<void> fetchCustomers() async {
    if (!kIsWeb) {
      _customers = await DatabaseHelper.instance.getAllCustomers();
      notifyListeners();
    }
  }

  Future<void> addCustomer(Customer customer) async {
    if (!kIsWeb) {
      await DatabaseHelper.instance.insertCustomer(customer);
      await fetchCustomers();
    }
  }

  Future<void> archiveCustomer(int customerId) async {
    if (!kIsWeb) {
      await DatabaseHelper.instance.archiveCustomer(customerId);
      await fetchCustomers();
    }
  }

  Future<void> addLedgerTransaction(LedgerTransaction txn) async {
    if (!kIsWeb) {
      await DatabaseHelper.instance.insertLedgerTransaction(txn);
      await fetchCustomers();
    }
  }

  Future<List<LedgerTransaction>> getLedger(int customerId) async {
    if (kIsWeb) return [];
    return await DatabaseHelper.instance.getLedgerForCustomer(customerId);
  }

  // --- PRO FEATURES (Defects) ---
  Future<void> fetchDefects() async {
    if (!kIsWeb) {
      _defects = await DatabaseHelper.instance.getAllDefects();
      notifyListeners();
    }
  }

  Future<void> markDefective(InventoryItem item, {int? customerId, String? customerName}) async {
    if (item.stockCount > 0) {
      if (kIsWeb) {
        // Basic web mock decrease
        final index = _mockWebDb.indexWhere((e) => e.id == item.id);
        if (index != -1) {
           _mockWebDb[index] = _mockWebDb[index].copyWith(stockCount: _mockWebDb[index].stockCount - 1);
        }
      } else {
        // Decrease stock
        final updatedItem = item.copyWith(stockCount: item.stockCount - 1);
        await DatabaseHelper.instance.updateItem(updatedItem);
        
        // Log defect
        final details = '${item.brand} ${item.model} (${item.qualityGrade})' + (customerName != null ? '\nReturned by: $customerName' : '');
        await DatabaseHelper.instance.insertDefect(Defect(
          itemDetails: details,
          quantity: 1,
          dateLogged: DateTime.now().toIso8601String(),
        ));

        // Log negative sale entry
        if (item.id != null) {
          await DatabaseHelper.instance.logSale(
            itemId: item.id!,
            quantity: -1,
            priceSold: 0.0,
            customerId: customerId,
            type: 'DEFECTIVE',
          );
        }
        
        await fetchItems();
        await fetchDefects();
      }
    }
  }

  Future<void> resolveDefect(int defectId, bool isReplacement, {int? itemId, int? quantity}) async {
    if (!kIsWeb) {
      await DatabaseHelper.instance.updateDefectStatus(defectId, 'RESOLVED');
      
      if (isReplacement && itemId != null && quantity != null && quantity > 0) {
        await DatabaseHelper.instance.incrementStock(itemId, quantity);
      }
      
      await fetchDefects();
      await fetchItems();
    }
  }
}
