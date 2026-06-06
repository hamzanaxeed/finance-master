import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/models/account.dart';

class AccountsListScreen extends ConsumerWidget {
  const AccountsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountProvider);
    final totalAssets = ref.watch(totalAssetsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);

    final totalGain = accounts.fold(0.0, (sum, acc) => sum + acc.gain);
    final gainPercent = accounts.fold(0.0, (sum, acc) => sum + acc.initialBalance) > 0
        ? (totalGain /
                accounts.fold(0.0, (sum, acc) => sum + acc.initialBalance)) *
            100
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Accounts'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/accounts/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Net Worth',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(totalAssets),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(

                ),
              ],
            ),
          ),
          Expanded(
            child: accounts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No accounts yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => context.push('/accounts/add'),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Account'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      return _AccountCard(account: account);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;

  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);
    final isPositive = account.gain >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/accounts/${account.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getAccountColor(account.type).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getAccountIcon(account.type),
                  color: _getAccountColor(account.type),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${account.type.name.toUpperCase()} • ${account.currency}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(account.currentBalance),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.wallet:
        return Icons.account_balance_wallet;
      case AccountType.savings:
        return Icons.savings;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.cash:
        return Icons.attach_money;
    }
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
