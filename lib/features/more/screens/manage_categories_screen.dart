import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/transaction_provider.dart';
import '../../../shared/models/transaction.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryProvider);

    Future<void> _addCategoryDialog(TransactionType type) async {
      final ctrl = TextEditingController();
      final name = await showDialog<String?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add category'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Category name'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Add')),
          ],
        ),
      );

      if (name != null && name.isNotEmpty) {
        await ref.read(categoryProvider.notifier).addCategory(type, name);
      }
    }

    Future<void> _confirmDelete(TransactionType type, String name) async {
      final ok = await showDialog<bool?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete category'),
          content: Text('Delete "$name" from ${type == TransactionType.income ? 'Income' : 'Expense'} categories?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        ),
      );

      if (ok == true) {
        await ref.read(categoryProvider.notifier).deleteCategory(type, name);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Income categories', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...categories.income.map((c) => Card(
                child: ListTile(
                  title: Text(c),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(TransactionType.income, c),
                  ),
                ),
              )),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _addCategoryDialog(TransactionType.income),
            icon: const Icon(Icons.add),
            label: const Text('Add income category'),
          ),
          const SizedBox(height: 24),
          Text('Expense categories', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...categories.expense.map((c) => Card(
                child: ListTile(
                  title: Text(c),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(TransactionType.expense, c),
                  ),
                ),
              )),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _addCategoryDialog(TransactionType.expense),
            icon: const Icon(Icons.add),
            label: const Text('Add expense category'),
          ),
        ],
      ),
    );
  }
}
