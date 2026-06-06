import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/transaction_provider.dart';
import '../../../shared/models/transaction.dart';

class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends ConsumerState<TransactionsListScreen> {
  TransactionType? _filterType;
  String _sortOption = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionProvider);
    final filteredTransactions = _filterType == null
        ? allTransactions
        : allTransactions.where((t) => t.type == _filterType).toList();

    // apply sorting to a local list (do not modify provider state)
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

    final monthlyIncome = ref.watch(monthlyIncomeProvider);
    final monthlyExpense = ref.watch(monthlyExpenseProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    final uri = GoRouterState.of(context).uri;
    final fromNav = uri.queryParameters['from'] == 'nav';

    return Scaffold(
      appBar: AppBar(
        // show back button only when opened via external link (not from bottom nav)
        leading: fromNav
            ? null
            : (Navigator.of(context).canPop()

                ? const BackButton()
                : IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/'))),
        title: const Text('Transactions'),
        actions: [
          // Add button moved to floating action button
          // filter moved to inline selector below (replaced chips)
          PopupMenuButton<String>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sortOption = v),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'date_desc', child: Text('Date: Newest')),
              const PopupMenuItem(value: 'date_asc', child: Text('Date: Oldest')),
              const PopupMenuItem(value: 'amount_desc', child: Text('Amount: High → Low')),
              const PopupMenuItem(value: 'amount_asc', child: Text('Amount: Low → High')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        tooltip: 'Add transaction',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Income',
                    value: currencyFormat.format(monthlyIncome),
                    color: Colors.green,
                    icon: Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Expense',
                    value: currencyFormat.format(monthlyExpense),
                    color: Colors.red,
                    icon: Icons.arrow_upward,
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
                // Left: descriptive title reflecting the current filter
                Builder(builder: (context) {
                  final title = _filterType == null
                      ? 'All transactions'
                      : (_filterType == TransactionType.income
                          ? 'Income transactions'
                          : (_filterType == TransactionType.expense ? 'Expense transactions' : 'Transfer transactions'));
                  return Text(title, style: Theme.of(context).textTheme.bodyMedium);
                }),

                // Right: compact selector to change the filter
                Builder(builder: (context) {
                  final filterLabel = _filterType == null
                      ? 'All'
                      : (_filterType == TransactionType.income
                          ? 'Income'
                          : (_filterType == TransactionType.expense ? 'Expense' : 'Transfer'));

                  return PopupMenuButton<String>(
                    tooltip: 'Filter transactions',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(filterLabel),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                    onSelected: (v) => setState(() {
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
                    }),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'all', child: Text('All')),
                      const PopupMenuItem(value: 'income', child: Text('Income')),
                      const PopupMenuItem(value: 'expense', child: Text('Expense')),
                      const PopupMenuItem(value: 'transfer', child: Text('Transfer')),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: displayedTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha((0.3 * 255).round()),
                        ),
                        const SizedBox(height: 16),
                        const Text('No transactions yet'),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => context.push('/transactions/add'),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Transaction'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: displayedTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = displayedTransactions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getTransactionColor(transaction.type).withAlpha((0.1 * 255).round()),
                            child: Icon(
                              _getTransactionIcon(transaction.type),
                              color: _getTransactionColor(transaction.type),
                            ),
                          ),
                          title: Text(transaction.category),
                          subtitle: Text(
                            DateFormat.yMMMd().format(transaction.date),
                          ),
                          trailing: Text(
                            '${transaction.type == TransactionType.income ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                            style: TextStyle(
                              color: _getTransactionColor(transaction.type),
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

  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
    }
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.arrow_downward;
      case TransactionType.expense:
        return Icons.arrow_upward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withAlpha((0.1 * 255).round()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
