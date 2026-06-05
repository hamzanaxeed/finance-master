import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/portfolio_provider.dart';
import 'package:wealthtracker/shared/models/portfolio.dart' as pmodel;

class PortfolioTransactionsScreen extends ConsumerWidget {
  const PortfolioTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(stockTransactionProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Transactions')),
      body: transactions.isEmpty
          ? const Center(child: Text('No transactions'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final txn = transactions[index];
                final isBuy = txn.type == pmodel.StockTransactionType.buy;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isBuy ? Colors.green.shade100 : Colors.red.shade100,
                      child: Icon(isBuy ? Icons.add : Icons.remove, color: isBuy ? Colors.green : Colors.red),
                    ),
                    title: Text('${isBuy ? 'BUY' : 'SELL'} ${txn.symbol}'),
                    subtitle: Text('${txn.quantity} shares @ ${currencyFormat.format(txn.price)}\n${DateFormat.yMMMd().format(txn.date)}'),
                    trailing: Text(
                      currencyFormat.format(txn.total),
                      style: TextStyle(color: isBuy ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
