import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/portfolio_provider.dart';
import '../../../providers/stock_providers.dart';
import '../../../core/theme/styles.dart';

class PortfolioHoldingsScreen extends ConsumerWidget {
  const PortfolioHoldingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(holdingsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 1);
    // height of the footer spacer so the FAB doesn't cover the last item
    final footerHeight = AppSpacing.footerHeight(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Holdings')),
      body: holdings.isEmpty
          ? const Center(child: Text('No holdings'))
          : ListView.builder(
              // keep normal internal padding and append a footer spacer as the final item
              padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.page, AppSpacing.page, AppSpacing.page),
              itemCount: holdings.length + 1,
              itemBuilder: (context, index) {
                if (index == holdings.length) return SizedBox(height: footerHeight);
                final holding = holdings[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.gap),
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.card),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Make left side flexible so long company names don't push the right side off-screen
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(holding.symbol, style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text(holding.companyName, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Live price and computed values
                            Consumer(builder: (ctx, ref, _) {
                              final asyncQuote = ref.watch(stockPriceProvider(holding.symbol));
                              return asyncQuote.when(
                                data: (q) {
                                  final currentPrice = q.price;
                                  final currentValue = currentPrice * holding.quantity;
                                  final invested = holding.totalInvestment;
                                  final pnl = currentValue - invested;
                                  final pnlPct = invested == 0 ? 0.0 : (pnl / invested) * 100;
                                  final isPositive = pnl >= 0;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(currencyFormat.format(currentValue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                      Text(
                                        '${isPositive ? '+' : ''}${pnlPct.toStringAsFixed(1)}%',
                                        style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  );
                                },
                                loading: () {
                                  // show cached/stored values while loading
                                  final isPositive = holding.profitLoss >= 0;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(currencyFormat.format(holding.currentValue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                      Text(
                                        '${isPositive ? '+' : ''}${holding.profitLossPercent.toStringAsFixed(1)}%',
                                        style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  );
                                },
                                error: (e, st) {
                                  final isPositive = holding.profitLoss >= 0;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(currencyFormat.format(holding.currentValue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                      Text(
                                        '${isPositive ? '+' : ''}${holding.profitLossPercent.toStringAsFixed(1)}%',
                                        style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }),
                          ],
                        ),
                        const Divider(height: 24),
                        _InfoRow('Quantity', '${holding.quantity} shares'),
                        _InfoRow('Avg Price', currencyFormat.format(holding.averagePrice)),
                        // Current Price row uses live quote when available
                        Consumer(builder: (ctx, ref, _) {
                          final asyncQuote = ref.watch(stockPriceProvider(holding.symbol));
                          return asyncQuote.when(
                            data: (q) => _InfoRow('Current Price', currencyFormat.format(q.price)),
                            loading: () => _InfoRow('Current Price', currencyFormat.format(holding.currentPrice)),
                            error: (e, st) => _InfoRow('Current Price', currencyFormat.format(holding.currentPrice)),
                          );
                        }),
                        _InfoRow('Total Investment', currencyFormat.format(holding.totalInvestment)),
                        Consumer(builder: (ctx, ref, _) {
                          final asyncQuote = ref.watch(stockPriceProvider(holding.symbol));
                          return asyncQuote.when(
                            data: (q) {
                              final currentValue = q.price * holding.quantity;
                              final invested = holding.totalInvestment;
                              final pnl = currentValue - invested;
                              final isPositive = pnl >= 0;
                              return _InfoRow('Profit/Loss', '${isPositive ? '+' : ''}${currencyFormat.format(pnl)}', valueColor: isPositive ? Colors.green : Colors.red);
                            },
                            loading: () {
                              final isPositive = holding.profitLoss >= 0;
                              return _InfoRow('Profit/Loss', '${isPositive ? '+' : ''}${currencyFormat.format(holding.profitLoss)}', valueColor: isPositive ? Colors.green : Colors.red);
                            },
                            error: (e, st) {
                              final isPositive = holding.profitLoss >= 0;
                              return _InfoRow('Profit/Loss', '${isPositive ? '+' : ''}${currencyFormat.format(holding.profitLoss)}', valueColor: isPositive ? Colors.green : Colors.red);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
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
