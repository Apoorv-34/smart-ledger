import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';

class SalesHistoryScreen extends StatefulWidget {
  @override
  _SalesHistoryScreenState createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _salesFuture;

  @override
  void initState() {
    super.initState();
    _refreshSales();
  }

  void _refreshSales() {
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    setState(() {
      _salesFuture = provider.getSalesHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History & Refunds', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _salesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading history: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final sales = snapshot.data ?? [];
          
          if (sales.isEmpty) {
            return const Center(child: Text('No sales recorded yet.', style: TextStyle(color: Colors.grey)));
          }

          double totalCash = 0;
          double totalCredit = 0;
          for (var s in sales) {
            final amt = s['price_sold'] as double;
            if (s['sale_type'] == 'CASH') totalCash += amt;
            else if (s['sale_type'] == 'CREDIT') totalCredit += amt;
          }

          final Map<String, List<Map<String, dynamic>>> groupedSales = {};
          for (var sale in sales) {
            final customerName = sale['customer_name'] as String? ?? 'Anonymous Cash Sales';
            if (!groupedSales.containsKey(customerName)) {
              groupedSales[customerName] = [];
            }
            groupedSales[customerName]!.add(sale);
          }

          final groupKeys = groupedSales.keys.toList();
          groupKeys.sort((a, b) {
            if (a == 'Anonymous Cash Sales') return 1;
            if (b == 'Anonymous Cash Sales') return -1;
            return a.compareTo(b);
          });

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.surfaceColor,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.3))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Cash Sales', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('₹${totalCash.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withOpacity(0.3))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Credit Sales', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('₹${totalCredit.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: groupKeys.length,
                  itemBuilder: (context, index) {
                    final customerName = groupKeys[index];
                    final customerSales = groupedSales[customerName]!;
                    
                    double customerTotal = 0;
                    for (var s in customerSales) {
                      if (s['sale_type'] != 'DEFECTIVE') {
                        customerTotal += (s['price_sold'] as double);
                      }
                    }

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
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.backgroundColor,
                            child: Icon(customerName == 'Anonymous Cash Sales' ? Icons.people_alt : Icons.person, color: AppTheme.primaryColor),
                          ),
                          title: Text(
                            customerName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                          ),
                          subtitle: Text(
                            '${customerSales.length} Transactions • Total: ₹${customerTotal.toStringAsFixed(0)}',
                            style: const TextStyle(color: AppTheme.subtleTextColor, fontSize: 13),
                          ),
                          children: customerSales.map((sale) {
                            final date = DateTime.parse(sale['timestamp']);
                            final dateStr = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                            
                            final isCash = sale['sale_type'] == 'CASH';
                            final isDefective = sale['sale_type'] == 'DEFECTIVE';

                            return InkWell(
                              onTap: isDefective ? null : () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: AppTheme.surfaceColor,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                  builder: (ctx) {
                                    return SafeArea(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Manage Sale', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                            const SizedBox(height: 16),
                                            ListTile(
                                              leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.warning, color: Colors.white)),
                                              title: const Text('Mark as Defective (RMA Return)'),
                                              subtitle: Text(isCash ? 'Removes revenue & logs defect' : 'Removes revenue, logs defect & auto-refunds Khata'),
                                              onTap: () async {
                                                Navigator.pop(ctx);
                                                
                                                int qtyToMark = 1;
                                                final int originalQty = sale['quantity'] as int;

                                                if (originalQty > 1) {
                                                  final qtyController = TextEditingController(text: originalQty.toString());
                                                  final result = await showDialog<int>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      backgroundColor: AppTheme.surfaceColor,
                                                      title: const Text('Partial RMA?'),
                                                      content: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text('This sale was for $originalQty items. How many are actually defective?'),
                                                          const SizedBox(height: 16),
                                                          TextField(
                                                            controller: qtyController,
                                                            keyboardType: TextInputType.number,
                                                            decoration: const InputDecoration(labelText: 'Defective Quantity', border: OutlineInputBorder()),
                                                          ),
                                                        ],
                                                      ),
                                                      actions: [
                                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                                          onPressed: () {
                                                            final parsed = int.tryParse(qtyController.text);
                                                            Navigator.pop(context, parsed);
                                                          },
                                                          child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  
                                                  if (result == null || result <= 0 || result > originalQty) return;
                                                  qtyToMark = result;
                                                }

                                                await Provider.of<InventoryProvider>(context, listen: false).markPastSaleAsDefective(sale['sale_id'], qtyToMark);
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marked $qtyToMark as Defective. Khata refunded if credit.'), backgroundColor: Colors.orange));
                                                _refreshSales();
                                              },
                                            ),
                                            const Divider(color: Color(0xFF30363D)),
                                            ListTile(
                                              leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.undo, color: Colors.white)),
                                              title: const Text('Undo Sale (Mistake)', style: TextStyle(color: Colors.redAccent)),
                                              subtitle: const Text('Deletes sale & restores stock (Manual Khata refund needed)'),
                                              onTap: () async {
                                                Navigator.pop(ctx);
                                                
                                                int qtyToUndo = 1;
                                                final int originalQty = sale['quantity'] as int;

                                                if (originalQty > 1) {
                                                  final qtyController = TextEditingController(text: originalQty.toString());
                                                  final result = await showDialog<int>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      backgroundColor: AppTheme.surfaceColor,
                                                      title: const Text('Partial Undo?'),
                                                      content: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text('This sale was for $originalQty items. How many do you want to undo?'),
                                                          const SizedBox(height: 16),
                                                          TextField(
                                                            controller: qtyController,
                                                            keyboardType: TextInputType.number,
                                                            decoration: const InputDecoration(labelText: 'Undo Quantity', border: OutlineInputBorder()),
                                                          ),
                                                        ],
                                                      ),
                                                      actions: [
                                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                          onPressed: () {
                                                            final parsed = int.tryParse(qtyController.text);
                                                            Navigator.pop(context, parsed);
                                                          },
                                                          child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  
                                                  if (result == null || result <= 0 || result > originalQty) return;
                                                  qtyToUndo = result;
                                                }

                                                await Provider.of<InventoryProvider>(context, listen: false).undoPastSale(sale['sale_id'], qtyToUndo);
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sale Undone ($qtyToUndo units). Stock restored. Khata adjusted if credit.'), backgroundColor: Colors.orange));
                                                _refreshSales();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                );
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  border: Border(top: BorderSide(color: Color(0xFF30363D))),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isDefective ? Colors.red.withOpacity(0.2) : isCash ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                                    child: Icon(isDefective ? Icons.warning_amber_rounded : isCash ? Icons.payments : Icons.menu_book, color: isDefective ? Colors.red : isCash ? Colors.green : Colors.blue),
                                  ),
                                  title: Text('${isDefective ? "[RMA] " : ""}${sale['brand']} ${sale['model']} (${sale['quality_grade']}) x${sale['quantity'].abs()}', style: TextStyle(color: isDefective ? Colors.redAccent : Colors.white)),
                                  subtitle: Text(
                                    dateStr,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  trailing: Text(
                                    isDefective ? 'DEFECTIVE' : '₹${sale['price_sold'].toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: isDefective ? Colors.redAccent : isCash ? Colors.green : Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isDefective ? 12 : 16,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  },
),
    );
  }
}
