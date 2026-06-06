import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/portfolio_provider.dart';
import 'package:wealthtracker/shared/models/portfolio.dart' as pmodel;
import '../../../shared/models/portfolio.dart' as models;

class PortfolioTransactionsScreen extends ConsumerWidget {
  const PortfolioTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockTransactions = ref.watch(stockTransactionProvider);
    final dividends = ref.watch(dividendProvider);

    // Merge stock transactions and dividends into a single list sorted by date desc
    final List<_TimelineItem> combined = [];
    for (final s in stockTransactions) {
      combined.add(_TimelineItem(kind: 'stock', date: s.date, data: s));
    }
    for (final d in dividends) {
      combined.add(_TimelineItem(kind: 'dividend', date: d.date, data: d));
    }
    combined.sort((a, b) => b.date.compareTo(a.date));

    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Transactions')),
      body: combined.isEmpty
          ? const Center(child: Text('No transactions'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: combined.length,
              itemBuilder: (context, index) {
                final item = combined[index];
                if (item.kind == 'stock') {
                  final txn = item.data as pmodel.StockTransaction;
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
                } else {
                  final d = item.data as models.Dividend;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.monetization_on, color: Colors.white),
                      ),
                      title: Text('DIVIDEND ${d.symbol}'),
                      subtitle: Text('${d.companyName} — ${d.amountPerShare.toStringAsFixed(2)} per share\n${DateFormat.yMMMd().format(d.date)}'),
                      trailing: Text(currencyFormat.format(d.totalReceived), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      isThreeLine: true,
                    ),
                  );
                }
              },
            ),
    );
  }
}

class _TimelineItem {
  final String kind; // 'stock' or 'dividend'
  final DateTime date;
  final Object data;
  _TimelineItem({required this.kind, required this.date, required this.data});
}
