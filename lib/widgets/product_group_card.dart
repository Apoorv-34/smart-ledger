import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory_item.dart';
import '../models/customer.dart';
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
    int quantity = 1;
    double priceSold = item.retailPrice;
    Customer? selectedCustomer;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final provider = Provider.of<InventoryProvider>(context, listen: false);
            final customers = provider.customers;
            
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sell ${item.brand} ${item.model}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 16),
                      // Quantity Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quantity', style: TextStyle(color: Colors.white)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.blue),
                                onPressed: quantity > 1 ? () => setState(() {
                                  quantity--;
                                  priceSold = item.retailPrice * quantity;
                                }) : null,
                              ),
                              Text('$quantity', style: const TextStyle(color: Colors.white, fontSize: 18)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                                onPressed: quantity < item.stockCount ? () => setState(() {
                                  quantity++;
                                  priceSold = item.retailPrice * quantity;
                                }) : null,
                              ),
                            ],
                          )
                        ],
                      ),
                      // Custom Price
                      TextField(
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Final Price (₹)', labelStyle: TextStyle(color: Colors.grey)),
                        controller: TextEditingController(text: priceSold.toStringAsFixed(0))..selection = TextSelection.collapsed(offset: priceSold.toStringAsFixed(0).length),
                        onChanged: (val) {
                          priceSold = double.tryParse(val) ?? (item.retailPrice * quantity);
                        },
                      ),
                      const SizedBox(height: 16),
                      // Customer Dropdown
                      DropdownButtonFormField<Customer>(
                        decoration: const InputDecoration(labelText: 'Select Customer (Optional)', labelStyle: TextStyle(color: Colors.grey)),
                        dropdownColor: AppTheme.backgroundColor,
                        value: selectedCustomer,
                        items: [
                          const DropdownMenuItem<Customer>(value: null, child: Text('Anonymous Cash Sale', style: TextStyle(color: Colors.white))),
                          ...customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(color: Colors.white))))
                        ],
                        onChanged: (val) {
                          setState(() { selectedCustomer = val; });
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              icon: const Icon(Icons.payments, color: Colors.white),
                              label: const Text('Cash Sale', style: TextStyle(color: Colors.white)),
                              onPressed: () async {
                                await provider.sellItem(item, quantity: quantity, priceSold: priceSold, customerId: selectedCustomer?.id, type: 'CASH');
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sold for Cash'), backgroundColor: Colors.green));
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              icon: const Icon(Icons.menu_book, color: Colors.white),
                              label: const Text('Credit (Khata)', style: TextStyle(color: Colors.white)),
                              onPressed: selectedCustomer == null ? null : () async {
                                await provider.sellItem(item, quantity: quantity, priceSold: priceSold, customerId: selectedCustomer!.id, type: 'CREDIT');
                                // Add to ledger
                                final txn = LedgerTransaction(
                                  customerId: selectedCustomer!.id!,
                                  itemDetails: '${item.brand} ${item.model} (${item.qualityGrade}) x$quantity',
                                  amount: priceSold,
                                  type: 'CREDIT',
                                  date: DateTime.now().toIso8601String(),
                                );
                                await provider.addLedgerTransaction(txn);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sold on Credit to ${selectedCustomer!.name}'), backgroundColor: Colors.blue));
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
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
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF30363D)),
                        ),
                        child: Text(
                          item.qualityGrade,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.subtleTextColor,
                            fontWeight: FontWeight.w600,
                          ),
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
