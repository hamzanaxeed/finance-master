import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/transaction.dart' as tmodel;

import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/transaction_provider.dart';
import '../../../shared/providers/portfolio_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_link_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAssets = ref.watch(totalAssetsProvider);
    final monthlyIncome = ref.watch(monthlyIncomeProvider);
    final monthlyExpense = ref.watch(monthlyExpenseProvider);
    final cashflow = monthlyIncome - monthlyExpense;
    final transactions = ref.watch(transactionProvider);

    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Master', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // open global search
              showSearch(
                context: context,
                delegate: GlobalSearchDelegate(
                  transactions: transactions,
                  accounts: ref.read(accountProvider),
                  holdings: ref.read(holdingsProvider),
                  currencyFormat: currencyFormat,
                ),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stat Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  title: 'Total Assets',
                  value: currencyFormat.format(totalAssets),
                  icon: Icons.account_balance_wallet,
                  color: Colors.blue,
                  trend: '+2.5%',
                ),
                StatCard(
                  title: 'Monthly Income',
                  value: currencyFormat.format(monthlyIncome),
                  icon: Icons.arrow_downward,
                  color: Colors.green,
                  subtitle: 'This month',
                ),
                StatCard(
                  title: 'Monthly Expense',
                  value: currencyFormat.format(monthlyExpense),
                  icon: Icons.arrow_upward,
                  color: Colors.red,
                  subtitle: 'This month',
                ),
                StatCard(
                  title: 'Cashflow',
                  value: '${cashflow >= 0 ? '+' : ''}${currencyFormat.format(cashflow)}',
                  icon: Icons.attach_money,
                  color: cashflow >= 0 ? Colors.purple : Colors.orange,
                  subtitle: cashflow >= 0 ? 'Surplus' : 'Deficit',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recent Transactions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Constrain title to avoid overflow and allow theme-driven style changes
                        Expanded(
                          child: Text(
                            'Recent Transactions',
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        // Keep button non-const so it uses current theme text style safely
                        TextButton(
                          onPressed: () => context.push('/transactions'),
                          child: Text('View all', style: Theme.of(context).textTheme.labelLarge),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...transactions.take(5).map((txn) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: txn.type == tmodel.TransactionType.income
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          child: Icon(
                            txn.type == tmodel.TransactionType.income
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: txn.type == tmodel.TransactionType.income
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        title: Text(txn.category),
                        subtitle: Text(
                          DateFormat.yMMMd().format(txn.date),
                        ),
                        trailing: Text(
                          '${txn.type == tmodel.TransactionType.income ? '+' : '-'}${currencyFormat.format(txn.amount)}',
                          style: TextStyle(
                            color: txn.type == tmodel.TransactionType.income
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => context.push('/transactions/${txn.id}'),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Links

          ],
        ),
      ),
    );
  }
}

class GlobalSearchDelegate extends SearchDelegate {
  final List transactions;
  final List accounts;
  final List holdings;
  final NumberFormat currencyFormat;

  GlobalSearchDelegate({required this.transactions, required this.accounts, required this.holdings, required this.currencyFormat});

  @override
  String? get searchFieldLabel => 'Search transactions, accounts, holdings';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) {
    final q = query.toLowerCase();
    final txnResults = transactions.where((t) {
      try {
        return (t.category.toLowerCase().contains(q) || t.accountId.toLowerCase().contains(q) || t.amount.toString().contains(q));
      } catch (_) {
        return false;
      }
    }).toList();

    final accResults = accounts.where((a) {
      try {
        return (a.name.toLowerCase().contains(q) || a.type.toLowerCase().contains(q));
      } catch (_) {
        return false;
      }
    }).toList();

    final holdResults = holdings.where((h) {
      try {
        return (h.symbol.toLowerCase().contains(q) || h.companyName.toLowerCase().contains(q));
      } catch (_) {
        return false;
      }
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (txnResults.isNotEmpty) ...[
          Text('Transactions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...txnResults.map((t) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: t.type == tmodel.TransactionType.income ? Colors.green.shade100 : Colors.red.shade100,
                  child: Icon(t.type == tmodel.TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward,
                      color: t.type == tmodel.TransactionType.income ? Colors.green : Colors.red),
                ),
                title: Text(t.category),
                subtitle: Text(DateFormat.yMMMd().format(t.date)),
                trailing: Text('${t.type == tmodel.TransactionType.income ? '+' : '-'}${currencyFormat.format(t.amount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  close(context, null);
                  context.push('/transactions/${t.id}');
                },
              ))
        ],

        if (accResults.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Accounts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...accResults.map((a) => ListTile(
                leading: const Icon(Icons.account_balance),
                title: Text(a.name),
                subtitle: Text('Balance: ${currencyFormat.format(a.currentBalance)}'),
                onTap: () {
                  close(context, null);
                  context.push('/accounts/${a.id}');
                },
              ))
        ],

        if (holdResults.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Holdings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...holdResults.map((h) => ListTile(
                leading: const Icon(Icons.show_chart),
                title: Text(h.symbol),
                subtitle: Text(h.companyName),
                onTap: () {
                  close(context, null);
                  context.push('/portfolio/holdings/${h.symbol}');
                },
              ))
        ],

        if (txnResults.isEmpty && accResults.isEmpty && holdResults.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('No results for "${query}"'))),
      ],
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...transactions.take(6).map((t) => ListTile(
                title: Text(t.category),
                subtitle: Text(DateFormat.yMMMd().format(t.date)),
                onTap: () {
                  query = t.category;
                  showResults(context);
                },
              )),
        ],
      );
    }
    return buildResults(context);
  }
}
