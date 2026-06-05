import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/transaction.dart';
import '../../../shared/providers/transaction_provider.dart';
import '../../../shared/providers/account_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String? _selectedCategory;
  String? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<String> _getCategories() {
    switch (_selectedType) {
      case TransactionType.income:
        return TransactionCategories.incomeCategories;
      case TransactionType.expense:
        return TransactionCategories.expenseCategories;
      case TransactionType.transfer:
        return ['Transfer'];
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate() && _selectedAccountId != null && _selectedCategory != null) {
      final amount = double.parse(_amountController.text);

      // Check account balance for expense/transfer
      final account = ref.read(accountProvider.notifier).getAccountById(_selectedAccountId!);
      if (_selectedType == TransactionType.expense && account != null && amount > account.currentBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insufficient account balance for this expense')),
        );
        return;
      }

      final transaction = Transaction(
        type: _selectedType,
        amount: amount,
        category: _selectedCategory!,
        accountId: _selectedAccountId!,
        date: _selectedDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      ref.read(transactionProvider.notifier).addTransaction(transaction);

      // Update account balances immediately
      if (_selectedType == TransactionType.income) {
        ref.read(accountProvider.notifier).updateBalance(_selectedAccountId!, transaction.amount);
      } else if (_selectedType == TransactionType.expense) {
        ref.read(accountProvider.notifier).updateBalance(_selectedAccountId!, -transaction.amount);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction added successfully')),
      );

      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Transaction Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    label: 'Income',
                    icon: Icons.arrow_downward,
                    color: Colors.green,
                    isSelected: _selectedType == TransactionType.income,
                    onTap: () {
                      setState(() {
                        _selectedType = TransactionType.income;
                        _selectedCategory = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeButton(
                    label: 'Expense',
                    icon: Icons.arrow_upward,
                    color: Colors.red,
                    isSelected: _selectedType == TransactionType.expense,
                    onTap: () {
                      setState(() {
                        _selectedType = TransactionType.expense;
                        _selectedCategory = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeButton(
                    label: 'Transfer',
                    icon: Icons.swap_horiz,
                    color: Colors.blue,
                    isSelected: _selectedType == TransactionType.transfer,
                    onTap: () {
                      setState(() {
                        _selectedType = TransactionType.transfer;
                        _selectedCategory = 'Transfer';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'Rs ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Invalid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _getCategories().map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value);
              },
              validator: (value) => value == null ? 'Please select category' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedAccountId,
              decoration: const InputDecoration(
                labelText: 'Account',
                border: OutlineInputBorder(),
              ),
              items: accounts.map((account) {
                return DropdownMenuItem(
                  value: account.id,
                  child: Text(account.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedAccountId = value);
              },
              validator: (value) => value == null ? 'Please select account' : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _handleSubmit,
                    child: const Text('Add Transaction'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(26) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withAlpha(153),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
