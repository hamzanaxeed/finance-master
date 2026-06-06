import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/transaction_provider.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/portfolio_provider.dart';
import '../../../shared/models/transaction.dart';


class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String? _selectedAccountId; // null = all accounts
  DateTime? _selectedMonth; // currently selected month (first day)

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // default to current month (first day)
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final transactions = ref.watch(transactionProvider);
    final accounts = ref.watch(accountProvider);
    final holdings = ref.watch(holdingsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    final now = DateTime.now();

    // Filter transactions by selected account for the chart views
    final filteredForChart = _selectedAccountId == null
        ? transactions
        : transactions.where((t) => t.accountId == _selectedAccountId).toList();

    // Monthly income/expense for last 12 months (oldest -> newest)
    final List<_MonthData> months = List.generate(12, (i) {
      final m = DateTime(now.year, now.month - (11 - i), 1);
      final label = DateFormat.MMM().format(m);
      final income = filteredForChart
          .where((t) => t.type == TransactionType.income && t.date.year == m.year && t.date.month == m.month)
          .fold(0.0, (p, e) => p + e.amount);
      final expense = filteredForChart
          .where((t) => t.type == TransactionType.expense && t.date.year == m.year && t.date.month == m.month)
          .fold(0.0, (p, e) => p + e.amount);
      return _MonthData(month: label, income: income, expense: expense);
    });

    // Yearly income totals (last 5 years)
    final years = <int>{};
    for (final t in transactions) years.add(t.date.year);
    final sortedYears = years.toList()..sort();
    final List<_YearData> yearData = sortedYears.map((y) {
      final income = transactions.where((t) => t.type == TransactionType.income && t.date.year == y).fold(0.0, (p, e) => p + e.amount);
      return _YearData(year: y.toString(), income: income);
    }).toList();

    // Top categories (expense)
    final Map<String, double> categoryMap = {};
    for (final t in transactions.where((t) => t.type == TransactionType.expense)) {
      categoryMap[t.category] = (categoryMap[t.category] ?? 0) + t.amount;
    }
    final topCategories = categoryMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topCatList = topCategories.take(6).map((e) => _CategoryData(e.key, e.value)).toList();

    final totalIncomeThisYear = transactions.where((t) => t.type == TransactionType.income && t.date.year == now.year).fold(0.0, (p, e) => p + e.amount);
    final totalExpenseThisYear = transactions.where((t) => t.type == TransactionType.expense && t.date.year == now.year).fold(0.0, (p, e) => p + e.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Assets', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 6),
                        Text(currencyFormat.format(ref.watch(totalAssetsProvider)), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Holdings: ${holdings.length}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Income (YTD)', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 6),
                        Text(currencyFormat.format(totalIncomeThisYear), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.green)),
                        const SizedBox(height: 6),
                        Text('Expense (YTD): ${currencyFormat.format(totalExpenseThisYear)}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Account selector for chart-specific views
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Text('Account:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _selectedAccountId,
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All Accounts')),
                        ...accounts.map((a) => DropdownMenuItem<String?>(value: a.id, child: Text(a.name))).toList()
                      ],
                      onChanged: (v) => setState(() => _selectedAccountId = v),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Monthly Income vs Expense
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly Income vs Expense', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: SfCartesianChart(
                      legend: Legend(isVisible: true),
                      primaryXAxis: CategoryAxis(),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series: <CartesianSeries>[
                        ColumnSeries<_MonthData, String>(
                          name: 'Income',
                          dataSource: months,
                          xValueMapper: (d, i) => d.month,
                          yValueMapper: (d, i) => d.income,
                          color: Colors.green,
                        ),
                        ColumnSeries<_MonthData, String>(
                          name: 'Expense',
                          dataSource: months,
                          xValueMapper: (d, i) => d.month,
                          yValueMapper: (d, i) => d.expense,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Yearly Income trend
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yearly Income Trend', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: SfCartesianChart(
                      primaryXAxis: CategoryAxis(),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series: <CartesianSeries>[
                        LineSeries<_YearData, String>(
                          dataSource: yearData,
                          xValueMapper: (d, i) => d.year,
                          yValueMapper: (d, i) => d.income,
                          color: Theme.of(context).colorScheme.primary,
                          markerSettings: const MarkerSettings(isVisible: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Top expense categories
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Top Expense Categories', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: SfCircularChart(
                      legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
                      series: <CircularSeries>[
                        DoughnutSeries<_CategoryData, String>(
                          dataSource: topCatList,
                          xValueMapper: (d, i) => d.category,
                          yValueMapper: (d, i) => d.amount,
                          dataLabelSettings: const DataLabelSettings(isVisible: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Month selector and inline transaction list (at end of screen)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header shows selected month (or prompt)
                  Text(
                    _selectedMonth == null
                        ? 'Select a month to view transactions'
                        : 'Transactions for ${DateFormat.yMMMM().format(_selectedMonth!)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  // Modern month selector widget (chevrons + picker)
                  _monthSelector(),
                  const SizedBox(height: 12),

                  // Inline transaction list for the selected month
                  Builder(builder: (context) {
                    if (_selectedMonth == null) return const SizedBox.shrink();
                    final selectedMonthDate = DateTime(_selectedMonth!.year, _selectedMonth!.month, 1);
                    final txnsForSelectedMonth = filteredForChart.where((t) => t.date.year == selectedMonthDate.year && t.date.month == selectedMonthDate.month).toList();

                    if (txnsForSelectedMonth.isEmpty) {
                      return Center(child: Text('No transactions for ${DateFormat.yMMMM().format(selectedMonthDate)}'));
                    }

                    // Use a shrink-wrapped ListView so it sizes to its children and scrolls with the page
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: txnsForSelectedMonth.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final t = txnsForSelectedMonth[index];
                        final color = _getTransactionColor(t.type);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withAlpha((0.1 * 255).round()),
                            child: Icon(_getTransactionIcon(t.type), color: color),
                          ),
                          title: Text(t.category),
                          subtitle: Text(DateFormat.yMMMd().format(t.date)),
                          trailing: Text(
                            '${t.type == TransactionType.income ? '+' : '-'}${currencyFormat.format(t.amount)}',
                            style: TextStyle(color: color, fontWeight: FontWeight.bold),
                          ),
                          onTap: () => context.push('/transactions/${t.id}'),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
    }
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.arrow_downward;
      case TransactionType.expense:
        return Icons.arrow_upward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  // Month selector widget (chevrons + central picker)
  Widget _monthSelector() {
    final selected = _selectedMonth ?? DateTime.now();
    // compute whether the right (forward) chevron should be enabled
    final selectedMonthStart = DateTime(selected.year, selected.month, 1);
    final currentMonthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final canMoveNext = selectedMonthStart.isBefore(currentMonthStart);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),

          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _showMonthPicker,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(selected),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.keyboard_arrow_down, size: 20),
                  ],
                ),
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.chevron_right),
            // disable moving forward beyond the current month
            onPressed: canMoveNext ? () => _changeMonth(1) : null,
          ),
        ],
      ),
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      final current = _selectedMonth ?? DateTime.now();
      final tentative = DateTime(current.year, current.month + delta, 1);
      final currentMonthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
      // Prevent selecting a month after the current month. If the tentative
      // month is in the future, clamp to the current month instead.
      if (tentative.isAfter(currentMonthStart)) {
        _selectedMonth = currentMonthStart;
      } else {
        _selectedMonth = tentative;
      }
    });
  }

  Future<void> _showMonthPicker() async {
    final now = DateTime.now();

    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Month'),
          children: List.generate(24, (index) {
            final month = DateTime(now.year, now.month - index, 1);

            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, month);
              },
              child: Text(DateFormat('MMMM yyyy').format(month)),
            );
          }),
        );
      },
    );

    if (result != null) {
      setState(() => _selectedMonth = DateTime(result.year, result.month, 1));
    }
  }
}

class _MonthData {
  final String month;
  final double income;
  final double expense;
  _MonthData({required this.month, required this.income, required this.expense});
}

class _YearData {
  final String year;
  final double income;
  _YearData({required this.year, required this.income});
}

class _CategoryData {
  final String category;
  final double amount;
  _CategoryData(this.category, this.amount);
}
