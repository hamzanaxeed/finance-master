import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/portfolio.dart';
import '../../../shared/providers/portfolio_provider.dart';

class AddStockTransactionScreen extends ConsumerStatefulWidget {
  final String? initialSymbol;
  final StockTransactionType? initialType;
  final double? initialPrice;
  final double? initialQuantity;

  const AddStockTransactionScreen({super.key, this.initialSymbol, this.initialType, this.initialPrice, this.initialQuantity});

  @override
  ConsumerState<AddStockTransactionScreen> createState() => _AddStockTransactionScreenState();
}

class _AddStockTransactionScreenState extends ConsumerState<AddStockTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _commissionController = TextEditingController(text: '0');

  StockTransactionType _selectedType = StockTransactionType.buy;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _symbolController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Prefill if initial values were provided
    final w = widget as AddStockTransactionScreen;
    if (w.initialSymbol != null) _symbolController.text = w.initialSymbol!.toUpperCase();
    if (w.initialPrice != null) _priceController.text = w.initialPrice!.toStringAsFixed(2);
    if (w.initialQuantity != null) _quantityController.text = w.initialQuantity!.toStringAsFixed(2);
    if (w.initialType != null) _selectedType = w.initialType!;
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final transaction = StockTransaction(
        symbol: _symbolController.text.toUpperCase(),
        type: _selectedType,
        quantity: double.parse(_quantityController.text),
        price: double.parse(_priceController.text),
        commission: double.parse(_commissionController.text),
        date: _selectedDate,
      );

      ref.read(stockTransactionProvider.notifier).addTransaction(transaction);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction added successfully')),
      );

      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Stock Transaction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('BUY'),
                    selected: _selectedType == StockTransactionType.buy,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedType = StockTransactionType.buy);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('SELL'),
                    selected: _selectedType == StockTransactionType.sell,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedType = StockTransactionType.sell);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _symbolController,
              decoration: const InputDecoration(labelText: 'Symbol', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price per Share', prefixText: 'Rs ', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commissionController,
              decoration: const InputDecoration(labelText: 'Commission', prefixText: 'Rs ', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
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
                if (date != null) setState(() => _selectedDate = date);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
                child: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              ),
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
