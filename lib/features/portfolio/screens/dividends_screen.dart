import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/portfolio_provider.dart';
import '../../../shared/providers/transaction_provider.dart';
import 'dividend/add_dividend_screen.dart';

class DividendsScreen extends ConsumerWidget {
  const DividendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dividends = ref.watch(dividendProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);

    final totalDividends = dividends.fold(0.0, (sum, d) => sum + d.totalReceived);

    return Scaffold(
      appBar: AppBar(title: const Text('Dividends'), actions: [
        PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'add') {
              await Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const AddDividendScreen()));
            }
          },
          itemBuilder: (ctx) => [const PopupMenuItem(value: 'add', child: Text('Add dividend'))],
        )
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const AddDividendScreen())),
        tooltip: 'Add dividend',
        child: const Icon(Icons.add),
      ),
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
                Text('Total Dividends', style: TextStyle(color: Colors.white.withAlpha((0.9 * 255).round()), fontSize: 14)),
                const SizedBox(height: 8),
                Text(currencyFormat.format(totalDividends), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Year to Date', style: TextStyle(color: Colors.white.withAlpha((0.9 * 255).round()))),
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
                          title: Text('${dividend.companyName} (${dividend.symbol})'),
                          subtitle: Text('Rs ${dividend.amountPerShare.toStringAsFixed(2)} per share\n${DateFormat.yMMMd().format(dividend.date)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(currencyFormat.format(dividend.totalReceived), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v != 'delete') return;

                                  final res = await showDialog<String?>(
                                    context: context,
                                    builder: (ctx) {
                                      return AlertDialog(
                                        title: const Text('Delete dividend'),
                                        content: const Text('Do you want to delete this dividend? You can also reverse the cash and remove the linked transaction.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancel')),
                                          TextButton(onPressed: () => Navigator.pop(ctx, 'delete'), child: const Text('Delete only')),
                                          ElevatedButton(onPressed: () => Navigator.pop(ctx, 'reverse'), child: const Text('Delete and reverse cash')),
                                        ],
                                      );
                                    },
                                  );

                                  if (res == null || res == 'cancel') return;

                                  if (res == 'delete') {
                                    ref.read(dividendProvider.notifier).deleteDividend(dividend.id);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dividend deleted')));
                                    return;
                                  }

                                  // reverse cash and delete linked transaction if possible
                                  final amount = dividend.totalReceived;
                                  final cash = ref.read(portfolioCashProvider);
                                  if (cash < amount) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient portfolio cash to reverse')));
                                    return;
                                  }

                                  // withdraw from portfolio (records a PortfolioTransfer)
                                  await ref.read(portfolioTransferProvider.notifier).withdrawFromPortfolio(amount, note: 'Reversal for deleted dividend');

                                  // delete linked transaction if exists
                                  if (dividend.transactionId != null) {
                                    ref.read(transactionProvider.notifier).deleteTransaction(dividend.transactionId!);
                                  }

                                  // delete dividend record
                                  ref.read(dividendProvider.notifier).deleteDividend(dividend.id);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dividend deleted and reversed')));
                                },
                                itemBuilder: (ctx) => [const PopupMenuItem(value: 'delete', child: Text('Delete'))],
                              )
                            ],
                          ),
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
