import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';

class ReturnsScreen extends StatefulWidget {
  @override
  _ReturnsScreenState createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<InventoryProvider>(context, listen: false).fetchDefects());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Defective Returns (RMA)'),
        backgroundColor: Colors.orange.shade800,
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          final pendingDefects = provider.defects.where((d) => d.status == 'PENDING').toList();

          if (pendingDefects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text('No pending returns!', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          // Group defects by customer name
          final Map<String, List<dynamic>> groupedDefects = {};
          for (var defect in pendingDefects) {
            String customerName = 'Anonymous / Shop Stock';
            if (defect.itemDetails.contains('\nReturned by: ')) {
              final parts = defect.itemDetails.split('\nReturned by: ');
              customerName = parts[1];
            }
            if (!groupedDefects.containsKey(customerName)) {
              groupedDefects[customerName] = [];
            }
            groupedDefects[customerName]!.add(defect);
          }

          final groupKeys = groupedDefects.keys.toList();
          groupKeys.sort((a, b) {
            if (a == 'Anonymous / Shop Stock') return 1;
            if (b == 'Anonymous / Shop Stock') return -1;
            return a.compareTo(b);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: groupKeys.length,
            itemBuilder: (context, index) {
              final customerName = groupKeys[index];
              final customerDefects = groupedDefects[customerName]!;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.orange.shade800.withOpacity(0.5), width: 1),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    iconColor: Colors.orange.shade800,
                    collapsedIconColor: Colors.orange.shade600,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      child: Icon(customerName == 'Anonymous / Shop Stock' ? Icons.storefront : Icons.person, color: Colors.orange.shade800),
                    ),
                    title: Text(
                      customerName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                    ),
                    subtitle: Text(
                      '${customerDefects.length} Pending Defective Items',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    children: customerDefects.map((defect) {
                      final date = DateTime.parse(defect.dateLogged);
                      final dateStr = '${date.day}/${date.month}/${date.year}';
                      
                      String cleanDetails = defect.itemDetails;
                      if (defect.itemDetails.contains('\nReturned by: ')) {
                        cleanDetails = defect.itemDetails.split('\nReturned by: ')[0];
                      }

                      return Container(
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.orange.withOpacity(0.2))),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          leading: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                          title: Text(cleanDetails, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Text('Logged on: $dateStr\nQty: ${defect.quantity}'),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E2128),
                                  title: const Text('Resolve Defect', style: TextStyle(color: Colors.white)),
                                  content: const Text('How did the supplier resolve this return?', style: TextStyle(color: Colors.white70)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                      onPressed: () {
                                        provider.resolveDefect(defect.id!, false);
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resolved with Refund'), backgroundColor: Colors.blue));
                                      },
                                      child: const Text('Refund (No Stock)', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      onPressed: () {
                                        provider.resolveDefect(
                                          defect.id!, 
                                          true, 
                                          itemId: defect.itemId, 
                                          quantity: defect.quantity
                                        );
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resolved & Stock Restored'), backgroundColor: Colors.green));
                                      },
                                      child: const Text('Replacement (+Stock)', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Resolve', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
