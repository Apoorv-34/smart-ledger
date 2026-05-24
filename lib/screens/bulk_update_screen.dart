import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory_item.dart';
import '../providers/inventory_provider.dart';
import '../utils/price_parser.dart';
import '../theme/app_theme.dart';

class BulkUpdateScreen extends StatefulWidget {
  const BulkUpdateScreen({Key? key}) : super(key: key);

  @override
  State<BulkUpdateScreen> createState() => _BulkUpdateScreenState();
}

class _BulkUpdateScreenState extends State<BulkUpdateScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _marginController = TextEditingController(text: '200');
  final TextEditingController _qtyController = TextEditingController(text: '0');
  
  bool _isWholesaleMode = false; // False: Final Price (Custom). True: Add Margin.
  
  List<InventoryItem> _previewItems = [];

  void _generatePreview() {
    final text = _textController.text;
    final margin = double.tryParse(_marginController.text) ?? 200.0;
    final qty = int.tryParse(_qtyController.text) ?? 0;
    
    if (text.trim().isEmpty) {
      setState(() => _previewItems = []);
      return;
    }

    setState(() {
      _previewItems = PriceParser.parseWhatsAppText(text, margin, isWholesalePrice: _isWholesaleMode, defaultQuantity: qty);
    });
  }

  void _applyUpdates() async {
    if (_previewItems.isEmpty) return;

    // In a real scenario, we would match existing DB items and update them.
    // For now, this adds them as new inventory or overrides.
    await Provider.of<InventoryProvider>(context, listen: false).applyBulkUpdates(_previewItems);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Inventory Updated Successfully!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Scraper'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: Column(
                children: [
                  RadioListTile<bool>(
                    title: const Text('Exact Selling Prices (Custom)', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Prices in text are already final. No extra margin will be added.', style: TextStyle(fontSize: 12, color: AppTheme.subtleTextColor)),
                    value: false,
                    groupValue: _isWholesaleMode,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (bool? value) {
                      setState(() => _isWholesaleMode = value!);
                      _generatePreview();
                    },
                  ),
                  RadioListTile<bool>(
                    title: const Text('Add Standard Profit Margin', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Prices in text are Wholesale. App will add margin to calculate Selling Price.', style: TextStyle(fontSize: 12, color: AppTheme.subtleTextColor)),
                    value: true,
                    groupValue: _isWholesaleMode,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (bool? value) {
                      setState(() => _isWholesaleMode = value!);
                      _generatePreview();
                    },
                  ),
                ],
              ),
            ),
            if (_isWholesaleMode) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Profit Margin (₹): ', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _marginController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _generatePreview(),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Add Stock Qty: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _generatePreview(),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (_) => _generatePreview(),
                decoration: const InputDecoration(
                  hintText: 'Paste WhatsApp broadcast message here...\n\ne.g.\niPh13 mini OLED 2500\nSam S21 OG 3000',
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_previewItems.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: ListView.builder(
                    itemCount: _previewItems.length,
                    itemBuilder: (context, index) {
                      final item = _previewItems[index];
                      return ListTile(
                        title: Text('${item.brand} - ${item.model}'),
                        subtitle: _isWholesaleMode 
                            ? Text('Wholesale: ₹${item.wholesalePrice} ➔ Sell: ₹${item.retailPrice}')
                            : Text('Final Selling Price: ₹${item.retailPrice}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(item.qualityGrade, style: const TextStyle(fontSize: 12, color: AppTheme.subtleTextColor)),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _applyUpdates,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('APPLY ALL'),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
