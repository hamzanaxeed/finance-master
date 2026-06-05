import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/portfolio_provider.dart';

class DividendsScreen extends ConsumerWidget {
  const DividendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dividends = ref.watch(dividendProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);

    final totalDividends = dividends.fold(0.0, (sum, d) => sum + d.totalReceived);

    return Scaffold(
      appBar: AppBar(title: const Text('Dividends')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.purple, Colors.deepPurple]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Dividends', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                const SizedBox(height: 8),
                Text(currencyFormat.format(totalDividends), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Year to Date', style: TextStyle(color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
          Expanded(
            child: dividends.isEmpty
                ? const Center(child: Text('No dividends'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: dividends.length,
                    itemBuilder: (context, index) {
                      final dividend = dividends[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.monetization_on, color: Colors.white),
                          ),
                          title: Text(dividend.symbol),
                          subtitle: Text('Rs ${dividend.amountPerShare.toStringAsFixed(2)} per share\n${DateFormat.yMMMd().format(dividend.date)}'),
                          trailing: Text(currencyFormat.format(dividend.totalReceived), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
