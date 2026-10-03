import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/stock_providers.dart';

class StockHoldingCard extends ConsumerWidget {
  final String symbol;
  final double quantity;
  final double averageBuyPrice;

  const StockHoldingCard({super.key, required this.symbol, required this.quantity, required this.averageBuyPrice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncQuote = ref.watch(stockPriceProvider(symbol));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(child: Text(symbol.substring(0, symbol.length.clamp(1,3)).toUpperCase())),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(symbol, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Qty: $quantity • Avg: ${averageBuyPrice.toStringAsFixed(1)}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            asyncQuote.when(
              data: (q) {
                final current = q.price;
                final currentValue = current * quantity;
                final invested = averageBuyPrice * quantity;
                final pnl = currentValue - invested;
                final pnlPct = invested == 0 ? 0.0 : (pnl / invested) * 100;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${current.toStringAsFixed(1)}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('${currentValue.toStringAsFixed(1)}', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text('${pnl >= 0 ? '+' : '-'}${pnl.abs().toStringAsFixed(1)} (${pnlPct.toStringAsFixed(1)}%)', style: TextStyle(color: pnl >= 0 ? Colors.green : Colors.red)),
                  ],
                );
              },
              loading: () => const SizedBox(width: 80, height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (e, st) => Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('N/A'),
                  const SizedBox(height: 4),
                  Text('Error', style: TextStyle(color: Colors.red.shade200)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
