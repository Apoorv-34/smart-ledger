import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/product_group_card.dart';
import '../theme/app_theme.dart';
import '../models/inventory_item.dart';
import 'bulk_update_screen.dart';
import 'bulk_stock_screen.dart';
import 'analytics_screen.dart';
import 'khata_screen.dart';
import 'returns_screen.dart';
import 'sales_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedBrand;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    Provider.of<InventoryProvider>(context, listen: false).searchItems(query);
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);

    return PopScope(
      canPop: _searchController.text.isEmpty && _selectedBrand == null,
      onPopInvoked: (didPop) {
        if (didPop) return;
        
        if (_searchController.text.isNotEmpty) {
          _searchController.clear();
          _onSearchChanged('');
        }
        setState(() {
          _selectedBrand = null;
        });
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Smart Ledger Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.blueAccent),
            tooltip: 'Sales Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'Bulk Stock Updater',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BulkStockScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.data_exploration, color: AppTheme.primaryColor),
            tooltip: 'Bulk Price Updater',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BulkUpdateScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.surfaceColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                border: Border(bottom: BorderSide(color: Color(0xFF30363D))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/logo.jpg', width: 64, height: 64, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 16),
                  const Text('Smart Ledger Pro', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.blue),
              title: const Text('Digital Khata', style: TextStyle(color: Colors.white, fontSize: 16)),
              subtitle: const Text('Customer ledgers & credit', style: TextStyle(color: AppTheme.subtleTextColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => KhataScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.orange),
              title: const Text('Sales History', style: TextStyle(color: Colors.white, fontSize: 16)),
              subtitle: const Text('View and refund past sales', style: TextStyle(color: AppTheme.subtleTextColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => SalesHistoryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              title: const Text('Defective Returns', style: TextStyle(color: Colors.white, fontSize: 16)),
              subtitle: const Text('Manage supplier RMA', style: TextStyle(color: AppTheme.subtleTextColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ReturnsScreen()));
              },
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
        children: [
          // Sticky Search Bar
          Container(
            color: AppTheme.backgroundColor,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Search brand or model (e.g., iPhone 13)',
                prefixIcon: Icon(Icons.search, color: AppTheme.subtleTextColor),
              ),
            ),
          ),
          
          // Company Filter
          Builder(
            builder: (context) {
              final Set<String> inventoryBrands = inventory.items.map((e) => e.brand).toSet();
              final List<String> predefinedBrands = [
                'Apple', 'Samsung', 'OnePlus', 'Vivo', 'Oppo', 'Realme', 
                'Mi', 'Redmi', 'Poco', 'Motorola', 'Google Pixel', 'Nothing', 'Infinix', 'Tecno', 'Itel'
              ];
              
              final Set<String> brands = {...predefinedBrands, ...inventoryBrands};

              return Container(
                color: AppTheme.backgroundColor,
                height: 50,
                width: double.infinity,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: const Text('All', style: TextStyle(color: Colors.white)),
                        selected: _selectedBrand == null,
                        selectedColor: AppTheme.primaryColor,
                        checkmarkColor: Colors.black,
                        backgroundColor: AppTheme.surfaceColor,
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedBrand = null;
                          });
                        },
                      ),
                    ),
                    ...brands.map((brand) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(brand, style: TextStyle(color: _selectedBrand == brand ? Colors.black : Colors.white)),
                          selected: _selectedBrand == brand,
                          selectedColor: AppTheme.primaryColor,
                          checkmarkColor: Colors.black,
                          backgroundColor: AppTheme.surfaceColor,
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedBrand = selected ? brand : null;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
          
          // Inventory List
          Expanded(
            child: inventory.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : inventory.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.subtleTextColor.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            const Text('No inventory found.', style: TextStyle(color: AppTheme.subtleTextColor, fontSize: 16)),
                          ],
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          // Group items by brand and model (case insensitive)
                          final Map<String, List<InventoryItem>> groupedItems = {};
                          final Map<String, String> displayNames = {};
                          
                          for (var item in inventory.items) {
                            if (_selectedBrand != null && item.brand != _selectedBrand) continue;
                            
                            final rawKey = '${item.brand} ${item.model}'.trim();
                            final normalizedKey = rawKey.toLowerCase();
                            
                            if (!groupedItems.containsKey(normalizedKey)) {
                              groupedItems[normalizedKey] = [];
                              displayNames[normalizedKey] = rawKey; // Save the first encountered casing for display
                            }
                            groupedItems[normalizedKey]!.add(item);
                          }
                          
                          final groupKeys = groupedItems.keys.toList();

                          return ListView.builder(
                            itemCount: groupKeys.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final key = groupKeys[index];
                              return ProductGroupCard(
                                groupName: displayNames[key]!,
                                items: groupedItems[key]!,
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      ),
      ),
    );
  }
}
