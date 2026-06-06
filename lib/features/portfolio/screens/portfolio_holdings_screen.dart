import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/portfolio_provider.dart';
import '../../../core/theme/styles.dart';

class PortfolioHoldingsScreen extends ConsumerWidget {
  const PortfolioHoldingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(holdingsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);
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

                final isPositive = holding.profitLoss >= 0;
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(holding.symbol, style: Theme.of(context).textTheme.titleLarge),
                                Text(holding.companyName, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(currencyFormat.format(holding.currentValue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                Text(
                                  '${isPositive ? '+' : ''}${holding.profitLossPercent.toStringAsFixed(2)}%',
                                  style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _InfoRow('Quantity', '${holding.quantity} shares'),
                        _InfoRow('Avg Price', currencyFormat.format(holding.averagePrice)),
                        _InfoRow('Current Price', currencyFormat.format(holding.currentPrice)),
                        _InfoRow('Total Investment', currencyFormat.format(holding.totalInvestment)),
                        _InfoRow(
                          'Profit/Loss',
                          '${isPositive ? '+' : ''}${currencyFormat.format(holding.profitLoss)}',
                          valueColor: isPositive ? Colors.green : Colors.red,
                        ),
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
