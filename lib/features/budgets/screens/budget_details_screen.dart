import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/budget_provider.dart';

class BudgetDetailsScreen extends ConsumerWidget {
  final String budgetId;

  const BudgetDetailsScreen({super.key, required this.budgetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(budgetProvider.notifier).getBudgetById(budgetId);

    if (budget == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Budget Not Found')),
        body: const Center(child: Text('Budget not found')),
      );
    }

    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);
    final percent = budget.percentUsed;
    final isOver = budget.isOverBudget;

    return Scaffold(
      appBar: AppBar(title: Text(budget.category)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    currencyFormat.format(budget.remaining),
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: isOver ? Colors.red : Colors.green),
                  ),
                  Text('Remaining', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(isOver ? Colors.red : percent > 80 ? Colors.orange : Colors.green),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('${percent.toStringAsFixed(1)}% of budget used', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Monthly Limit', value: currencyFormat.format(budget.monthlyLimit)),
          _InfoRow(label: 'Spent', value: currencyFormat.format(budget.spent)),
          _InfoRow(label: 'Remaining', value: currencyFormat.format(budget.remaining)),
          _InfoRow(label: 'Period', value: budget.period),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
