import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/transaction.dart' as tmodel;

import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/transaction_provider.dart';
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
        title: const Text('Finance Master'),

        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search dialog
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
                        Text(
                          'Recent Transactions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TextButton(
                          onPressed: () => context.push('/transactions'),
                          child: const Text('View all'),
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
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                QuickLinkCard(
                  title: 'Transactions',
                  icon: Icons.swap_horiz,
                  count: '${transactions.length} total',
                  onTap: () => context.push('/transactions'),
                ),
                QuickLinkCard(
                  title: 'Analytics',
                  icon: Icons.analytics,
                  count: 'Insights',
                  onTap: () => context.push('/analytics'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
