import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory_item.dart';
import '../models/ledger_transaction.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';

class ProductGroupCard extends StatelessWidget {
  final String groupName;
  final List<InventoryItem> items;

  const ProductGroupCard({Key? key, required this.groupName, required this.items}) : super(key: key);

  void _showManageDialog(BuildContext context, InventoryItem item) {
    final TextEditingController stockController = TextEditingController(text: item.stockCount.toString());
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text('Manage ${item.qualityGrade}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Update Stock Count:', style: TextStyle(color: AppTheme.subtleTextColor)),
            const SizedBox(height: 12),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Stock',
                prefixIcon: Icon(Icons.inventory_2),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              if (item.id != null) {
                Provider.of<InventoryProvider>(context, listen: false).deleteItem(item.id!);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item deleted'), backgroundColor: AppTheme.dangerColor));
              }
            },
            icon: const Icon(Icons.delete, color: AppTheme.dangerColor),
            label: const Text('Delete', style: TextStyle(color: AppTheme.dangerColor)),
          ),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(stockController.text) ?? item.stockCount;
              final updatedItem = item.copyWith(stockCount: newStock);
              Provider.of<InventoryProvider>(context, listen: false).updateItem(updatedItem);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSellOptionsDialog(BuildContext context, InventoryItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Action Options', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text('${item.brand} ${item.model} (${item.qualityGrade})'),
              ),
              Divider(color: Colors.grey[800]),
              ListTile(
                leading: const Icon(Icons.payments, color: Colors.green),
                title: const Text('Quick Cash Sale', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Provider.of<InventoryProvider>(context, listen: false).sellItem(item);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sold for Cash'), backgroundColor: Colors.green));
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book, color: Colors.blue),
                title: const Text('Sell on Credit (Khata)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSelectCustomerDialog(context, item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                title: const Text('Mark as Defective (RMA)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Provider.of<InventoryProvider>(context, listen: false).markDefective(item);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Moved to Defective Returns'), backgroundColor: Colors.orange));
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }

  void _showSelectCustomerDialog(BuildContext context, InventoryItem item) {
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    final customers = provider.customers;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Select Customer', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: customers.isEmpty 
              ? const Text('No customers found. Go to Khata to add one.', style: TextStyle(color: Colors.grey))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: customers.length,
                  itemBuilder: (c, i) {
                    final cust = customers[i];
                    return ListTile(
                      title: Text(cust.name, style: TextStyle(color: Colors.white)),
                      subtitle: Text('Due: ₹${cust.totalDue.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey)),
                      onTap: () async {
                        await provider.sellItem(item); // Decrease stock & log sale
                        
                        // Add to ledger
                        final txn = LedgerTransaction(
                          customerId: cust.id!,
                          itemDetails: '${item.brand} ${item.model} (${item.qualityGrade})',
                          amount: item.retailPrice,
                          type: 'CREDIT',
                          date: DateTime.now().toIso8601String(),
                        );
                        await provider.addLedgerTransaction(txn);
                        
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sold to ${cust.name} on Credit'), backgroundColor: Colors.blue));
                      },
                    );
                  }
              ),
          ),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx))
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalStock = items.fold(0, (sum, item) => sum + item.stockCount);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF30363D), width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppTheme.primaryColor,
          collapsedIconColor: AppTheme.subtleTextColor,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: const Icon(Icons.phone_android, color: AppTheme.secondaryColor),
          ),
          title: Text(
            groupName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '${items.length} Options • Total Stock: $totalStock',
              style: const TextStyle(color: AppTheme.subtleTextColor, fontSize: 13),
            ),
          ),
          children: items.map((item) {
            final bool isLowStock = item.stockCount < 3;
            final bool outOfStock = item.stockCount <= 0;

            return InkWell(
              onTap: () => _showManageDialog(context, item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFF30363D))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF30363D)),
                      ),
                      child: Text(
                        item.qualityGrade,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.subtleTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${item.retailPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Stock: ${item.stockCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: outOfStock
                                  ? AppTheme.dangerColor
                                  : isLowStock
                                      ? Colors.orangeAccent
                                      : AppTheme.subtleTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                      ElevatedButton(
                        onPressed: outOfStock
                            ? null
                            : () => _showSellOptionsDialog(context, item),
                        style: ElevatedButton.styleFrom(
                        backgroundColor: outOfStock ? Colors.grey[800] : AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: const Size(70, 36),
                      ),
                      child: Text(
                        outOfStock ? 'SOLD OUT' : 'SELL',
                        style: TextStyle(
                          color: outOfStock ? Colors.grey[500] : Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
