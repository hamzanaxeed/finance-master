import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/portfolio_provider.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(holdingsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);

    final totalInvestment = holdings.fold(0.0, (sum, h) => sum + h.totalInvestment);
    final totalValue = holdings.fold(0.0, (sum, h) => sum + h.currentValue);
    final totalProfitLoss = totalValue - totalInvestment;
    final profitLossPercent = totalInvestment > 0 ? (totalProfitLoss / totalInvestment) * 100 : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/portfolio/add-transaction'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.green, Colors.teal]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Portfolio Value', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                const SizedBox(height: 8),
                Text(currencyFormat.format(totalValue), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(totalProfitLoss >= 0 ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${totalProfitLoss >= 0 ? '+' : ''}${currencyFormat.format(totalProfitLoss)} (${totalProfitLoss >= 0 ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%)',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Icon(Icons.attach_money, size: 20),
                          const SizedBox(height: 4),
                          const Text('Invested', style: TextStyle(fontSize: 12)),
                          Text(currencyFormat.format(totalInvestment), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Icon(Icons.show_chart, size: 20),
                          const SizedBox(height: 4),
                          const Text('Holdings', style: TextStyle(fontSize: 12)),
                          Text('${holdings.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: holdings.isEmpty
                ? const Center(child: Text('No holdings'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: holdings.length,
                    itemBuilder: (context, index) {
                      final holding = holdings[index];
                      final isPositive = holding.profitLoss >= 0;
                      return InkWell(
                        onTap: () => context.push('/portfolio/holdings/${holding.symbol}'),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(holding.symbol, style: Theme.of(context).textTheme.titleMedium),
                                    Text(currencyFormat.format(holding.currentValue), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${holding.quantity} shares @ Rs ${holding.averagePrice.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall),
                                    Text(
                                      '${isPositive ? '+' : ''}${holding.profitLossPercent.toStringAsFixed(2)}%',
                                      style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],

                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/portfolio/transactions'),
                icon: const Icon(Icons.receipt),
                label: const Text('Transactions'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
