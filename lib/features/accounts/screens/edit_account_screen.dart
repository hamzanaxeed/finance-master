import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/account.dart';
import '../../../shared/providers/account_provider.dart';

class EditAccountScreen extends ConsumerStatefulWidget {
  final String accountId;

  const EditAccountScreen({super.key, required this.accountId});

  @override
  ConsumerState<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends ConsumerState<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  AccountType? _selectedType;
  String? _selectedCurrency;

  // Hide savings, investment and cash from the editable dropdown options
  List<AccountType> get _visibleAccountTypes => AccountType.values.where((t) {
        return t != AccountType.savings && t != AccountType.investment && t != AccountType.cash;
      }).toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final account = ref.read(accountProvider.notifier).getAccountById(widget.accountId);
      if (account != null) {
        _nameController.text = account.name;
        _selectedType = account.type;
        _selectedCurrency = account.currency;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate() && _selectedType != null && _selectedCurrency != null) {
      final account = ref.read(accountProvider.notifier).getAccountById(widget.accountId);
      if (account != null) {
        ref.read(accountProvider.notifier).updateAccount(
          widget.accountId,
          account.copyWith(
            name: _nameController.text.trim(),
            type: _selectedType,
            currency: _selectedCurrency,
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account updated successfully')),
        );

        context.pop();
      }
    }
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete this account?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(accountProvider.notifier).deleteAccount(widget.accountId);
              context.pop();
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deleted')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider.notifier).getAccountById(widget.accountId);

    if (account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account Not Found')),
        body: const Center(child: Text('Account not found')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'Edit Account',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              tooltip: 'Delete Account',
              onPressed: _handleDelete,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // Section: Basic Info
            Text(
              'Account Details',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Account Name',
                hintText: 'e.g., Personal Savings',
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter account name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<AccountType>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Account Type',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              items: [
                ..._visibleAccountTypes,
                if (_selectedType != null && !_visibleAccountTypes.contains(_selectedType)) _selectedType!,
              ].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 20),

            // Section: Preferences
            Text(
              'Currency Settings',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: InputDecoration(
                labelText: 'Currency',
                prefixIcon: const Icon(Icons.payments_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              items: ['PKR', 'USD', 'EUR', 'GBP', 'JPY'].map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text(currency),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCurrency = value);
              },
            ),
            const SizedBox(height: 40),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _handleSubmit,
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
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
