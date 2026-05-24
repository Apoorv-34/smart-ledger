import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedFilterIndex = 0; // 0: 7 Days, 1: 30 Days, 2: 6 Months, 3: All Time
  
  Map<String, dynamic> _analyticsData = {};
  bool _isLoading = true;
  
  int _totalSold = 0;
  double _totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    DateTime startDate;
    final now = DateTime.now();
    switch (_selectedFilterIndex) {
      case 0:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 1:
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 2:
        startDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case 3:
      default:
        startDate = DateTime(2000); // effectively "all time"
        break;
    }

    final provider = Provider.of<InventoryProvider>(context, listen: false);
    final data = await provider.fetchAnalytics(startDate);
    
    int sold = 0;
    double rev = 0;
    final models = data['topModels'] as List<Map<String, dynamic>>? ?? [];
    for (var row in models) {
      sold += (row['total_sold'] as int);
      rev += (row['total_revenue'] as double);
    }

    setState(() {
      _analyticsData = data;
      _totalSold = sold;
      _totalRevenue = rev;
      _isLoading = false;
    });
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      backgroundColor: AppTheme.backgroundColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.subtleTextColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? AppTheme.primaryColor : const Color(0xFF30363D)),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilterIndex = index;
            _loadAnalytics();
          });
        }
      },
    );
  }

  Widget _buildOverviewTab() {
    final models = _analyticsData['topModels'] as List<Map<String, dynamic>>? ?? [];
    return Column(
      children: [
        // Summary Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E242C), Color(0xFF111418)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Units Sold', style: TextStyle(color: AppTheme.subtleTextColor, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        _totalSold.toString(),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: const Color(0xFF30363D)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Est. Revenue', style: TextStyle(color: AppTheme.subtleTextColor, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${_totalRevenue.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Top Selling Models', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: models.isEmpty
              ? const Center(child: Text('No sales recorded in this period.', style: TextStyle(color: AppTheme.subtleTextColor)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: models.length,
                  itemBuilder: (context, index) {
                    final row = models[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF30363D)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.backgroundColor,
                          child: Text('#${index + 1}', style: const TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold)),
                        ),
                        title: Text('${row['brand']} ${row['model']}'),
                        subtitle: Text(row['quality_grade'], style: const TextStyle(color: AppTheme.subtleTextColor)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${row['total_sold']} sold', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('₹${(row['total_revenue'] as double).toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCustomersTab() {
    final spenders = _analyticsData['topSpenders'] as List<Map<String, dynamic>>? ?? [];
    final returners = _analyticsData['topReturners'] as List<Map<String, dynamic>>? ?? [];
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Top Customers by Revenue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
        const SizedBox(height: 8),
        if (spenders.isEmpty) const Text('No customer sales found in this period.', style: TextStyle(color: AppTheme.subtleTextColor)),
        ...spenders.map((row) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: AppTheme.backgroundColor, child: Icon(Icons.person, color: Colors.white)),
            title: Text(row['name']),
            subtitle: Text('${row['total_items']} items purchased'),
            trailing: Text('₹${(row['total_spent'] as double).toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
        )),
        
        const SizedBox(height: 32),
        const Text('Highest RMA (Returns)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
        const SizedBox(height: 8),
        if (returners.isEmpty) const Text('No customer returns found in this period.', style: TextStyle(color: AppTheme.subtleTextColor)),
        ...returners.map((row) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: AppTheme.backgroundColor, child: Icon(Icons.warning, color: Colors.orange)),
            title: Text(row['name']),
            trailing: Text('${row['total_returns']} returns', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
        )),
      ],
    );
  }

  Widget _buildLedgerTab() {
    final debtors = _analyticsData['topDebtors'] as List<Map<String, dynamic>>? ?? [];
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Outstanding Khata Balances', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.dangerColor)),
        const SizedBox(height: 8),
        if (debtors.isEmpty) const Text('No outstanding balances.', style: TextStyle(color: AppTheme.subtleTextColor)),
        ...debtors.map((row) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: AppTheme.backgroundColor, child: Icon(Icons.account_balance, color: AppTheme.dangerColor)),
            title: Text(row['name']),
            subtitle: Text(row['phone']),
            trailing: Text('₹${(row['total_due'] as double).toStringAsFixed(0)} Due', style: const TextStyle(color: AppTheme.dangerColor, fontWeight: FontWeight.bold, fontSize: 16)),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Advanced Analytics'),
          bottom: const TabBar(
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.subtleTextColor,
            tabs: [
              Tab(text: 'Overview', icon: Icon(Icons.bar_chart)),
              Tab(text: 'Customers', icon: Icon(Icons.people)),
              Tab(text: 'Ledger', icon: Icon(Icons.account_balance_wallet)),
            ],
          ),
        ),
        body: Column(
          children: [
            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildFilterChip(0, 'Last 7 Days'),
                  const SizedBox(width: 8),
                  _buildFilterChip(1, 'Last 30 Days'),
                  const SizedBox(width: 8),
                  _buildFilterChip(2, 'Last 6 Months'),
                  const SizedBox(width: 8),
                  _buildFilterChip(3, 'All Time'),
                ],
              ),
            ),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : TabBarView(
                      children: [
                        _buildOverviewTab(),
                        _buildCustomersTab(),
                        _buildLedgerTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
