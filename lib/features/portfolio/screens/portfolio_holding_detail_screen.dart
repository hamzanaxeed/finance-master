import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/providers/portfolio_provider.dart';
import '../../../shared/models/portfolio.dart';

class HoldingDetailScreen extends ConsumerWidget {
  final String symbol;
  const HoldingDetailScreen({super.key, required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(holdingsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);

    StockHolding? holding;
    try {
      holding = holdings.firstWhere((h) => h.symbol == symbol);
    } catch (_) {
      holding = null;
    }

    if (holding == null) {
      return Scaffold(
        appBar: AppBar(title: Text(symbol)),
        body: const Center(child: Text('Holding not found')),
      );
    }

    final transactions = ref.watch(stockTransactionProvider).where((t) => t.symbol == symbol).toList();
    final priceHistory = ref.watch(priceHistoryProvider)[symbol] ?? [];

    DateTime? firstTxnDate;
    if (transactions.isNotEmpty) {
      firstTxnDate = transactions.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
    }

    final preTxnHistory = firstTxnDate == null ? priceHistory : priceHistory.where((p) => p.time.isBefore(firstTxnDate!)).toList();

    final latestPrice = priceHistory.isNotEmpty ? priceHistory.last.price : holding.currentPrice;
    final displayCurrentValue = holding.quantity * latestPrice;
    final displayProfitLoss = displayCurrentValue - holding.totalInvestment;
    final displayProfitLossPercent = holding.totalInvestment > 0 ? (displayProfitLoss / holding.totalInvestment) * 100 : 0;
    final isPositive = displayProfitLoss >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(holding.symbol),
        actions: [
          IconButton(
            tooltip: 'Edit share',
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final controller = TextEditingController(text: holding!.companyName);
              final res = await showDialog<String?>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Edit Share'),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(labelText: 'Company name'),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
                    ],
                  );
                },
              );
              if (res != null && res.isNotEmpty) {
                ref.read(holdingMetaProvider.notifier).updateCompanyName(symbol, res);
              }
            },
          ),
          IconButton(
            tooltip: 'Update current price',
            icon: const Icon(Icons.currency_rupee),
            onPressed: () async {
              final controller = TextEditingController();
              final res = await showDialog<double?>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Update Current Price'),
                    content: TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Price'),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () {
                          final v = double.tryParse(controller.text.trim());
                          Navigator.pop(context, v);
                        },
                        child: const Text('Update'),
                      ),
                    ],
                  );
                },
              );
              if (res != null) {
                final pp = PricePoint(time: DateTime.now(), price: res);
                ref.read(priceHistoryProvider.notifier).addPricePoint(symbol, pp);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(holding.companyName, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${holding.quantity} shares', style: Theme.of(context).textTheme.bodyMedium),
                        Text(currencyFormat.format(displayCurrentValue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const Divider(height: 24),
                    _InfoRow('Avg Price', currencyFormat.format(holding.averagePrice)),
                    _InfoRow('Current Price', currencyFormat.format(latestPrice)),
                    _InfoRow('Total Investment', currencyFormat.format(holding.totalInvestment)),
                    _InfoRow('Current Value', currencyFormat.format(displayCurrentValue)),
                    _InfoRow('Profit/Loss', '${displayProfitLoss >= 0 ? '+' : ''}${currencyFormat.format(displayProfitLoss)}', valueColor: isPositive ? Colors.green : Colors.red),
                    _InfoRow('Profit/Loss %', '${displayProfitLossPercent >= 0 ? '+' : ''}${displayProfitLossPercent.toStringAsFixed(2)}%', valueColor: isPositive ? Colors.green : Colors.red),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Price charts
            Text('Price history', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            priceHistory.isEmpty
                ? const Text('No price history available')
                : SizedBox(
                    height: 200,
                    child: _buildChart(context, priceHistory),
                  ),
            const SizedBox(height: 12),
            Text('Pre-transaction chart', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            preTxnHistory.isEmpty
                ? const Text('No pre-transaction price data')
                : SizedBox(height: 160, child: _buildChart(context, preTxnHistory)),
            const SizedBox(height: 16),
            Text('Transactions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            transactions.isEmpty
                ? const Text('No transactions for this holding')
                : Column(
                    children: transactions.reversed.map((t) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('${t.type.name.toUpperCase()} ${t.quantity} @ Rs ${t.price.toStringAsFixed(2)}'),
                          subtitle: Text(DateFormat.yMMMd().format(t.date)),
                          trailing: Text('Rs ${t.total.toStringAsFixed(2)}'),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<PricePoint> points) {
    if (points.isEmpty) return const SizedBox.shrink();
    final sorted = List<PricePoint>.from(points)..sort((a, b) => a.time.compareTo(b.time));
    final spots = sorted.map((p) => FlSpot(p.time.millisecondsSinceEpoch.toDouble(), p.price)).toList();
    final minX = spots.first.x;
    final maxX = spots.last.x;
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);


    // Ensure non-zero interval for SideTitles
    double interval = (maxX - minX) / 4.0;
    if (interval == 0 || interval.isNaN || interval.isInfinite) {
      interval = 1.0; // fallback when all points share same timestamp
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, interval: interval, getTitlesWidget: (value, meta) {
              final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              final text = DateFormat.Md().format(dt);
              return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: const TextStyle(fontSize: 10)));
            }),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
        ),
        minX: minX,
        maxX: maxX,
        minY: minY * 0.95,
        maxY: maxY * 1.05,
        lineBarsData: [
          LineChartBarData(spots: spots, isCurved: true, dotData: FlDotData(show: false), color: Theme.of(context).primaryColor, barWidth: 2),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: valueColor)),
        ],
      ),
    );
  }
}
