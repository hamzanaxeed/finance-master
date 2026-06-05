import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/transaction_provider.dart';
import '../../../shared/models/account.dart';
import '../../../shared/models/transaction.dart';

class AccountDetailsScreen extends ConsumerWidget {
  final String accountId;

  const AccountDetailsScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider.notifier).getAccountById(accountId);
    final allTransactions = ref.watch(transactionProvider);
    final accountTransactions = allTransactions.where((t) => t.accountId == accountId).toList();

    if (account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account Not Found')),
        body: const Center(child: Text('Account not found')),
      );
    }

    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);
    final isPositive = account.gain >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/accounts/${account.id}/edit'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getAccountColor(account.type),
                  _getAccountColor(account.type).withAlpha(204),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.type.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withAlpha(230),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(account.currentBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white.withAlpha(230),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}${currencyFormat.format(account.gain)} (${account.gainPercent.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        color: Colors.white.withAlpha(230),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    label: 'Initial Balance',
                    value: currencyFormat.format(account.initialBalance),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    label: 'Currency',
                    value: account.currency,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transactions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${accountTransactions.length} total',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: accountTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(77),
                        ),
                        const SizedBox(height: 16),
                        const Text('No transactions yet'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: accountTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = accountTransactions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: transaction.type == TransactionType.income
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            child: Icon(
                              transaction.type == TransactionType.income
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: transaction.type == TransactionType.income
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          title: Text(transaction.category),
                          subtitle: Text(
                            DateFormat.yMMMd().format(transaction.date),
                          ),
                          trailing: Text(
                            '${transaction.type == TransactionType.income ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                            style: TextStyle(
                              color: transaction.type == TransactionType.income
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () => context.push('/transactions/${transaction.id}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getAccountColor(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return Colors.blue;
      case AccountType.wallet:
        return Colors.purple;
      case AccountType.savings:
        return Colors.green;
      case AccountType.investment:
        return Colors.orange;
      case AccountType.cash:
        return Colors.grey;
    }
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
