import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/transaction_provider.dart';
import '../../../shared/models/transaction.dart';

class ActivityTimelineScreen extends ConsumerWidget {
  const ActivityTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Timeline')),
      body: transactions.isEmpty
          ? const Center(child: Text('No activities'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final txn = transactions[index];
                final isIncome = txn.type == TransactionType.income;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                      child: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(txn.category),
                    subtitle: Text('${txn.type.name.toUpperCase()} • ${DateFormat.yMMMd().format(txn.date)}'),
                    trailing: Text(
                      '${isIncome ? '+' : '-'}${currencyFormat.format(txn.amount)}',
                      style: TextStyle(
                        color: isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
