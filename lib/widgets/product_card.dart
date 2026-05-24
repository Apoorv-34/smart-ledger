import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory_item.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final InventoryItem item;

  const ProductCard({Key? key, required this.item}) : super(key: key);

  void _showManageDialog(BuildContext context) {
    final TextEditingController stockController = TextEditingController(text: item.stockCount.toString());
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text('Manage ${item.model}'),
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

  @override
  Widget build(BuildContext context) {
    final bool isLowStock = item.stockCount < 3;
    final bool outOfStock = item.stockCount <= 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showManageDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon/Avatar placeholder for product
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: const Icon(
                Icons.phone_android,
                color: AppTheme.secondaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.brand} ${item.model}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Row(
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
                      const SizedBox(width: 8),
                      Text(
                        '₹${item.retailPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Stock: ${item.stockCount}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
            
            // Sell Button
            ElevatedButton(
              onPressed: outOfStock
                  ? null
                  : () {
                      Provider.of<InventoryProvider>(context, listen: false).sellItem(
                        item,
                        quantity: 1,
                        priceSold: item.retailPrice,
                        type: 'CASH'
                      );
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sold 1x ${item.model}'),
                          backgroundColor: AppTheme.primaryColor,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: outOfStock ? Colors.grey[800] : AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minimumSize: const Size(80, 48),
              ),
              child: Text(
                outOfStock ? 'SOLD OUT' : 'SELL',
                style: TextStyle(
                  color: outOfStock ? Colors.grey[500] : Colors.black,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
