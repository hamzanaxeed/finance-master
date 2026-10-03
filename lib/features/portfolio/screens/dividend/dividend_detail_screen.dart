import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/portfolio.dart';
import '../../../../shared/providers/portfolio_provider.dart';
import '../../../../shared/providers/transaction_provider.dart';

class DividendDetailScreen extends ConsumerWidget {
  final Dividend dividend;
  const DividendDetailScreen({super.key, required this.dividend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);
    // compute number of shares from totalReceived / amountPerShare (guard divide-by-zero)
    final shares = dividend.amountPerShare > 0 ? dividend.totalReceived / dividend.amountPerShare : 0.0;
    final sharesFormat = NumberFormat('#,##0.####');
    // Try to resolve linked transaction to display notes (but do not show transaction ID)
    final linkedTxn = dividend.transactionId != null ? ref.read(transactionProvider.notifier).getTransactionById(dividend.transactionId!) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('${dividend.companyName}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _handleDeleteAction(context, ref, dividend, v),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
              const PopupMenuItem(value: 'reverse', child: Text('Delete & Reverse Cash')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.business_outlined),
                  title: Text('${dividend.companyName} (${dividend.symbol})', style: Theme.of(context).textTheme.titleLarge),
                  subtitle: Text('Recorded on ${DateFormat.yMMMd().format(dividend.date)}'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Amount per share:', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(width: 8),
                    Text('Rs ${dividend.amountPerShare.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Shares:', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(width: 8),
                    Text(sharesFormat.format(shares), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Total received:', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(width: 8),
                    Text(currencyFormat.format(dividend.totalReceived), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 12),
                // Show notes from linked transaction if available; otherwise don't show a notes block
                if (linkedTxn != null && (linkedTxn.notes != null && linkedTxn.notes!.trim().isNotEmpty)) ...[
                  Text('Notes', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Text(linkedTxn.notes!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDeleteAction(BuildContext context, WidgetRef ref, Dividend dividend, String action) async {
    if (action != 'delete' && action != 'reverse') return;

    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Delete Dividend'),
          content: const Text('Are you sure you want to delete this dividend?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'confirm'), child: const Text('Delete')),
          ],
        );
      },
    );

    if (result != 'confirm') return;

    if (action == 'delete') {
      ref.read(dividendProvider.notifier).deleteDividend(dividend.id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Dividend record deleted')));
      Navigator.of(context).pop();
      return;
    }

    final amount = dividend.totalReceived;
    final currentCashBalance = ref.read(portfolioCashProvider);
    if (currentCashBalance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Insufficient cash available to reverse payout')));
      return;
    }

    await ref.read(portfolioTransferProvider.notifier).withdrawFromPortfolio(
      amount,
      note: 'Reversal for deleted dividend: ${dividend.companyName}',
    );

    if (dividend.transactionId != null) {
      ref.read(transactionProvider.notifier).deleteTransaction(dividend.transactionId!);
    }

    ref.read(dividendProvider.notifier).deleteDividend(dividend.id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔄 Payout deleted and balance reversed')));
    Navigator.of(context).pop();
  }
}
