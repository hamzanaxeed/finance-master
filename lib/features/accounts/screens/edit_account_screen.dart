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
      appBar: AppBar(
        title: const Text('Edit Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter account name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AccountType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Account Type',
                border: OutlineInputBorder(),
              ),
              // Only show allowed types; if the current account has a hidden type include it so the field's value is valid
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
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCurrency,
              decoration: const InputDecoration(
                labelText: 'Currency',
                border: OutlineInputBorder(),
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
                    child: const Text('Save Changes'),
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
