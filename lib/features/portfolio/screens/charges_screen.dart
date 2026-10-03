import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/portfolio_provider.dart';
import '../../../shared/models/portfolio.dart';

class ChargesScreen extends ConsumerWidget {
  const ChargesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charges = ref.watch(chargesProvider);
    final total = ref.watch(portfolioTotalChargesProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Charges'),
        actions: [
          IconButton(
            tooltip: 'Add charge',
            icon: const Icon(Icons.add),
            onPressed: () => _showAddChargeDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Charges', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 6),
                        Text(currencyFormat.format(total), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Icon(Icons.receipt_long_rounded, size: 36, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: charges.isEmpty
                ? Center(child: Text('No charges yet', style: Theme.of(context).textTheme.titleMedium))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: charges.length,
                    itemBuilder: (ctx, i) {
                      final c = charges[charges.length - 1 - i]; // show newest first
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.remove, color: Colors.white)),
                          title: Text(currencyFormat.format(c.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          subtitle: c.note != null ? Text(c.note!) : null,
                          trailing: Text(DateFormat.yMMMd().format(c.date)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddChargeDialog(BuildContext context, WidgetRef ref) {
    final _formKey = GlobalKey<FormState>();
    final _amountCtrl = TextEditingController();
    final _noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Charge'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount', prefixText: 'Rs '),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter amount';
                    final d = double.tryParse(v);
                    if (d == null || d <= 0) return 'Enter valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(labelText: 'Note (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (!(_formKey.currentState?.validate() ?? false)) return;
                final amt = double.parse(_amountCtrl.text);
                final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

                // Deduct from portfolio cash if available
                final currentCash = ref.read(portfolioCashProvider);
                if (currentCash < amt) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient portfolio cash to add charge')));
                  return;
                }

                // withdraw and record charge
                ref.read(portfolioCashActionsProvider).withdraw(amt);
                final c = Charge(amount: amt, note: note, date: DateTime.now());
                ref.read(chargesProvider.notifier).addCharge(c);

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Charge recorded')));
              },
              child: const Text('Add Charge'),
            ),
          ],
        );
      },
    );
  }
}
