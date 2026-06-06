import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../shared/providers/transaction_provider.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/portfolio_provider.dart';
import '../../../core/theme/styles.dart';
import '../../../shared/models/transaction.dart';


class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);
    final holdings = ref.watch(holdingsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    final now = DateTime.now();

    // Monthly income/expense for last 12 months (oldest -> newest)
    final List<_MonthData> months = List.generate(12, (i) {
      final m = DateTime(now.year, now.month - (11 - i), 1);
      final label = DateFormat.MMM().format(m);
      final income = transactions
          .where((t) => t.type == TransactionType.income && t.date.year == m.year && t.date.month == m.month)
          .fold(0.0, (p, e) => p + e.amount);
      final expense = transactions
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
          SizedBox(height: 8),
        ],
      ),
    );
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
