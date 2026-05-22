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

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: pendingDefects.length,
            itemBuilder: (context, index) {
              final defect = pendingDefects[index];
              final date = DateTime.parse(defect.dateLogged);
              final dateStr = '${date.day}/${date.month}/${date.year}';

              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.orange.shade200, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                  ),
                  title: Text(defect.itemDetails, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text('Logged on: $dateStr\nQty: ${defect.quantity}'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      provider.resolveDefect(defect.id!);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marked as Resolved/Returned')));
                    },
                    child: Text('Resolve'),
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
