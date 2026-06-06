import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/transaction_provider.dart';
import '../../../shared/models/account.dart';
import '../../../shared/models/transaction.dart';

class AccountDetailsScreen extends ConsumerStatefulWidget {
  final String accountId;

  const AccountDetailsScreen({super.key, required this.accountId});

  @override
  ConsumerState<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends ConsumerState<AccountDetailsScreen> {
  String _sortOption = 'date_desc';
  TransactionType? _filterType;

  @override
  Widget build(BuildContext context) {
    final accountId = widget.accountId;
    final account = ref.watch(accountProvider.notifier).getAccountById(accountId);
    final allTransactions = ref.watch(transactionProvider);
    final accountTransactions = allTransactions.where((t) => t.accountId == accountId).toList();
    // apply filtering first
    final filteredTransactions = _filterType == null
        ? accountTransactions
        : accountTransactions.where((t) => t.type == _filterType).toList();
    // apply sorting locally
    final displayedTransactions = List.of(filteredTransactions);
    switch (_sortOption) {
      case 'date_desc':
        displayedTransactions.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'date_asc':
        displayedTransactions.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'amount_desc':
        displayedTransactions.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        displayedTransactions.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      default:
        displayedTransactions.sort((a, b) => b.date.compareTo(a.date));
    }

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
                Row(
                  children: [
                    Text(
                      'Transactions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${displayedTransactions.length} total)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    // moved filter popup next to title

                  ],
                ),
                PopupMenuButton<String>(
                  tooltip: 'Filter transactions',
                  icon: const Icon(Icons.filter_list, size: 20),
                  onSelected: (v) {
                    setState(() {
                      switch (v) {
                        case 'all':
                          _filterType = null;
                          break;
                        case 'income':
                          _filterType = TransactionType.income;
                          break;
                        case 'expense':
                          _filterType = TransactionType.expense;
                          break;
                        case 'transfer':
                          _filterType = TransactionType.transfer;
                          break;
                      }
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'all', child: Text('All')),
                    const PopupMenuItem(value: 'income', child: Text('Income')),
                    const PopupMenuItem(value: 'expense', child: Text('Expense')),
                    const PopupMenuItem(value: 'transfer', child: Text('Transfer')),
                  ],
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
                : Column(
                    children: [

                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: displayedTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = displayedTransactions[index];
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


class _SortOptionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _SortOptionButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        // Modern replacements for primary and onPrimary
        backgroundColor: isSelected ? theme.colorScheme.primary : null,
        foregroundColor: isSelected ? Colors.white : null,
        textStyle: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      child: Text(label),
    );
  }
}
