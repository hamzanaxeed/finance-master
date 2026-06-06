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
  int? _selectedMonthIndex; // selected month pill index

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
                  Text(
                    _selectedMonthIndex == null
                        ? 'Select a month to view transactions'
                        : 'Transactions for ${DateFormat.yMMMM().format(DateTime(now.year, now.month - (11 - _selectedMonthIndex!), 1))}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  // Horizontal month selector
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: months.length,
                      itemBuilder: (context, idx) {
                        final m = months[idx];
                        final selected = _selectedMonthIndex == idx;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => setState(() => _selectedMonthIndex = idx),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor),
                                boxShadow: selected
                                    ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withAlpha((0.16 * 255).round()), blurRadius: 6, offset: const Offset(0, 2))]
                                    : null,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    m.month,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    width: selected ? 24 : 0,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
    ),
                          );

                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Inline transaction list for the selected month
                  Builder(builder: (context) {
                    if (_selectedMonthIndex == null) return const SizedBox.shrink();
                    final selectedMonthDate = DateTime(now.year, now.month - (11 - _selectedMonthIndex!), 1);
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
