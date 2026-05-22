import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory_item.dart';
import '../providers/inventory_provider.dart';
import '../utils/price_parser.dart';
import '../theme/app_theme.dart';

class BulkStockScreen extends StatefulWidget {
  const BulkStockScreen({Key? key}) : super(key: key);

  @override
  State<BulkStockScreen> createState() => _BulkStockScreenState();
}

class _BulkStockScreenState extends State<BulkStockScreen> {
  final TextEditingController _textController = TextEditingController();
  List<InventoryItem> _previewItems = [];

  void _generatePreview() {
    final text = _textController.text;
    
    if (text.trim().isEmpty) {
      setState(() => _previewItems = []);
      return;
    }

    setState(() {
      _previewItems = PriceParser.parseStockUpdateText(text);
    });
  }

  void _applyUpdates() async {
    if (_previewItems.isEmpty) return;

    final provider = Provider.of<InventoryProvider>(context, listen: false);
    await provider.applyBulkStockUpdates(_previewItems);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock levels updated successfully!'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Stock Updater'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: TextField(
                controller: _textController,
                onChanged: (_) => _generatePreview(),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Paste WhatsApp stock list here...\n\ne.g.\niPhone 13 mini OLED 5\nSam S21 OG 2\nOnePlus Nord 2 10 pcs',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Preview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: _previewItems.isEmpty
                    ? const Center(
                        child: Text(
                          'No valid quantities found.\nMake sure lines end with a number (e.g. "Model 5").',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.subtleTextColor),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _previewItems.length,
                        separatorBuilder: (context, index) => const Divider(color: Color(0xFF30363D), height: 1),
                        itemBuilder: (context, index) {
                          final item = _previewItems[index];
                          return ListTile(
                            title: Text('${item.brand} - ${item.model}'),
                            subtitle: Text('Add Stock: +${item.stockCount}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF30363D)),
                              ),
                              child: Text(
                                item.qualityGrade,
                                style: const TextStyle(fontSize: 12, color: AppTheme.subtleTextColor),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _previewItems.isEmpty ? null : _applyUpdates,
                icon: const Icon(Icons.check_circle_outline, color: Colors.black),
                label: const Text(
                  'APPLY STOCK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  disabledBackgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
