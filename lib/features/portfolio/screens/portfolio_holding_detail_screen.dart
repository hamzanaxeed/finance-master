import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

    final isPositive = holding.profitLoss >= 0;

    return Scaffold(
      appBar: AppBar(title: Text(holding.symbol)),
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
                        Text(currencyFormat.format(holding.currentValue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const Divider(height: 24),
                    _InfoRow('Avg Price', currencyFormat.format(holding.averagePrice)),
                    _InfoRow('Current Price', currencyFormat.format(holding.currentPrice)),
                    _InfoRow('Total Investment', currencyFormat.format(holding.totalInvestment)),
                    _InfoRow('Current Value', currencyFormat.format(holding.currentValue)),
                    _InfoRow('Profit/Loss', '${isPositive ? '+' : ''}${currencyFormat.format(holding.profitLoss)}', valueColor: isPositive ? Colors.green : Colors.red),
                    _InfoRow('Profit/Loss %', '${isPositive ? '+' : ''}${holding.profitLossPercent.toStringAsFixed(2)}%', valueColor: isPositive ? Colors.green : Colors.red),
                  ],
                ),
              ),
            ),
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
