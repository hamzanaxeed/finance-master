import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/portfolio_provider.dart';
import '../../../shared/providers/account_provider.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(holdingsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);

    // Cash currently available in portfolio
    final cashAvailable = ref.watch(portfolioCashProvider);
    // Current market value of holdings
    final holdingsValue = ref.watch(portfolioHoldingsValueProvider);
    // Total portfolio value = cash + holdings current value
    final totalValue = ref.watch(portfolioTotalValueProvider);

    // Invested = net external transfers into portfolio (transfers in - transfers out)
    final invested = ref.watch(portfolioTotalInvestedProvider);

    // Profit/Loss calculated against invested (net transfers)
    final totalProfitLoss = totalValue - invested;
    final profitLossPercent = invested > 0 ? (totalProfitLoss / invested) * 100 : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'transactions') {
                context.push('/portfolio/transactions');
              } else if (value == 'transfer') {
                _showTransferDialog(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'transactions', child: Text('Transactions')),
              PopupMenuItem(value: 'transfer', child: Text('Transfer')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.green, Colors.teal]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Portfolio Value', style: TextStyle(color: Color.fromRGBO(255, 255, 255, 0.9), fontSize: 14)),
                const SizedBox(height: 8),
                Text(currencyFormat.format(totalValue), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(totalProfitLoss >= 0 ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${totalProfitLoss >= 0 ? '+' : ''}${currencyFormat.format(totalProfitLoss)} (${totalProfitLoss >= 0 ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%)',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Icon(Icons.account_balance_wallet, size: 20),
                          const SizedBox(height: 4),
                          const Text('Cash', style: TextStyle(fontSize: 12)),
                          Text(currencyFormat.format(cashAvailable), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Icon(Icons.attach_money, size: 20),
                          const SizedBox(height: 4),
                          const Text('Invested', style: TextStyle(fontSize: 12)),
                          // Show net invested (transfers in - transfers out)
                          Text(currencyFormat.format(invested), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Icon(Icons.show_chart, size: 20),
                          const SizedBox(height: 4),
                          const Text('Holdings', style: TextStyle(fontSize: 12)),
                          Text(currencyFormat.format(holdingsValue), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: holdings.isEmpty
                ? const Center(child: Text('No holdings'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: holdings.length,
                    itemBuilder: (context, index) {
                      final holding = holdings[index];
                      final isPositive = holding.profitLoss >= 0;
                      return InkWell(
                        onTap: () => context.push('/portfolio/holdings/${holding.symbol}'),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(holding.symbol, style: Theme.of(context).textTheme.titleMedium),
                                    Text(currencyFormat.format(holding.currentValue), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${holding.quantity} shares @ Rs ${holding.averagePrice.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall),
                                    Text(
                                      '${isPositive ? '+' : ''}${holding.profitLossPercent.toStringAsFixed(2)}%',
                                      style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/portfolio/add-transaction'),
        tooltip: 'Add transaction',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showTransferDialog(BuildContext context, WidgetRef ref) {
    final accounts = ref.read(accountProvider);
    showDialog(
      context: context,
      builder: (context) {
        String? selectedAccountId = accounts.isNotEmpty ? accounts.first.id : null;
        bool toPortfolio = true; // true: account -> portfolio, false: portfolio -> account
        final _formKey = GlobalKey<FormState>();
        final _amountCtrl = TextEditingController();
        final _noteCtrl = TextEditingController();

        return AlertDialog(
          title: const Text('Transfer funds'),
          content: StatefulBuilder(builder: (context, setState) {
            return Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('From account → Portfolio'),
                          selected: toPortfolio,
                          onSelected: (v) => setState(() => toPortfolio = true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Portfolio → Account'),
                          selected: !toPortfolio,
                          onSelected: (v) => setState(() => toPortfolio = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (accounts.isEmpty) const Text('No accounts available. Create an account first.'),
                  if (accounts.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: selectedAccountId,
                      items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                      onChanged: (v) => setState(() => selectedAccountId = v),
                      decoration: const InputDecoration(labelText: 'Account', border: OutlineInputBorder()),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountCtrl,
                    decoration: const InputDecoration(labelText: 'Amount', prefixText: 'Rs ', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final a = double.tryParse(v);
                      if (a == null || a <= 0) return 'Enter valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: _noteCtrl, decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder())),
                ],
              ),
            );
          }),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final amount = double.parse(_amountCtrl.text);
                if (selectedAccountId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select an account')));
                  return;
                }

                final portfolioCash = ref.read(portfolioCashProvider);

                if (toPortfolio) {
                  // Check account balance
                  final acc = ref.read(accountProvider.notifier).getAccountById(selectedAccountId!);
                  if (acc == null || acc.currentBalance < amount) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient account balance')));
                    return;
                  }
                  await ref.read(portfolioTransferProvider.notifier).transferFromAccountToPortfolio(selectedAccountId!, amount, note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text);
                } else {
                  // portfolio -> account
                  if (portfolioCash < amount) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient portfolio cash')));
                    return;
                  }
                  await ref.read(portfolioTransferProvider.notifier).transferFromPortfolioToAccount(selectedAccountId!, amount, note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text);
                }


                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer completed')));
                Navigator.pop(context);
              },
              child: const Text('Transfer'),
            ),
          ],
        );
      },
    );
  }
}
