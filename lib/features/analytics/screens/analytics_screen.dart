import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/account_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAssets = ref.watch(totalAssetsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    // Loans removed — net worth equals total assets
    final netWorth = totalAssets;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics Center')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            
            children: [
              Expanded(
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Net Worth', style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(netWorth),
                          style: TextStyle(color: Colors.blue.shade900, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.trending_up, size: 12, color: Colors.blue.shade700),
                            const SizedBox(width: 4),
                            Text('+5.2%', style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Assets', style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(totalAssets),
                          style: TextStyle(color: Colors.green.shade900, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.trending_up, size: 12, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text('+3.8%', style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Key Metrics', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Savings Rate', style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 4),
                            const Text('32.5%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Debt-to-Income', style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 4),
                            const Text('18.2%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Investment Return', style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 4),
                            const Text('+12.4%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Emergency Fund', style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 4),
                            const Text('6.2 mo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
