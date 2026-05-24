import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/inventory_provider.dart';
import '../models/customer.dart';
import '../models/ledger_transaction.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  CustomerDetailScreen({required this.customer});

  @override
  _CustomerDetailScreenState createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  List<LedgerTransaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    final txns = await provider.getLedger(widget.customer.id!);
    setState(() {
      _transactions = txns;
      _isLoading = false;
    });
  }

  Future<void> _shareBillOnWhatsApp() async {
    String message = '*Smart Ledger*\n_Where Technology Meets Trust_\n\n';
    message += 'Hello ${widget.customer.name} 👋\n';
    message += 'Here is your current account statement:\n\n';
    
    // Reverse the list for chronological order (oldest to newest) or keep as is (newest to oldest)
    // Currently _transactions are fetched ordered by date DESC. Let's show newest on top.
    for (var txn in _transactions) {
      // Simple date format
      final date = DateTime.parse(txn.date);
      final dateStr = '${date.day}/${date.month}';

      if (txn.type == 'CREDIT') {
        message += '[$dateStr] 🔴 Taken: ${txn.itemDetails} (₹${txn.amount.toStringAsFixed(0)})\n';
      } else {
        message += '[$dateStr] 🟢 Paid: Payment Received (₹${txn.amount.toStringAsFixed(0)})\n';
      }
    }
    
    message += '\n-------------------\n';
    if (widget.customer.totalDue < 0) {
      message += '*Total Advance Credit: ₹${widget.customer.totalDue.abs().toStringAsFixed(0)}*\n';
    } else {
      message += '*Total Outstanding Due: ₹${widget.customer.totalDue.toStringAsFixed(0)}*\n';
    }
    message += '-------------------\n\n';
    message += 'Thank you for doing business with us! 🙏\n';
    message += 'Please feel free to reach out if you have any questions regarding this statement.';

    final encodedMessage = Uri.encodeComponent(message);
    // Use wa.me which is the official WhatsApp API and much more reliable
    final url = Uri.parse('https://wa.me/91${widget.customer.phone}?text=$encodedMessage');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch WhatsApp')));
    }
  }

  void _showPaymentDialog() {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Record Payment'),
          content: TextField(
            controller: amountController,
            decoration: InputDecoration(labelText: 'Amount Received (₹)', prefixIcon: Icon(Icons.currency_rupee)),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  final txn = LedgerTransaction(
                    customerId: widget.customer.id!,
                    itemDetails: 'Payment Received',
                    amount: amount,
                    type: 'PAYMENT',
                    date: DateTime.now().toIso8601String(),
                  );
                  await Provider.of<InventoryProvider>(context, listen: false).addLedgerTransaction(txn);
                  _loadLedger();
                  Navigator.pop(context);
                }
              },
              child: Text('Save Payment'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // We need to fetch the updated customer due amount from the provider
    final customer = Provider.of<InventoryProvider>(context).customers.firstWhere((c) => c.id == widget.customer.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.green.shade400),
            onPressed: _shareBillOnWhatsApp,
            tooltip: 'Share via WhatsApp',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Archive Customer',
            onPressed: () {
              // Strict balance check (accounting for float precision)
              if (customer.totalDue.abs() > 0.01) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Cannot archive customer with an active balance. Please settle their Khata first.'), 
                  backgroundColor: Colors.red
                ));
                return;
              }
              
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E2128),
                  title: const Text('Archive Customer?', style: TextStyle(color: Colors.white)),
                  content: Text('Are you sure you want to archive ${customer.name}? Their history will be saved but they will be removed from your active list.', style: const TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        await Provider.of<InventoryProvider>(context, listen: false).archiveCustomer(customer.id!);
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer Archived.'), backgroundColor: Colors.orange));
                      },
                      child: const Text('Archive', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            padding: EdgeInsets.all(24),
            width: double.infinity,
            color: Colors.blue.shade800,
            child: Column(
              children: [
                Text(customer.totalDue < 0 ? 'Total Advance Credit' : 'Total Outstanding Due', style: TextStyle(color: Colors.blue.shade100, fontSize: 16)),
                SizedBox(height: 8),
                Text('₹${customer.totalDue.abs().toStringAsFixed(0)}', style: TextStyle(color: customer.totalDue < 0 ? Colors.greenAccent : Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showPaymentDialog,
                  icon: Icon(Icons.account_balance_wallet),
                  label: Text('Record Payment Received'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final txn = _transactions[index];
                    final isCredit = txn.type == 'CREDIT';
                    
                    // Simple date format
                    final date = DateTime.parse(txn.date);
                    final dateStr = '${date.day}/${date.month}/${date.year}';

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCredit ? Colors.red.shade100 : Colors.green.shade100,
                          child: Icon(
                            isCredit ? Icons.arrow_outward : Icons.arrow_downward,
                            color: isCredit ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text(txn.itemDetails, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(dateStr),
                        trailing: Text(
                          '${isCredit ? '-' : '+'}₹${txn.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: isCredit ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
