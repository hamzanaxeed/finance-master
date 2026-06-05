import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/budget_provider.dart';

class BudgetsListScreen extends ConsumerWidget {
  const BudgetsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    final totalAllocated = budgets.fold(0.0, (sum, b) => sum + b.monthlyLimit);
    final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spent);
    final overBudgetCount = budgets.where((b) => b.isOverBudget).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Budget', style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormat.format(totalAllocated),
                            style: TextStyle(color: Colors.blue.shade900, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Spent', style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormat.format(totalSpent),
                            style: TextStyle(color: Colors.orange.shade900, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (overBudgetCount > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$overBudgetCount budget${overBudgetCount > 1 ? 's are' : ' is'} over limit',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: budgets.isEmpty
                ? const Center(child: Text('No budgets yet'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: budgets.length,
                    itemBuilder: (context, index) {
                      final budget = budgets[index];
                      final percent = budget.percentUsed;
                      final isOver = budget.isOverBudget;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => context.push('/budgets/${budget.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(budget.category, style: Theme.of(context).textTheme.titleMedium),
                                    Text(
                                      '${currencyFormat.format(budget.spent)} / ${currencyFormat.format(budget.monthlyLimit)}',
                                      style: TextStyle(color: isOver ? Colors.red : null, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percent / 100,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation(
                                      isOver ? Colors.red : percent > 80 ? Colors.orange : Colors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('${percent.toStringAsFixed(0)}% used', style: Theme.of(context).textTheme.bodySmall),
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
    );
  }
}
