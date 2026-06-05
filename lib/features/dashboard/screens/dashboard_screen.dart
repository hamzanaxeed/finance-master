import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/transaction.dart' as tmodel;

import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/transaction_provider.dart';
import '../../../shared/providers/budget_provider.dart';
import '../../../shared/providers/loan_provider.dart';
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
    final budgets = ref.watch(budgetProvider);
    final loans = ref.watch(loanProvider);
    final totalDebt = ref.watch(totalDebtProvider);

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
                  icon: Icons.arrow_upward,
                  color: Colors.green,
                  subtitle: 'This month',
                ),
                StatCard(
                  title: 'Monthly Expense',
                  value: currencyFormat.format(monthlyExpense),
                  icon: Icons.arrow_downward,
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

            // Debt Alert
            if (totalDebt > 0)
              Card(
                color: Colors.orange.shade50,
                child: InkWell(
                  onTap: () => context.push('/loans'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.credit_card,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Debt',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${currencyFormat.format(totalDebt)} outstanding',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                  title: 'Budgets',
                  icon: Icons.pie_chart,
                  count: '${budgets.length} active',
                  onTap: () => context.push('/budgets'),
                ),
                QuickLinkCard(
                  title: 'Loans',
                  icon: Icons.credit_card,
                  count: '${loans.length} active',
                  onTap: () => context.push('/loans'),
                ),
                QuickLinkCard(
                  title: 'Analytics',
                  icon: Icons.analytics,
                  count: 'Insights',
                  onTap: () => context.push('/analytics'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // View All Features
            Card(
              child: InkWell(
                onTap: () => context.go('/more'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View All Features',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Access transactions, activity timeline & more',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.arrow_forward,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
